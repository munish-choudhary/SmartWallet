import 'dart:typed_data';

/// Plain Base58 (Bitcoin alphabet) decoding — a text *encoding*, not a
/// key-derivation or signing algorithm, so it's outside CLAUDE.md's "never
/// implement BIP-39/BIP-32/derivation/signing in Dart" rule. Used only to
/// turn a Solana private-key string into raw bytes for
/// `Vault.importPrivateKey`, which still takes those bytes from here to
/// Trust Wallet Core for anything cryptographic.
const _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Throws [FormatException] if [input] contains characters outside the
/// Base58 alphabet.
Uint8List decodeBase58(String input) {
  var value = BigInt.zero;
  final base = BigInt.from(58);
  for (final char in input.codeUnits) {
    final index = _alphabet.indexOf(String.fromCharCode(char));
    if (index == -1) {
      throw FormatException('Invalid base58 character', input);
    }
    value = value * base + BigInt.from(index);
  }

  var bytes = <int>[];
  while (value > BigInt.zero) {
    bytes.add((value % BigInt.from(256)).toInt());
    value = value ~/ BigInt.from(256);
  }
  bytes = bytes.reversed.toList();

  // Leading '1's in the input encode leading zero bytes.
  var leadingZeros = 0;
  for (final char in input.codeUnits) {
    if (char == 0x31) {
      leadingZeros++;
    } else {
      break;
    }
  }

  return Uint8List.fromList([
    ...List.filled(leadingZeros, 0),
    ...bytes,
  ]);
}
