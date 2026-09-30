import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../data/models/wc_session.dart';

part 'wallet_connect_state.freezed.dart';

@freezed
sealed class WalletConnectState with _$WalletConnectState {
  const factory WalletConnectState.loading() = WalletConnectLoading;
  const factory WalletConnectState.loaded(List<WcSession> sessions) =
      WalletConnectLoaded;
  const factory WalletConnectState.failure(AppFailure failure) =
      WalletConnectFailure;
}
