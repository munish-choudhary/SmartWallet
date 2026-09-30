import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show Sha256;

import '../../features/onboarding/data/bip39_wordlist.dart';
import '../result/result.dart';
import 'envelope.dart' show SecretType;
import 'pin.dart';
import 'private_key_format.dart';
import 'vault.dart';
import 'vault_session.dart';

/// **DEV-ONLY fake implementation of [Vault].** Holds no real key
/// material behind real cryptography — mnemonics are random wordlist
/// picks, "encryption" is an in-memory map, and delays are simulated to
/// approximate the real Argon2id timing. Never wire this into a release
/// build or anything that touches real funds. It exists purely so the
/// onboarding UI can be built and tested before `wallet_core_ffi` has
/// real Trust Wallet Core bindings (see
/// packages/wallet_core_ffi/README.md) and before `VaultImpl`'s
/// pending-wallet flow is implemented (see lib/core/vault/README.md).
///
/// Per CLAUDE.md, mnemonic generation here is deliberately *not* a real
/// BIP-39 implementation (no real entropy/checksum encoding) — CLAUDE.md
/// forbids reimplementing BIP-39 in Dart even for this fake, so words are
/// just random wordlist picks with wordlist-membership validation, not
/// checksum validation.
final class FakeVault implements Vault {
  FakeVault({required this.wordlist, Random? random})
    : _random = random ?? Random.secure();

  final Bip39Wordlist wordlist;
  final Random _random;

  final Map<WalletId, _FakeWalletRecord> _wallets = {};
  final _statusController = StreamController<VaultStatus>.broadcast();
  WalletId? _activeId;
  bool _unlocked = false;
  bool _biometricsEnabled = false;
  Uint8List? _pinHash;

  List<String>? _pendingMnemonic;
  String? _pendingWalletId;
  VerificationChallenge? _pendingChallenge;

  static const _simulatedKdfDelay = Duration(milliseconds: 500);

  void dispose() => unawaited(_statusController.close());

  // ---- existence / status ----

  @override
  Future<bool> hasAnyWallet() async => _wallets.isNotEmpty;

  @override
  Future<Result<WalletId>> activeWalletId() async {
    if (_wallets.isEmpty) return const Result.err(AppFailure.walletNotFound());
    final chosen = _activeId;
    return Result.ok(
      chosen != null && _wallets.containsKey(chosen)
          ? chosen
          : _wallets.keys.first,
    );
  }

  @override
  Future<List<WalletId>> walletIds() async => _wallets.keys.toList();

  @override
  Future<Result<void>> setActiveWallet(WalletId id) async {
    if (!_wallets.containsKey(id)) {
      return const Result.err(AppFailure.walletNotFound());
    }
    _activeId = id;
    return const Result.ok(null);
  }

  @override
  Stream<VaultStatus> get status => _statusController.stream;

  @override
  void lock() => _setUnlocked(false);

  @override
  Future<bool> get isBiometricAvailable async => true;

  // ---- pending-wallet flow (create + verify) ----

  @override
  Future<Result<void>> startPendingWallet({int words = 12}) async {
    assert(words == 12 || words == 24, 'words must be 12 or 24');
    discardPendingWallet();
    _pendingMnemonic = List.generate(
      words,
      (_) => wordlist.words[_random.nextInt(wordlist.words.length)],
    );
    _pendingWalletId = _generateId(_random);
    return const Result.ok(null);
  }

  @override
  Future<Result<List<String>>> pendingPhraseForDisplay() async {
    final mnemonic = _pendingMnemonic;
    if (mnemonic == null) {
      return const Result.err(AppFailure.noPendingWallet());
    }
    return Result.ok(List.unmodifiable(mnemonic));
  }

  @override
  Future<Result<VerificationChallenge>> verificationChallenge() async {
    final mnemonic = _pendingMnemonic;
    if (mnemonic == null) {
      return const Result.err(AppFailure.noPendingWallet());
    }
    final indices = <int>{};
    while (indices.length < 3 && indices.length < mnemonic.length) {
      indices.add(_random.nextInt(mnemonic.length));
    }
    final challenges =
        indices.map((i) {
            final correct = mnemonic[i];
            final distractors = <String>{};
            while (distractors.length < 2) {
              final candidate =
                  wordlist.words[_random.nextInt(wordlist.words.length)];
              if (candidate != correct) distractors.add(candidate);
            }
            final options = [correct, ...distractors]..shuffle(_random);
            return WordChallenge(wordIndex: i + 1, options: options);
          }).toList()
          ..sort((a, b) => a.wordIndex.compareTo(b.wordIndex));
    final challenge = VerificationChallenge(challenges);
    _pendingChallenge = challenge;
    return Result.ok(challenge);
  }

  @override
  Future<Result<WalletId>> confirmPendingWallet({
    required List<String> answers,
    required Pin pin,
  }) async {
    final mnemonic = _pendingMnemonic;
    final challenge = _pendingChallenge;
    final walletId = _pendingWalletId;
    if (mnemonic == null || challenge == null || walletId == null) {
      return const Result.err(AppFailure.noPendingWallet());
    }
    if (answers.length != challenge.challenges.length) {
      return const Result.err(AppFailure.verificationFailed());
    }
    for (var i = 0; i < challenge.challenges.length; i++) {
      final expected = mnemonic[challenge.challenges[i].wordIndex - 1];
      if (answers[i] != expected) {
        return const Result.err(AppFailure.verificationFailed());
      }
    }

    await Future.delayed(_simulatedKdfDelay);
    await _setPin(pin);
    _wallets[walletId] = _FakeWalletRecord.mnemonic(mnemonic.join(' '));
    discardPendingWallet();
    _setUnlocked(true);
    return Result.ok(walletId);
  }

  @override
  void discardPendingWallet() {
    _pendingMnemonic = null;
    _pendingWalletId = null;
    _pendingChallenge = null;
  }

  // ---- validation ----

  @override
  Future<Result<void>> validateMnemonic(String mnemonic) async {
    final words = mnemonic.trim().split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) {
      return const Result.err(AppFailure.invalidMnemonic());
    }
    for (final word in words) {
      if (!wordlist.contains(word)) {
        return const Result.err(AppFailure.invalidMnemonic());
      }
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> validatePrivateKey(
    String key,
    ChainFamily chain,
  ) async {
    return isValidPrivateKeyFormat(key, chain)
        ? const Result.ok(null)
        : const Result.err(AppFailure.invalidPrivateKey());
  }

  // ---- direct create / import (no verification step) ----

  @override
  Future<Result<WalletId>> createWallet({
    required Pin pin,
    int words = 12,
  }) async {
    assert(words == 12 || words == 24, 'words must be 12 or 24');
    final mnemonic = List.generate(
      words,
      (_) => wordlist.words[_random.nextInt(wordlist.words.length)],
    ).join(' ');
    await Future.delayed(_simulatedKdfDelay);
    final walletId = _generateId(_random);
    await _setPin(pin);
    _wallets[walletId] = _FakeWalletRecord.mnemonic(mnemonic);
    _setUnlocked(true);
    return Result.ok(walletId);
  }

  @override
  Future<Result<WalletId>> importMnemonic(
    String mnemonic, {
    required Pin pin,
  }) async {
    final validation = await validateMnemonic(mnemonic);
    if (validation.failureOrNull != null) {
      return Result.err(validation.failureOrNull!);
    }
    await Future.delayed(_simulatedKdfDelay);
    final walletId = _generateId(_random);
    await _setPin(pin);
    _wallets[walletId] = _FakeWalletRecord.mnemonic(mnemonic);
    _setUnlocked(true);
    return Result.ok(walletId);
  }

  @override
  Future<Result<WalletId>> importPrivateKey(
    Uint8List key,
    CoinType coin, {
    required Pin pin,
  }) async {
    if (key.isEmpty) {
      return const Result.err(AppFailure.invalidPrivateKey());
    }
    await Future.delayed(_simulatedKdfDelay);
    final walletId = _generateId(_random);
    await _setPin(pin);
    _wallets[walletId] = _FakeWalletRecord.privateKey(key, coin);
    _setUnlocked(true);
    return Result.ok(walletId);
  }

  // ---- unlock / biometrics / pin ----

  @override
  Future<Result<void>> unlock(Pin pin) async {
    await Future.delayed(_simulatedKdfDelay);
    if (!await _pinMatches(pin)) {
      return const Result.err(AppFailure.wrongPin());
    }
    _setUnlocked(true);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> unlockWithBiometrics() async {
    if (!_biometricsEnabled) {
      return const Result.err(AppFailure.biometricUnavailable());
    }
    await Future.delayed(_simulatedKdfDelay);
    _setUnlocked(true);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> enableBiometrics({required Pin pin}) async {
    if (!await _pinMatches(pin)) return const Result.err(AppFailure.wrongPin());
    _biometricsEnabled = true;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> disableBiometrics({required Pin pin}) async {
    if (!await _pinMatches(pin)) return const Result.err(AppFailure.wrongPin());
    _biometricsEnabled = false;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> changePin({
    required Pin current,
    required Pin next,
  }) async {
    if (!await _pinMatches(current)) {
      return const Result.err(AppFailure.wrongPin());
    }
    await _setPin(next);
    return const Result.ok(null);
  }

  // ---- accounts / secrets / removal ----

  @override
  Future<Result<List<Account>>> accounts(WalletId id) async {
    if (!_unlocked) return const Result.err(AppFailure.vaultLocked());
    final wallet = _wallets[id];
    if (wallet == null) return const Result.err(AppFailure.walletNotFound());
    return Result.ok([
      Account(walletId: id, address: '0xFAKE${id.substring(0, 8)}'),
    ]);
  }

  @override
  Future<Result<SignedPayload>> sign(SignRequest request) async {
    // Signing is out of scope for the onboarding fake vault.
    return const Result.err(AppFailure.notImplemented());
  }

  @override
  Future<Result<SecretReveal>> revealSecret(
    WalletId id, {
    required Pin pin,
  }) async {
    if (!await _pinMatches(pin)) return const Result.err(AppFailure.wrongPin());
    final wallet = _wallets[id];
    if (wallet == null) return const Result.err(AppFailure.walletNotFound());
    final secret = wallet.mnemonic != null
        ? Uint8List.fromList(utf8.encode(wallet.mnemonic!))
        : wallet.key!;
    return Result.ok(SecretReveal(type: wallet.type, secret: secret));
  }

  @override
  Future<Result<Uint8List>> exportPrivateKey(
    WalletId id, {
    required CoinType coin,
    required Pin pin,
  }) async {
    if (!await _pinMatches(pin)) return const Result.err(AppFailure.wrongPin());
    final wallet = _wallets[id];
    if (wallet == null) return const Result.err(AppFailure.walletNotFound());
    if (wallet.key != null) return Result.ok(Uint8List.fromList(wallet.key!));
    final seed = '${wallet.mnemonic}/${coin.name}'.codeUnits;
    return Result.ok(
      Uint8List.fromList([for (var i = 0; i < 32; i++) seed[i % seed.length] ^ i]),
    );
  }

  @override
  Future<Result<void>> removeWallet(WalletId id, {required Pin pin}) async {
    if (!await _pinMatches(pin)) return const Result.err(AppFailure.wrongPin());
    _wallets.remove(id);
    return const Result.ok(null);
  }

  // ---- internals ----

  void _setUnlocked(bool value) {
    _unlocked = value;
    _statusController.add(value ? VaultStatus.unlocked : VaultStatus.locked);
  }

  Future<void> _setPin(Pin pin) async {
    final hash = await Sha256().hash(pin.bytes);
    _pinHash = Uint8List.fromList(hash.bytes);
  }

  Future<bool> _pinMatches(Pin pin) async {
    final stored = _pinHash;
    if (stored == null) return false;
    final hash = await Sha256().hash(pin.bytes);
    if (stored.length != hash.bytes.length) return false;
    var diff = 0;
    for (var i = 0; i < stored.length; i++) {
      diff |= stored[i] ^ hash.bytes[i];
    }
    return diff == 0;
  }
}

String _generateId(Random random) {
  final bytes = Uint8List.fromList(
    List.generate(16, (_) => random.nextInt(256)),
  );
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

final class _FakeWalletRecord {
  const _FakeWalletRecord.mnemonic(this.mnemonic)
    : type = SecretType.mnemonic,
      key = null,
      coin = null;

  const _FakeWalletRecord.privateKey(this.key, this.coin)
    : type = SecretType.privateKey,
      mnemonic = null;

  final SecretType type;
  final String? mnemonic;
  final Uint8List? key;
  final CoinType? coin;
}
