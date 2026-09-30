import 'dart:convert';

/// Small, strict parsers for the hex strings EVM JSON-RPC uses. Everything
/// here handles untrusted input and returns null rather than throwing.
abstract final class EvmHex {
  static final _address = RegExp(r'^0x[0-9a-fA-F]{40}$');
  static final _quantity = RegExp(r'^0x[0-9a-fA-F]{1,64}$');
  static final _data = RegExp(r'^0x([0-9a-fA-F]{2})*$');

  static bool isAddress(Object? value) =>
      value is String && _address.hasMatch(value);

  static bool sameAddress(String a, String b) => a.toLowerCase() == b.toLowerCase();

  /// `0x1a` → 26. Null when not a valid hex quantity.
  static BigInt? quantity(Object? value) {
    if (value is! String || !_quantity.hasMatch(value)) return null;
    return BigInt.parse(value.substring(2), radix: 16);
  }

  /// Valid `0x`-prefixed even-length hex data (including `0x`).
  static bool isData(Object? value) => value is String && _data.hasMatch(value);

  static List<int>? bytes(String hex) {
    if (!isData(hex)) return null;
    final body = hex.substring(2);
    return [
      for (var i = 0; i < body.length; i += 2)
        int.parse(body.substring(i, i + 2), radix: 16),
    ];
  }

  /// Decodes a `personal_sign` payload. Hex that is valid printable UTF-8
  /// becomes text; any other hex is returned as-is and flagged unreadable.
  static ({String text, bool readable}) decodeMessage(String raw) {
    if (!isData(raw)) return (text: raw, readable: true);
    final data = bytes(raw)!;
    try {
      final text = utf8.decode(data);
      final printable = !text.runes.any(
        (r) => r < 0x20 && r != 0x0A && r != 0x0D && r != 0x09,
      );
      if (printable) return (text: text, readable: true);
    } on FormatException {
      // fall through: not UTF-8
    }
    return (text: raw, readable: false);
  }

  /// `formatUnits(250000000000000000, 18)` → `0.25`.
  static String formatUnits(BigInt value, int decimals, {int maxFraction = 6}) {
    if (value == BigInt.zero) return '0';
    final base = BigInt.from(10).pow(decimals);
    final whole = value ~/ base;
    final fraction = (value % base).toString().padLeft(decimals, '0');
    var trimmed = fraction.substring(0, maxFraction.clamp(0, decimals));
    trimmed = trimmed.replaceFirst(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) {
      // Non-zero but smaller than the display precision.
      return whole == BigInt.zero ? '<0.${'0' * (maxFraction - 1)}1' : '$whole';
    }
    return '$whole.$trimmed';
  }

  /// `uint256` max-ish values that mean "no limit" (ERC-20 `approve`).
  static final unlimitedThreshold = BigInt.one << 255;
  static bool isUnlimited(BigInt amount) => amount >= unlimitedThreshold;

  /// Same idea for a `uintN` field in typed data: Permit2 uses `uint160`,
  /// whose "unlimited" is `2^160 - 1`, far below the `uint256` threshold.
  /// Only token-amount-sized types (≥ 96 bits) qualify, so a `uint48`
  /// timestamp or nonce is never relabelled.
  static bool isUnlimitedForBits(BigInt amount, int bits) =>
      bits >= 96 && amount >= (BigInt.one << (bits - 1));
}
