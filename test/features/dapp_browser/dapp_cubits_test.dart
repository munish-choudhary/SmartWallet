import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/dapp_browser/data/browser_url_resolver.dart';
import 'package:smart_wallet/features/dapp_browser/data/dapp_browser_repository.dart';
import 'package:smart_wallet/features/dapp_browser/data/dapp_connection_repository.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/bridge_models.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/dapp_interaction.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/eip1193_bridge.dart';
import 'package:smart_wallet/features/dapp_browser/data/models/browser_visit.dart';
import 'package:smart_wallet/features/dapp_browser/data/models/dapp.dart';
import 'package:smart_wallet/features/dapp_browser/view_model/dapp_browser_cubit.dart';
import 'package:smart_wallet/features/dapp_browser/view_model/dapp_browser_state.dart';
import 'package:smart_wallet/features/dapp_browser/view_model/dapp_web_view_cubit.dart';
import 'package:smart_wallet/features/dapp_browser/view_model/dapp_web_view_state.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_chain.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_account_source.dart';

import 'bridge_test_helpers.dart';

void main() {
  group('DappBrowserCubit', () {
    blocTest<DappBrowserCubit, DappBrowserState>(
      'loads the catalog',
      build: () => DappBrowserCubit(repository: InMemoryDappBrowserRepository()),
      expect: () => [
        isA<DappBrowserLoaded>().having((s) => s.visible, 'visible', isNotEmpty),
      ],
    );

    blocTest<DappBrowserCubit, DappBrowserState>(
      'filters by category and clears the filter',
      build: () => DappBrowserCubit(repository: InMemoryDappBrowserRepository()),
      act: (cubit) async {
        await pumpEventQueue();
        cubit.selectCategory(DappCategory.nft);
        cubit.selectCategory(null);
      },
      skip: 1,
      expect: () => [
        isA<DappBrowserLoaded>().having(
          (s) => s.visible.map((d) => d.category).toSet(),
          'categories',
          {DappCategory.nft},
        ),
        isA<DappBrowserLoaded>().having(
          (s) => s.visible.map((d) => d.category).toSet().length,
          'all categories',
          greaterThan(1),
        ),
      ],
    );

    blocTest<DappBrowserCubit, DappBrowserState>(
      'a favorite shows up, and the chosen category survives repo updates',
      build: () => DappBrowserCubit(repository: InMemoryDappBrowserRepository()),
      act: (cubit) async {
        await pumpEventQueue();
        cubit.selectCategory(DappCategory.defi);
        await cubit.toggleFavorite('uniswap');
      },
      skip: 2,
      expect: () => [
        isA<DappBrowserLoaded>()
            .having((s) => s.favorites.map((d) => d.id), 'favorites', ['uniswap'])
            .having((s) => s.category, 'category', DappCategory.defi),
      ],
    );

    blocTest<DappBrowserCubit, DappBrowserState>(
      'selectCategory is ignored before the data has loaded',
      build: () => DappBrowserCubit(repository: _NeverLoads()),
      act: (cubit) => cubit.selectCategory(DappCategory.nft),
      expect: () => <DappBrowserState>[],
    );

    test('resolve delegates to the URL resolver', () async {
      final cubit = DappBrowserCubit(repository: InMemoryDappBrowserRepository());
      expect(cubit.resolve('example.com'), isA<ResolvedUrl>());
      expect(cubit.resolve('javascript:1'), isA<RejectedInput>());
      await cubit.close();
    });
  });

  group('DappWebViewCubit', () {
    late InMemoryDappBrowserRepository browserRepo;
    late InMemoryDappConnectionRepository connections;
    late FakeSigner signer;
    late FakeReader reader;
    late DappPromptBroker broker;
    late Eip1193Bridge bridge;
    late StreamSubscription<DappPrompt> promptSub;
    bool approveConnections = true;
    final clock = DateTime.utc(2026, 9, 30, 12);

    DappWebViewCubit build(String rawUrl) {
      browserRepo = InMemoryDappBrowserRepository();
      connections = InMemoryDappConnectionRepository();
      signer = FakeSigner();
      reader = FakeReader();
      broker = DappPromptBroker();
      bridge = Eip1193Bridge(
        connections: connections,
        accounts: const InMemoryWalletAccountSource(),
        prompter: broker,
        signer: signer,
        reader: reader,
      );
      final cubit = DappWebViewCubit(
        rawUrl: rawUrl,
        browserRepository: browserRepo,
        connections: connections,
        bridge: bridge,
        broker: broker,
        now: () => clock,
      );
      promptSub = cubit.prompts.listen((p) {
        if (p is ConnectPrompt) p.respond(approveConnections);
      });
      addTearDown(() async {
        await promptSub.cancel();
        await cubit.close();
      });
      return cubit;
    }

    setUp(() => approveConnections = true);

    String request(String method, {List<Object?> params = const []}) =>
        jsonEncode({'id': 1, 'method': method, 'params': params});

    DappWebViewBrowsing browsing(DappWebViewCubit c) =>
        c.state as DappWebViewBrowsing;

    group('initial state', () {
      test('a URL starts browsing that page', () {
        final cubit = build('https://app.uniswap.org');
        expect(browsing(cubit).page.url.host, 'app.uniswap.org');
        expect(browsing(cubit).page.loading, isTrue);
        expect(browsing(cubit).chain, WcChains.ethereum);
        expect(cubit.initialUri, Uri.parse('https://app.uniswap.org'));
      });

      test('plain text becomes a web search', () {
        final cubit = build('how to swap');
        expect(browsing(cubit).page.url.host, 'duckduckgo.com');
      });

      test('an unsafe address is blocked, with a reason', () {
        for (final raw in ['javascript:alert(1)', 'file:///etc/passwd', '']) {
          final cubit = build(raw);
          expect(cubit.state, isA<DappWebViewBlocked>(), reason: raw);
          expect(cubit.initialUri, isNull);
        }
      });
    });

    group('address bar', () {
      test('a good address becomes a navigation command', () async {
        final cubit = build('https://a.com');
        final commands = <Uri>[];
        final sub = cubit.navigationCommands.listen(commands.add);

        expect(cubit.submitAddress('uniswap.org'), isNull);
        expect(cubit.submitAddress('some words'), isNull);
        await pumpEventQueue();

        expect(commands.map((u) => u.host), ['uniswap.org', 'duckduckgo.com']);
        await sub.cancel();
      });

      test('a bad address returns a message and navigates nowhere', () async {
        final cubit = build('https://a.com');
        final commands = <Uri>[];
        final sub = cubit.navigationCommands.listen(commands.add);

        expect(cubit.submitAddress('javascript:alert(1)'), contains('not supported'));
        expect(cubit.submitAddress(''), isNotNull);
        await pumpEventQueue();

        expect(commands, isEmpty);
        await sub.cancel();
      });

      test('allowNavigation only permits web pages', () {
        final cubit = build('https://a.com');
        expect(cubit.allowNavigation(Uri.parse('https://b.com')), isTrue);
        expect(cubit.allowNavigation(Uri.parse('intent://x')), isFalse);
        expect(cubit.allowNavigation(Uri.parse('javascript:1')), isFalse);
      });
    });

    group('page events', () {
      test('track progress, title, url and back/forward state', () {
        final cubit = build('https://a.com');

        cubit.onLoadStart(Uri.parse('https://a.com/next'));
        expect(browsing(cubit).page.url.path, '/next');
        expect(browsing(cubit).page.progress, closeTo(0.05, 1e-9));

        cubit.onProgress(60);
        expect(browsing(cubit).page.progress, closeTo(0.6, 1e-9));
        cubit.onProgress(500);
        expect(browsing(cubit).page.progress, 1.0);

        cubit.onTitle('Hello');
        cubit.onTitle(null);
        expect(browsing(cubit).page.title, 'Hello');

        cubit.onNavState(canGoBack: true, canGoForward: false);
        expect(browsing(cubit).page.canGoBack, isTrue);
        expect(browsing(cubit).page.canGoForward, isFalse);

        cubit.onLoadStop(Uri.parse('https://a.com/next'), title: 'Done');
        expect(browsing(cubit).page.loading, isFalse);
        expect(browsing(cubit).page.title, 'Done');
        expect(browsing(cubit).page.isSecure, isTrue);
      });

      test('a finished page is recorded in history without its query', () async {
        final cubit = build('https://a.com');
        cubit.onLoadStop(
          Uri.parse('https://a.com/swap?token=SECRET#x'),
          title: 'Swap',
        );
        await pumpEventQueue();
        final recents = (await browserRepo.watch().first).recents;
        expect(recents.single.url, 'https://a.com/swap');
        expect(recents.single.title, 'Swap');
      });

      test('non-web pages are not recorded', () async {
        final cubit = build('https://a.com');
        cubit.onLoadStop(Uri.parse('about:blank'));
        await pumpEventQueue();
        expect((await browserRepo.watch().first).recents, isEmpty);
      });

      test('events are ignored while blocked', () {
        final cubit = build('javascript:1');
        cubit.onProgress(50);
        cubit.onTitle('x');
        expect(cubit.state, isA<DappWebViewBlocked>());
      });
    });

    group('wallet bridge', () {
      Future<String?> message(
        DappWebViewCubit cubit,
        String method, {
        List<Object?> params = const [],
        Uri? origin,
        bool isMainFrame = true,
        Object? raw,
      }) =>
          cubit.handleBridgeMessage(
            message: raw ?? request(method, params: params),
            sourceOrigin: origin ?? Uri.parse('https://app.uniswap.org'),
            isMainFrame: isMainFrame,
          );

      test('answers a request from the page on screen', () async {
        final cubit = build('https://app.uniswap.org/swap');
        final reply = jsonDecode((await message(cubit, 'eth_chainId'))!) as Map;
        expect(reply['type'], 'response');
        expect(reply['id'], 1);
        expect(reply['result'], '0x1');
      });

      test('drops messages from iframes', () async {
        final cubit = build('https://app.uniswap.org');
        expect(await message(cubit, 'eth_chainId', isMainFrame: false), isNull);
      });

      test('drops messages with no origin or from another origin', () async {
        final cubit = build('https://app.uniswap.org');
        expect(
          await cubit.handleBridgeMessage(
            message: request('eth_chainId'),
            sourceOrigin: null,
            isMainFrame: true,
          ),
          isNull,
        );
        expect(
          await message(cubit, 'eth_chainId', origin: Uri.parse('https://evil.com')),
          isNull,
        );
        expect(
          await message(cubit, 'eth_chainId', origin: Uri.parse('about:blank')),
          isNull,
        );
      });

      test('drops malformed messages', () async {
        final cubit = build('https://app.uniswap.org');
        for (final raw in <Object?>[null, 5, 'nope', '{}']) {
          final reply = await cubit.handleBridgeMessage(
            message: raw,
            sourceOrigin: Uri.parse('https://app.uniswap.org'),
            isMainFrame: true,
          );
          expect(reply, isNull, reason: '$raw');
        }
      });

      test('drops everything while blocked', () async {
        final cubit = build('javascript:1');
        expect(await message(cubit, 'eth_chainId'), isNull);
      });

      test('connecting updates the toolbar state', () async {
        final cubit = build('https://app.uniswap.org');
        expect(browsing(cubit).connection, isNull);

        final reply = jsonDecode((await message(cubit, 'eth_requestAccounts'))!) as Map;
        expect(reply['result'], [account]);

        expect(browsing(cubit).connection!.address, account);
        expect(browsing(cubit).connection!.origin, uniswap);
      });

      test('a rejected connection leaves the toolbar untouched', () async {
        approveConnections = false;
        final cubit = build('https://app.uniswap.org');
        final reply = jsonDecode((await message(cubit, 'eth_requestAccounts'))!) as Map;
        expect(reply['error']['code'], 4001);
        expect(browsing(cubit).connection, isNull);
      });

      test('switching chain from the page updates the state', () async {
        final cubit = build('https://app.uniswap.org');
        await message(cubit, 'eth_requestAccounts');
        await message(cubit, 'wallet_switchEthereumChain', params: [
          {'chainId': '0x89'},
        ]);
        expect(browsing(cubit).chain, WcChains.polygon);
        expect(browsing(cubit).connection!.chain, WcChains.polygon);
      });

      test('navigating to another origin drops the old connection state', () async {
        final cubit = build('https://app.uniswap.org');
        await message(cubit, 'eth_requestAccounts');
        expect(browsing(cubit).connection, isNotNull);

        cubit.onLoadStart(Uri.parse('https://other.com'));
        await pumpEventQueue();
        expect(browsing(cubit).connection, isNull);

        cubit.onLoadStart(Uri.parse('https://app.uniswap.org/pool'));
        await pumpEventQueue();
        expect(browsing(cubit).connection, isNotNull);
      });

      test('a message posted after the page navigated away is dropped', () async {
        final cubit = build('https://app.uniswap.org');
        cubit.onLoadStart(Uri.parse('https://other.com'));
        expect(await message(cubit, 'eth_chainId'), isNull); // stale sender
      });

      test('disconnect revokes access', () async {
        final cubit = build('https://app.uniswap.org');
        await message(cubit, 'eth_requestAccounts');
        await cubit.disconnect();
        expect(browsing(cubit).connection, isNull);
        final reply = jsonDecode((await message(cubit, 'eth_accounts'))!) as Map;
        expect(reply['result'], isEmpty);
      });

      test('switchChain from the toolbar is reflected and reaches the page', () async {
        final cubit = build('https://app.uniswap.org');
        await message(cubit, 'eth_requestAccounts');
        final events = <BridgeEvent>[];
        final sub = cubit.pageEvents.listen(events.add);

        await cubit.switchChain(WcChains.base);
        await pumpEventQueue();

        expect(browsing(cubit).chain, WcChains.base);
        expect((events.single as ChainChangedEvent).chainIdHex, '0x2105');
        await sub.cancel();
      });

      test('provider events only go to the page that is open', () async {
        final cubit = build('https://other.com/page');
        final events = <BridgeEvent>[];
        final sub = cubit.pageEvents.listen(events.add);

        // An event for a site that is not on screen must not reach this page.
        await bridge.switchChain(uniswap, WcChains.base);
        await pumpEventQueue();
        expect(events, isEmpty);

        // An event for the page on screen is delivered.
        await bridge.switchChain('https://other.com', WcChains.polygon);
        await pumpEventQueue();
        expect(events.single.origin, 'https://other.com');
        expect((events.single as ChainChangedEvent).chainIdHex, '0x89');
        await sub.cancel();
      });
    });

    test('closing rejects prompts that are still open', () async {
      final cubit = build('https://app.uniswap.org');
      await promptSub.cancel();
      late ConnectPrompt open;
      promptSub = cubit.prompts.listen((p) => open = p as ConnectPrompt);

      final pending = message2(cubit);
      await pumpEventQueue();
      await cubit.close();

      expect(await open.answer, isFalse);
      await pending;
    });
  });
}

Future<String?> message2(DappWebViewCubit cubit) => cubit.handleBridgeMessage(
      message: jsonEncode({'id': 1, 'method': 'eth_requestAccounts', 'params': []}),
      sourceOrigin: Uri.parse('https://app.uniswap.org'),
      isMainFrame: true,
    );

class _NeverLoads implements DappBrowserRepository {
  @override
  Stream<DappBrowserSnapshot> watch() => const Stream.empty();
  @override
  Future<Result<void>> toggleFavorite(String dappId) => throw UnimplementedError();
  @override
  Future<Result<void>> recordVisit(BrowserVisit visit) => throw UnimplementedError();
  @override
  Future<Result<void>> clearRecents() => throw UnimplementedError();
}
