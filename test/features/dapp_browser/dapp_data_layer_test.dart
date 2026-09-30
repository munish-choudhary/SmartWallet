import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/dapp_browser/data/dapp_browser_repository.dart';
import 'package:smart_wallet/features/dapp_browser/data/dapp_catalog.dart';
import 'package:smart_wallet/features/dapp_browser/data/dapp_connection_repository.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/dapp_interaction.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/evm_read_client.dart';
import 'package:smart_wallet/features/dapp_browser/data/models/browser_visit.dart';
import 'package:smart_wallet/features/dapp_browser/data/models/dapp_connection.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_chain.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_dapp.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_request.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_account_source.dart';
import 'package:smart_wallet/core/result/result.dart';

import 'bridge_test_helpers.dart';

final _t0 = DateTime.utc(2026, 9, 30, 12);

void main() {
  group('BrowserVisit.sanitized', () {
    test('keeps origin and path only — no query, fragment or credentials', () {
      final visit = BrowserVisit.sanitized(
        uri: Uri.parse('https://user:pw@app.uniswap.org:8443/swap?token=SECRET#frag'),
        title: '  Swap  ',
        visitedAt: _t0,
      );
      expect(visit.url, 'https://app.uniswap.org:8443/swap');
      expect(visit.url, isNot(contains('SECRET')));
      expect(visit.url, isNot(contains('pw')));
      expect(visit.title, 'Swap');
      expect(visit.host, 'app.uniswap.org');
    });
  });

  group('InMemoryDappBrowserRepository', () {
    test('emits the catalog immediately', () async {
      final snapshot = await InMemoryDappBrowserRepository().watch().first;
      expect(snapshot.catalog, DappCatalog.featured);
      expect(snapshot.favoriteIds, isEmpty);
      expect(snapshot.recents, isEmpty);
    });

    test('toggling a favorite adds then removes it and notifies', () async {
      final repo = InMemoryDappBrowserRepository();
      final seen = <Set<String>>[];
      final sub = repo.watch().listen((s) => seen.add(s.favoriteIds));
      await pumpEventQueue();

      await repo.toggleFavorite('uniswap');
      await repo.toggleFavorite('uniswap');
      await pumpEventQueue();

      expect(seen, [
        <String>{},
        {'uniswap'},
        <String>{},
      ]);
      await sub.cancel();
    });

    test('favorites resolve to catalog entries in catalog order', () async {
      final repo = InMemoryDappBrowserRepository();
      await repo.toggleFavorite('aave');
      await repo.toggleFavorite('uniswap');
      final snapshot = await repo.watch().first;
      expect(snapshot.favorites.map((d) => d.id), ['uniswap', 'aave']);
    });

    test('an unknown dApp id is refused', () async {
      final result = await InMemoryDappBrowserRepository().toggleFavorite('nope');
      expect(result.isOk, isFalse);
    });

    test('recents are newest-first, deduplicated and capped', () async {
      final repo = InMemoryDappBrowserRepository();
      BrowserVisit visit(String path) => BrowserVisit(
            url: 'https://a.com/$path',
            title: path,
            visitedAt: _t0,
          );

      await repo.recordVisit(visit('one'));
      await repo.recordVisit(visit('two'));
      await repo.recordVisit(visit('one')); // revisit: moves to the front
      var snapshot = await repo.watch().first;
      expect(snapshot.recents.map((v) => v.title), ['one', 'two']);

      for (var i = 0; i < 30; i++) {
        await repo.recordVisit(visit('p$i'));
      }
      snapshot = await repo.watch().first;
      expect(snapshot.recents, hasLength(InMemoryDappBrowserRepository.maxRecents));
      expect(snapshot.recents.first.title, 'p29');
    });

    test('clearRecents empties history only', () async {
      final repo = InMemoryDappBrowserRepository();
      await repo.toggleFavorite('uniswap');
      await repo.recordVisit(BrowserVisit(url: 'https://a.com/', title: 'a', visitedAt: _t0));
      await repo.clearRecents();
      final snapshot = await repo.watch().first;
      expect(snapshot.recents, isEmpty);
      expect(snapshot.favoriteIds, {'uniswap'});
    });

    test('two watchers each get their own stream and updates', () async {
      final repo = InMemoryDappBrowserRepository();
      final a = <int>[];
      final b = <int>[];
      final subA = repo.watch().listen((s) => a.add(s.recents.length));
      final subB = repo.watch().listen((s) => b.add(s.recents.length));
      await pumpEventQueue();
      await repo.recordVisit(BrowserVisit(url: 'https://a.com/', title: 'a', visitedAt: _t0));
      await pumpEventQueue();
      expect(a, [0, 1]);
      expect(b, [0, 1]);
      await subA.cancel();
      await subB.cancel();
    });
  });

  group('InMemoryDappConnectionRepository', () {
    test('save, read, list and remove by origin', () async {
      final repo = InMemoryDappConnectionRepository();
      final connection = DappConnection(
        origin: uniswap,
        address: account,
        chain: WcChains.ethereum,
        connectedAt: _t0,
      );
      expect((await repo.connectionFor(uniswap)).valueOrNull, isNull);

      await repo.save(connection);
      expect((await repo.connectionFor(uniswap)).valueOrNull, connection);
      expect((await repo.all()).valueOrNull, hasLength(1));

      await repo.remove(uniswap);
      expect((await repo.connectionFor(uniswap)).valueOrNull, isNull);
    });

    test('withChain keeps everything else', () {
      final c = DappConnection(
        origin: uniswap,
        address: account,
        chain: WcChains.ethereum,
        connectedAt: _t0,
      ).withChain(WcChains.base);
      expect(c.chain, WcChains.base);
      expect(c.origin, uniswap);
      expect(c.address, account);
      expect(c.connectedAt, _t0);
    });
  });

  group('DappPromptBroker', () {
    const dapp = WcDapp(name: 'X', url: 'https://x.com');
    const walletAccount = WalletAccount(address: account, label: 'Main');

    WcRequest request() => WcPersonalSignRequest(
          id: 'r',
          dapp: dapp,
          chain: WcChains.ethereum,
          signer: account,
          receivedAt: _t0,
          message: 'hi',
        );

    test('fails closed with no UI attached', () async {
      final broker = DappPromptBroker();
      expect(await broker.confirmConnection(dapp, walletAccount), isFalse);
      expect((await broker.review(request())).approved, isFalse);
      broker.notice('ignored');
      broker.dispose();
    });

    test('hands prompts to the UI and returns its answers', () async {
      final broker = DappPromptBroker();
      final sub = broker.prompts.listen((p) {
        switch (p) {
          case ConnectPrompt():
            p.respond(true);
          case ReviewPrompt():
            p.respond(const WcRequestDecision.approve(approvalCap: '7'));
          case NoticePrompt():
            break;
        }
      });

      expect(await broker.confirmConnection(dapp, walletAccount), isTrue);
      final decision = await broker.review(request());
      expect(decision.approved, isTrue);
      expect(decision.approvalCap, '7');
      await sub.cancel();
      broker.dispose();
    });

    test('shows one prompt at a time, in order', () async {
      final broker = DappPromptBroker();
      final shown = <ReviewPrompt>[];
      final sub = broker.prompts.listen((p) {
        if (p is ReviewPrompt) shown.add(p);
      });

      final first = broker.review(request());
      final second = broker.review(request());
      await pumpEventQueue();
      expect(shown, hasLength(1)); // second waits

      shown.first.respond(const WcRequestDecision.approve());
      await first;
      await pumpEventQueue();
      expect(shown, hasLength(2));

      shown.last.respond(const WcRequestDecision.reject());
      expect((await second).approved, isFalse);
      await sub.cancel();
      broker.dispose();
    });

    test('disposing rejects everything still waiting', () async {
      final broker = DappPromptBroker();
      final sub = broker.prompts.listen((_) {}); // UI attached, never answers
      final pendingReview = broker.review(request());
      final pendingConnect = broker.confirmConnection(dapp, walletAccount);
      await pumpEventQueue();

      broker.dispose();

      expect((await pendingReview).approved, isFalse);
      expect(await pendingConnect, isFalse);
      await sub.cancel();
    });

    test('notices reach the UI when attached', () async {
      final broker = DappPromptBroker();
      final notices = <String>[];
      final sub = broker.prompts.listen((p) {
        if (p is NoticePrompt) notices.add(p.message);
      });
      broker.notice('hello');
      await pumpEventQueue();
      expect(notices, ['hello']);
      await sub.cancel();
      broker.dispose();
    });
  });

  group('UnavailableDappSigningGateway', () {
    test('always refuses — it never fabricates a signature', () async {
      final result = await const UnavailableDappSigningGateway().execute(
        WcPersonalSignRequest(
          id: 'r',
          dapp: const WcDapp(name: 'X', url: 'https://x.com'),
          chain: WcChains.ethereum,
          signer: account,
          receivedAt: _t0,
          message: 'hi',
        ),
      );
      expect(result.failureOrNull, isA<NotImplementedFailure>());
    });
  });

  group('DioEvmReadClient', () {
    late List<RequestOptions> seen;

    DioEvmReadClient client(
      Future<ResponseBody> Function(RequestOptions) handler, {
      Map<int, String>? endpoints,
    }) {
      seen = [];
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          seen.add(options);
          return handler(options);
        });
      return DioEvmReadClient(dio: dio, endpoints: endpoints);
    }

    ResponseBody json(Object body, {int status = 200}) => ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );

    test('returns the result and posts a well-formed JSON-RPC call', () async {
      final c = client((_) async => json({'jsonrpc': '2.0', 'id': 1, 'result': '0x10'}));
      final outcome = await c.call(WcChains.polygon, 'eth_blockNumber', const []);

      expect((outcome as RpcSuccess).value, '0x10');
      final request = seen.single;
      expect(request.uri.host, 'polygon-bor-rpc.publicnode.com');
      final body = jsonDecode(request.data as String) as Map;
      expect(body['method'], 'eth_blockNumber');
      expect(body['jsonrpc'], '2.0');
      expect(request.followRedirects, isFalse);
    });

    test('routes each chain to its own endpoint', () async {
      final c = client((_) async => json({'result': '0x1'}));
      for (final chain in WcChains.all) {
        await c.call(chain, 'eth_chainId', const []);
      }
      expect(seen.map((r) => r.uri.host).toSet(), hasLength(WcChains.all.length));
    });

    test('node errors keep their code, message and data', () async {
      final c = client((_) async => json({
            'error': {'code': 3, 'message': 'execution reverted', 'data': '0x08c379a0'},
          }));
      final outcome = await c.call(WcChains.ethereum, 'eth_call', const []);
      final failure = outcome as RpcFailure;
      expect(failure.code, 3);
      expect(failure.message, 'execution reverted');
      expect(failure.data, '0x08c379a0');
    });

    test('malformed or partial responses count as unreachable', () async {
      for (final body in [
        ResponseBody.fromString('not json', 200),
        ResponseBody.fromString('[]', 200),
        ResponseBody.fromString('{}', 200),
      ]) {
        final c = client((_) async => body);
        expect(
          await c.call(WcChains.ethereum, 'eth_call', const []),
          isA<RpcUnreachable>(),
        );
      }
    });

    test('transport errors and unknown chains count as unreachable', () async {
      final failing = client((_) async => throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          ));
      expect(
        await failing.call(WcChains.ethereum, 'eth_call', const []),
        isA<RpcUnreachable>(),
      );

      final noEndpoint = client((_) async => json({'result': '0x1'}), endpoints: const {});
      expect(
        await noEndpoint.call(WcChains.ethereum, 'eth_call', const []),
        isA<RpcUnreachable>(),
      );
      expect(seen, isEmpty);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);
  final Future<ResponseBody> Function(RequestOptions) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}
