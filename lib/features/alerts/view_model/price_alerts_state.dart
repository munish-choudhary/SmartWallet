import 'package:freezed_annotation/freezed_annotation.dart';

import '../../portfolio/data/models/token_asset.dart';
import '../data/price_alert.dart';

part 'price_alerts_state.freezed.dart';

@freezed
sealed class PriceAlertsState with _$PriceAlertsState {
  const factory PriceAlertsState.loading() = PriceAlertsLoading;
  const factory PriceAlertsState.loaded({
    required List<PriceAlert> alerts,
    required List<TokenAsset> tokens,
  }) = PriceAlertsLoaded;
}
