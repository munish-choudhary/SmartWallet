import '../../../walletconnect/data/models/wc_dapp.dart';
import '../dapp_catalog.dart';
import '../models/dapp.dart';

/// Builds the [WcDapp] the review sheets show for a browser origin.
///
/// A page controls its own `<title>`, favicon and meta tags, so none of
/// that is used. The name is the curated name only when the *origin* is a
/// catalog match over HTTPS; otherwise it is the bare host, so a phishing
/// page cannot present itself as "Uniswap".
abstract final class DappIdentity {
  static const _fallbackColors = [
    0xFF7255A5,
    0xFF3B82F6,
    0xFF14B8A6,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF8B5CF6,
  ];

  static WcDapp forOrigin(
    String origin, {
    List<Dapp> catalog = DappCatalog.featured,
  }) {
    final uri = Uri.tryParse(origin);
    final host = _normalize(uri?.host ?? origin);
    if (uri != null && uri.scheme == 'https') {
      for (final dapp in catalog) {
        if (_normalize(dapp.host) == host) {
          return WcDapp(
            name: dapp.name,
            url: origin,
            description: dapp.description,
            brandColor: dapp.brandColor,
            tags: [dapp.category.label],
            verification: WcVerification.verified,
          );
        }
      }
    }
    final hash = host.codeUnits.fold<int>(
      0,
      (acc, unit) => (acc * 31 + unit) & 0x7fffffff,
    );
    return WcDapp(
      name: uri?.host.isNotEmpty == true ? uri!.host : origin,
      url: origin,
      brandColor: _fallbackColors[hash % _fallbackColors.length],
      verification: WcVerification.unverified,
    );
  }

  static String _normalize(String host) {
    final lower = host.toLowerCase();
    return lower.startsWith('www.') ? lower.substring(4) : lower;
  }
}
