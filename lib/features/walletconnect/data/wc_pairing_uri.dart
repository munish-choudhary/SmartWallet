/// Local validation of a WalletConnect v2 pairing link before we spend a
/// network round-trip on it:
/// `wc:<topic>@2?relay-protocol=irn&symKey=<64 hex chars>[&expiryTimestamp=…]`
///
/// The link carries the pairing's symmetric key, so it is treated like a
/// secret: it is never logged, never placed in route params, and the
/// parsed form deliberately keeps only what the UI needs.
final class WcPairingUri {
  const WcPairingUri._(this.topic, this.expiresAt);

  final String topic;
  final DateTime? expiresAt;

  static final _topic = RegExp(r'^[0-9a-fA-F]{64}$');
  static final _symKey = RegExp(r'^[0-9a-fA-F]{64}$');

  /// Returns null unless [input] is a structurally valid v2 pairing link.
  static WcPairingUri? tryParse(String input) {
    final trimmed = input.trim();
    if (!trimmed.startsWith('wc:')) return null;
    final rest = trimmed.substring(3);
    final at = rest.indexOf('@');
    if (at <= 0) return null;
    final topic = rest.substring(0, at);
    final afterAt = rest.substring(at + 1);
    final q = afterAt.indexOf('?');
    if (q < 0) return null;
    if (afterAt.substring(0, q) != '2') return null;
    if (!_topic.hasMatch(topic)) return null;

    final Map<String, String> params;
    try {
      params = Uri.splitQueryString(afterAt.substring(q + 1));
    } on FormatException {
      return null;
    }
    if (params['relay-protocol'] == null ||
        params['relay-protocol']!.isEmpty) {
      return null;
    }
    final key = params['symKey'];
    if (key == null || !_symKey.hasMatch(key)) return null;

    DateTime? expiresAt;
    final ts = int.tryParse(params['expiryTimestamp'] ?? '');
    if (ts != null) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
    }
    return WcPairingUri._(topic, expiresAt);
  }

  bool isExpired(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now.toUtc());
}
