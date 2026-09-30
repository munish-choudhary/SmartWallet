import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet/app/router.dart';
import 'package:smart_wallet/app/routes.dart';
import 'package:smart_wallet/app/theme/app_theme.dart';
import 'package:smart_wallet/features/walletconnect/data/in_memory_wallet_connect_repository.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_connect_repository.dart';

import 'wc_test_helpers.dart';

/// Pumps the real router (so the route tree and ShellRoute wiring are
/// covered) at [location].
Future<GoRouter> pumpRoute(
  WidgetTester tester,
  String location, {
  InMemoryWalletConnectRepository? repository,
}) async {
  tester.view
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repo = repository ?? buildRepository();
  final router = buildRouter()..go(location);
  await tester.pumpWidget(
    RepositoryProvider<WalletConnectRepository>.value(
      value: repo,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pump();
  await settleFor(tester, const Duration(milliseconds: 400));
  return router;
}

/// Pumps in small steps so route/sheet animations actually advance — one
/// big `pump(duration)` only produces a single frame.
Future<void> settleFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  for (var elapsed = Duration.zero; elapsed < total; elapsed += step) {
    await tester.pump(step);
  }
}

void main() {
  group('WalletConnect hub', () {
    testWidgets('lists connected apps', (tester) async {
      await pumpRoute(tester, Routes.walletConnect);

      expect(find.text('WalletConnect'), findsOneWidget);
      expect(find.text('Uniswap'), findsOneWidget);
      expect(find.text('OpenSea'), findsOneWidget);
      expect(find.text('app.uniswap.org'), findsOneWidget);
      expect(find.text('2 CONNECTED'), findsOneWidget);
    });

    testWidgets('shows an empty state with no sessions', (tester) async {
      await pumpRoute(
        tester,
        Routes.walletConnect,
        repository: buildRepository(seedSessions: false),
      );

      expect(find.text('No connected apps'), findsOneWidget);
      expect(find.text('Browse dApps'), findsOneWidget);
    });

    testWidgets('Connect stays disabled until the link is a valid one', (
      tester,
    ) async {
      await pumpRoute(tester, Routes.walletConnect);
      final field = find.byType(TextField);

      await tester.enterText(field, 'https://example.com');
      await tester.pump();
      expect(
        find.text("That doesn't look like a WalletConnect link"),
        findsOneWidget,
      );
      await tester.tap(find.text('Connect'));
      await settleFor(tester, const Duration(milliseconds: 300));
      expect(find.text('Connecting…'), findsNothing); // tap did nothing

      await tester.enterText(field, validPairingLink());
      await tester.pump();
      expect(
        find.text("That doesn't look like a WalletConnect link"),
        findsNothing,
      );
    });

    testWidgets('a valid link starts pairing and is cleared from the field', (
      tester,
    ) async {
      await pumpRoute(
        tester,
        Routes.walletConnect,
        repository: buildRepository(latency: const Duration(milliseconds: 200)),
      );
      final field = find.byType(TextField);

      await tester.enterText(field, validPairingLink());
      await tester.pump();
      await tester.tap(find.text('Connect'));
      await tester.pump();
      await settleFor(tester, const Duration(milliseconds: 50));

      expect(find.text('Connecting…'), findsOneWidget);
      // The pairing link carries a key: it must not linger in the field.
      final hub = tester.widget<TextField>(
        find.byType(TextField, skipOffstage: false),
      );
      expect(hub.controller!.text, isEmpty);

      await settleFor(tester, const Duration(milliseconds: 400));
      expect(find.text('Aave wants to connect'), findsOneWidget);
    });
  });

  group('pairing flow', () {
    testWidgets('proposal sheet → Connect → success screen', (tester) async {
      await pumpRoute(tester, Routes.walletConnect);

      await tester.enterText(find.byType(TextField), validPairingLink());
      await tester.pump();
      await tester.tap(find.text('Connect'));
      await tester.pump(); // connecting
      await settleFor(tester, const Duration(milliseconds: 1000));

      // The seeded first proposal is the verified "Aave".
      expect(find.text('Aave wants to connect'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);

      await tester.tap(find.text('Connect').last);
      await tester.pump();
      await settleFor(tester, const Duration(milliseconds: 600));

      expect(find.text('Connected to Aave'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await settleFor(tester, const Duration(milliseconds: 600));

      expect(find.text('Connected to Aave'), findsNothing);
      expect(find.text('Active sessions'.toUpperCase()), findsOneWidget);
      expect(find.text('Aave'), findsOneWidget);
      expect(find.text('3 CONNECTED'), findsOneWidget);
    });

    testWidgets('rejecting the proposal returns to the hub', (tester) async {
      await pumpRoute(tester, Routes.walletConnect);

      await tester.enterText(find.byType(TextField), validPairingLink());
      await tester.pump();
      await tester.tap(find.text('Connect'));
      await tester.pump();
      await settleFor(tester, const Duration(milliseconds: 1000));

      await tester.tap(find.text('Reject'));
      await settleFor(tester, const Duration(milliseconds: 600));

      expect(find.text('Connecting'), findsNothing);
      expect(find.text('2 CONNECTED'), findsOneWidget);
    });

    testWidgets('a link that is expired shows a clear failure', (tester) async {
      await pumpRoute(tester, Routes.walletConnect);
      final past = testNow.millisecondsSinceEpoch ~/ 1000 - 60;

      await tester.enterText(
        find.byType(TextField),
        validPairingLink(extra: '&expiryTimestamp=$past'),
      );
      await tester.pump();
      await tester.tap(find.text('Connect'));
      await tester.pump();
      await settleFor(tester, const Duration(milliseconds: 400));

      expect(find.text("Couldn't connect"), findsOneWidget);
      expect(find.textContaining('expired'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await settleFor(tester, const Duration(milliseconds: 600));
      expect(find.text("Couldn't connect"), findsNothing);
      expect(find.text('2 CONNECTED'), findsOneWidget);
    });
  });

  group('Connected App Detail', () {
    String sessionRoute(String topic) => Routes.walletConnectSessionPath(topic);

    testWidgets('renders the session from the design', (tester) async {
      await pumpRoute(tester, sessionRoute('a1f3c8d2e5b7'));

      expect(find.text('Connected App'), findsOneWidget);
      expect(find.text('ENCRYPTED SESSION ACTIVE'), findsOneWidget);
      expect(find.text('Uniswap'), findsOneWidget);
      expect(find.text('app.uniswap.org'), findsOneWidget);
      expect(find.text('VERIFIED DOMAIN'), findsOneWidget);
      expect(find.text('CONNECTED ACCOUNT'), findsOneWidget);
      expect(find.text('Main Account'), findsOneWidget);
      expect(find.text('0x71C7...976F'), findsOneWidget);
      expect(find.text('AUTHORIZED NETWORKS'), findsOneWidget);
      expect(find.text('Ethereum Mainnet'), findsOneWidget);
      expect(find.text('CHAIN ID: 1'), findsOneWidget);
      expect(find.text('Arbitrum One'), findsOneWidget);
      expect(find.text('CHAIN ID: 42161'), findsOneWidget);
      expect(find.text('GRANTED ACCESS'), findsOneWidget);
      expect(find.text('3 ACTIVE'), findsOneWidget);
      expect(find.text('SESSION TIMELINE'), findsOneWidget);
      expect(find.text('Expires in'), findsOneWidget);
      expect(find.text('Disconnect Session'), findsOneWidget);
    });

    testWidgets('an unknown topic says so instead of spinning', (tester) async {
      await pumpRoute(tester, sessionRoute('missing'));
      expect(find.text('Session not found'), findsOneWidget);
    });

    testWidgets('disconnect asks first, and Cancel keeps the session', (
      tester,
    ) async {
      final router = await pumpRoute(tester, sessionRoute('a1f3c8d2e5b7'));

      await tester.ensureVisible(find.text('Disconnect Session'));
      await tester.tap(find.text('Disconnect Session'));
      await settleFor(tester, const Duration(milliseconds: 300));
      expect(find.text('Disconnect Uniswap?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await settleFor(tester, const Duration(milliseconds: 300));

      expect(find.text('Disconnect Uniswap?'), findsNothing);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        sessionRoute('a1f3c8d2e5b7'),
      );
    });

    testWidgets('confirming disconnect removes it and returns to the hub', (
      tester,
    ) async {
      final repository = buildRepository();
      final router = await pumpRoute(
        tester,
        sessionRoute('a1f3c8d2e5b7'),
        repository: repository,
      );

      await tester.ensureVisible(find.text('Disconnect Session'));
      await tester.tap(find.text('Disconnect Session'));
      await settleFor(tester, const Duration(milliseconds: 300));
      await tester.tap(find.text('Disconnect').last);
      await tester.pump();
      await settleFor(tester, const Duration(milliseconds: 500));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.walletConnect,
      );
      expect(find.text('Uniswap'), findsNothing);
      expect(find.text('OpenSea'), findsOneWidget);
      expect((await repository.watchSessions().first).length, 1);
    });
  });
}
