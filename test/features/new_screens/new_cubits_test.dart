import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/alerts/data/price_alert.dart';
import 'package:smart_wallet/features/alerts/data/price_alerts_repository.dart';
import 'package:smart_wallet/features/alerts/view_model/price_alerts_cubit.dart';
import 'package:smart_wallet/features/alerts/view_model/price_alerts_state.dart';
import 'package:smart_wallet/features/buy_sell/view_model/buy_sell_cubit.dart';
import 'package:smart_wallet/features/buy_sell/view_model/buy_sell_state.dart';
import 'package:smart_wallet/features/notifications/data/notifications_repository.dart';
import 'package:smart_wallet/features/notifications/view_model/notifications_cubit.dart';
import 'package:smart_wallet/features/portfolio/data/portfolio_repository.dart';
import 'package:smart_wallet/features/portfolio/view_model/manage_tokens_cubit.dart';
import 'package:smart_wallet/features/portfolio/view_model/manage_tokens_state.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('NotificationsCubit: unread count drops after markAllRead', () async {
    final cubit = NotificationsCubit(repository: InMemoryNotificationsRepository());
    await settle();
    expect(cubit.state.unreadCount, 2);
    await cubit.markAllRead();
    await settle();
    expect(cubit.state.unreadCount, 0);
    await cubit.close();
  });

  test('ManageTokensCubit: hiding a token removes it from the portfolio', () async {
    final repo = InMemoryPortfolioRepository();
    final cubit = ManageTokensCubit(repository: repo);
    await settle();
    await cubit.toggleHidden('ethereum');
    await settle();
    final state = cubit.state as ManageTokensLoaded;
    expect(state.assets.firstWhere((a) => a.id == 'ethereum').isHidden, isTrue);
    final snapshot = (await repo.getSnapshot()).valueOrNull!;
    expect(snapshot.assets.where((a) => a.isHidden), hasLength(1));
    cubit.setQuery('sol');
    expect(cubit.state.filtered.map((a) => a.symbol), ['SOL']);
    await cubit.close();
  });

  test('PriceAlertsCubit: rejects non-positive target, accepts valid one', () async {
    final repo = InMemoryPriceAlertsRepository();
    final cubit = PriceAlertsCubit(
      alerts: repo,
      portfolio: InMemoryPortfolioRepository(),
    );
    await settle();
    final loaded = cubit.state as PriceAlertsLoaded;
    final token = loaded.tokens.first;
    expect(
      await cubit.create(token: token, targetUsd: 0, direction: AlertDirection.above),
      isFalse,
    );
    expect(
      await cubit.create(token: token, targetUsd: 5000, direction: AlertDirection.above),
      isTrue,
    );
    await settle();
    expect((cubit.state as PriceAlertsLoaded).alerts, hasLength(3));
    await cubit.close();
  });

  test('BuySellCubit: quote math and sell-over-balance check', () async {
    final cubit = BuySellCubit(repository: InMemoryPortfolioRepository());
    await settle();
    cubit.setAmount('1000');
    var s = cubit.state as BuySellReady;
    expect(s.feeUsd, closeTo(15, 1e-9));
    expect(s.tokenAmount, closeTo(985 / s.token.priceUsd, 1e-9));
    expect(s.exceedsBalance, isFalse);
    cubit.setSide(TradeSide.sell);
    cubit.setAmount('${s.token.fiatValue + 1}');
    s = cubit.state as BuySellReady;
    expect(s.exceedsBalance, isTrue);
    await cubit.close();
  });
}
