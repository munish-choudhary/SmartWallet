import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/onboarding/data/onboarding_pin_holder.dart';
import 'package:smart_wallet/features/onboarding/view_model/pin_setup_cubit.dart';

void main() {
  group('PinSetupCubit (create step)', () {
    late OnboardingPinHolder holder;

    setUp(() => holder = OnboardingPinHolder());

    blocTest<PinSetupCubit, PinSetupState>(
      'accumulates digits one at a time',
      build: () => PinSetupCubit(step: PinStep.create, pinHolder: holder),
      act: (cubit) => cubit
        ..addDigit('1')
        ..addDigit('2'),
      expect: () => [
        const PinSetupState(digitCount: 1),
        const PinSetupState(digitCount: 2),
      ],
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'rejects a trivial PIN (all same digit) and clears the buffer',
      build: () => PinSetupCubit(step: PinStep.create, pinHolder: holder),
      act: (cubit) {
        for (final d in ['1', '1', '1', '1', '1', '1']) {
          cubit.addDigit(d);
        }
      },
      expect: () => [
        const PinSetupState(digitCount: 1),
        const PinSetupState(digitCount: 2),
        const PinSetupState(digitCount: 3),
        const PinSetupState(digitCount: 4),
        const PinSetupState(digitCount: 5),
        const PinSetupState(digitCount: 6),
        const PinSetupState(
          digitCount: 0,
          error: PinSetupError.trivialPin,
          shake: true,
        ),
      ],
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'rejects a sequential PIN (123456)',
      build: () => PinSetupCubit(step: PinStep.create, pinHolder: holder),
      act: (cubit) {
        for (final d in ['1', '2', '3', '4', '5', '6']) {
          cubit.addDigit(d);
        }
      },
      verify: (cubit) {
        expect(cubit.state.error, PinSetupError.trivialPin);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'accepts a non-trivial PIN and marks the step completed',
      build: () => PinSetupCubit(step: PinStep.create, pinHolder: holder),
      act: (cubit) {
        for (final d in ['4', '8', '1', '5', '9', '2']) {
          cubit.addDigit(d);
        }
      },
      verify: (cubit) {
        expect(cubit.state.completed, isTrue);
        expect(cubit.state.error, isNull);
        expect(holder.hasConfirmedPin, isFalse); // stored as "first entry", not confirmed yet
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'removeDigit removes the last digit',
      build: () => PinSetupCubit(step: PinStep.create, pinHolder: holder),
      act: (cubit) => cubit
        ..addDigit('4')
        ..addDigit('8')
        ..removeDigit(),
      expect: () => [
        const PinSetupState(digitCount: 1),
        const PinSetupState(digitCount: 2),
        const PinSetupState(digitCount: 1),
      ],
    );
  });

  group('PinSetupCubit (confirm step)', () {
    late OnboardingPinHolder holder;

    setUp(() {
      holder = OnboardingPinHolder();
      final create = PinSetupCubit(step: PinStep.create, pinHolder: holder);
      for (final d in ['4', '8', '1', '5', '9', '2']) {
        create.addDigit(d);
      }
      create.close();
    });

    blocTest<PinSetupCubit, PinSetupState>(
      'matching PIN completes the step and confirms it in the holder',
      build: () => PinSetupCubit(step: PinStep.confirm, pinHolder: holder),
      act: (cubit) {
        for (final d in ['4', '8', '1', '5', '9', '2']) {
          cubit.addDigit(d);
        }
      },
      verify: (cubit) {
        expect(cubit.state.completed, isTrue);
        expect(holder.hasConfirmedPin, isTrue);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'mismatched PIN shakes and increments the mismatch counter',
      build: () => PinSetupCubit(step: PinStep.confirm, pinHolder: holder),
      act: (cubit) {
        for (final d in ['1', '1', '1', '1', '1', '1']) {
          cubit.addDigit(d);
        }
      },
      verify: (cubit) {
        expect(cubit.state.error, PinSetupError.mismatch);
        expect(cubit.state.mismatchCount, 1);
        expect(cubit.state.tooManyMismatches, isFalse);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'sends tooManyMismatches after 3 wrong confirms',
      build: () => PinSetupCubit(step: PinStep.confirm, pinHolder: holder),
      act: (cubit) {
        for (var attempt = 0; attempt < 3; attempt++) {
          for (final d in ['1', '1', '1', '1', '1', '1']) {
            cubit.addDigit(d);
          }
        }
      },
      verify: (cubit) {
        expect(cubit.state.mismatchCount, 3);
        expect(cubit.state.tooManyMismatches, isTrue);
      },
    );
  });
}
