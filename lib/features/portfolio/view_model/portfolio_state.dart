import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/app_failure.dart';
import '../data/models/portfolio_filter.dart';
import '../data/models/portfolio_snapshot.dart';
import '../data/models/token_asset.dart';

part 'portfolio_state.freezed.dart';

@freezed
sealed class PortfolioState with _$PortfolioState {
  const PortfolioState._();

  const factory PortfolioState.loading() = PortfolioLoading;

  const factory PortfolioState.loaded(
    PortfolioSnapshot data, {
    @Default(false) bool refreshing,
    @Default(PortfolioFilter.all) PortfolioFilter activeFilter,
    @Default('') String searchQuery,
    TokenAsset? selectedToken,
  }) = PortfolioLoaded;

  const factory PortfolioState.failure(AppFailure failure) = PortfolioFailure;

  List<TokenAsset> get visibleAssets {
    return switch (this) {
      PortfolioLoaded(
        :final data,
        :final activeFilter,
        :final searchQuery,
      ) =>
        data.assets.where((asset) {
          if (asset.isHidden) return false;
          final matchesCategory = switch (activeFilter) {
            PortfolioFilter.all => true,
            PortfolioFilter.tokens => asset.network != 'BTC',
            PortfolioFilter.defi => asset.stakedBalance > 0,
          };
          if (!matchesCategory) return false;

          if (searchQuery.trim().isEmpty) return true;
          final query = searchQuery.toLowerCase().trim();
          return asset.name.toLowerCase().contains(query) ||
              asset.symbol.toLowerCase().contains(query);
        }).toList(),
      _ => const [],
    };
  }
}
