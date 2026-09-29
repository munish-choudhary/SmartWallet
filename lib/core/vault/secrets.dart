import 'dart:typed_data';

/// Zero-fills [bytes] in place. Call in a `finally` block after any secret
/// (mnemonic bytes, private key, KEK, PIN) is no longer needed, per
/// CLAUDE.md's Memory Hygiene rules.
void zeroize(Uint8List bytes) {
  bytes.fillRange(0, bytes.length, 0);
}
