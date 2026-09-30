import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/walletconnect/data/in_memory_wallet_connect_repository.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_request.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_session.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_connect_repository.dart';
import 'package:smart_wallet/features/walletconnect/data/wc_demo_data.dart';
import 'package:smart_wallet/features/walletconnect/view_model/request_review_cubit.dart';
import 'package:smart_wallet/features/walletconnect/view_model/request_review_state.dart';
import 'package:smart_wallet/features/walletconnect/view_model/session_detail_cubit.dart';
import 'package:smart_wallet/features/walletconnect/view_model/session_detail_state.dart';
import 'package:smart_wallet/features/walletconnect/view_model/wallet_connect_cubit.dart';
import 'package:smart_wallet/features/walletconnect/view_model/wallet_connect_state.dart';

import 'wc_test_helpers.dart';

class _MockRepository extends Mock implements WalletConnectRepository {}

late InMemoryWalletConnectRepository _sharedRepository;

void main() {
  setUpAll(() => registerFallbackValue(const WcRequestDecision.reject()));

  group('WalletConnectCubit', () {
    blocTest<WalletConnectCubit, WalletConnectState>(
      'loads the live session list',
      build: () => WalletConnectCubit(repository: buildRepository()),
      expect: () => [
        isA<WalletConnectLoaded>().having((s) => s.sessions.length, 'count', 2),
      ],
    );

    blocTest<WalletConnectCubit, WalletConnectState>(
      'reflects a disconnect made elsewhere without being asked',
      build: () {
        final repository = buildRepository();
        addTearDown(() => repository.dispose());
        _sharedRepository = repository;
        return WalletConnectCubit(repository: repository);
      },
      act: (cubit) async {
        await pumpEventQueue();
        await _sharedRepository.disconnect('a1f3c8d2e5b7');
      },
      expect: () => [
        isA<WalletConnectLoaded>().having((s) => s.sessions.length, 'count', 2),
        isA<WalletConnectLoaded>().having((s) => s.sessions.length, 'count', 1),
      ],
    );

    test('exposes the dev request simulator only when the repository has one',
        () async {
      final real = WalletConnectCubit(repository: buildRepository());
      expect(real.canSimulateRequests, isTrue);
      expect(await real.simulateRequest(WcSimulatedRequestKind.message), isTrue);
      await real.close();

      final mock = _MockRepository();
      when(mock.watchSessions).thenAnswer((_) => const Stream.empty());
      final plain = WalletConnectCubit(repository: mock);
      expect(plain.canSimulateRequests, isFalse);
      expect(await plain.simulateRequest(WcSimulatedRequestKind.message), isFalse);
      await plain.close();
    });

    test('a stream error becomes a failure state', () async {
      final mock = _MockRepository();
      when(mock.watchSessions).thenAnswer((_) => Stream.error(StateError('x')));
      final cubit = WalletConnectCubit(repository: mock);
      await pumpEventQueue();
      expect(cubit.state, isA<WalletConnectFailure>());
      await cubit.close();
    });
  });

  group('SessionDetailCubit', () {
    blocTest<SessionDetailCubit, SessionDetailState>(
      'loads a session',
      build: () => SessionDetailCubit(
        topic: 'a1f3c8d2e5b7',
        repository: buildRepository(),
      ),
      expect: () => [isA<SessionDetailReady>()],
    );

    blocTest<SessionDetailCubit, SessionDetailState>(
      'an unknown topic is notFound',
      build: () => SessionDetailCubit(
        topic: 'missing',
        repository: buildRepository(),
      ),
      expect: () => [isA<SessionDetailNotFound>()],
    );

    blocTest<SessionDetailCubit, SessionDetailState>(
      'disconnect: disconnecting, then disconnected',
      build: () => SessionDetailCubit(
        topic: 'a1f3c8d2e5b7',
        repository: buildRepository(),
      ),
      act: (cubit) async {
        await pumpEventQueue();
        await cubit.disconnect();
      },
      expect: () => [
        isA<SessionDetailReady>(),
        isA<SessionDetailDisconnecting>(),
        isA<SessionDetailDisconnected>(),
      ],
    );

    blocTest<SessionDetailCubit, SessionDetailState>(
      'a failed disconnect keeps the session and can be retried',
      build: () {
        final repository = buildRepository();
        return SessionDetailCubit(
          topic: 'a1f3c8d2e5b7',
          repository: _FailingDisconnect(repository),
        );
      },
      act: (cubit) async {
        await pumpEventQueue();
        await cubit.disconnect();
        await cubit.disconnect();
      },
      expect: () => [
        isA<SessionDetailReady>(),
        isA<SessionDetailDisconnecting>(),
        isA<SessionDetailDisconnectFailed>(),
        isA<SessionDetailDisconnecting>(),
        isA<SessionDetailDisconnectFailed>(),
      ],
    );

    blocTest<SessionDetailCubit, SessionDetailState>(
      'disconnect does nothing before the session has loaded',
      build: () => SessionDetailCubit(
        topic: 'missing',
        repository: buildRepository(),
      ),
      act: (cubit) => cubit.disconnect(),
      expect: () => [isA<SessionDetailNotFound>()],
    );
  });

  group('RequestReviewCubit', () {
    late _MockRepository repository;
    late StreamController<WcRequest> requests;
    late List<WcRequestDecision> decisions;

    WcRequest request(String id) => buildDemoRequest(
          kind: WcSimulatedRequestKind.message,
          id: id,
          session: WcDemoData.sessions(testNow, '0xabc', 'Main').first,
          now: testNow,
        );

    setUp(() {
      repository = _MockRepository();
      requests = StreamController<WcRequest>.broadcast();
      decisions = [];
      when(() => repository.incomingRequests).thenAnswer((_) => requests.stream);
      when(() => repository.respond(any(), any())).thenAnswer((invocation) async {
        decisions.add(invocation.positionalArguments[1] as WcRequestDecision);
        return const Result.ok(null);
      });
    });

    tearDown(() => requests.close());

    blocTest<RequestReviewCubit, RequestReviewState>(
      'a request opens a review',
      build: () => RequestReviewCubit(repository: repository),
      act: (cubit) async {
        requests.add(request('r1'));
        await pumpEventQueue();
      },
      expect: () => [isA<RequestReviewReviewing>()],
    );

    blocTest<RequestReviewCubit, RequestReviewState>(
      'requests queue up and are reviewed one at a time',
      build: () => RequestReviewCubit(repository: repository),
      act: (cubit) async {
        requests
          ..add(request('r1'))
          ..add(request('r2'));
        await pumpEventQueue();
        await cubit.approve();
        await cubit.reject();
      },
      expect: () => [
        isA<RequestReviewReviewing>().having((s) => s.request.id, 'id', 'r1'),
        isA<RequestReviewReviewing>().having((s) => s.queued, 'queued', 1),
        isA<RequestReviewSubmitting>(),
        isA<RequestReviewReviewing>()
            .having((s) => s.request.id, 'id', 'r2')
            .having((s) => s.queued, 'queued', 0),
        isA<RequestReviewSubmitting>(),
        isA<RequestReviewIdle>(),
      ],
      verify: (_) {
        expect(decisions.map((d) => d.approved), [true, false]);
        verify(() => repository.respond('r1', any())).called(1);
        verify(() => repository.respond('r2', any())).called(1);
      },
    );

    blocTest<RequestReviewCubit, RequestReviewState>(
      'the spending cap the user chose reaches the repository',
      build: () => RequestReviewCubit(repository: repository),
      act: (cubit) async {
        requests.add(request('r1'));
        await pumpEventQueue();
        await cubit.approve(approvalCap: '500');
      },
      verify: (_) => expect(decisions.single.approvalCap, '500'),
    );

    blocTest<RequestReviewCubit, RequestReviewState>(
      'approve/reject with nothing on screen does nothing',
      build: () => RequestReviewCubit(repository: repository),
      act: (cubit) async {
        await cubit.approve();
        await cubit.reject();
      },
      expect: () => <RequestReviewState>[],
      verify: (_) => verifyNever(() => repository.respond(any(), any())),
    );

    test('a request arriving mid-submit is queued, not dropped', () async {
      final gate = Completer<Result<void>>();
      when(() => repository.respond(any(), any()))
          .thenAnswer((_) => gate.future);
      final cubit = RequestReviewCubit(repository: repository);
      addTearDown(cubit.close);

      requests.add(request('r1'));
      await pumpEventQueue();
      final approving = cubit.approve();
      await pumpEventQueue();
      expect(cubit.state, isA<RequestReviewSubmitting>());

      requests.add(request('r2'));
      await pumpEventQueue();
      expect(cubit.state, isA<RequestReviewSubmitting>());

      gate.complete(const Result.ok(null));
      await approving;
      expect(
        cubit.state,
        isA<RequestReviewReviewing>()
            .having((s) => s.request.id, 'id', 'r2')
            .having((s) => s.queued, 'queued', 0),
      );
    });
  });
}

/// Delegates to a real repository but fails every disconnect.
class _FailingDisconnect extends _MockRepository {
  _FailingDisconnect(this._inner);
  final WalletConnectRepository _inner;

  @override
  Future<Result<WcSession>> getSession(String topic) =>
      _inner.getSession(topic);

  @override
  Future<Result<void>> disconnect(String topic) async =>
      const Result.err(AppFailure.unknown('boom'));
}
