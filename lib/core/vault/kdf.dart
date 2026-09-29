import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'envelope.dart';

/// Derives a 32-byte key-encryption key (KEK) from a PIN + salt, using
/// whichever [KdfParams] the envelope records. Runs inside [Isolate.run] by
/// the caller ([VaultImpl]), not here, so this stays a pure function.
abstract interface class KeyDerivation {
  Future<Uint8List> deriveKek({
    required Uint8List pin,
    required Uint8List salt,
    required KdfParams params,
  });

  /// The default params for newly created envelopes. Argon2id per
  /// CLAUDE.md's starting point (m=64MiB, t=3, p=1) — benchmark on a
  /// low-end Android device and adjust to hit 300-800ms before shipping.
  KdfParams defaultParams();
}

const int _kekLengthBytes = 32;

final class CryptographyKeyDerivation implements KeyDerivation {
  const CryptographyKeyDerivation();

  @override
  KdfParams defaultParams() => const KdfParams.argon2id(m: 65536, t: 3, p: 1);

  @override
  Future<Uint8List> deriveKek({
    required Uint8List pin,
    required Uint8List salt,
    required KdfParams params,
  }) async {
    return switch (params) {
      Argon2idParams(:final m, :final t, :final p) => _argon2id(
          pin: pin,
          salt: salt,
          memoryKib: m,
          iterations: t,
          parallelism: p,
        ),
      Pbkdf2Params(:final iterations) => _pbkdf2(
          pin: pin,
          salt: salt,
          iterations: iterations,
        ),
    };
  }

  Future<Uint8List> _argon2id({
    required Uint8List pin,
    required Uint8List salt,
    required int memoryKib,
    required int iterations,
    required int parallelism,
  }) async {
    final algorithm = Argon2id(
      memory: memoryKib,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: _kekLengthBytes,
    );
    final secretKey = await algorithm.deriveKeyFromPassword(
      password: String.fromCharCodes(pin),
      nonce: salt,
    );
    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  /// Fallback only if Argon2id is not viable on a platform, per CLAUDE.md.
  Future<Uint8List> _pbkdf2({
    required Uint8List pin,
    required Uint8List salt,
    required int iterations,
  }) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _kekLengthBytes * 8,
    );
    final secretKey = await algorithm.deriveKeyFromPassword(
      password: String.fromCharCodes(pin),
      nonce: salt,
    );
    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }
}
