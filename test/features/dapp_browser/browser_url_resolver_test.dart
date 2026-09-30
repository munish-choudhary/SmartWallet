import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/dapp_browser/data/browser_url_resolver.dart';

Uri _url(String input) {
  final r = BrowserUrlResolver.resolve(input);
  expect(r, isA<ResolvedUrl>(), reason: input);
  return (r as ResolvedUrl).uri;
}

void main() {
  group('BrowserUrlResolver.resolve', () {
    test('keeps an explicit https URL intact', () {
      expect(
        _url('https://app.uniswap.org/swap?chain=base#x').toString(),
        'https://app.uniswap.org/swap?chain=base#x',
      );
    });

    test('assumes https for a bare host, with path and port', () {
      expect(_url('app.uniswap.org').toString(), 'https://app.uniswap.org');
      expect(_url('example.com/a/b?q=1').toString(), 'https://example.com/a/b?q=1');
      expect(_url('example.com:8443/x').toString(), 'https://example.com:8443/x');
      expect(_url('localhost:3000').toString(), 'https://localhost:3000');
    });

    test('allows plain http explicitly typed (the page shows "not secure")', () {
      expect(_url('http://localhost:3000').scheme, 'http');
    });

    test('normalises scheme and host case', () {
      final uri = _url('HTTPS://APP.Uniswap.ORG');
      expect(uri.scheme, 'https');
      expect(uri.host, 'app.uniswap.org');
    });

    test('trims whitespace', () {
      expect(_url('  example.com \n').host, 'example.com');
    });

    test('falls back to a web search for anything that is not a URL', () {
      for (final q in ['uniswap', 'how to swap eth', 'what is 1.5 eth in usd']) {
        final r = BrowserUrlResolver.resolve(q);
        expect(r, isA<ResolvedSearch>(), reason: q);
        final uri = (r as ResolvedSearch).uri;
        expect(uri.host, 'duckduckgo.com');
        expect(uri.queryParameters['q'], q);
      }
    });

    test('refuses every scheme that is not http(s)', () {
      for (final input in [
        'javascript:alert(document.cookie)',
        'JaVaScRiPt:alert(1)',
        'javascript:1', // looks like host:port, must still be refused
        'data:1',
        'data:text/html,<script>alert(1)</script>',
        'file:///etc/passwd',
        'intent://scan/#Intent;scheme=zxing;end',
        'wc:${'0' * 64}@2?relay-protocol=irn&symKey=${'a' * 64}',
        'view-source:https://example.com',
        'ftp://example.com',
        'about:blank',
      ]) {
        expect(
          BrowserUrlResolver.resolve(input),
          isA<RejectedInput>(),
          reason: input,
        );
      }
    });

    test('refuses credentials in the URL (host-spoofing trick)', () {
      final r = BrowserUrlResolver.resolve('https://app.uniswap.org@evil.com');
      expect(r, isA<RejectedInput>());
    });

    test('refuses empty input', () {
      expect(BrowserUrlResolver.resolve(''), isA<RejectedInput>());
      expect(BrowserUrlResolver.resolve('   '), isA<RejectedInput>());
    });

    test('refuses a URL with no host', () {
      expect(BrowserUrlResolver.resolve('https://'), isA<RejectedInput>());
    });
  });

  group('allowsNavigation', () {
    test('web pages and about:blank only', () {
      expect(BrowserUrlResolver.allowsNavigation(Uri.parse('https://a.com')), isTrue);
      expect(BrowserUrlResolver.allowsNavigation(Uri.parse('http://a.com')), isTrue);
      expect(BrowserUrlResolver.allowsNavigation(Uri.parse('about:blank')), isTrue);
    });

    test('blocks other schemes and credentialed URLs', () {
      for (final u in [
        'javascript:void(0)',
        'data:text/html,hi',
        'file:///x',
        'intent://x',
        'wc:abc@2?x=y',
        'https://user:pw@a.com',
        'https:///nohost',
      ]) {
        expect(
          BrowserUrlResolver.allowsNavigation(Uri.parse(u)),
          isFalse,
          reason: u,
        );
      }
    });
  });

  group('originOf', () {
    test('drops default ports, keeps custom ones', () {
      expect(
        BrowserUrlResolver.originOf(Uri.parse('https://a.com:443/x?y=1')),
        'https://a.com',
      );
      expect(
        BrowserUrlResolver.originOf(Uri.parse('http://a.com:80/')),
        'http://a.com',
      );
      expect(
        BrowserUrlResolver.originOf(Uri.parse('https://a.com:8443/')),
        'https://a.com:8443',
      );
    });

    test('distinguishes subdomains and schemes', () {
      expect(
        BrowserUrlResolver.originOf(Uri.parse('https://app.a.com')),
        isNot(BrowserUrlResolver.originOf(Uri.parse('https://a.com'))),
      );
      expect(
        BrowserUrlResolver.originOf(Uri.parse('http://a.com')),
        isNot(BrowserUrlResolver.originOf(Uri.parse('https://a.com'))),
      );
    });

    test('is null for non-web URIs', () {
      expect(BrowserUrlResolver.originOf(Uri.parse('about:blank')), isNull);
      expect(BrowserUrlResolver.originOf(Uri.parse('file:///x')), isNull);
    });
  });
}
