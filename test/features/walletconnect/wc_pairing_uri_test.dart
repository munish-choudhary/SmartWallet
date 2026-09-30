import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/walletconnect/data/wc_pairing_uri.dart';

import 'wc_test_helpers.dart';

void main() {
  group('WcPairingUri.tryParse', () {
    test('accepts a v2 pairing link', () {
      final parsed = WcPairingUri.tryParse(validPairingLink());
      expect(parsed, isNotNull);
      expect(parsed!.topic, hasLength(64));
      expect(parsed.expiresAt, isNull);
    });

    test('trims surrounding whitespace (pasted links often carry it)', () {
      expect(WcPairingUri.tryParse('  ${validPairingLink()}\n'), isNotNull);
    });

    test('reads expiryTimestamp', () {
      final ts = testNow.millisecondsSinceEpoch ~/ 1000 + 300;
      final parsed = WcPairingUri.tryParse(
        validPairingLink(extra: '&expiryTimestamp=$ts'),
      )!;
      expect(parsed.isExpired(testNow), isFalse);
      expect(parsed.isExpired(testNow.add(const Duration(minutes: 6))), isTrue);
    });

    test('rejects everything that is not a v2 pairing link', () {
      final topic = '0' * 64;
      final key = 'ab12' * 16;
      final bad = <String>[
        '',
        'hello',
        'https://example.com',
        'wc:',
        'wc:$topic@2', // no query
        'wc:$topic@1?relay-protocol=irn&symKey=$key', // v1
        'wc:${'0' * 63}@2?relay-protocol=irn&symKey=$key', // short topic
        'wc:${'z' * 64}@2?relay-protocol=irn&symKey=$key', // non-hex topic
        'wc:$topic@2?relay-protocol=irn', // no key
        'wc:$topic@2?relay-protocol=irn&symKey=abc', // short key
        'wc:$topic@2?symKey=$key', // no relay protocol
        'WC:$topic@2?relay-protocol=irn&symKey=$key', // wrong case scheme
      ];
      for (final input in bad) {
        expect(WcPairingUri.tryParse(input), isNull, reason: input);
      }
    });
  });
}
