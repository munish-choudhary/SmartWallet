import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/notifications/data/notifications_repository.dart';
import 'package:smart_wallet/features/notifications/view_model/notifications_cubit.dart';
import 'package:smart_wallet/features/portfolio/data/portfolio_repository.dart';
import 'package:smart_wallet/features/portfolio/view/portfolio_screen.dart';
import 'package:smart_wallet/features/portfolio/view_model/portfolio_cubit.dart';

void main() {
  group('PortfolioScreen Widget Test', () {
    late InMemoryPortfolioRepository repository;

    setUp(() {
      repository = InMemoryPortfolioRepository();
    });

    Widget createSubject() {
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

    testWidgets('renders total balance and default tokens from snapshot',
        (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify total balance from Figma spec
      expect(find.text('TOTAL BALANCE'), findsOneWidget);
      expect(find.text('\$275,410.85'), findsOneWidget);

      // Verify quick action buttons
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Receive'), findsOneWidget);
      expect(find.text('Swap'), findsOneWidget);
      expect(find.text('Buy'), findsOneWidget);

      // Verify filter pills
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tokens'), findsOneWidget);
      expect(find.text('DeFi'), findsOneWidget);

      // Verify tokens rendered
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('Solana'), findsOneWidget);
      expect(find.text('Avalanche'), findsOneWidget);

      // Verify AI floating assistant message
      expect(find.text('Portfolio looks healthy! ⚡'), findsOneWidget);
    });

    testWidgets('tapping filter tab filters token list', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Tokens' filter (excludes Bitcoin since network is BTC)
      await tester.tap(find.text('Tokens'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('Bitcoin'), findsNothing);
    });

    testWidgets('tapping a token opens TokenDetailScreen', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Ethereum card
      await tester.tap(find.text('Ethereum'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Token Detail components
      expect(find.text('YOUR HOLDINGS'), findsOneWidget);
      expect(find.text('17.5% of Portfolio'), findsOneWidget);
      expect(find.text('Swap ETH'), findsOneWidget);
      expect(find.text('Earn up to 4.2% APY'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
    });

    testWidgets('tapping Swap button opens SwapScreen', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Swap button in action row
      await tester.tap(find.text('Swap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Swap screen components
      expect(find.text('Instant Swap'), findsOneWidget);
      expect(find.text('BEST ROUTE ACTIVE'), findsOneWidget);
      expect(find.text('Review Swap'), findsOneWidget);
      expect(find.text('Exchange Rate'), findsOneWidget);
    });
  });
}
