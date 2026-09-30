import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/models/wc_chain.dart';
import '../data/wallet_connect_repository.dart';
import 'pairing_state.dart';

class PairingCubit extends Cubit<PairingState> {
  PairingCubit({required WalletConnectRepository repository})
      : _repository = repository,
        super(const PairingState.idle());

  final WalletConnectRepository _repository;

  /// Bumped on cancel/reset so a late repository response can't resurrect
  /// a flow the user already left.
  int _generation = 0;

  Future<void> pair(String uri) async {
    // A finished flow (connected / failed) never blocks a new pairing.
    if (state is PairingConnecting ||
        state is PairingProposal ||
        state is PairingApproving) {
      return;
    }
    final generation = ++_generation;
    emit(const PairingState.connecting());
    final result = await _repository.pair(uri);
    if (isClosed || generation != _generation) return;
    emit(switch (result) {
      Ok(:final value) => PairingState.proposal(value),
      Err(:final failure) => PairingState.failure(failure),
    });
  }

  Future<void> approve(List<WcChain> chains) async {
    final current = state;
    if (current is! PairingProposal) return;
    final generation = ++_generation;
    emit(PairingState.approving(current.proposal));
    final result = await _repository.approveProposal(
      current.proposal.id,
      chains: chains,
    );
    if (isClosed || generation != _generation) return;
    emit(switch (result) {
      Ok(:final value) => PairingState.connected(value),
      Err(:final failure) => PairingState.failure(failure),
    });
  }

  Future<void> reject() async {
    final current = state;
    if (current is! PairingProposal) return;
    _generation++;
    emit(const PairingState.idle());
    await _repository.rejectProposal(current.proposal.id);
  }

  /// Abandons the flow at any stage (back button, cancel, success "Done").
  void reset() {
    final current = state;
    _generation++;
    emit(const PairingState.idle());
    if (current is PairingProposal) {
      _repository.rejectProposal(current.proposal.id);
    } else if (current is PairingApproving) {
      _repository.rejectProposal(current.proposal.id);
    }
  }
}
