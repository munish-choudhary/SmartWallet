import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the hardware-wrapped envelope bytes and the wallet id index.
/// Per CLAUDE.md, this data goes in `flutter_secure_storage` only — never
/// Drift, plain files, SharedPreferences, logs, or analytics.
abstract interface class EnvelopeStore {
  Future<void> writeWrapped(String walletId, Uint8List wrapped);
  Future<Uint8List?> readWrapped(String walletId);
  Future<void> delete(String walletId);

  /// Small, non-secret bookkeeping per wallet (secret type, and — for
  /// imported-key wallets only — which coin the key was validated
  /// against). Public keys/addresses themselves belong in Drift once that
  /// layer exists; this is just enough for `Vault` to function standalone.
  Future<void> writeMeta(String walletId, Map<String, Object?> meta);
  Future<Map<String, Object?>?> readMeta(String walletId);
  Future<void> deleteMeta(String walletId);

  Future<List<String>> listWalletIds();
  Future<void> addWalletId(String walletId);
  Future<void> removeWalletId(String walletId);

  /// Which wallet the app operates on (a wallet id — not secret).
  Future<String?> readActiveWalletId();
  Future<void> writeActiveWalletId(String walletId);
  Future<void> deleteActiveWalletId();

  /// The biometric-wrapped PIN blob (see CLAUDE.md's Biometrics section).
  /// One per vault, not per wallet — the PIN unlocks every wallet in the
  /// vault.
  Future<void> writeBiometricPin(Uint8List wrapped);
  Future<Uint8List?> readBiometricPin();
  Future<void> deleteBiometricPin();
}

final class SecureEnvelopeStore implements EnvelopeStore {
  SecureEnvelopeStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _walletIdsKey = 'vault.walletIds';
  static const _biometricPinKey = 'vault.biometricPin';
  static const _activeWalletIdKey = 'vault.activeWalletId';
  String _envelopeKey(String walletId) => 'vault.envelope.$walletId';
  String _metaKey(String walletId) => 'vault.meta.$walletId';

  @override
  Future<void> writeWrapped(String walletId, Uint8List wrapped) =>
      _storage.write(
        key: _envelopeKey(walletId),
        value: base64Encode(wrapped),
      );

  @override
  Future<Uint8List?> readWrapped(String walletId) async {
    final raw = await _storage.read(key: _envelopeKey(walletId));
    if (raw == null) return null;
    return base64Decode(raw);
  }

  @override
  Future<void> delete(String walletId) =>
      _storage.delete(key: _envelopeKey(walletId));

  @override
  Future<List<String>> listWalletIds() async {
    final raw = await _storage.read(key: _walletIdsKey);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  @override
  Future<void> addWalletId(String walletId) async {
    final ids = {...await listWalletIds(), walletId}.toList();
    await _storage.write(key: _walletIdsKey, value: jsonEncode(ids));
  }

  @override
  Future<void> removeWalletId(String walletId) async {
    final ids = (await listWalletIds())..remove(walletId);
    await _storage.write(key: _walletIdsKey, value: jsonEncode(ids));
  }

  @override
  Future<String?> readActiveWalletId() =>
      _storage.read(key: _activeWalletIdKey);

  @override
  Future<void> writeActiveWalletId(String walletId) =>
      _storage.write(key: _activeWalletIdKey, value: walletId);

  @override
  Future<void> deleteActiveWalletId() =>
      _storage.delete(key: _activeWalletIdKey);

  @override
  Future<void> writeMeta(String walletId, Map<String, Object?> meta) =>
      _storage.write(key: _metaKey(walletId), value: jsonEncode(meta));

  @override
  Future<Map<String, Object?>?> readMeta(String walletId) async {
    final raw = await _storage.read(key: _metaKey(walletId));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, Object?>;
  }

  @override
  Future<void> deleteMeta(String walletId) =>
      _storage.delete(key: _metaKey(walletId));

  @override
  Future<void> writeBiometricPin(Uint8List wrapped) =>
      _storage.write(key: _biometricPinKey, value: base64Encode(wrapped));

  @override
  Future<Uint8List?> readBiometricPin() async {
    final raw = await _storage.read(key: _biometricPinKey);
    if (raw == null) return null;
    return base64Decode(raw);
  }

  @override
  Future<void> deleteBiometricPin() => _storage.delete(key: _biometricPinKey);
}
