import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';

part 'balance_privacy_state.freezed.dart';

@freezed
sealed class BalancePrivacyState with _$BalancePrivacyState {
  const factory BalancePrivacyState.loading() = BalancePrivacyLoading;
  const factory BalancePrivacyState.ready({required bool hideBalances}) =
      BalancePrivacyReady;
  const factory BalancePrivacyState.failure(AppFailure failure) =
      BalancePrivacyFailure;
}
