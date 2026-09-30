import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet/app/routes.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/app/theme/app_theme.dart';
import 'package:smart_wallet/features/dapp_browser/data/dapp_browser_repository.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/dapp_interaction.dart';
import 'package:smart_wallet/features/dapp_browser/data/models/browser_visit.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/dapp_provider_script.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/bridge_models.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/eip1193_bridge.dart';
import 'package:smart_wallet/features/dapp_browser/view/dapp_browser_screen.dart';
import 'package:smart_wallet/features/dapp_browser/view/dapp_web_view_screen.dart';
import 'package:smart_wallet/features/dapp_browser/view_model/dapp_browser_cubit.dart';
import 'package:smart_wallet/features/dapp_browser/view_model/dapp_web_view_cubit.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_account_source.dart';

import 'bridge_test_helpers.dart';

Future<void> settle(WidgetTester tester, [int ms = 400]) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _bigScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('DappBrowserScreen (discover)', () {
    late InMemoryDappBrowserRepository repo;
    late GoRouter router;

    Future<void> pumpDiscover(WidgetTester tester) async {
      _bigScreen(tester);
      repo = InMemoryDappBrowserRepository();
      router = GoRouter(
        initialLocation: Routes.dapps,
        routes: [
          GoRoute(
            path: Routes.dapps,
            builder: (context, state) => BlocProvider(
              create: (_) => DappBrowserCubit(repository: repo),
              child: const DappBrowserScreen(),
            ),
            routes: [
              GoRoute(
                path: 'browse',
                builder: (context, state) =>
                    Scaffold(body: Text('BROWSING ${state.uri.queryParameters['url']}')),
              ),
            ],
          ),
          GoRoute(
            path: Routes.walletConnect,
            builder: (context, state) => const Scaffold(body: Text('WC HUB')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      );
      await settle(tester);
    }

    testWidgets('shows featured dApps and the security note', (tester) async {
      await pumpDiscover(tester);

      expect(find.text('dApps'), findsOneWidget);
      expect(find.text('Uniswap'), findsOneWidget);
      expect(find.text('OpenSea'), findsOneWidget);
      expect(find.text('FEATURED'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('third-party websites'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('third-party websites'), findsOneWidget);
    });

    testWidgets('category chips filter the list and All restores it', (
      tester,
    ) async {
      await pumpDiscover(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'NFT'));
      await settle(tester);
      expect(find.text('OpenSea'), findsOneWidget);
      expect(find.text('Uniswap'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await settle(tester);
      expect(find.text('Uniswap'), findsOneWidget);
    });

    testWidgets('starring a dApp adds it to Favorites', (tester) async {
      await pumpDiscover(tester);
      expect(find.text('FAVORITES'), findsNothing);

      await tester.tap(find.byTooltip('Add to favorites').first);
      await settle(tester);

      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });

    testWidgets('tapping a dApp opens it in the browser', (tester) async {
      await pumpDiscover(tester);
      await tester.tap(find.text('Uniswap'));
      await settle(tester);
      expect(find.text('BROWSING https://app.uniswap.org'), findsOneWidget);
    });

    testWidgets('the search bar opens a typed address or searches', (
      tester,
    ) async {
      await pumpDiscover(tester);

      await tester.enterText(find.byType(TextField), 'aave.com');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await settle(tester);
      expect(find.text('BROWSING https://aave.com'), findsOneWidget);
    });

    testWidgets('an unsafe address is refused with a message', (tester) async {
      await pumpDiscover(tester);

      await tester.enterText(find.byType(TextField), 'javascript:alert(1)');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await settle(tester);

      expect(find.textContaining('not supported'), findsOneWidget);
      expect(find.textContaining('BROWSING'), findsNothing);
    });

    testWidgets('recent pages appear and can be cleared', (tester) async {
      await pumpDiscover(tester);
      await repo.recordVisit(
        BrowserVisit(
          url: 'https://a.com/swap',
          title: 'Swap tokens',
          visitedAt: DateTime.utc(2026),
        ),
      );
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Swap tokens'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('RECENT'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await settle(tester);
      expect(find.text('Swap tokens'), findsNothing);
    });

    testWidgets('the header link opens WalletConnect', (tester) async {
      await pumpDiscover(tester);
      await tester.tap(find.byIcon(Icons.link_rounded));
      await settle(tester);
      expect(find.text('WC HUB'), findsOneWidget);
    });
  });

  group('DappWebViewScreen chrome', () {
    late BridgeHarness h;
    late DappPromptBroker broker;
    late DappWebViewCubit cubit;

    Future<void> pumpBrowser(
      WidgetTester tester, {
      String url = 'https://app.uniswap.org/swap',
    }) async {
      _bigScreen(tester);
      h = BridgeHarness();
      broker = DappPromptBroker();
      // The harness bridge talks to a fake prompter; build the real one
      // against the broker so the UI is what answers prompts.
      final bridge = Eip1193Bridge(
        connections: h.connections,
        accounts: const InMemoryWalletAccountSource(),
        prompter: broker,
        signer: h.signer,
        reader: h.reader,
      );
      cubit = DappWebViewCubit(
        rawUrl: url,
        browserRepository: InMemoryDappBrowserRepository(),
        connections: h.connections,
        bridge: bridge,
        broker: broker,
      );
      // Unmount first: a cubit's close() waits for its BlocBuilders'
      // subscriptions to end, which only happens once the tree is gone.
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await cubit.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: BlocProvider.value(
            value: cubit,
            child: const DappWebViewScreen(
              webViewOverride: ColoredBox(
                color: Colors.black,
                child: Center(child: Text('web content')),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
    }

    Future<String?> pageCalls(String method, {List<Object?> params = const []}) =>
        cubit.handleBridgeMessage(
          message: jsonEncode({'id': 1, 'method': method, 'params': params}),
          sourceOrigin: Uri.parse('https://app.uniswap.org'),
          isMainFrame: true,
        );

    testWidgets('shows the host, a lock, and the not-connected pill', (
      tester,
    ) async {
      await pumpBrowser(tester);
      expect(find.text('app.uniswap.org'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.text('web content'), findsOneWidget);
      expect(find.text('NOT SECURE'), findsNothing);
    });

    testWidgets('plain http is labelled not secure', (tester) async {
      await pumpBrowser(tester, url: 'http://example.com');
      expect(find.text('NOT SECURE'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
    });

    testWidgets('a blocked address shows why instead of a page', (tester) async {
      await pumpBrowser(tester, url: 'javascript:alert(1)');
      expect(find.text("Can't open page"), findsOneWidget);
      expect(find.textContaining('not supported'), findsOneWidget);
      expect(find.text('web content'), findsNothing);
    });

    testWidgets('tapping the address edits it; Go sends a navigation command', (
      tester,
    ) async {
      await pumpBrowser(tester);
      final commands = <Uri>[];
      final sub = cubit.navigationCommands.listen(commands.add);

      await tester.tap(find.text('app.uniswap.org'));
      await settle(tester, 100);
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      expect(
        tester.widget<TextField>(field).controller!.text,
        'https://app.uniswap.org/swap',
      );

      await tester.enterText(field, 'aave.com');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await settle(tester, 100);

      expect(commands.single.host, 'aave.com');
      expect(find.byType(TextField), findsNothing); // back to the pill
      unawaited(sub.cancel()); // awaiting cancel() hangs inside FakeAsync
    });

    testWidgets('an unsafe address typed in the bar is refused', (tester) async {
      await pumpBrowser(tester);
      final commands = <Uri>[];
      final sub = cubit.navigationCommands.listen(commands.add);

      await tester.tap(find.text('app.uniswap.org'));
      await settle(tester, 100);
      await tester.enterText(find.byType(TextField), 'javascript:alert(1)');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await settle(tester, 100);

      expect(commands, isEmpty);
      expect(find.textContaining('not supported'), findsOneWidget);
      unawaited(sub.cancel()); // awaiting cancel() hangs inside FakeAsync
    });

    testWidgets('the progress bar shows only while loading', (tester) async {
      await pumpBrowser(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      cubit.onLoadStop(Uri.parse('https://app.uniswap.org/swap'), title: 'Swap');
      await settle(tester, 100);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('back/forward enable from the page state', (tester) async {
      await pumpBrowser(tester);
      IconButton button(String tooltip) =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, tooltip == 'Back' ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded));

      expect(button('Back').onPressed, isNull);
      expect(button('Forward').onPressed, isNull);

      cubit.onNavState(canGoBack: true, canGoForward: true);
      await settle(tester, 100);
      expect(button('Back').onPressed, isNotNull);
      expect(button('Forward').onPressed, isNotNull);
    });

    testWidgets('a page asking to connect shows the connect sheet', (tester) async {
      await pumpBrowser(tester);

      final reply = pageCalls('eth_requestAccounts');
      await settle(tester, 600);

      expect(find.text('Connect to Uniswap?'), findsOneWidget);
      expect(find.text('VERIFIED DOMAIN'), findsOneWidget);
      expect(find.text('0x71C7...976F'), findsOneWidget);

      await tester.tap(find.text('Connect'));
      await settle(tester, 600);

      expect(jsonDecode((await reply)!)['result'], [account]);
      expect(find.text('0x71C7...976F · Ethereum Mainnet'), findsOneWidget);
    });

    testWidgets('rejecting the connect sheet tells the page no', (tester) async {
      await pumpBrowser(tester);
      final reply = pageCalls('eth_requestAccounts');
      await settle(tester, 600);

      await tester.tap(find.text('Reject'));
      await settle(tester, 600);

      expect(jsonDecode((await reply)!)['error']['code'], 4001);
      expect(find.text('Not connected'), findsOneWidget);
    });

    testWidgets('an unknown site is shown by its host with a caution', (
      tester,
    ) async {
      await pumpBrowser(tester, url: 'https://some-random-site.xyz');
      final reply = cubit.handleBridgeMessage(
        message: jsonEncode({'id': 1, 'method': 'eth_requestAccounts', 'params': []}),
        sourceOrigin: Uri.parse('https://some-random-site.xyz'),
        isMainFrame: true,
      );
      await settle(tester, 600);

      expect(find.text('Connect to some-random-site.xyz?'), findsOneWidget);
      expect(find.text("We couldn't verify this site"), findsOneWidget);
      await tester.tap(find.text('Reject'));
      await settle(tester, 400);
      await reply;
    });

    testWidgets('a transaction request shows the review sheet with the browser badge', (
      tester,
    ) async {
      await pumpBrowser(tester);
      final connect = pageCalls('eth_requestAccounts');
      await settle(tester, 600);
      await tester.tap(find.text('Connect'));
      await settle(tester, 600);
      await connect;

      final reply = pageCalls('eth_sendTransaction', params: [
        {
          'from': account,
          'to': '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD',
          'value': '0xde0b6b3a7640000',
        },
      ]);
      await settle(tester, 600);

      expect(find.text('Confirm transaction'), findsOneWidget);
      expect(find.text('UNISWAP · IN-APP BROWSER'), findsOneWidget);
      expect(find.text('1 ETH'), findsWidgets);

      await tester.tap(find.text('Reject'));
      await settle(tester, 600);
      expect(jsonDecode((await reply)!)['error']['code'], 4001);
    });

    testWidgets('approving while signing is unavailable says nothing was signed', (
      tester,
    ) async {
      await pumpBrowser(tester);
      final connect = pageCalls('eth_requestAccounts');
      await settle(tester, 600);
      await tester.tap(find.text('Connect'));
      await settle(tester, 600);
      await connect;

      h.signer.answer = const Result.err(AppFailure.notImplemented());
      final reply = pageCalls('personal_sign', params: ['0x48656c6c6f', account]);
      await settle(tester, 600);
      expect(find.text('Hello'), findsOneWidget);

      await tester.tap(find.text('Sign'));
      await settle(tester, 600);

      final error = jsonDecode((await reply)!)['error'] as Map;
      expect(error['code'], RpcCode.unsupportedMethod);
      expect(find.textContaining('Nothing was signed'), findsOneWidget);
    });

    testWidgets('the connection sheet lists the account, switches network, disconnects', (
      tester,
    ) async {
      await pumpBrowser(tester);
      final connect = pageCalls('eth_requestAccounts');
      await settle(tester, 600);
      await tester.tap(find.text('Connect'));
      await settle(tester, 600);
      await connect;

      await tester.tap(find.text('0x71C7...976F · Ethereum Mainnet'));
      await settle(tester, 600);
      expect(find.text('CONNECTED ACCOUNT'.toUpperCase()), findsNothing);
      expect(find.text('Connected account'), findsOneWidget);
      expect(find.text('Polygon'), findsOneWidget);

      await tester.tap(find.text('Polygon'));
      await settle(tester, 600);
      expect(find.text('0x71C7...976F · Polygon'), findsOneWidget);

      await tester.tap(find.text('0x71C7...976F · Polygon'));
      await settle(tester, 600);
      await tester.tap(find.text('Disconnect'));
      await settle(tester, 600);
      expect(find.text('Not connected'), findsOneWidget);
    });

    testWidgets('the sheet for an unconnected site explains how to connect', (
      tester,
    ) async {
      await pumpBrowser(tester);
      await tester.tap(find.text('Not connected'));
      await settle(tester, 600);
      expect(find.text('Not connected'), findsWidgets);
      expect(find.textContaining('Connect Wallet'), findsOneWidget);
      expect(find.text('Disconnect'), findsNothing);
    });
  });

  group('DappProviderScript', () {
    test('has no unreplaced placeholders and points at the bridge object', () {
      final source = DappProviderScript.source;
      expect(source, isNot(contains('__BRIDGE__')));
      expect(source, isNot(contains('__ICON__')));
      expect(source, contains("'${DappProviderScript.bridgeObject}'"));
      expect(source, contains('data:image/svg+xml;base64,'));
    });

    test('never claims to be MetaMask', () {
      expect(DappProviderScript.source, isNot(contains('isMetaMask: true')));
    });

    test('emitScript JSON-encodes event data (no script injection)', () {
      const hostile = AccountsChangedEvent('https://a.com', [
        '"); alert(1); ("',
        '</script><script>alert(2)</script>',
      ]);
      final js = DappProviderScript.emitScript(hostile);
      // Everything hostile sits inside a JSON string literal.
      expect(js, startsWith('window.__lexorEmit && window.__lexorEmit("accountsChanged", '));
      final args = js.substring(js.indexOf('(', js.indexOf('&&')) + 1, js.lastIndexOf(');'));
      final decoded = jsonDecode('[$args]') as List;
      expect(decoded[0], 'accountsChanged');
      expect(decoded[1], hostile.accounts);
    });
  });
}

