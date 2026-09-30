import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../data/models/wc_session.dart';

part 'session_detail_state.freezed.dart';

@freezed
sealed class SessionDetailState with _$SessionDetailState {
  const factory SessionDetailState.loading() = SessionDetailLoading;
  const factory SessionDetailState.ready(WcSession session) =
      SessionDetailReady;
  const factory SessionDetailState.disconnecting(WcSession session) =
      SessionDetailDisconnecting;
  const factory SessionDetailState.disconnected(WcSession session) =
      SessionDetailDisconnected;
  const factory SessionDetailState.disconnectFailed(
    WcSession session,
    AppFailure failure,
  ) = SessionDetailDisconnectFailed;
  const factory SessionDetailState.notFound() = SessionDetailNotFound;
}
