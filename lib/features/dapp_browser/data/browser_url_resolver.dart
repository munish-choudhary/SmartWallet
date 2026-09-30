/// Turns whatever the user typed into something safe to load.
///
/// The browser only ever loads `http(s)` pages. Everything else that looks
/// like a scheme (`javascript:`, `data:`, `file:`, `intent:`, `wc:` …) is
/// refused rather than handed to the WebView, and URLs with embedded
/// credentials (`https://app.uniswap.org@evil.com`) are refused because
/// they are the classic way to disguise a phishing host.
sealed class ResolvedInput {
  const ResolvedInput();
}

/// A URL (typed, or `https://` assumed for a bare host).
final class ResolvedUrl extends ResolvedInput {
  const ResolvedUrl(this.uri);
  final Uri uri;
}

/// Not a URL — search for it instead.
final class ResolvedSearch extends ResolvedInput {
  const ResolvedSearch(this.uri);
  final Uri uri;
}

final class RejectedInput extends ResolvedInput {
  const RejectedInput(this.reason);
  final String reason;
}

abstract final class BrowserUrlResolver {
  static final _scheme = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.\-]*):');
  static final _hostPort = RegExp(r'^[^/\s:]+:\d+([/?#].*)?$');
  static final _looksLikeHost = RegExp(
    r'^(localhost|(\d{1,3}\.){3}\d{1,3}|([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,})(:\d+)?([/?#].*)?$',
  );

  static const _searchBase = 'https://duckduckgo.com/';

  /// Schemes refused outright, checked before the `host:port` heuristic so
  /// something like `javascript:1` can't be mistaken for a host and port.
  static const _blockedSchemes = {
    'javascript',
    'vbscript',
    'data',
    'blob',
    'file',
    'content',
    'intent',
    'about',
    'view-source',
    'wc',
    'ftp',
  };

  static ResolvedInput resolve(String input) {
    final text = input.trim();
    if (text.isEmpty) return const RejectedInput('Enter a web address');

    String candidate;
    final scheme = _scheme.firstMatch(text)?.group(1)?.toLowerCase();
    if (scheme != null && _blockedSchemes.contains(scheme)) {
      return RejectedInput('"$scheme:" links are not supported');
    }
    if (scheme != null && !_hostPort.hasMatch(text)) {
      if (scheme != 'http' && scheme != 'https') {
        return RejectedInput('"$scheme:" links are not supported');
      }
      candidate = text;
    } else if (!text.contains(RegExp(r'\s')) && _looksLikeHost.hasMatch(text)) {
      candidate = 'https://$text';
    } else {
      return ResolvedSearch(
        Uri.parse(_searchBase).replace(queryParameters: {'q': text}),
      );
    }

    final Uri uri;
    try {
      uri = Uri.parse(candidate);
    } on FormatException {
      return const RejectedInput('That address is not valid');
    }
    if (uri.host.isEmpty) return const RejectedInput('That address is not valid');
    if (uri.userInfo.isNotEmpty) {
      return const RejectedInput(
        'Addresses with a username or password are blocked',
      );
    }
    return ResolvedUrl(uri);
  }

  /// Whether the WebView may navigate to [uri] (link clicks, redirects).
  /// `about:blank` is allowed because pages open it internally.
  static bool allowsNavigation(Uri uri) {
    if (uri.toString() == 'about:blank') return true;
    return (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  /// `https://app.uniswap.org[:port]`, or null for non-web URIs.
  static String? originOf(Uri uri) {
    if (!(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) {
      return null;
    }
    final port = uri.hasPort &&
            !((uri.scheme == 'https' && uri.port == 443) ||
                (uri.scheme == 'http' && uri.port == 80))
        ? ':${uri.port}'
        : '';
    return '${uri.scheme}://${uri.host}$port';
  }
}
