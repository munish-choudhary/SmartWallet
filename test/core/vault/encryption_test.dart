import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/vault/encryption.dart';

Uint8List _kek(int seed) => Uint8List.fromList(List.generate(32, (i) => (i + seed) & 0xFF));

void main() {
  const cipher = AesGcmEnvelopeCipher();
  final plaintext = Uint8List.fromList(utf8.encode('super secret mnemonic'));

  group('AesGcmEnvelopeCipher', () {
    test('round-trips plaintext through encrypt/decrypt', () async {
      final kek = _kek(1);
      final (nonce, ct) = await cipher.encrypt(
        plaintext: plaintext,
        kek: kek,
        walletId: 'wallet-1',
        envelopeVersion: 1,
      );

      final decrypted = await cipher.decrypt(
        nonce: nonce,
        ciphertextWithTag: ct,
        kek: kek,
        walletId: 'wallet-1',
        envelopeVersion: 1,
      );

      expect(decrypted, plaintext);
    });

    test('wrong KEK fails the GCM tag check', () async {
      final (nonce, ct) = await cipher.encrypt(
        plaintext: plaintext,
        kek: _kek(1),
        walletId: 'wallet-1',
        envelopeVersion: 1,
      );

      expect(
        () => cipher.decrypt(
          nonce: nonce,
          ciphertextWithTag: ct,
          kek: _kek(2),
          walletId: 'wallet-1',
          envelopeVersion: 1,
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('tampered ciphertext fails the GCM tag check', () async {
      final kek = _kek(1);
      final (nonce, ct) = await cipher.encrypt(
        plaintext: plaintext,
        kek: kek,
        walletId: 'wallet-1',
        envelopeVersion: 1,
      );
      final tampered = Uint8List.fromList(ct)..[0] ^= 0xFF;

      expect(
        () => cipher.decrypt(
          nonce: nonce,
          ciphertextWithTag: tampered,
          kek: kek,
          walletId: 'wallet-1',
          envelopeVersion: 1,
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('AAD binds ciphertext to walletId — swapping it fails decryption',
        () async {
      final kek = _kek(1);
      final (nonce, ct) = await cipher.encrypt(
        plaintext: plaintext,
        kek: kek,
        walletId: 'wallet-1',
        envelopeVersion: 1,
      );

      expect(
        () => cipher.decrypt(
          nonce: nonce,
          ciphertextWithTag: ct,
          kek: kek,
          walletId: 'wallet-2',
          envelopeVersion: 1,
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('nonce is fresh and random on every encrypt call', () async {
      final kek = _kek(1);
      final nonces = <String>{};
      for (var i = 0; i < 20; i++) {
        final (nonce, _) = await cipher.encrypt(
          plaintext: plaintext,
          kek: kek,
          walletId: 'wallet-1',
          envelopeVersion: 1,
        );
        nonces.add(base64Encode(nonce));
      }
      expect(nonces, hasLength(20));
    });
  });
}
