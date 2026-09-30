import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/notifications/data/notifications_repository.dart';
import 'package:smart_wallet/features/notifications/view_model/notifications_cubit.dart';
import 'package:smart_wallet/features/portfolio/data/portfolio_repository.dart';
import 'package:smart_wallet/features/portfolio/view/activity_history_screen.dart';
import 'package:smart_wallet/features/portfolio/view/portfolio_screen.dart';
import 'package:smart_wallet/features/portfolio/view/receive_token_screen.dart';
import 'package:smart_wallet/features/portfolio/view/swap_screen.dart';
import 'package:smart_wallet/features/portfolio/view/transaction_failed_screen.dart';
import 'package:smart_wallet/features/portfolio/view/transaction_pending_screen.dart';
import 'package:smart_wallet/features/portfolio/view/transaction_success_screen.dart';
import 'package:smart_wallet/features/portfolio/view_model/portfolio_cubit.dart';

void main() {
  void setMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Portfolio Navigation Flow Tests', () {
    late InMemoryPortfolioRepository repository;

    setUp(() {
      repository = InMemoryPortfolioRepository();
    });

    Widget createPortfolioSubject() {
      return MaterialApp(
        home: RepositoryProvider<PortfolioRepository>.value(
          value: repository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => PortfolioCubit(repository: repository)),
              BlocProvider(
                create: (_) => NotificationsCubit(
                  repository: InMemoryNotificationsRepository(),
                ),
              ),
            ],
            child: const PortfolioScreen(),
          ),
        ),
      );
    }

    testWidgets('tapping Receive in PortfolioBalanceCard opens ReceiveTokenScreen',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(createPortfolioSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Receive quick action
      await tester.tap(find.text('Receive'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify ReceiveTokenScreen elements
      expect(find.text('RECEIVE'), findsOneWidget);
      expect(find.text('Select Asset to Deposit'), findsOneWidget);
      expect(find.text('INSTANT DEPOSIT'), findsOneWidget);
      expect(find.text('SUPPORTED ASSETS (4)'), findsOneWidget);
    });

    testWidgets('tapping Send in PortfolioBalanceCard opens TransactionPendingScreen',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(createPortfolioSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Send quick action
      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify TransactionPendingScreen
      expect(find.text('TRANSACTION IN FLIGHT'), findsOneWidget);
      expect(find.text('Transaction Submitted'), findsOneWidget);
      expect(find.text('Speed Up'), findsOneWidget);

      // Advance past auto transition timer
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('tapping Activity in bottom nav bar opens ActivityHistoryScreen',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(createPortfolioSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Activity tab icon (Icons.receipt_long_rounded) in bottom nav bar
      await tester.tap(find.byIcon(Icons.receipt_long_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify ActivityHistoryScreen
      expect(find.text('ACTIVITY'), findsOneWidget);
      expect(find.text('Transaction Ledger'), findsOneWidget);
      expect(find.text('TOTAL VOLUME'), findsOneWidget);
      expect(find.text('\$148,920.40'), findsOneWidget);
    });
  });

  group('ReceiveTokenScreen Tests', () {
    testWidgets('renders search, network filters, and opens QR modal on tap',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiveTokenScreen(),
        ),
      );
      await tester.pump();

      // Verify header and search
      expect(find.text('RECEIVE'), findsOneWidget);
      expect(find.text('Select Asset to Deposit'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Ethereum'), findsAtLeastNWidgets(1));

      // Tap Ethereum token item to open QR modal sheet
      await tester.tap(find.text('ETH'));
      await tester.pumpAndSettle();

      // Verify QR sheet modal content
      expect(find.text('Receive Ethereum'), findsOneWidget);
      expect(find.text('YOUR DEPOSIT ADDRESS'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Share Address'), findsOneWidget);
    });
  });

  group('ActivityHistoryScreen Tests', () {
    testWidgets('renders volume metric and filters ledger items',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityHistoryScreen(),
        ),
      );
      await tester.pump();

      // Verify volume metric and group headers
      expect(find.text('TOTAL VOLUME'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Sent ETH'), findsOneWidget);
      expect(find.text('Swap ETH → USDC'), findsOneWidget);
      expect(find.text('Aave Deposit'), findsOneWidget);

      // Tap Sends filter
      await tester.tap(find.text('Sends'));
      await tester.pump();

      expect(find.text('Sent ETH'), findsOneWidget);
      expect(find.text('Swap ETH → USDC'), findsNothing);
    });

    testWidgets('tapping pending transaction navigates to TransactionPendingScreen',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityHistoryScreen(),
        ),
      );
      await tester.pump();

      // Tap Pending tx -> opens TransactionPendingScreen
      await tester.tap(find.text('Sent ETH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TRANSACTION IN FLIGHT'), findsOneWidget);

      // Advance past auto-transition timer
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('tapping completed swap navigates to TransactionSuccessScreen',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityHistoryScreen(),
        ),
      );
      await tester.pump();

      // Tap Completed tx -> opens TransactionSuccessScreen
      await tester.tap(find.text('Swap ETH → USDC'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('VERIFIED SETTLEMENT'), findsOneWidget);
      expect(find.text('Transfer Complete'), findsOneWidget);
    });

    testWidgets('tapping failed transaction navigates to TransactionFailedScreen',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityHistoryScreen(),
        ),
      );
      await tester.pump();

      // Tap Failed tx -> opens TransactionFailedScreen
      await tester.tap(find.text('Aave Deposit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TRANSACTION REVERTED'), findsOneWidget);
      expect(find.text('Execution Reverted'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TransactionFailedScreen),
          matching: find.text('OUT_OF_GAS'),
        ),
        findsOneWidget,
      );
    });
  });

  group('TransactionPendingScreen Tests', () {
    testWidgets('renders flight badge, orbital rings, and speeds up to success',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionPendingScreen(
            autoCompleteSeconds: 0, // Disable auto transition for deterministic test
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TRANSACTION IN FLIGHT'), findsOneWidget);
      expect(find.text('Transaction Submitted'), findsOneWidget);
      expect(find.text('CONFIRMING BLOCK'), findsOneWidget);
      expect(find.text('Speed Up'), findsOneWidget);

      // Tap Speed Up CTA -> should transition to TransactionSuccessScreen
      await tester.tap(find.text('Speed Up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('VERIFIED SETTLEMENT'), findsOneWidget);
      expect(find.text('Transfer Complete'), findsOneWidget);
    });
  });

  group('TransactionFailedScreen Tests', () {
    testWidgets('renders diagnostics, shows technical trace modal, and retries with boosted gas',
        (tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionFailedScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('TRANSACTION REVERTED'), findsOneWidget);
      expect(find.text('Execution Reverted'), findsOneWidget);
      expect(find.text('OUT_OF_GAS'), findsOneWidget);
      expect(find.text('CODE: EVM-0x02'), findsOneWidget);

      // Tap View Technical Trace -> shows modal
      await tester.tap(find.text('View Technical Trace'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('EVM Execution Trace'), findsOneWidget);
      expect(find.text('Close Trace'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close Trace'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Retry -> should replace with TransactionPendingScreen
      await tester.tap(find.text('TRY AGAIN WITH BOOSTED GAS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TRANSACTION IN FLIGHT'), findsOneWidget);
      expect(find.text('BOOSTED'), findsOneWidget);

      // Advance past auto transition timer
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('TransactionSuccessScreen Tests', () {
    testWidgets('renders celebration cluster, copy tx hash, and Done CTA',
        (tester) async {
      setMobileViewport(tester);
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TransactionSuccessScreen(
            onDone: () => doneCalled = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('VERIFIED SETTLEMENT'), findsOneWidget);
      expect(find.text('Transfer Complete'), findsOneWidget);
      expect(find.text('0x7a3f...9b21'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(doneCalled, isTrue);
    });
  });

  group('SwapScreen to Pending & Success Flow', () {
    testWidgets('Review Swap navigates to pending screen', (tester) async {
      setMobileViewport(tester);
      final repository = InMemoryPortfolioRepository();
      final snapshotResult = await repository.getSnapshot();
      final assets = snapshotResult.valueOrNull?.assets ?? [];

      await tester.pumpWidget(
        MaterialApp(
          home: SwapScreen(
            allTokens: assets,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Instant Swap'), findsOneWidget);
      expect(find.text('Review Swap'), findsOneWidget);

      // Scroll to and tap Review Swap
      await tester.ensureVisible(find.text('Review Swap'));
      await tester.tap(find.text('Review Swap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should be on TransactionPendingScreen
      expect(find.text('TRANSACTION IN FLIGHT'), findsOneWidget);
      expect(find.text('Transaction Submitted'), findsOneWidget);

      // Advance past auto transition timer
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
