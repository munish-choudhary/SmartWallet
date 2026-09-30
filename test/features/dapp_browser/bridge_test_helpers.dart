import 'dart:convert';

import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/dapp_browser/data/dapp_connection_repository.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/bridge_models.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/dapp_interaction.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/eip1193_bridge.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/evm_read_client.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_chain.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_dapp.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_request.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_account_source.dart';

const account = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
const uniswap = 'https://app.uniswap.org';
const unknownSite = 'https://some-random-site.xyz';

class FakePrompter implements DappInteractionPrompter {
  bool connectAnswer = true;
  WcRequestDecision reviewAnswer = const WcRequestDecision.approve();

  final List<WcDapp> connectPrompts = [];
  final List<WcRequest> reviewed = [];
  final List<String> notices = [];

  @override
  Future<bool> confirmConnection(WcDapp dapp, WalletAccount account) async {
    connectPrompts.add(dapp);
    return connectAnswer;
  }

  @override
  Future<WcRequestDecision> review(WcRequest request) async {
    reviewed.add(request);
    return reviewAnswer;
  }

  @override
  void notice(String message) => notices.add(message);
}

class FakeSigner implements DappSigningGateway {
  Result<String> answer = const Result.ok('0xsigned');
  final List<({WcRequest request, String? cap})> calls = [];

  @override
  Future<Result<String>> execute(WcRequest request, {String? approvalCap}) async {
    calls.add((request: request, cap: approvalCap));
    return answer;
  }
}

class FakeReader implements EvmReadClient {
  RpcOutcome outcome = const RpcSuccess('0x10');
  Object? throwError;
  final List<({WcChain chain, String method, List<Object?> params})> calls = [];

  @override
  Future<RpcOutcome> call(WcChain chain, String method, List<Object?> params) async {
    calls.add((chain: chain, method: method, params: params));
    if (throwError != null) throw throwError!;
    return outcome;
  }
}

class BridgeHarness {
  BridgeHarness({DateTime? now})
      : connections = InMemoryDappConnectionRepository(),
        prompter = FakePrompter(),
        signer = FakeSigner(),
        reader = FakeReader() {
    bridge = Eip1193Bridge(
      connections: connections,
      accounts: const InMemoryWalletAccountSource(),
      prompter: prompter,
      signer: signer,
      reader: reader,
      now: () => now ?? DateTime.utc(2026, 9, 30, 12),
    );
  }

  final InMemoryDappConnectionRepository connections;
  final FakePrompter prompter;
  final FakeSigner signer;
  final FakeReader reader;
  late final Eip1193Bridge bridge;
  int _id = 0;

  Future<BridgeResponse> call(
    String method, {
    List<Object?> params = const [],
    String origin = uniswap,
  }) =>
      bridge.handle(
        BridgeRequest(id: ++_id, method: method, params: params, origin: origin),
      );

  Future<void> connect({String origin = uniswap}) async {
    final r = await call('eth_requestAccounts', origin: origin);
    expectResult(r);
  }

  void expectResult(BridgeResponse r) {
    if (r is! BridgeResult) throw StateError('expected a result, got $r');
  }
}

Object? resultOf(BridgeResponse r) => (r as BridgeResult).value;
BridgeError errorOf(BridgeResponse r) => r as BridgeError;

String approveCalldata(String amountWord) =>
    '0x095ea7b3${'0' * 24}3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad$amountWord';

String typedDataJson({int chainId = 1, String primaryType = 'Mail'}) =>
    jsonEncode({
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
        ],
        primaryType: [
          {'name': 'contents', 'type': 'string'},
        ],
      },
      'primaryType': primaryType,
      'domain': {'name': 'Ether Mail', 'chainId': chainId},
      'message': {'contents': 'Hello, Bob!'},
    });
