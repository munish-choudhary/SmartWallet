import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/vault/vault.dart' show WalletId;

/// Where the user-chosen wallet names live. Names aren't secret, but they
/// stay on the device only (never sent to a node or backend), so they sit in
/// `flutter_secure_storage` alongside the rest of the wallet metadata until
/// the Drift layer exists.
abstract interface class WalletNameStore {
  Future<String?> read(WalletId walletId);
  Future<void> write(WalletId walletId, String name);
  Future<void> delete(WalletId walletId);
}

final class SecureWalletNameStore implements WalletNameStore {
  SecureWalletNameStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  String _key(WalletId walletId) => 'wallet.name.$walletId';

  @override
  Future<String?> read(WalletId walletId) => _storage.read(key: _key(walletId));

  @override
  Future<void> write(WalletId walletId, String name) =>
      _storage.write(key: _key(walletId), value: name);

  @override
  Future<void> delete(WalletId walletId) =>
      _storage.delete(key: _key(walletId));
}

/// Session-only store for tests and previews.
final class InMemoryWalletNameStore implements WalletNameStore {
  InMemoryWalletNameStore([Map<WalletId, String>? initial])
      : _names = {...?initial};

  final Map<WalletId, String> _names;

  @override
  Future<String?> read(WalletId walletId) async => _names[walletId];

  @override
  Future<void> write(WalletId walletId, String name) async =>
      _names[walletId] = name;

  @override
  Future<void> delete(WalletId walletId) async => _names.remove(walletId);
}
