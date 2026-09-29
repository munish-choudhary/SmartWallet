import 'dart:typed_data';

import 'secrets.dart';

/// A user's PIN, held as bytes for as long as possible so it can be
/// zeroized. Per CLAUDE.md: minimum 6 digits, never stored, never
/// converted to a persisted `String`.
final class Pin {
  Pin(String digits) : _bytes = Uint8List.fromList(digits.codeUnits) {
    if (digits.length < 6 || !RegExp(r'^\d+$').hasMatch(digits)) {
      zeroize(_bytes);
      throw ArgumentError('PIN must be at least 6 digits');
    }
  }

  Pin.fromBytes(this._bytes);

  final Uint8List _bytes;

  Uint8List get bytes => _bytes;

  /// Caller must call this in a `finally` block once the PIN is no longer
  /// needed. After this, [bytes] is all zeros.
  void dispose() => zeroize(_bytes);
}
