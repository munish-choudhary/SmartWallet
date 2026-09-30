import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/bridge_models.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/evm_read_client.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_chain.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_dapp.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_request.dart';

import 'bridge_test_helpers.dart';

void main() {
  late BridgeHarness h;
  setUp(() => h = BridgeHarness());

  group('chain & accounts (no prompt needed)', () {
    test('defaults to Ethereum mainnet', () async {
      expect(resultOf(await h.call('eth_chainId')), '0x1');
      expect(resultOf(await h.call('net_version')), '1');
    });

    test('a site sees no accounts until it is connected', () async {
      expect(resultOf(await h.call('eth_accounts')), isEmpty);
      expect(resultOf(await h.call('wallet_getPermissions')), isEmpty);
    });
  });

  group('eth_requestAccounts', () {
    test('asks the user, then reveals the account and remembers it', () async {
      final r = await h.call('eth_requestAccounts');
      expect(resultOf(r), [account]);
      expect(h.prompter.connectPrompts, hasLength(1));

      expect(resultOf(await h.call('eth_accounts')), [account]);
      expect(
        resultOf(await h.call('wallet_getPermissions')),
        [
          {'parentCapability': 'eth_accounts'},
        ],
      );
    });

    test('a curated origin is shown verified with its real name', () async {
      await h.connect(origin: uniswap);
      final dapp = h.prompter.connectPrompts.single;
      expect(dapp.name, 'Uniswap');
      expect(dapp.verification, WcVerification.verified);
    });

    test('an unknown origin is shown by host and unverified', () async {
      await h.connect(origin: unknownSite);
      final dapp = h.prompter.connectPrompts.single;
      expect(dapp.name, 'some-random-site.xyz');
      expect(dapp.verification, WcVerification.unverified);
    });

    test('a look-alike host cannot borrow a curated name', () async {
      for (final origin in [
        'https://app.uniswap.org.evil.com',
        'https://app-uniswap.org',
        'http://app.uniswap.org', // downgraded scheme
      ]) {
        final fresh = BridgeHarness();
        await fresh.call('eth_requestAccounts', origin: origin);
        final prompts = fresh.prompter.connectPrompts;
        if (prompts.isNotEmpty) {
          expect(prompts.single.name, isNot('Uniswap'), reason: origin);
          expect(
            prompts.single.verification,
            WcVerification.unverified,
            reason: origin,
          );
        }
      }
    });

    test('rejection returns 4001 and stores nothing', () async {
      h.prompter.connectAnswer = false;
      final e = errorOf(await h.call('eth_requestAccounts'));
      expect(e.code, RpcCode.userRejected);
      expect(resultOf(await h.call('eth_accounts')), isEmpty);
    });

    test('an already-connected origin is not asked again', () async {
      await h.connect();
      await h.call('eth_requestAccounts');
      expect(h.prompter.connectPrompts, hasLength(1));
    });

    test('permission is per origin, never shared', () async {
      await h.connect(origin: uniswap);
      expect(resultOf(await h.call('eth_accounts', origin: unknownSite)), isEmpty);
      expect(
        resultOf(await h.call('eth_accounts', origin: 'https://evil.app.uniswap.org')),
        isEmpty,
      );
    });

    test('plain http is refused without prompting (except localhost)', () async {
      final e = errorOf(
        await h.call('eth_requestAccounts', origin: 'http://some-site.com'),
      );
      expect(e.code, RpcCode.unauthorized);
      expect(h.prompter.connectPrompts, isEmpty);

      final ok = await h.call('eth_requestAccounts', origin: 'http://localhost:3000');
      expect(resultOf(ok), [account]);
    });

    test('wallet_requestPermissions connects like eth_requestAccounts', () async {
      final r = await h.call('wallet_requestPermissions', params: [
        {'eth_accounts': <String, Object?>{}},
      ]);
      expect(
        resultOf(r),
        [
          {'parentCapability': 'eth_accounts'},
        ],
      );
      expect(resultOf(await h.call('eth_accounts')), [account]);
    });

    test('disconnect revokes access and tells the page', () async {
      await h.connect();
      final events = <BridgeEvent>[];
      final sub = h.bridge.events.listen(events.add);

      await h.bridge.disconnect(uniswap);
      await pumpEventQueue();

      expect(resultOf(await h.call('eth_accounts')), isEmpty);
      expect(events.single, isA<AccountsChangedEvent>());
      expect((events.single as AccountsChangedEvent).accounts, isEmpty);
      await sub.cancel();
    });
  });

  group('wallet_switchEthereumChain', () {
    test('switches network, emits chainChanged, even before connecting', () async {
      final events = <BridgeEvent>[];
      final sub = h.bridge.events.listen(events.add);

      final r = await h.call('wallet_switchEthereumChain', params: [
        {'chainId': '0x89'},
      ]);
      await pumpEventQueue();

      expect(resultOf(r), isNull);
      expect(resultOf(await h.call('eth_chainId')), '0x89');
      expect(resultOf(await h.call('net_version')), '137');
      expect((events.single as ChainChangedEvent).chainIdHex, '0x89');
      expect(events.single.origin, uniswap);
      await sub.cancel();
    });

    test('the choice is remembered on the connection', () async {
      await h.connect();
      await h.call('wallet_switchEthereumChain', params: [
        {'chainId': '0xa4b1'},
      ]);
      final saved = (await h.connections.connectionFor(uniswap)).valueOrNull!;
      expect(saved.chain, WcChains.arbitrum);
    });

    test('networks are per origin', () async {
      await h.call('wallet_switchEthereumChain', params: [
        {'chainId': '0x89'},
      ]);
      expect(resultOf(await h.call('eth_chainId', origin: unknownSite)), '0x1');
    });

    test('unsupported chain → 4902; missing param → -32602', () async {
      final unknown = errorOf(await h.call('wallet_switchEthereumChain', params: [
        {'chainId': '0x539'},
      ]));
      expect(unknown.code, RpcCode.unrecognizedChain);

      final missing = errorOf(await h.call('wallet_switchEthereumChain'));
      expect(missing.code, RpcCode.invalidParams);

      final junk = errorOf(await h.call('wallet_switchEthereumChain', params: [
        {'chainId': 137},
      ]));
      expect(junk.code, RpcCode.invalidParams);
    });

    test('switchChain from the UI behaves the same', () async {
      await h.connect();
      await h.bridge.switchChain(uniswap, WcChains.base);
      expect(resultOf(await h.call('eth_chainId')), '0x2105');
    });
  });

  group('personal_sign', () {
    const hexHello = '0x48656c6c6f'; // "Hello"

    test('needs a connection, and never prompts without one', () async {
      final e = errorOf(await h.call('personal_sign', params: [hexHello, account]));
      expect(e.code, RpcCode.unauthorized);
      expect(h.prompter.reviewed, isEmpty);
      expect(h.signer.calls, isEmpty);
    });

    test('shows the decoded message, attributed to the browser', () async {
      await h.connect();
      await h.call('personal_sign', params: [hexHello, account]);

      final request = h.prompter.reviewed.single as WcPersonalSignRequest;
      expect(request.message, 'Hello');
      expect(request.messageIsReadable, isTrue);
      expect(request.origin, WcRequestOrigin.inAppBrowser);
      expect(request.dapp.name, 'Uniswap');
      expect(request.signer, account);
      expect(request.chain, WcChains.ethereum);
    });

    test('approval reaches the signer and its result is returned', () async {
      await h.connect();
      final r = await h.call('personal_sign', params: [hexHello, account]);
      expect(resultOf(r), '0xsigned');
      expect(h.signer.calls, hasLength(1));
    });

    test('rejection is 4001 and the signer is never called', () async {
      await h.connect();
      h.prompter.reviewAnswer = const WcRequestDecision.reject();
      final e = errorOf(await h.call('personal_sign', params: [hexHello, account]));
      expect(e.code, RpcCode.userRejected);
      expect(h.signer.calls, isEmpty);
    });

    test('an unavailable signing pipeline is reported, not faked', () async {
      await h.connect();
      h.signer.answer = const Result.err(AppFailure.notImplemented());
      final e = errorOf(await h.call('personal_sign', params: [hexHello, account]));
      expect(e.code, RpcCode.unsupportedMethod);
      expect(h.prompter.notices.single, contains('Nothing was signed'));
    });

    test('other signer failures become a generic error (no details leak)', () async {
      await h.connect();
      h.signer.answer = const Result.err(AppFailure.unknown('secret-ish detail'));
      final e = errorOf(await h.call('personal_sign', params: [hexHello, account]));
      expect(e.code, RpcCode.internal);
      expect(e.message, isNot(contains('secret')));
    });

    test('only the connected account may sign (case-insensitive)', () async {
      await h.connect();
      final other = errorOf(await h.call('personal_sign', params: [
        hexHello,
        '0x000000000000000000000000000000000000dEaD',
      ]));
      expect(other.code, RpcCode.unauthorized);
      expect(h.prompter.reviewed, isEmpty);

      final lower = await h.call('personal_sign', params: [
        hexHello,
        account.toLowerCase(),
      ]);
      expect(resultOf(lower), '0xsigned');
    });

    test('accepts the legacy [address, message] order', () async {
      await h.connect();
      final r = await h.call('personal_sign', params: [account, hexHello]);
      expect(resultOf(r), '0xsigned');
      expect((h.prompter.reviewed.single as WcPersonalSignRequest).message, 'Hello');
    });

    test('unreadable data is flagged; bad params are rejected early', () async {
      await h.connect();
      await h.call('personal_sign', params: ['0xdeadbeef', account]);
      expect(
        (h.prompter.reviewed.single as WcPersonalSignRequest).messageIsReadable,
        isFalse,
      );

      h.prompter.reviewed.clear();
      expect(
        errorOf(await h.call('personal_sign', params: [hexHello])).code,
        RpcCode.invalidParams,
      );
      expect(
        errorOf(await h.call('personal_sign', params: [5, account])).code,
        RpcCode.invalidParams,
      );
      expect(h.prompter.reviewed, isEmpty);
    });

    test('eth_sign is refused outright', () async {
      await h.connect();
      final e = errorOf(await h.call('eth_sign', params: [account, '0x00']));
      expect(e.code, RpcCode.unsupportedMethod);
      expect(h.prompter.reviewed, isEmpty);
    });
  });

  group('eth_signTypedData_v4', () {
    test('reviews the parsed message', () async {
      await h.connect();
      final r = await h.call('eth_signTypedData_v4', params: [account, typedDataJson()]);
      expect(resultOf(r), '0xsigned');
      final request = h.prompter.reviewed.single as WcTypedDataRequest;
      expect(request.primaryType, 'Mail');
      expect(request.fields.single.value, 'Hello, Bob!');
      expect(request.authorizesTransfers, isFalse);
      expect(request.origin, WcRequestOrigin.inAppBrowser);
    });

    test('flags permit-style messages', () async {
      await h.connect();
      await h.call('eth_signTypedData_v4', params: [
        account,
        typedDataJson(primaryType: 'PermitSingle'),
      ]);
      expect(
        (h.prompter.reviewed.single as WcTypedDataRequest).authorizesTransfers,
        isTrue,
      );
    });

    test('refuses typed data for a different chain than the one selected', () async {
      await h.connect(); // Ethereum
      final e = errorOf(await h.call('eth_signTypedData_v4', params: [
        account,
        typedDataJson(chainId: 137),
      ]));
      expect(e.code, RpcCode.invalidParams);
      expect(h.prompter.reviewed, isEmpty);
    });

    test('requires a connection, the right account and valid data', () async {
      expect(
        errorOf(await h.call('eth_signTypedData_v4', params: [account, typedDataJson()]))
            .code,
        RpcCode.unauthorized,
      );
      await h.connect();
      expect(
        errorOf(await h.call('eth_signTypedData_v4', params: [
          '0x000000000000000000000000000000000000dEaD',
          typedDataJson(),
        ])).code,
        RpcCode.unauthorized,
      );
      expect(
        errorOf(await h.call('eth_signTypedData_v4', params: [account, 'nonsense']))
            .code,
        RpcCode.invalidParams,
      );
      expect(h.prompter.reviewed, isEmpty);
    });
  });

  group('eth_sendTransaction', () {
    Map<String, Object?> tx({
      Object? from = account,
      Object? to = '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD',
      Object? value,
      Object? data,
      Object? chainId,
      Object? gas,
      Object? gasPrice,
    }) =>
        {
          if (from != null) 'from': from,
          if (to != null) 'to': to,
          if (value != null) 'value': value,
          if (data != null) 'data': data,
          if (chainId != null) 'chainId': chainId,
          if (gas != null) 'gas': gas,
          if (gasPrice != null) 'gasPrice': gasPrice,
        };

    test('a plain transfer is reviewed with value and fee', () async {
      await h.connect();
      final r = await h.call('eth_sendTransaction', params: [
        tx(value: '0x3782dace9d90000', gas: '0x5208', gasPrice: '0x3b9aca00'),
      ]);
      expect(resultOf(r), '0xsigned');

      final request = h.prompter.reviewed.single as WcTransactionRequest;
      expect(request.valueDisplay, '0.25 ETH');
      expect(request.networkFeeDisplay, '0.000021 ETH');
      expect(request.to, '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD');
      expect(request.isContractCall, isFalse);
      expect(request.risks, isEmpty);
      expect(request.origin, WcRequestOrigin.inAppBrowser);
    });

    test('unknown fee is stated honestly', () async {
      await h.connect();
      await h.call('eth_sendTransaction', params: [tx(value: '0x1')]);
      expect(
        (h.prompter.reviewed.single as WcTransactionRequest).networkFeeDisplay,
        'Estimated when sent',
      );
    });

    test('an unlimited approval is decoded, warned about, and the cap is forwarded',
        () async {
      await h.connect();
      h.prompter.reviewAnswer = const WcRequestDecision.approve(approvalCap: '500');
      await h.call('eth_sendTransaction', params: [
        tx(
          to: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
          data: approveCalldata('f' * 64),
        ),
      ]);

      final request = h.prompter.reviewed.single as WcTransactionRequest;
      expect(request.methodName, 'approve');
      expect(request.approval!.isUnlimited, isTrue);
      expect(request.approval!.spender, '0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad');
      expect(request.risks.single.severity, WcRiskSeverity.danger);
      expect(h.signer.calls.single.cap, '500');
    });

    test('a limited approval is not flagged unlimited', () async {
      await h.connect();
      await h.call('eth_sendTransaction', params: [
        tx(
          to: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
          data: approveCalldata('59682f00'.padLeft(64, '0')),
        ),
      ]);
      final request = h.prompter.reviewed.single as WcTransactionRequest;
      expect(request.approval!.isUnlimited, isFalse);
      expect(request.risks, isEmpty);
    });

    test('setApprovalForAll(true) is flagged as dangerous', () async {
      await h.connect();
      await h.call('eth_sendTransaction', params: [
        tx(
          data: '0xa22cb465${'0' * 24}3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad${'0' * 63}1',
        ),
      ]);
      final request = h.prompter.reviewed.single as WcTransactionRequest;
      expect(request.risks.single.severity, WcRiskSeverity.danger);
      expect(request.risks.single.title, contains('NFTs'));
    });

    test('calldata we cannot name gets a caution, not a friendly label', () async {
      await h.connect();
      await h.call('eth_sendTransaction', params: [tx(data: '0xdeadbeef00')]);
      final request = h.prompter.reviewed.single as WcTransactionRequest;
      expect(request.methodName, isNull);
      expect(request.risks.single.severity, WcRiskSeverity.caution);
    });

    test('rejection is 4001 and nothing is signed', () async {
      await h.connect();
      h.prompter.reviewAnswer = const WcRequestDecision.reject();
      final e = errorOf(await h.call('eth_sendTransaction', params: [tx()]));
      expect(e.code, RpcCode.userRejected);
      expect(h.signer.calls, isEmpty);
    });

    test('validates every field before showing anything', () async {
      await h.connect();
      final cases = <String, (List<Object?>, int)>{
        'no params': (const [], RpcCode.invalidParams),
        'not an object': (const ['0x00'], RpcCode.invalidParams),
        'wrong sender': (
          [tx(from: '0x000000000000000000000000000000000000dEaD')],
          RpcCode.unauthorized,
        ),
        'deploy': ([tx(to: null)], RpcCode.unsupportedMethod),
        'bad to': ([tx(to: '0x123')], RpcCode.invalidParams),
        'bad value': ([tx(value: 'one')], RpcCode.invalidParams),
        'bad data': ([tx(data: '0xabc')], RpcCode.invalidParams),
        'other chain': ([tx(chainId: '0x89')], RpcCode.invalidParams),
        'chainId not hex': ([tx(chainId: 1)], RpcCode.invalidParams),
      };
      for (final entry in cases.entries) {
        final e = errorOf(await h.call('eth_sendTransaction', params: entry.value.$1));
        expect(e.code, entry.value.$2, reason: entry.key);
      }
      expect(h.prompter.reviewed, isEmpty);
      expect(h.signer.calls, isEmpty);
    });

    test('matching chainId is accepted; "from" may be omitted', () async {
      await h.connect();
      final r = await h.call('eth_sendTransaction', params: [
        tx(from: null, chainId: '0x1'),
      ]);
      expect(resultOf(r), '0xsigned');
    });

    test('requires a connection', () async {
      final e = errorOf(await h.call('eth_sendTransaction', params: [tx()]));
      expect(e.code, RpcCode.unauthorized);
      expect(h.prompter.reviewed, isEmpty);
    });

    test('uses the network the user selected', () async {
      await h.connect();
      await h.call('wallet_switchEthereumChain', params: [
        {'chainId': '0x89'},
      ]);
      await h.call('eth_sendTransaction', params: [tx(value: '0xde0b6b3a7640000')]);
      final request = h.prompter.reviewed.single as WcTransactionRequest;
      expect(request.chain, WcChains.polygon);
      expect(request.valueDisplay, '1 POL');
    });
  });

  group('read-only proxy', () {
    test('forwards allowed methods to the current chain', () async {
      await h.call('wallet_switchEthereumChain', params: [
        {'chainId': '0x2105'},
      ]);
      final r = await h.call('eth_call', params: [
        {'to': account},
        'latest',
      ]);
      expect(resultOf(r), '0x10');
      expect(h.reader.calls.single.method, 'eth_call');
      expect(h.reader.calls.single.chain, WcChains.base);
      expect(h.reader.calls.single.params, hasLength(2));
    });

    test('never forwards write methods or anything unknown', () async {
      for (final method in [
        'eth_sendRawTransaction',
        'eth_signTransaction',
        'personal_unlockAccount',
        'debug_traceTransaction',
        'wallet_addEthereumChain',
        'wallet_watchAsset',
      ]) {
        final e = errorOf(await h.call(method));
        expect(e.code, RpcCode.unsupportedMethod, reason: method);
      }
      expect(h.reader.calls, isEmpty);
    });

    test('passes node errors through, including revert data', () async {
      h.reader.outcome = const RpcFailure(3, 'execution reverted', data: '0x08c379a0');
      final e = errorOf(await h.call('eth_call', params: [{}, 'latest']));
      expect(e.code, 3);
      expect(e.data, '0x08c379a0');
    });

    test('an unreachable node is a 4900, not a hang', () async {
      h.reader.outcome = const RpcUnreachable();
      final e = errorOf(await h.call('eth_blockNumber'));
      expect(e.code, RpcCode.disconnected);
    });

    test('an unexpected exception becomes a generic internal error', () async {
      h.reader.throwError = StateError('boom with secrets');
      final e = errorOf(await h.call('eth_blockNumber'));
      expect(e.code, RpcCode.internal);
      expect(e.message, 'Internal error');
    });
  });

  test('an unknown method is 4200 and echoes at most a truncated name', () async {
    final e = errorOf(await h.call('x' * 500));
    expect(e.code, RpcCode.unsupportedMethod);
    expect(e.message.length, lessThan(120));
  });
}
