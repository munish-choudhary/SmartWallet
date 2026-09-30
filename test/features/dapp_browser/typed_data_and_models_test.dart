import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/bridge_models.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/typed_data_parser.dart';

Map<String, Object?> _permit({Object chainId = 1, String primaryType = 'PermitSingle'}) => {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
          {'name': 'verifyingContract', 'type': 'address'},
        ],
        'PermitSingle': [
          {'name': 'details', 'type': 'PermitDetails'},
          {'name': 'spender', 'type': 'address'},
          {'name': 'sigDeadline', 'type': 'uint256'},
        ],
        'PermitDetails': [
          {'name': 'token', 'type': 'address'},
          {'name': 'amount', 'type': 'uint160'},
          {'name': 'nonce', 'type': 'uint48'},
        ],
      },
      'primaryType': primaryType,
      'domain': {
        'name': 'Permit2',
        'chainId': chainId,
        'verifyingContract': '0x000000000022D473030F116dDEE9F6B43aC78BA3',
      },
      'message': {
        'details': {
          'token': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
          'amount': '1461501637330902918203684832716283019655932542975',
          'nonce': '0',
        },
        'spender': '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD',
        'sigDeadline': '1893456000',
      },
    };

void main() {
  group('TypedDataParser', () {
    test('flattens nested structs in declaration order', () {
      final parsed = TypedDataParser.parse(jsonEncode(_permit()))!;
      expect(parsed.primaryType, 'PermitSingle');
      expect(parsed.chainId, 1);
      expect(parsed.domain.map((f) => f.label), ['name', 'chainId', 'verifyingContract']);
      expect(parsed.fields.map((f) => (f.label, f.depth)), [
        ('details', 0),
        ('token', 1),
        ('amount', 1),
        ('nonce', 1),
        ('spender', 0),
        ('sigDeadline', 0),
      ]);
      expect(parsed.fields.first.value, isEmpty); // struct header row
    });

    test('accepts a decoded map as well as a JSON string', () {
      expect(TypedDataParser.parse(_permit()), isNotNull);
    });

    test('permit/order style types are flagged as authorizing transfers', () {
      for (final type in ['PermitSingle', 'Permit', 'OrderComponents', 'Bid']) {
        final doc = _permit(primaryType: type);
        (doc['types'] as Map)[type] = (doc['types'] as Map)['PermitSingle'];
        expect(TypedDataParser.parse(doc)!.authorizesTransfers, isTrue, reason: type);
      }
      final mail = {
        'types': {
          'Mail': [
            {'name': 'contents', 'type': 'string'},
          ],
        },
        'primaryType': 'Mail',
        'domain': <String, Object?>{},
        'message': {'contents': 'Hello'},
      };
      expect(TypedDataParser.parse(mail)!.authorizesTransfers, isFalse);
    });

    test('reads the chain id from int, decimal string or hex', () {
      expect(TypedDataParser.parse(_permit(chainId: 137))!.chainId, 137);
      expect(TypedDataParser.parse(_permit(chainId: '8453'))!.chainId, 8453);
      expect(TypedDataParser.parse(_permit(chainId: '0x89'))!.chainId, 137);
      expect(TypedDataParser.parse(_permit(chainId: 'nope'))!.chainId, isNull);
    });

    test('a max-value amount is shown as Unlimited, at any width', () {
      // The fixture's amount is Permit2's uint160 max.
      final parsed = TypedDataParser.parse(_permit())!;
      expect(parsed.fields.firstWhere((f) => f.label == 'amount').value, 'Unlimited');
      // Small fields keep their literal value.
      expect(parsed.fields.firstWhere((f) => f.label == 'nonce').value, '0');
      expect(parsed.fields.firstWhere((f) => f.label == 'sigDeadline').value, '1893456000');

      final doc = _permit();
      ((doc['message'] as Map)['details'] as Map)['amount'] = '1500000000';
      expect(
        TypedDataParser.parse(doc)!.fields.firstWhere((f) => f.label == 'amount').value,
        '1500000000',
      );
    });

    test('flattens arrays', () {
      final doc = {
        'types': {
          'Batch': [
            {'name': 'tokens', 'type': 'address[]'},
          ],
        },
        'primaryType': 'Batch',
        'domain': <String, Object?>{},
        'message': {
          'tokens': ['0xa', '0xb'],
        },
      };
      final parsed = TypedDataParser.parse(doc)!;
      expect(parsed.fields.map((f) => f.label), ['tokens[0]', 'tokens[1]']);
    });

    test('caps rows, depth and value length (hostile payloads)', () {
      final many = {
        'types': {
          'Big': [
            for (var i = 0; i < 500; i++) {'name': 'f$i', 'type': 'string'},
          ],
        },
        'primaryType': 'Big',
        'domain': <String, Object?>{},
        'message': {for (var i = 0; i < 500; i++) 'f$i': 'x' * 10000},
      };
      final parsed = TypedDataParser.parse(many)!;
      expect(parsed.fields.length, lessThanOrEqualTo(62));
      expect(parsed.fields.last.label, '…');
      expect(parsed.fields.first.value.length, lessThanOrEqualTo(201));

      // A self-referential struct must not recurse forever.
      final loop = {
        'types': {
          'Node': [
            {'name': 'next', 'type': 'Node'},
          ],
        },
        'primaryType': 'Node',
        'domain': <String, Object?>{},
        'message': <String, Object?>{},
      };
      final nested = loop['message']! as Map<String, Object?>;
      var cursor = nested;
      for (var i = 0; i < 50; i++) {
        final child = <String, Object?>{};
        cursor['next'] = child;
        cursor = child;
      }
      expect(TypedDataParser.parse(loop)!.fields.length, lessThan(10));
    });

    test('rejects documents that are not typed data', () {
      for (final bad in [
        null,
        42,
        'not json',
        '[]',
        '{}',
        jsonEncode({'types': {}, 'primaryType': 'X', 'message': {}}),
        jsonEncode({
          'types': {'X': []},
          'primaryType': 'X',
        }),
        'x' * (600 * 1024),
      ]) {
        expect(TypedDataParser.parse(bad), isNull, reason: '$bad'.substring(0, 20.clamp(0, '$bad'.length)));
      }
    });
  });

  group('BridgeRequest.parse', () {
    const origin = 'https://app.uniswap.org';

    test('parses a well-formed request; origin comes from the caller', () {
      final r = BridgeRequest.parse(
        jsonEncode({
          'id': 7,
          'method': 'eth_accounts',
          'params': [],
          'origin': 'https://evil.com', // ignored
        }),
        origin: origin,
      )!;
      expect(r.id, 7);
      expect(r.method, 'eth_accounts');
      expect(r.params, isEmpty);
      expect(r.origin, origin);
    });

    test('missing params become empty; an object becomes a one-item list', () {
      expect(
        BridgeRequest.parse('{"id":1,"method":"m"}', origin: origin)!.params,
        isEmpty,
      );
      expect(
        BridgeRequest.parse('{"id":1,"method":"m","params":{"a":1}}', origin: origin)!
            .params,
        [
          {'a': 1},
        ],
      );
    });

    test('string ids are kept as given', () {
      expect(BridgeRequest.parse('{"id":"abc","method":"m"}', origin: origin)!.id, 'abc');
    });

    test('drops anything malformed', () {
      for (final bad in <Object?>[
        null,
        42,
        '',
        'not json',
        '[]',
        '{"method":"m"}', // no id
        '{"id":1}', // no method
        '{"id":1,"method":""}',
        '{"id":1,"method":5}',
        '{"id":[],"method":"m"}',
        '{"id":1,"method":"m","params":5}',
        '{"id":1,"method":"${'x' * 200}"}',
        '{"id":1,"method":"m","params":"${'x' * (600 * 1024)}"}',
      ]) {
        expect(BridgeRequest.parse(bad, origin: origin), isNull);
      }
    });
  });

  group('BridgeResponse JSON', () {
    test('result and error shapes match what the page script expects', () {
      expect(
        jsonDecode(const BridgeResult(3, ['0xabc']).toJsonString()),
        {'type': 'response', 'id': 3, 'result': ['0xabc']},
      );
      expect(
        jsonDecode(const BridgeError(3, 4001, 'nope').toJsonString()),
        {
          'type': 'response',
          'id': 3,
          'error': {'code': 4001, 'message': 'nope'},
        },
      );
      expect(
        jsonDecode(
          const BridgeError(3, 3, 'reverted', data: '0x08c379a0').toJsonString(),
        )['error']['data'],
        '0x08c379a0',
      );
    });

    test('a null result is still serialised (eth_switchEthereumChain)', () {
      final json = jsonDecode(const BridgeResult(1, null).toJsonString());
      expect(json.containsKey('result'), isTrue);
      expect(json['result'], isNull);
    });
  });
}
