import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/settings/data/network_draft.dart';
import 'package:smart_wallet/features/settings/data/network_preset.dart';

const _valid = NetworkDraft(
  name: 'Ethereum Fast Relay',
  rpcUrl: 'https://rpc.example.com/v2/key',
  chainId: '1',
  symbol: 'eth',
  explorerUrl: 'https://etherscan.io',
);

void main() {
  group('NetworkDraft.validate', () {
    test('accepts a complete draft and normalises it', () {
      expect(_valid.validate(), isEmpty);
      final network = _valid.toNetwork()!;
      expect(network.currencySymbol, 'ETH');
      expect(network.chainId, 1);
      expect(network.rpcUrl, Uri.parse('https://rpc.example.com/v2/key'));
      expect(network.explorerUrl, Uri.parse('https://etherscan.io'));
    });

    test('the block explorer is optional', () {
      final draft = _valid.copyWith(explorerUrl: '  ');
      expect(draft.validate(), isEmpty);
      expect(draft.toNetwork()!.explorerUrl, isNull);
    });

    test('an empty draft flags every required field but not the explorer', () {
      expect(const NetworkDraft().validate(), {
        NetworkField.name: NetworkFieldError.required,
        NetworkField.rpcUrl: NetworkFieldError.required,
        NetworkField.chainId: NetworkFieldError.required,
        NetworkField.symbol: NetworkFieldError.required,
      });
      expect(const NetworkDraft().toNetwork(), isNull);
    });

    test('a typed but malformed explorer is rejected', () {
      expect(
        _valid.copyWith(explorerUrl: 'etherscan.io').validate(),
        {NetworkField.explorerUrl: NetworkFieldError.invalidUrl},
      );
    });

    test('name is capped', () {
      expect(
        NetworkDraft.validateName('x' * (NetworkDraft.maxNameLength + 1)),
        NetworkFieldError.tooLong,
      );
      expect(NetworkDraft.validateName('x' * NetworkDraft.maxNameLength), isNull);
    });
  });

  group('URL rules', () {
    test('https is accepted', () {
      expect(NetworkDraft.validateUrl('https://rpc.example.com'), isNull);
    });

    test('plain http is refused for remote hosts', () {
      expect(
        NetworkDraft.validateUrl('http://rpc.example.com'),
        NetworkFieldError.insecureUrl,
      );
    });

    test('plain http is allowed for a local dev node', () {
      expect(NetworkDraft.validateUrl('http://localhost:8545'), isNull);
      expect(NetworkDraft.validateUrl('http://127.0.0.1:8545'), isNull);
      expect(NetworkDraft.validateUrl('http://[::1]:8545'), isNull);
    });

    test('other schemes, missing hosts and bare words are invalid', () {
      for (final bad in [
        'ftp://rpc.example.com',
        'javascript:alert(1)',
        'https://',
        'rpc.example.com',
        'not a url',
        'wss://rpc.example.com',
      ]) {
        expect(
          NetworkDraft.validateUrl(bad),
          NetworkFieldError.invalidUrl,
          reason: bad,
        );
      }
    });

    test('embedded credentials are refused (host-spoofing trick)', () {
      expect(
        NetworkDraft.validateUrl('https://etherscan.io@evil.example.com'),
        NetworkFieldError.invalidUrl,
      );
    });

    test('a look-alike loopback host over http is still insecure', () {
      expect(
        NetworkDraft.validateUrl('http://localhost.evil.example.com'),
        NetworkFieldError.insecureUrl,
      );
    });
  });

  group('chain ID rules', () {
    test('accepts positive whole numbers up to the EIP-155 bound', () {
      expect(NetworkDraft.validateChainId('1'), isNull);
      expect(NetworkDraft.validateChainId('42161'), isNull);
      expect(
        NetworkDraft.validateChainId('${NetworkDraft.maxChainId}'),
        isNull,
      );
    });

    test('rejects zero, negatives, decimals, hex, junk and overflow', () {
      for (final bad in [
        '0',
        '-1',
        '1.5',
        '0x1',
        'abc',
        '${NetworkDraft.maxChainId + 1}',
        '99999999999999999999999',
      ]) {
        expect(
          NetworkDraft.validateChainId(bad),
          NetworkFieldError.invalidChainId,
          reason: bad,
        );
      }
    });
  });

  group('symbol rules', () {
    test('2-6 letters or digits', () {
      expect(NetworkDraft.validateSymbol('ETH'), isNull);
      expect(NetworkDraft.validateSymbol('1INCH'), isNull);
      for (final bad in ['E', 'TOOLONG7', 'E TH', 'ET-H']) {
        expect(
          NetworkDraft.validateSymbol(bad),
          NetworkFieldError.invalidSymbol,
          reason: bad,
        );
      }
    });
  });

  test('every preset is itself a valid network', () {
    for (final preset in NetworkPreset.all) {
      final draft = NetworkDraft(
        name: preset.name,
        rpcUrl: preset.rpcUrl,
        chainId: '${preset.chainId}',
        symbol: preset.currencySymbol,
        explorerUrl: preset.explorerUrl,
      );
      expect(draft.validate(), isEmpty, reason: preset.label);
    }
  });
}
