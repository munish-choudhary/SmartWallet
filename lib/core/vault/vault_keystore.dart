import 'package:flutter/services.dart';

/// The hardware layer described in CLAUDE.md: wraps/unwraps the serialized
/// PIN-layer envelope with a non-exportable key (Android Keystore
/// StrongBox / iOS Secure Enclave). Implemented natively — this Dart side
/// only defines the contract and the channel plumbing.
///
/// Native implementations (Kotlin/Swift) are a follow-up — see
/// `lib/core/vault/README.md` — until then, calling
/// [MethodChannelVaultKeystore] on a real device will throw a
/// [MissingPluginException].
abstract interface class VaultKeystore {
  /// Encrypts [bytes] (the serialized, PIN-layer-encrypted envelope) with
  /// the hardware-bound key, creating it on first use for [keyAlias].
  Future<Uint8List> wrap({required String keyAlias, required Uint8List bytes});

  /// Reverses [wrap]. Throws [VaultKeystoreInvalidatedException] if the key
  /// was invalidated (e.g. biometric enrollment changed on Android).
  Future<Uint8List> unwrap({
    required String keyAlias,
    required Uint8List wrapped,
  });

  /// Permanently deletes the hardware key for [keyAlias] (wallet removal,
  /// biometrics disabled).
  Future<void> deleteKey({required String keyAlias});

  Future<bool> isStrongBiometricAvailable();
}

final class VaultKeystoreInvalidatedException implements Exception {
  const VaultKeystoreInvalidatedException(this.keyAlias);
  final String keyAlias;

  @override
  String toString() =>
      'VaultKeystoreInvalidatedException: key "$keyAlias" was invalidated '
      '(biometric enrollment changed or item unreadable)';
}

/// Talks to the native `vault_keystore` platform channel.
///
/// Native method names/args this expects on both platforms:
/// - `wrap(keyAlias: String, bytes: Uint8List) -> Uint8List`
/// - `unwrap(keyAlias: String, wrapped: Uint8List) -> Uint8List`
///   throws a `PlatformException(code: "invalidated")` on key invalidation.
/// - `deleteKey(keyAlias: String) -> void`
/// - `isStrongBiometricAvailable() -> bool`
final class MethodChannelVaultKeystore implements VaultKeystore {
  MethodChannelVaultKeystore([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('vault_keystore');

  final MethodChannel _channel;

  @override
  Future<Uint8List> wrap({
    required String keyAlias,
    required Uint8List bytes,
  }) async {
    final result = await _channel.invokeMethod<Uint8List>('wrap', {
      'keyAlias': keyAlias,
      'bytes': bytes,
    });
    return result!;
  }

  @override
  Future<Uint8List> unwrap({
    required String keyAlias,
    required Uint8List wrapped,
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('unwrap', {
        'keyAlias': keyAlias,
        'wrapped': wrapped,
      });
      return result!;
    } on PlatformException catch (e) {
      if (e.code == 'invalidated') {
        throw VaultKeystoreInvalidatedException(keyAlias);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteKey({required String keyAlias}) =>
      _channel.invokeMethod<void>('deleteKey', {'keyAlias': keyAlias});

  @override
  Future<bool> isStrongBiometricAvailable() async {
    final result =
        await _channel.invokeMethod<bool>('isStrongBiometricAvailable');
    return result ?? false;
  }
}
