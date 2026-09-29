import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/portfolio/data/models/portfolio_filter.dart';
import 'package:smart_wallet/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:smart_wallet/features/portfolio/data/models/token_asset.dart';
import 'package:smart_wallet/features/portfolio/data/portfolio_repository.dart';
import 'package:smart_wallet/features/portfolio/view_model/portfolio_cubit.dart';
import 'package:smart_wallet/features/portfolio/view_model/portfolio_state.dart';

class MockPortfolioRepository extends Mock implements PortfolioRepository {}

void main() {
  group('PortfolioCubit', () {
    late MockPortfolioRepository repository;
    late StreamController<Result<PortfolioSnapshot>> streamController;

    const testSnapshot = PortfolioSnapshot(
      totalBalanceUsd: 100000.0,
      change24hPercent: 5.0,
      change24hUsd: 5000.0,
      assets: [
        TokenAsset(
          id: 'ethereum',
          name: 'Ethereum',
          symbol: 'ETH',
          network: 'ERC-20',
          balance: 10.0,
          priceUsd: 3000.0,
          change24h: 4.5,
          iconBgColor: 0xFF627EEA,
          contractAddress: '0x123',
          marketCap: '\$300B',
          volume24h: '\$10B',
          sparklinePoints: [2900, 3000],
          stakedBalance: 2.0,
        ),
        TokenAsset(
          id: 'bitcoin',
          name: 'Bitcoin',
          symbol: 'BTC',
          network: 'BTC',
          balance: 1.0,
          priceUsd: 70000.0,
          change24h: 2.5,
          iconBgColor: 0xFFF7931A,
          contractAddress: 'Native',
          marketCap: '\$1.4T',
          volume24h: '\$25B',
          sparklinePoints: [68000, 70000],
          stakedBalance: 0.0,
        ),
      ],
      recentTransactions: [],
    );

    setUp(() {
      repository = MockPortfolioRepository();
      streamController = StreamController<Result<PortfolioSnapshot>>.broadcast();
      when(() => repository.watchSnapshot()).thenAnswer((_) => streamController.stream);
      when(() => repository.getSnapshot()).thenAnswer((_) async => const Result.ok(testSnapshot));
      when(() => repository.refresh()).thenAnswer((_) async => const Result.ok(testSnapshot));
      when(() => repository.toggleFavorite(any())).thenAnswer((_) async => const Result.ok(null));
    });

    tearDown(() {
      streamController.close();
    });

    test('initial state is PortfolioState.loading', () {
      final cubit = PortfolioCubit(repository: repository);
      expect(cubit.state, const PortfolioState.loading());
      cubit.close();
    });

    blocTest<PortfolioCubit, PortfolioState>(
      'emits loaded state when repository stream yields snapshot',
      build: () => PortfolioCubit(repository: repository),
      act: (cubit) {
        streamController.add(const Result.ok(testSnapshot));
      },
      expect: () => [
        const PortfolioState.loaded(testSnapshot),
      ],
    );

    blocTest<PortfolioCubit, PortfolioState>(
      'emits failure state when repository stream yields error',
      build: () => PortfolioCubit(repository: repository),
      act: (cubit) {
        streamController.add(const Result.err(AppFailure.network('Network down')));
      },
      expect: () => [
        const PortfolioState.failure(AppFailure.network('Network down')),
      ],
    );

    blocTest<PortfolioCubit, PortfolioState>(
      'setFilter updates activeFilter on loaded state',
      build: () => PortfolioCubit(repository: repository),
      seed: () => const PortfolioState.loaded(testSnapshot),
      act: (cubit) => cubit.setFilter(PortfolioFilter.tokens),
      expect: () => [
        const PortfolioState.loaded(
          testSnapshot,
          activeFilter: PortfolioFilter.tokens,
        ),
      ],
      verify: (cubit) {
        final visible = cubit.state.visibleAssets;
        expect(visible.length, 1);
        expect(visible.first.symbol, 'ETH');
      },
    );

    blocTest<PortfolioCubit, PortfolioState>(
      'setFilter to defi filters assets with stakedBalance > 0',
      build: () => PortfolioCubit(repository: repository),
      seed: () => const PortfolioState.loaded(testSnapshot),
      act: (cubit) => cubit.setFilter(PortfolioFilter.defi),
      expect: () => [
        const PortfolioState.loaded(
          testSnapshot,
          activeFilter: PortfolioFilter.defi,
        ),
      ],
      verify: (cubit) {
        final visible = cubit.state.visibleAssets;
        expect(visible.length, 1);
        expect(visible.first.symbol, 'ETH');
      },
    );

    blocTest<PortfolioCubit, PortfolioState>(
      'setSearchQuery filters visible assets by query',
      build: () => PortfolioCubit(repository: repository),
      seed: () => const PortfolioState.loaded(testSnapshot),
      act: (cubit) => cubit.setSearchQuery('btc'),
      expect: () => [
        const PortfolioState.loaded(
          testSnapshot,
          searchQuery: 'btc',
        ),
      ],
      verify: (cubit) {
        final visible = cubit.state.visibleAssets;
        expect(visible.length, 1);
        expect(visible.first.symbol, 'BTC');
      },
    );

    blocTest<PortfolioCubit, PortfolioState>(
      'refresh sets refreshing flag and updates data',
      build: () => PortfolioCubit(repository: repository),
      seed: () => const PortfolioState.loaded(testSnapshot),
      act: (cubit) async => cubit.refresh(),
      expect: () => [
        const PortfolioState.loaded(testSnapshot, refreshing: true),
        const PortfolioState.loaded(testSnapshot, refreshing: false),
      ],
      verify: (_) {
        verify(() => repository.refresh()).called(1);
      },
    );

    blocTest<PortfolioCubit, PortfolioState>(
      'toggleFavorite calls repository toggleFavorite',
      build: () => PortfolioCubit(repository: repository),
      seed: () => const PortfolioState.loaded(testSnapshot),
      act: (cubit) => cubit.toggleFavorite('ethereum'),
      verify: (_) {
        verify(() => repository.toggleFavorite('ethereum')).called(1);
      },
    );
  });
}
