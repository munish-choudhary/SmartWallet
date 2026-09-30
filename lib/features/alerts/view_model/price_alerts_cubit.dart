import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../portfolio/data/models/token_asset.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../data/price_alert.dart';
import '../data/price_alerts_repository.dart';
import 'price_alerts_state.dart';

class PriceAlertsCubit extends Cubit<PriceAlertsState> {
  PriceAlertsCubit({
    required PriceAlertsRepository alerts,
    required PortfolioRepository portfolio,
  })  : _alerts = alerts,
        super(const PriceAlertsState.loading()) {
    _alertsSub = alerts.watch().listen((items) {
      _items = items;
      _publish();
    });
    _portfolioSub = portfolio.watchSnapshot().listen((result) {
      if (result case Ok(:final value)) {
        _tokens = value.assets;
        _publish();
      }
    });
  }

  final PriceAlertsRepository _alerts;
  StreamSubscription<dynamic>? _alertsSub;
  StreamSubscription<dynamic>? _portfolioSub;
  List<PriceAlert>? _items;
  List<TokenAsset>? _tokens;

  void _publish() {
    final items = _items;
    final tokens = _tokens;
    if (items == null || tokens == null) return;
    emit(PriceAlertsState.loaded(alerts: items, tokens: tokens));
  }

  /// Returns false when [targetUsd] is not a positive number.
  Future<bool> create({
    required TokenAsset token,
    required double targetUsd,
    required AlertDirection direction,
  }) async {
    if (!targetUsd.isFinite || targetUsd <= 0) return false;
    await _alerts.add(PriceAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      tokenId: token.id,
      symbol: token.symbol,
      targetUsd: targetUsd,
      direction: direction,
    ));
    return true;
  }

  Future<void> setEnabled(String id, {required bool enabled}) =>
      _alerts.setEnabled(id, enabled: enabled);

  Future<void> remove(String id) => _alerts.remove(id);

  @override
  Future<void> close() {
    _alertsSub?.cancel();
    _portfolioSub?.cancel();
    return super.close();
  }
}
