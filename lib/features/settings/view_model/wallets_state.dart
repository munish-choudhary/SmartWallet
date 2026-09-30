import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../../../core/vault/vault.dart' show WalletId;
import '../data/wallet_profile.dart';

part 'wallets_state.freezed.dart';

@freezed
sealed class WalletsState with _$WalletsState {
  const factory WalletsState.loading() = WalletsLoading;

  /// [switchingTo] is the wallet being made active right now, if any.
  const factory WalletsState.loaded(
    List<WalletProfile> wallets, {
    required WalletId activeId,
    WalletId? switchingTo,
  }) = WalletsLoaded;

  const factory WalletsState.failure(AppFailure failure) = WalletsFailure;
}
