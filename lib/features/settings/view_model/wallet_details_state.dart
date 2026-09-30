import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../../portfolio/data/models/portfolio_snapshot.dart';
import '../data/wallet_profile.dart';

part 'wallet_details_state.freezed.dart';

@freezed
sealed class WalletDetailsState with _$WalletDetailsState {
  const factory WalletDetailsState.loading() = WalletDetailsLoading;

  /// [portfolio] is `null` when the balance couldn't be fetched — the rest of
  /// the screen (rename, keys, address) still works without it.
  const factory WalletDetailsState.loaded(
    WalletProfile profile, {
    PortfolioSnapshot? portfolio,
  }) = WalletDetailsLoaded;

  const factory WalletDetailsState.failure(AppFailure failure) =
      WalletDetailsFailure;
}
