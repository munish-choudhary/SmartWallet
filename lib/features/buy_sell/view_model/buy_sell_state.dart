import 'package:freezed_annotation/freezed_annotation.dart';

import '../../portfolio/data/models/token_asset.dart';

part 'buy_sell_state.freezed.dart';

enum TradeSide { buy, sell }

@freezed
sealed class BuySellState with _$BuySellState {
  const BuySellState._();

  const factory BuySellState.loading() = BuySellLoading;
  const factory BuySellState.ready({
    required List<TokenAsset> tokens,
    required TokenAsset token,
    @Default(TradeSide.buy) TradeSide side,

    /// Raw text of the fiat amount field (USD).
    @Default('') String amountText,
  }) = BuySellReady;
}

/// Provider fee is a flat placeholder until a real on/off-ramp is integrated.
const double kBuySellFeeRate = 0.015;

extension BuySellReadyX on BuySellReady {
  double get amountUsd => double.tryParse(amountText) ?? 0;
  double get feeUsd => amountUsd * kBuySellFeeRate;
  double get tokenAmount =>
      token.priceUsd <= 0 ? 0 : (amountUsd - feeUsd) / token.priceUsd;

  /// Selling more than the balance is flagged.
  bool get exceedsBalance =>
      side == TradeSide.sell && amountUsd > token.fiatValue;
}
