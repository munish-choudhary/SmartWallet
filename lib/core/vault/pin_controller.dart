import 'dart:typed_data';

import 'pin.dart';
import 'secrets.dart';

/// Owns the raw PIN digit buffer for a PIN-entry screen. Digits are held
/// only as bytes here — never as a `String`, never surfaced to Cubit/Bloc
/// state (which should hold only the digit *count* and UI flags). Call
/// [dispose] once the buffer is no longer needed (after building a [Pin]
/// and using it, or when the screen is torn down) to zero it.
final class PinController {
  PinController({this.maxLength = 6})
      : _buffer = Uint8List(maxLength),
        _length = 0;

  final int maxLength;
  final Uint8List _buffer;
  int _length;

  int get length => _length;
  bool get isComplete => _length == maxLength;

  void addDigit(String digit) {
    if (_length >= maxLength) return;
    _buffer[_length] = digit.codeUnitAt(0);
    _length++;
  }

  void removeLast() {
    if (_length == 0) return;
    _length--;
    _buffer[_length] = 0;
  }

  void clear() {
    zeroize(_buffer);
    _length = 0;
  }

  /// Builds a [Pin] from the current digits. Caller owns the returned
  /// [Pin] and is responsible for disposing it after use.
  Pin toPin() => Pin(String.fromCharCodes(_buffer.sublist(0, _length)));

  /// Whether the currently-entered digits form a trivially-guessable PIN:
  /// all the same digit (`000000`, `111111`, ...), or strictly ascending
  /// / descending sequential digits (`123456`, `654321`, ...). Only
  /// meaningful once [isComplete].
  bool isTrivial() {
    if (_length == 0) return false;
    final digits = [for (var i = 0; i < _length; i++) _buffer[i] - 0x30];

    final allSame = digits.every((d) => d == digits.first);
    if (allSame) return true;

    var ascending = true;
    var descending = true;
    for (var i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i - 1] + 1) ascending = false;
      if (digits[i] != digits[i - 1] - 1) descending = false;
    }
    return ascending || descending;
  }

  /// Compares this controller's digits against [other]'s, in constant time
  /// with respect to buffer length (not early-exiting on first mismatch),
  /// without ever materializing either as a `String`.
  bool matches(PinController other) {
    if (_length != other._length) return false;
    var diff = 0;
    for (var i = 0; i < _length; i++) {
      diff |= _buffer[i] ^ other._buffer[i];
    }
    return diff == 0;
  }

  void dispose() => zeroize(_buffer);
}
