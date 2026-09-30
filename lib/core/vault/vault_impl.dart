import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show SecretBoxAuthenticationError;
import 'package:wallet_core_ffi/wallet_core_ffi.dart' as wc;

import '../result/result.dart';
import 'encryption.dart';
import 'envelope.dart';
import 'envelope_store.dart';
import 'kdf.dart';
import 'lockout_policy.dart';
import 'pin.dart';
import 'private_key_format.dart';
import 'secrets.dart';
import 'vault.dart';
import 'vault_keystore.dart';
import 'vault_session.dart';
import 'wallet_core_gateway.dart';

/// Runs [computation] somewhere off the calling isolate. Defaults to
/// [Isolate.run] in production. Tests inject an identity runner so fakes
/// (mocktail, etc.) — which aren't isolate-transferable — keep working.
typedef IsolateRunner = Future<T> Function<T>(
  FutureOr<T> Function() computation,
);

Uint8List _randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List.generate(length, (_) => random.nextInt(256)),
  );
}

String _defaultGenerateWalletId() {
  final bytes = _randomBytes(16);
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

const _envelopeVersion = 1;
const _saltLength = 16;

/// The concrete [Vault]. See CLAUDE.md's Vault & Key Management section —
/// this implements that spec exactly. A vault may hold several wallets
/// (one HD wallet, plus zero or more imported-key wallets), all unlocked
/// by the same PIN.
final class VaultImpl implements Vault {
  VaultImpl({
    WalletCoreGateway? walletCore,
    KeyDerivation? kdf,
    AesGcmEnvelopeCipher? cipher,
    required VaultKeystore keystore,
    required EnvelopeStore envelopeStore,
    required LockoutPolicy lockoutPolicy,
    required VaultSession session,
    IsolateRunner isolateRunner = Isolate.run,
    String Function() generateWalletId = _defaultGenerateWalletId,
  })  : _walletCore = walletCore ?? const WalletCoreFfiGateway(),
        _kdf = kdf ?? const CryptographyKeyDerivation(),
        _cipher = cipher ?? const AesGcmEnvelopeCipher(),
        _keystore = keystore,
        _envelopeStore = envelopeStore,
        _lockoutPolicy = lockoutPolicy,
        _session = session,
        _isolateRunner = isolateRunner,
        _generateWalletId = generateWalletId;

  final WalletCoreGateway _walletCore;
  final KeyDerivation _kdf;
  final AesGcmEnvelopeCipher _cipher;
  final VaultKeystore _keystore;
  final EnvelopeStore _envelopeStore;
  final LockoutPolicy _lockoutPolicy;
  final VaultSession _session;
  final IsolateRunner _isolateRunner;
  final String Function() _generateWalletId;

  static const _biometricPinAlias = 'biometric_pin';
  String _walletKeyAlias(String walletId) => 'wallet_$walletId';

  @override
  Stream<VaultStatus> get status => _session.status;

  @override
  void lock() => _session.clear();

  @override
  Future<bool> get isBiometricAvailable => _keystore.isStrongBiometricAvailable();

  @override
  Future<bool> hasAnyWallet() async =>
      (await _envelopeStore.listWalletIds()).isNotEmpty;

  @override
  Future<Result<WalletId>> activeWalletId() async {
    final ids = await _envelopeStore.listWalletIds();
    if (ids.isEmpty) return const Result.err(AppFailure.walletNotFound());
    final chosen = await _envelopeStore.readActiveWalletId();
    return Result.ok(chosen != null && ids.contains(chosen) ? chosen : ids.first);
  }

  @override
  Future<List<WalletId>> walletIds() => _envelopeStore.listWalletIds();

  @override
  Future<Result<void>> setActiveWallet(WalletId id) async {
    if (!(await _envelopeStore.listWalletIds()).contains(id)) {
      return const Result.err(AppFailure.walletNotFound());
    }
    await _envelopeStore.writeActiveWalletId(id);
    return const Result.ok(null);
  }

  // ---- pending-wallet flow ----
  // Not implemented yet — VaultImpl already has every piece this needs
  // (kdf/cipher/keystore/envelopeStore), but wiring it up for real is a
  // deliberate follow-up (tracked in lib/core/vault/README.md) kept out of
  // this pass to limit scope. `FakeVault` implements the full flow now so
  // the onboarding UI can be built and tested against it.

  @override
  Future<Result<void>> startPendingWallet({int words = 12}) async =>
      const Result.err(AppFailure.notImplemented());

  @override
  Future<Result<List<String>>> pendingPhraseForDisplay() async =>
      const Result.err(AppFailure.notImplemented());

  @override
  Future<Result<VerificationChallenge>> verificationChallenge() async =>
      const Result.err(AppFailure.notImplemented());

  @override
  Future<Result<WalletId>> confirmPendingWallet({
    required List<String> answers,
    required Pin pin,
  }) async => const Result.err(AppFailure.notImplemented());

  @override
  void discardPendingWallet() {}

  @override
  Future<Result<void>> validateMnemonic(String mnemonic) async {
    if (!_walletCore.isValidMnemonic(mnemonic)) {
      return const Result.err(AppFailure.invalidMnemonic());
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

  // ---- creation / import ----

  @override
  Future<Result<WalletId>> createWallet({required Pin pin, int words = 12}) {
    assert(words == 12 || words == 24, 'words must be 12 or 24');
    final strength = words == 24 ? 256 : 128;
    final mnemonic = _walletCore.createMnemonic(strength: strength);
    return _storeNewSecret(
      pin: pin,
      type: SecretType.mnemonic,
      secretBytes: Uint8List.fromList(utf8.encode(mnemonic)),
      coin: null,
    );
  }

  @override
  Future<Result<WalletId>> importMnemonic(String mnemonic, {required Pin pin}) {
    if (!_walletCore.isValidMnemonic(mnemonic)) {
      return Future.value(const Result.err(AppFailure.invalidMnemonic()));
    }
    return _storeNewSecret(
      pin: pin,
      type: SecretType.mnemonic,
      secretBytes: Uint8List.fromList(utf8.encode(mnemonic)),
      coin: null,
    );
  }

  @override
  Future<Result<WalletId>> importPrivateKey(
    Uint8List key,
    wc.CoinType coin, {
    required Pin pin,
  }) async {
    try {
      _walletCore.addressForImportedKey(key, coin);
    } on ArgumentError {
      return const Result.err(AppFailure.invalidPrivateKey());
    }
    return _storeNewSecret(
      pin: pin,
      type: SecretType.privateKey,
      secretBytes: key,
      coin: coin,
    );
  }

  Future<Result<WalletId>> _storeNewSecret({
    required Pin pin,
    required SecretType type,
    required Uint8List secretBytes,
    required wc.CoinType? coin,
  }) async {
    final walletId = _generateWalletId();
    try {
      final salt = _randomBytes(_saltLength);
      final kdfParams = _kdf.defaultParams();
      final kek = await _isolateRunner(
        () => _kdf.deriveKek(pin: pin.bytes, salt: salt, params: kdfParams),
      );
      final (nonce, ct) = await _cipher.encrypt(
        plaintext: secretBytes,
        kek: kek,
        walletId: walletId,
        envelopeVersion: _envelopeVersion,
      );
      final envelope = Envelope(
        v: _envelopeVersion,
        walletId: walletId,
        type: type,
        kdf: kdfParams,
        salt: base64Encode(salt),
        nonce: base64Encode(nonce),
        ct: base64Encode(ct),
      );
      final wrapped = await _keystore.wrap(
        keyAlias: _walletKeyAlias(walletId),
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(envelope.toJson()))),
      );
      await _envelopeStore.writeWrapped(walletId, wrapped);
      await _envelopeStore.addWalletId(walletId);
      await _envelopeStore.writeMeta(walletId, {
        'type': type.name,
        'coin': coin?.name,
      });
      _session.open({walletId: kek});
      return Result.ok(walletId);
    } finally {
      zeroize(secretBytes);
    }
  }

  // ---- unlock ----

  @override
  Future<Result<void>> unlock(Pin pin) async {
    final remaining = await _lockoutPolicy.remainingLockout();
    if (remaining != null) {
      return Result.err(AppFailure.vaultLockedOut(remaining));
    }

    final verified = await _verifyPinAgainstAllWallets(pin);
    return verified.when(
      ok: (keksByWalletId) async {
        await _lockoutPolicy.recordSuccess();
        _session.open(keksByWalletId);
        return const Result.ok(null);
      },
      err: (failure) async {
        await _lockoutPolicy.recordFailure();
        final remaining = await _lockoutPolicy.remainingLockout();
        if (remaining != null) {
          return Result.err(AppFailure.vaultLockedOut(remaining));
        }
        return Result.err(failure);
      },
    );
  }

  @override
  Future<Result<void>> unlockWithBiometrics() async {
    final wrapped = await _envelopeStore.readBiometricPin();
    if (wrapped == null) {
      return const Result.err(AppFailure.biometricUnavailable());
    }
    late final Uint8List pinBytes;
    try {
      pinBytes = await _keystore.unwrap(
        keyAlias: _biometricPinAlias,
        wrapped: wrapped,
      );
    } on VaultKeystoreInvalidatedException {
      await _envelopeStore.deleteBiometricPin();
      return const Result.err(AppFailure.biometricUnavailable());
    }
    final pin = Pin.fromBytes(pinBytes);
    try {
      return await unlock(pin);
    } finally {
      pin.dispose();
    }
  }

  /// Attempts to decrypt every wallet's envelope with [pin]. All must
  /// succeed or none are considered unlocked — a single shared PIN across
  /// the vault's wallets.
  Future<Result<Map<String, Uint8List>>> _verifyPinAgainstAllWallets(
    Pin pin,
  ) async {
    final walletIds = await _envelopeStore.listWalletIds();
    final keksByWalletId = <String, Uint8List>{};
    try {
      for (final walletId in walletIds) {
        final kek = await _decryptEnvelopeKek(walletId, pin);
        if (kek == null) {
          for (final k in keksByWalletId.values) {
            zeroize(k);
          }
          return const Result.err(AppFailure.wrongPin());
        }
        keksByWalletId[walletId] = kek;
      }
      return Result.ok(keksByWalletId);
    } catch (_) {
      for (final k in keksByWalletId.values) {
        zeroize(k);
      }
      return const Result.err(AppFailure.wrongPin());
    }
  }

  /// Returns the derived KEK if [pin] unlocks [walletId]'s envelope, or
  /// `null` on a wrong PIN / tampered ciphertext / invalidated hardware key.
  Future<Uint8List?> _decryptEnvelopeKek(String walletId, Pin pin) async {
    final envelope = await _readEnvelope(walletId);
    if (envelope == null) return null;
    final salt = base64Decode(envelope.salt);
    final kek = await _isolateRunner(
      () => _kdf.deriveKek(pin: pin.bytes, salt: salt, params: envelope.kdf),
    );
    try {
      await _cipher.decrypt(
        nonce: base64Decode(envelope.nonce),
        ciphertextWithTag: base64Decode(envelope.ct),
        kek: kek,
        walletId: walletId,
        envelopeVersion: envelope.v,
      );
      return kek;
    } on SecretBoxAuthenticationError {
      zeroize(kek);
      return null;
    }
  }

  Future<Envelope?> _readEnvelope(String walletId) async {
    final wrapped = await _envelopeStore.readWrapped(walletId);
    if (wrapped == null) return null;
    final Uint8List unwrapped;
    try {
      unwrapped = await _keystore.unwrap(
        keyAlias: _walletKeyAlias(walletId),
        wrapped: wrapped,
      );
    } on VaultKeystoreInvalidatedException {
      return null;
    }
    final json = jsonDecode(utf8.decode(unwrapped)) as Map<String, Object?>;
    return Envelope.fromJson(json);
  }

  /// Decrypts wallet [walletId]'s secret using the already-unlocked
  /// session KEK (no PIN needed — caller must already hold an unlocked
  /// session for this wallet).
  Future<Uint8List> _decryptSecretWithSessionKek(String walletId) async {
    final kek = _session.kekFor(walletId);
    if (kek == null) {
      throw StateError('wallet $walletId is not unlocked');
    }
    final envelope = await _readEnvelope(walletId);
    if (envelope == null) {
      throw StateError('wallet $walletId has no envelope');
    }
    return _cipher.decrypt(
      nonce: base64Decode(envelope.nonce),
      ciphertextWithTag: base64Decode(envelope.ct),
      kek: kek,
      walletId: walletId,
      envelopeVersion: envelope.v,
    );
  }

  // ---- biometrics ----

  @override
  Future<Result<void>> enableBiometrics({required Pin pin}) async {
    final verified = await _verifyPinAgainstAllWallets(pin);
    return verified.when(
      ok: (keks) async {
        for (final k in keks.values) {
          zeroize(k);
        }
        final wrapped = await _keystore.wrap(
          keyAlias: _biometricPinAlias,
          bytes: pin.bytes,
        );
        await _envelopeStore.writeBiometricPin(wrapped);
        return const Result.ok(null);
      },
      err: (failure) async => Result.err(failure),
    );
  }

  @override
  Future<Result<void>> disableBiometrics({required Pin pin}) async {
    final verified = await _verifyPinAgainstAllWallets(pin);
    return verified.when(
      ok: (keks) async {
        for (final k in keks.values) {
          zeroize(k);
        }
        await _envelopeStore.deleteBiometricPin();
        await _keystore.deleteKey(keyAlias: _biometricPinAlias);
        return const Result.ok(null);
      },
      err: (failure) async => Result.err(failure),
    );
  }

  // ---- PIN change (atomic per-wallet: decrypt old -> encrypt new ->
  // write new -> verify -> old is only ever overwritten after that) ----

  @override
  Future<Result<void>> changePin({
    required Pin current,
    required Pin next,
  }) async {
    final walletIds = await _envelopeStore.listWalletIds();
    for (final walletId in walletIds) {
      final result = await _changePinForWallet(walletId, current, next);
      if (result.failureOrNull != null) {
        // A partial multi-wallet failure here is a known limitation of
        // this pass: wallets already migrated stay on `next`, the rest
        // stay on `current`. Revisit if multi-wallet vaults ship.
        return result;
      }
    }
    return const Result.ok(null);
  }

  Future<Result<void>> _changePinForWallet(
    String walletId,
    Pin current,
    Pin next,
  ) async {
    final oldEnvelope = await _readEnvelope(walletId);
    if (oldEnvelope == null) return const Result.err(AppFailure.walletNotFound());

    final oldSalt = base64Decode(oldEnvelope.salt);
    final oldKek = await _isolateRunner(
      () => _kdf.deriveKek(
        pin: current.bytes,
        salt: oldSalt,
        params: oldEnvelope.kdf,
      ),
    );

    final Uint8List plaintext;
    try {
      plaintext = await _cipher.decrypt(
        nonce: base64Decode(oldEnvelope.nonce),
        ciphertextWithTag: base64Decode(oldEnvelope.ct),
        kek: oldKek,
        walletId: walletId,
        envelopeVersion: oldEnvelope.v,
      );
    } on SecretBoxAuthenticationError {
      zeroize(oldKek);
      return const Result.err(AppFailure.wrongPin());
    }

    try {
      final newSalt = _randomBytes(_saltLength);
      final newKdfParams = _kdf.defaultParams();
      final newKek = await _isolateRunner(
        () => _kdf.deriveKek(pin: next.bytes, salt: newSalt, params: newKdfParams),
      );
      final (nonce, ct) = await _cipher.encrypt(
        plaintext: plaintext,
        kek: newKek,
        walletId: walletId,
        envelopeVersion: _envelopeVersion,
      );
      final newEnvelope = Envelope(
        v: _envelopeVersion,
        walletId: walletId,
        type: oldEnvelope.type,
        kdf: newKdfParams,
        salt: base64Encode(newSalt),
        nonce: base64Encode(nonce),
        ct: base64Encode(ct),
      );
      final wrapped = await _keystore.wrap(
        keyAlias: _walletKeyAlias(walletId),
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(newEnvelope.toJson()))),
      );

      // Verify before activating: unwrap + decrypt the bytes we're about
      // to write, independent of the objects still in scope.
      final verifyUnwrapped = await _keystore.unwrap(
        keyAlias: _walletKeyAlias(walletId),
        wrapped: wrapped,
      );
      final verifyEnvelope = Envelope.fromJson(
        jsonDecode(utf8.decode(verifyUnwrapped)) as Map<String, Object?>,
      );
      await _cipher.decrypt(
        nonce: base64Decode(verifyEnvelope.nonce),
        ciphertextWithTag: base64Decode(verifyEnvelope.ct),
        kek: newKek,
        walletId: walletId,
        envelopeVersion: verifyEnvelope.v,
      );

      // Only now does the new envelope replace the old one.
      await _envelopeStore.writeWrapped(walletId, wrapped);

      if (_session.kekFor(walletId) != null) {
        _session.forgetWallet(walletId);
        _session.open({walletId: newKek});
      } else {
        zeroize(newKek);
      }
      return const Result.ok(null);
    } finally {
      zeroize(oldKek);
      zeroize(plaintext);
    }
  }

  // ---- accounts / signing / reveal / removal ----

  @override
  Future<Result<List<Account>>> accounts(WalletId id) async {
    if (_session.kekFor(id) == null) {
      return const Result.err(AppFailure.vaultLocked());
    }
    final meta = await _envelopeStore.readMeta(id);
    if (meta == null) return const Result.err(AppFailure.walletNotFound());

    final secretBytes = await _decryptSecretWithSessionKek(id);
    try {
      final type = SecretType.values.byName(meta['type']! as String);
      if (type == SecretType.mnemonic) {
        final mnemonic = utf8.decode(secretBytes);
        final accounts = [
          for (final coin in wc.CoinType.values)
            Account(walletId: id, address: _walletCore.addressForCoin(mnemonic, coin)),
        ];
        return Result.ok(accounts);
      } else {
        final coin = wc.CoinType.values.byName(meta['coin']! as String);
        final address = _walletCore.addressForImportedKey(secretBytes, coin);
        return Result.ok([Account(walletId: id, address: address)]);
      }
    } finally {
      zeroize(secretBytes);
    }
  }

  @override
  Future<Result<SignedPayload>> sign(SignRequest request) async {
    if (_session.kekFor(request.walletId) == null) {
      return const Result.err(AppFailure.vaultLocked());
    }
    final meta = await _envelopeStore.readMeta(request.walletId);
    if (meta == null) return const Result.err(AppFailure.walletNotFound());

    final secretBytes = await _decryptSecretWithSessionKek(request.walletId);
    try {
      final type = SecretType.values.byName(meta['type']! as String);
      final signed = await _isolateRunner(() {
        if (type == SecretType.mnemonic) {
          return _walletCore.sign(
            mnemonic: utf8.decode(secretBytes),
            coin: request.coin,
            signingInputProto: request.signingInputProto,
          );
        }
        return _walletCore.signWithImportedKey(
          keyBytes: secretBytes,
          coin: request.coin,
          signingInputProto: request.signingInputProto,
        );
      });
      return Result.ok(SignedPayload(signed));
    } finally {
      zeroize(secretBytes);
    }
  }

  @override
  Future<Result<SecretReveal>> revealSecret(
    WalletId id, {
    required Pin pin,
  }) async {
    final kek = await _decryptEnvelopeKek(id, pin);
    if (kek == null) return const Result.err(AppFailure.wrongPin());
    try {
      final meta = await _envelopeStore.readMeta(id);
      if (meta == null) return const Result.err(AppFailure.walletNotFound());
      final envelope = await _readEnvelope(id);
      final secretBytes = await _cipher.decrypt(
        nonce: base64Decode(envelope!.nonce),
        ciphertextWithTag: base64Decode(envelope.ct),
        kek: kek,
        walletId: id,
        envelopeVersion: envelope.v,
      );
      final type = SecretType.values.byName(meta['type']! as String);
      return Result.ok(SecretReveal(type: type, secret: secretBytes));
    } finally {
      zeroize(kek);
    }
  }

  @override
  Future<Result<Uint8List>> exportPrivateKey(
    WalletId id, {
    required wc.CoinType coin,
    required Pin pin,
  }) async {
    final revealed = await revealSecret(id, pin: pin);
    final reveal = revealed.valueOrNull;
    if (reveal == null) return Result.err(revealed.failureOrNull!);
    if (reveal.type == SecretType.privateKey) return Result.ok(reveal.secret);
    try {
      final key = await _isolateRunner(
        () => _walletCore.privateKeyForCoin(utf8.decode(reveal.secret), coin),
      );
      return Result.ok(key);
    } finally {
      zeroize(reveal.secret);
    }
  }

  @override
  Future<Result<void>> removeWallet(WalletId id, {required Pin pin}) async {
    final kek = await _decryptEnvelopeKek(id, pin);
    if (kek == null) return const Result.err(AppFailure.wrongPin());
    zeroize(kek);

    await _envelopeStore.delete(id);
    await _envelopeStore.removeWalletId(id);
    await _envelopeStore.deleteMeta(id);
    if (await _envelopeStore.readActiveWalletId() == id) {
      await _envelopeStore.deleteActiveWalletId();
    }
    await _keystore.deleteKey(keyAlias: _walletKeyAlias(id));
    _session.forgetWallet(id);
    return const Result.ok(null);
  }
}
