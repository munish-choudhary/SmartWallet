import '../../../core/result/result.dart';
import 'models/wc_chain.dart';
import 'models/wc_request.dart';
import 'models/wc_session.dart';
import 'models/wc_session_proposal.dart';

/// Single source of truth for WalletConnect sessions and requests.
///
/// The production implementation wraps `reown_walletkit`; every incoming
/// `eth_sendTransaction` / `personal_sign` / `eth_signTypedData_v4` surfaces
/// here as a [WcRequest] and must be answered through [respond] after the
/// user has seen a review sheet.
abstract interface class WalletConnectRepository {
  /// Emits the current sessions immediately, then on every change.
  Stream<List<WcSession>> watchSessions();

  Future<Result<WcSession>> getSession(String topic);

  /// Starts pairing from a `wc:` link and resolves with the dApp's
  /// session proposal. The link is validated locally first.
  Future<Result<WcSessionProposal>> pair(String uri);

  Future<Result<WcSession>> approveProposal(
    String proposalId, {
    required List<WcChain> chains,
  });

  Future<Result<void>> rejectProposal(String proposalId);

  /// Ends the session and revokes all of its permissions.
  Future<Result<void>> disconnect(String topic);

  /// Requests arriving from connected dApps, one event per request.
  Stream<WcRequest> get incomingRequests;

  Future<Result<void>> respond(String requestId, WcRequestDecision decision);
}
