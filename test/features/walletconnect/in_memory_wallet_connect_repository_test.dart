import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_chain.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_dapp.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_request.dart';
import 'package:smart_wallet/features/walletconnect/data/wc_demo_data.dart';

import 'wc_test_helpers.dart';

void main() {
  group('InMemoryWalletConnectRepository', () {
    test('watchSessions emits the seeded sessions first', () async {
      final repo = buildRepository();
      final sessions = await repo.watchSessions().first;
      expect(sessions.map((s) => s.dapp.name), ['Uniswap', 'OpenSea']);
    });

    test('an empty repository emits an empty list', () async {
      final repo = buildRepository(seedSessions: false);
      expect(await repo.watchSessions().first, isEmpty);
    });

    test('getSession finds by topic and fails for unknown topics', () async {
      final repo = buildRepository();
      expect((await repo.getSession('a1f3c8d2e5b7')).isOk, isTrue);
      expect((await repo.getSession('nope')).isOk, isFalse);
    });

    group('pair', () {
      test('rejects links that are not WalletConnect links', () async {
        final repo = buildRepository();
        final result = await repo.pair('https://example.com');
        expect(result.failureOrNull, isA<UnknownFailure>());
      });

      test('rejects an expired link', () async {
        final repo = buildRepository();
        final past = testNow.millisecondsSinceEpoch ~/ 1000 - 10;
        final result = await repo.pair(
          validPairingLink(extra: '&expiryTimestamp=$past'),
        );
        expect(
          (result.failureOrNull as UnknownFailure).message,
          contains('expired'),
        );
      });

      test('a link can only be used once', () async {
        final repo = buildRepository();
        final link = validPairingLink(seed: 1);
        expect((await repo.pair(link)).isOk, isTrue);
        final again = await repo.pair(link);
        expect(
          (again.failureOrNull as UnknownFailure).message,
          contains('already used'),
        );
      });

      test('hands out verified, unverified, then flagged dApps', () async {
        final repo = buildRepository();
        final verifications = <WcVerification>[];
        for (var i = 0; i < 3; i++) {
          final proposal =
              (await repo.pair(validPairingLink(seed: i))).valueOrNull!;
          verifications.add(proposal.dapp.verification);
        }
        expect(verifications, [
          WcVerification.verified,
          WcVerification.unverified,
          WcVerification.flagged,
        ]);
      });
    });

    group('approveProposal', () {
      test('creates a session, newest first, and notifies watchers', () async {
        final repo = buildRepository();
        final events = <int>[];
        final sub = repo.watchSessions().listen((s) => events.add(s.length));
        await pumpEventQueue();

        final proposal =
            (await repo.pair(validPairingLink())).valueOrNull!;
        final session = (await repo.approveProposal(
          proposal.id,
          chains: proposal.requiredChains,
        ))
            .valueOrNull!;
        await pumpEventQueue();

        expect(session.dapp.name, proposal.dapp.name);
        expect(session.chains, proposal.requiredChains);
        expect(session.expiresAt.isAfter(session.connectedAt), isTrue);
        expect(events, [2, 3]);
        expect(
          (await repo.watchSessions().first).first.topic,
          session.topic,
        );
        await sub.cancel();
      });

      test('refuses to approve without a required chain', () async {
        final repo = buildRepository();
        final proposal = (await repo.pair(validPairingLink())).valueOrNull!;
        final result = await repo.approveProposal(
          proposal.id,
          chains: const [WcChains.polygon],
        );
        expect(result.isOk, isFalse);
        expect((await repo.watchSessions().first), hasLength(2));
      });

      test('fails for an unknown or already-decided proposal', () async {
        final repo = buildRepository();
        final proposal = (await repo.pair(validPairingLink())).valueOrNull!;
        await repo.rejectProposal(proposal.id);
        final result = await repo.approveProposal(
          proposal.id,
          chains: proposal.requiredChains,
        );
        expect(result.isOk, isFalse);
      });
    });

    test('disconnect removes the session and fails for unknown topics',
        () async {
      final repo = buildRepository();
      expect((await repo.disconnect('a1f3c8d2e5b7')).isOk, isTrue);
      final sessions = await repo.watchSessions().first;
      expect(sessions.map((s) => s.topic), ['9be04a7c1d63']);
      expect((await repo.disconnect('a1f3c8d2e5b7')).isOk, isFalse);
    });

    group('requests', () {
      test('simulateRequest emits a request attributed to a session',
          () async {
        final repo = buildRepository();
        final future = repo.incomingRequests.first;
        expect(await repo.simulateRequest(WcSimulatedRequestKind.swap), isTrue);
        final request = await future;
        expect(request, isA<WcTransactionRequest>());
        expect(request.dapp.name, 'Uniswap');
        expect(request.origin, WcRequestOrigin.walletConnect);
      });

      test('simulateRequest reports false with no session', () async {
        final repo = buildRepository(seedSessions: false);
        expect(
          await repo.simulateRequest(WcSimulatedRequestKind.message),
          isFalse,
        );
      });

      test('each request can be answered once', () async {
        final repo = buildRepository();
        final future = repo.incomingRequests.first;
        await repo.simulateRequest(WcSimulatedRequestKind.message);
        final request = await future;
        expect(
          (await repo.respond(request.id, const WcRequestDecision.reject()))
              .isOk,
          isTrue,
        );
        expect(
          (await repo.respond(request.id, const WcRequestDecision.reject()))
              .isOk,
          isFalse,
        );
      });

      test('demo unlimited approval is flagged as unlimited', () async {
        final repo = buildRepository();
        final future = repo.incomingRequests.first;
        await repo.simulateRequest(WcSimulatedRequestKind.unlimitedApproval);
        final tx = await future as WcTransactionRequest;
        expect(tx.approval!.isUnlimited, isTrue);
        expect(tx.risks.single.severity, WcRiskSeverity.danger);
      });
    });
  });
}
