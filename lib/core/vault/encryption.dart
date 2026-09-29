import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM encrypt/decrypt for the PIN layer. A fresh random 12-byte
/// nonce is generated for every [encrypt] call — never reused, per
/// CLAUDE.md. AAD binds ciphertext to `walletId || envelopeVersion` so an
/// envelope can't be silently swapped between wallets or replayed across
/// versions.
final class AesGcmEnvelopeCipher {
  const AesGcmEnvelopeCipher();

  static final _algorithm = AesGcm.with256bits();

  Uint8List _aad(String walletId, int envelopeVersion) =>
      Uint8List.fromList(utf8.encode('$walletId|$envelopeVersion'));

  /// Returns `(nonce, ciphertextWithTag)`.
  Future<(Uint8List nonce, Uint8List ct)> encrypt({
    required Uint8List plaintext,
    required Uint8List kek,
    required String walletId,
    required int envelopeVersion,
  }) async {
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: SecretKey(kek),
      nonce: nonce,
      aad: _aad(walletId, envelopeVersion),
    );
    return (
      Uint8List.fromList(secretBox.nonce),
      Uint8List.fromList(secretBox.cipherText + secretBox.mac.bytes),
    );
  }

  /// Throws [SecretBoxAuthenticationError] if the GCM tag doesn't verify —
  /// i.e. wrong KEK (wrong PIN) or tampered ciphertext. Callers must not
  /// catch this broadly and must map it to `AppFailure.wrongPin()`.
  Future<Uint8List> decrypt({
    required Uint8List nonce,
    required Uint8List ciphertextWithTag,
    required Uint8List kek,
    required String walletId,
    required int envelopeVersion,
  }) async {
    const macLength = 16;
    if (ciphertextWithTag.length < macLength) {
      throw ArgumentError('ciphertext shorter than GCM tag');
    }
    final splitPoint = ciphertextWithTag.length - macLength;
    final secretBox = SecretBox(
      ciphertextWithTag.sublist(0, splitPoint),
      nonce: nonce,
      mac: Mac(ciphertextWithTag.sublist(splitPoint)),
    );
    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: SecretKey(kek),
      aad: _aad(walletId, envelopeVersion),
    );
    return Uint8List.fromList(plaintext);
  }
}
