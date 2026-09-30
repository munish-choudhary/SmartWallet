import 'dart:async';

import '../../../core/result/result.dart';
import 'models/wc_chain.dart';
import 'models/wc_request.dart';
import 'models/wc_session.dart';
import 'models/wc_session_proposal.dart';
import 'wallet_account_source.dart';
import 'wallet_connect_repository.dart';
import 'wc_demo_data.dart';
import 'wc_pairing_uri.dart';

/// Stand-in for the relay: sessions live in memory and a pairing link
/// yields a canned proposal. It exists so the WalletConnect UI can be
/// built and exercised end to end.
///
/// It is **not** wired to `reown_walletkit` and it never signs — approving
/// a request here only resolves the simulated dApp's pending call.
class InMemoryWalletConnectRepository
    implements WalletConnectRepository, WcRequestSimulator {
  InMemoryWalletConnectRepository({
    WalletAccountSource accountSource = const InMemoryWalletAccountSource(),
    Duration latency = const Duration(milliseconds: 1400),
    DateTime Function()? now,
    bool seedSessions = true,
  })  : _accountSource = accountSource,
        _latency = latency,
        _now = now ?? DateTime.now {
    if (seedSessions) {
      // Seeded lazily on first read so the account lookup can be async.
      _seedPending = true;
    }
  }

  final WalletAccountSource _accountSource;
  final Duration _latency;
  final DateTime Function() _now;

  bool _seedPending = false;
  final List<WcSession> _sessions = [];
  final Map<String, WcSessionProposal> _pending = {};
  final Set<String> _usedPairingTopics = {};
  final Set<String> _openRequests = {};
  final List<StreamController<List<WcSession>>> _watchers = [];
  final _requests = StreamController<WcRequest>.broadcast();
  int _nextProposal = 0;
  int _nextTopic = 0;
  int _nextRequest = 0;

  Future<void> _ensureSeeded() async {
    if (!_seedPending) return;
    _seedPending = false;
    final account = (await _accountSource.activeEvmAccount()).valueOrNull;
    if (account == null) return;
    _sessions.addAll(
      WcDemoData.sessions(_now(), account.address, account.label),
    );
  }

  List<WcSession> _snapshot() => List.unmodifiable(_sessions);

  void _notify() {
    final snapshot = _snapshot();
    for (final watcher in List.of(_watchers)) {
      watcher.add(snapshot);
    }
  }

  @override
  Stream<List<WcSession>> watchSessions() {
    late final StreamController<List<WcSession>> controller;
    controller = StreamController<List<WcSession>>(
      onListen: () async {
        await _ensureSeeded();
        if (controller.isClosed) return;
        _watchers.add(controller);
        controller.add(_snapshot());
      },
      onCancel: () => _watchers.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<Result<WcSession>> getSession(String topic) async {
    await _ensureSeeded();
    for (final session in _sessions) {
      if (session.topic == topic) return Result.ok(session);
    }
    return const Result.err(AppFailure.unknown('Session not found'));
  }

  @override
  Future<Result<WcSessionProposal>> pair(String uri) async {
    final parsed = WcPairingUri.tryParse(uri);
    if (parsed == null) {
      return const Result.err(
        AppFailure.unknown('That is not a valid WalletConnect link.'),
      );
    }
    if (parsed.isExpired(_now())) {
      return const Result.err(
        AppFailure.unknown(
          'This WalletConnect link has expired. Ask the app for a new one.',
        ),
      );
    }
    if (!_usedPairingTopics.add(parsed.topic)) {
      return const Result.err(
        AppFailure.unknown('This WalletConnect link was already used.'),
      );
    }
    if (_latency > Duration.zero) await Future<void>.delayed(_latency);

    final seeds = WcDemoData.proposals(_now());
    final seed = seeds[_nextProposal % seeds.length];
    final proposal = seed.copyWith(id: 'proposal-${_nextProposal++}');
    _pending[proposal.id] = proposal;
    return Result.ok(proposal);
  }

  @override
  Future<Result<WcSession>> approveProposal(
    String proposalId, {
    required List<WcChain> chains,
  }) async {
    final proposal = _pending[proposalId];
    if (proposal == null) {
      return const Result.err(
        AppFailure.unknown('This connection request is no longer available.'),
      );
    }
    final missing =
        proposal.requiredChains.where((c) => !chains.contains(c)).toList();
    if (missing.isNotEmpty) {
      return const Result.err(
        AppFailure.unknown('The app requires a network you did not approve.'),
      );
    }
    final account = await _accountSource.activeEvmAccount();
    if (account case Err(:final failure)) return Result.err(failure);
    final address = account.valueOrNull!;

    final now = _now();
    final session = WcSession(
      topic: 'session${(_nextTopic++).toString().padLeft(4, '0')}',
      dapp: proposal.dapp,
      accountAddress: address.address,
      accountLabel: address.label,
      chains: chains,
      permissions: proposal.permissions,
      connectedAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      lastActivityAt: now,
    );
    _pending.remove(proposalId);
    await _ensureSeeded();
    _sessions.insert(0, session);
    _notify();
    return Result.ok(session);
  }

  @override
  Future<Result<void>> rejectProposal(String proposalId) async {
    _pending.remove(proposalId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> disconnect(String topic) async {
    await _ensureSeeded();
    final before = _sessions.length;
    _sessions.removeWhere((s) => s.topic == topic);
    if (_sessions.length == before) {
      return const Result.err(AppFailure.unknown('Session not found'));
    }
    _notify();
    return const Result.ok(null);
  }

  @override
  Stream<WcRequest> get incomingRequests => _requests.stream;

  @override
  Future<Result<void>> respond(
    String requestId,
    WcRequestDecision decision,
  ) async {
    if (!_openRequests.remove(requestId)) {
      return const Result.err(
        AppFailure.unknown('This request is no longer pending.'),
      );
    }
    return const Result.ok(null);
  }

  /// Dev tool: emits a request of [kind] from the first connected dApp.
  /// Returns false when there is no session to attribute it to.
  @override
  Future<bool> simulateRequest(WcSimulatedRequestKind kind) async {
    await _ensureSeeded();
    if (_sessions.isEmpty) return false;
    final id = 'request-${_nextRequest++}';
    _openRequests.add(id);
    _requests.add(
      buildDemoRequest(
        kind: kind,
        id: id,
        session: _sessions.first,
        now: _now(),
      ),
    );
    return true;
  }

  void dispose() {
    unawaited(_requests.close());
    for (final watcher in List.of(_watchers)) {
      unawaited(watcher.close());
    }
  }
}
