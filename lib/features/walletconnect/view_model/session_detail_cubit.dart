import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/wallet_connect_repository.dart';
import 'session_detail_state.dart';

class SessionDetailCubit extends Cubit<SessionDetailState> {
  SessionDetailCubit({
    required String topic,
    required WalletConnectRepository repository,
  })  : _topic = topic,
        _repository = repository,
        super(const SessionDetailState.loading()) {
    load();
  }

  final String _topic;
  final WalletConnectRepository _repository;

  Future<void> load() async {
    final result = await _repository.getSession(_topic);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => SessionDetailState.ready(value),
      Err() => const SessionDetailState.notFound(),
    });
  }

  Future<void> disconnect() async {
    final current = state;
    final session = switch (current) {
      SessionDetailReady(:final session) => session,
      SessionDetailDisconnectFailed(:final session) => session,
      _ => null,
    };
    if (session == null) return;
    emit(SessionDetailState.disconnecting(session));
    final result = await _repository.disconnect(_topic);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => SessionDetailState.disconnected(session),
      Err(:final failure) => SessionDetailState.disconnectFailed(
          session,
          failure,
        ),
    });
  }
}
