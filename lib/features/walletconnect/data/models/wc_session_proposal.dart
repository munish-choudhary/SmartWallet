import 'package:freezed_annotation/freezed_annotation.dart';

import 'wc_chain.dart';
import 'wc_dapp.dart';
import 'wc_session.dart';

part 'wc_session_proposal.freezed.dart';

/// A dApp's request to open a session, awaiting the user's decision.
@freezed
sealed class WcSessionProposal with _$WcSessionProposal {
  const WcSessionProposal._();

  const factory WcSessionProposal({
    required String id,
    required WcDapp dapp,

    /// Chains the dApp cannot work without — the user can only approve
    /// with all of them or reject.
    required List<WcChain> requiredChains,

    /// Chains the dApp would like; each can be toggled off.
    required List<WcChain> optionalChains,
    required List<WcPermission> permissions,
    required DateTime expiresAt,
  }) = _WcSessionProposal;

  List<WcChain> get allChains => [...requiredChains, ...optionalChains];
}
