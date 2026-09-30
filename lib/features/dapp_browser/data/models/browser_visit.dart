/// A page the user opened, for the "Recent" list.
///
/// Only origin + path are kept: query strings and fragments routinely carry
/// session tokens, OAuth codes and wallet addresses that have no business
/// in history.
final class BrowserVisit {
  const BrowserVisit({
    required this.url,
    required this.title,
    required this.visitedAt,
  });

  final String url;
  final String title;
  final DateTime visitedAt;

  factory BrowserVisit.sanitized({
    required Uri uri,
    required String title,
    required DateTime visitedAt,
  }) {
    final clean = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    );
    return BrowserVisit(
      url: clean.toString(),
      title: title.trim(),
      visitedAt: visitedAt,
    );
  }

  String get host => Uri.tryParse(url)?.host ?? url;
}
