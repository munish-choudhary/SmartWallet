import 'dart:typed_data';

import 'package:smart_wallet/core/vault/envelope.dart';
import 'package:smart_wallet/core/vault/envelope_store.dart';
import 'package:smart_wallet/core/vault/kdf.dart';
import 'package:smart_wallet/core/vault/vault_keystore.dart';
import 'package:smart_wallet/core/vault/wallet_core_gateway.dart';
import 'package:wallet_core_ffi/wallet_core_ffi.dart' as wc;

/// Deterministic, fast stand-in for [CryptographyKeyDerivation] — real
/// Argon2id is intentionally slow (300-800ms target per CLAUDE.md), which
/// would make every vault test slow. This is NOT secure and must never be
/// used outside tests.
final class FakeKeyDerivation implements KeyDerivation {
  const FakeKeyDerivation();

  @override
  KdfParams defaultParams() => const KdfParams.argon2id(m: 1, t: 1, p: 1);

  @override
  Future<Uint8List> deriveKek({
    required Uint8List pin,
    required Uint8List salt,
    required KdfParams params,
  }) async {
    final kek = Uint8List(32);
    for (var i = 0; i < kek.length; i++) {
      final pinByte = pin.isEmpty ? 0 : pin[i % pin.length];
      final saltByte = salt.isEmpty ? 0 : salt[i % salt.length];
      kek[i] = (pinByte ^ saltByte ^ i) & 0xFF;
    }
    return kek;
  }
}

/// In-memory stand-in for [SecureEnvelopeStore] — no `flutter_secure_storage`
/// platform channel needed in unit tests.
final class InMemoryEnvelopeStore implements EnvelopeStore {
  final Map<String, Uint8List> _wrapped = {};
  final Map<String, Map<String, Object?>> _meta = {};
  final List<String> _walletIds = [];
  Uint8List? _biometricPin;

  @override
  Future<void> writeWrapped(String walletId, Uint8List wrapped) async =>
      _wrapped[walletId] = wrapped;

  @override
  Future<Uint8List?> readWrapped(String walletId) async => _wrapped[walletId];

  @override
  Future<void> delete(String walletId) async => _wrapped.remove(walletId);

  @override
  Future<void> writeMeta(String walletId, Map<String, Object?> meta) async =>
      _meta[walletId] = meta;

  @override
  Future<Map<String, Object?>?> readMeta(String walletId) async =>
      _meta[walletId];

  @override
  Future<void> deleteMeta(String walletId) async => _meta.remove(walletId);

  @override
  Future<List<String>> listWalletIds() async => List.unmodifiable(_walletIds);

  @override
  Future<void> addWalletId(String walletId) async {
    if (!_walletIds.contains(walletId)) _walletIds.add(walletId);
  }

  @override
  Future<void> removeWalletId(String walletId) async =>
      _walletIds.remove(walletId);

  @override
  Future<void> writeBiometricPin(Uint8List wrapped) async =>
      _biometricPin = wrapped;

  @override
  Future<Uint8List?> readBiometricPin() async => _biometricPin;

  @override
  Future<void> deleteBiometricPin() async => _biometricPin = null;
}

/// Fakes the hardware wrap as a fixed-XOR "cipher" — enough to prove
/// [VaultImpl] round-trips through it correctly, and to simulate key
/// invalidation, without needing a real Keystore/Secure Enclave.
final class FakeVaultKeystore implements VaultKeystore {
  final Set<String> _invalidated = {};
  final Set<String> _deleted = {};

  static const _xorByte = 0x5A;

  Uint8List _xor(Uint8List input) =>
      Uint8List.fromList([for (final b in input) b ^ _xorByte]);

  void invalidate(String keyAlias) => _invalidated.add(keyAlias);

  @override
  Future<Uint8List> wrap({
    required String keyAlias,
    required Uint8List bytes,
  }) async {
    _deleted.remove(keyAlias);
    return _xor(bytes);
  }

  @override
  Future<Uint8List> unwrap({
    required String keyAlias,
    required Uint8List wrapped,
  }) async {
    if (_invalidated.contains(keyAlias) || _deleted.contains(keyAlias)) {
      throw VaultKeystoreInvalidatedException(keyAlias);
    }
    return _xor(wrapped);
  }

  @override
  Future<void> deleteKey({required String keyAlias}) async {
    _deleted.add(keyAlias);
  }

  @override
  Future<bool> isStrongBiometricAvailable() async => true;
}

/// Deterministic fake of Trust Wallet Core, since the real bindings don't
/// exist yet (see packages/wallet_core_ffi/README.md).
final class FakeWalletCoreGateway implements WalletCoreGateway {
  int _mnemonicCounter = 0;
  static const validMnemonics = {'valid mnemonic one', 'valid mnemonic two'};

  @override
  bool isValidMnemonic(String mnemonic) => validMnemonics.contains(mnemonic);

  @override
  String createMnemonic({required int strength}) {
    _mnemonicCounter++;
    return 'generated mnemonic $_mnemonicCounter (strength=$strength)';
  }

  @override
  String addressForCoin(String mnemonic, wc.CoinType coin) =>
      '0x${coin.name}:${mnemonic.hashCode}';

  @override
  String addressForImportedKey(Uint8List keyBytes, wc.CoinType coin) {
    final expectedLength = coin.curve == wc.Curve.ed25519 ? 32 : 32;
    if (keyBytes.length != expectedLength) {
      throw ArgumentError('invalid key length for ${coin.name}');
    }
    return '0x${coin.name}:imported:${keyBytes.first}';
  }

  @override
  Uint8List sign({
    required String mnemonic,
    required wc.CoinType coin,
    required Uint8List signingInputProto,
  }) =>
      Uint8List.fromList([...signingInputProto, coin.index]);

  @override
  Uint8List signWithImportedKey({
    required Uint8List keyBytes,
    required wc.CoinType coin,
    required Uint8List signingInputProto,
  }) =>
      Uint8List.fromList([...signingInputProto, coin.index]);
}
