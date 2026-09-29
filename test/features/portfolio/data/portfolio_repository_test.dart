import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/portfolio/data/portfolio_repository.dart';

void main() {
  group('InMemoryPortfolioRepository', () {
    late InMemoryPortfolioRepository repository;

    setUp(() {
      repository = InMemoryPortfolioRepository();
    });

    test('getSnapshot returns Ok with default seed snapshot', () async {
      final result = await repository.getSnapshot();

      expect(result.isOk, isTrue);
      final snapshot = result.valueOrNull!;
      expect(snapshot.totalBalanceUsd, 275410.85);
      expect(snapshot.assets.length, 4);
      expect(snapshot.assets.first.symbol, 'ETH');
      expect(snapshot.recentTransactions.length, 3);
    });

    test('watchSnapshot emits latest snapshot stream', () async {
      expect(
        repository.watchSnapshot(),
        emits(isA<Ok<dynamic>>()),
      );
    });

    test('toggleFavorite toggles asset favorite flag and emits update', () async {
      final initialResult = await repository.getSnapshot();
      final initialEth =
          initialResult.valueOrNull!.assets.firstWhere((a) => a.id == 'ethereum');
      expect(initialEth.isFavorite, isTrue);

      final toggleResult = await repository.toggleFavorite('ethereum');
      expect(toggleResult.isOk, isTrue);

      final updatedResult = await repository.getSnapshot();
      final updatedEth =
          updatedResult.valueOrNull!.assets.firstWhere((a) => a.id == 'ethereum');
      expect(updatedEth.isFavorite, isFalse);
    });

    test('refresh emits snapshot', () async {
      final result = await repository.refresh();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.totalBalanceUsd, 275410.85);
    });
  });
}
