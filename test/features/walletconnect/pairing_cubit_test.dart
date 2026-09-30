import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/walletconnect/view_model/pairing_cubit.dart';
import 'package:smart_wallet/features/walletconnect/view_model/pairing_state.dart';

import 'wc_test_helpers.dart';

void main() {
  group('PairingCubit', () {
    blocTest<PairingCubit, PairingState>(
      'pair: connecting, then the dApp proposal',
      build: () => PairingCubit(repository: buildRepository()),
      act: (cubit) => cubit.pair(validPairingLink()),
      expect: () => [isA<PairingConnecting>(), isA<PairingProposal>()],
    );

    blocTest<PairingCubit, PairingState>(
      'pair with a bad link ends in failure',
      build: () => PairingCubit(repository: buildRepository()),
      act: (cubit) => cubit.pair('not a link'),
      expect: () => [isA<PairingConnecting>(), isA<PairingFailure>()],
    );

    blocTest<PairingCubit, PairingState>(
      'approve: approving, then connected with a session',
      build: () => PairingCubit(repository: buildRepository()),
      act: (cubit) async {
        await cubit.pair(validPairingLink());
        final proposal = (cubit.state as PairingProposal).proposal;
        await cubit.approve(proposal.requiredChains);
      },
      expect: () => [
        isA<PairingConnecting>(),
        isA<PairingProposal>(),
        isA<PairingApproving>(),
        isA<PairingConnected>(),
      ],
    );

    blocTest<PairingCubit, PairingState>(
      'approve is ignored when there is no proposal on screen',
      build: () => PairingCubit(repository: buildRepository()),
      act: (cubit) => cubit.approve(const []),
      expect: () => <PairingState>[],
    );

    blocTest<PairingCubit, PairingState>(
      'reject returns to idle',
      build: () => PairingCubit(repository: buildRepository()),
      act: (cubit) async {
        await cubit.pair(validPairingLink());
        await cubit.reject();
      },
      expect: () => [
        isA<PairingConnecting>(),
        isA<PairingProposal>(),
        isA<PairingIdle>(),
      ],
    );

    blocTest<PairingCubit, PairingState>(
      'a late response after reset does not resurrect the flow',
      build: () => PairingCubit(
        repository: buildRepository(latency: const Duration(milliseconds: 30)),
      ),
      act: (cubit) async {
        final pending = cubit.pair(validPairingLink());
        await Future<void>.delayed(const Duration(milliseconds: 5));
        cubit.reset();
        await pending;
      },
      wait: const Duration(milliseconds: 60),
      expect: () => [isA<PairingConnecting>(), isA<PairingIdle>()],
    );

    blocTest<PairingCubit, PairingState>(
      'pair is ignored while already connecting',
      build: () => PairingCubit(
        repository: buildRepository(latency: const Duration(milliseconds: 20)),
      ),
      act: (cubit) async {
        final first = cubit.pair(validPairingLink());
        await cubit.pair(validPairingLink(seed: 9));
        await first;
      },
      expect: () => [isA<PairingConnecting>(), isA<PairingProposal>()],
    );

    blocTest<PairingCubit, PairingState>(
      'a finished flow does not block the next pairing',
      build: () => PairingCubit(repository: buildRepository()),
      act: (cubit) async {
        await cubit.pair(validPairingLink());
        await cubit.approve((cubit.state as PairingProposal).proposal.requiredChains);
        await cubit.pair(validPairingLink(seed: 2));
      },
      skip: 4,
      expect: () => [isA<PairingConnecting>(), isA<PairingProposal>()],
    );
  });
}
