import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/models/wc_session.dart';
import '../data/wallet_connect_repository.dart';
import '../data/wc_demo_data.dart';
import 'wallet_connect_state.dart';

/// Backs the WalletConnect hub: the live list of connected dApps.
class WalletConnectCubit extends Cubit<WalletConnectState> {
  WalletConnectCubit({required WalletConnectRepository repository})
      : _repository = repository,
        super(const WalletConnectState.loading()) {
    _subscription = _repository.watchSessions().listen(
      (List<WcSession> sessions) => emit(WalletConnectState.loaded(sessions)),
      onError: (Object _) => emit(
        const WalletConnectState.failure(
          AppFailure.unknown('Could not load connected apps.'),
        ),
      ),
    );
  }

  final WalletConnectRepository _repository;
  late final StreamSubscription<List<WcSession>> _subscription;

  /// True when the repository can fabricate requests (in-memory demo only).
  bool get canSimulateRequests => _repository is WcRequestSimulator;

  Future<bool> simulateRequest(WcSimulatedRequestKind kind) async {
    // Typed as Object so the `is` check can promote to the unrelated interface.
    final Object repository = _repository;
    if (repository is! WcRequestSimulator) return false;
    return repository.simulateRequest(kind);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
