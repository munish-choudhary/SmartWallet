import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../data/models/wc_session.dart';
import '../data/models/wc_session_proposal.dart';

part 'pairing_state.freezed.dart';

/// The pairing flow: link → proposal → decision → connected session.
/// The link itself (it carries the pairing key) is never held in state.
@freezed
sealed class PairingState with _$PairingState {
  const factory PairingState.idle() = PairingIdle;
  const factory PairingState.connecting() = PairingConnecting;
  const factory PairingState.proposal(WcSessionProposal proposal) =
      PairingProposal;
  const factory PairingState.approving(WcSessionProposal proposal) =
      PairingApproving;
  const factory PairingState.connected(WcSession session) = PairingConnected;
  const factory PairingState.failure(AppFailure failure) = PairingFailure;
}
