import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/pin.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
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

  group('PinSetupCubit (verify step)', () {
    late OnboardingPinHolder holder;
    late FakeVault vault;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      holder = OnboardingPinHolder();
      vault = FakeVault(wordlist: await Bip39Wordlist.load());
      await vault.createWallet(pin: Pin('481592'));
    });

    Future<void> enter(PinSetupCubit cubit, List<String> digits) async {
      digits.forEach(cubit.addDigit);
      // The vault check is async; let it settle.
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    test('the existing PIN completes the step and is handed to the holder',
        () async {
      final cubit = PinSetupCubit(
        step: PinStep.verify,
        pinHolder: holder,
        vault: vault,
      );
      await enter(cubit, ['4', '8', '1', '5', '9', '2']);

      expect(cubit.state.completed, isTrue);
      expect(cubit.state.verifying, isFalse);
      expect(holder.hasConfirmedPin, isTrue);
      await cubit.close();
    });

    test('a wrong PIN shakes, clears the buffer and stores nothing', () async {
      final cubit = PinSetupCubit(
        step: PinStep.verify,
        pinHolder: holder,
        vault: vault,
      );
      await enter(cubit, ['1', '1', '1', '1', '1', '1']);

      expect(cubit.state.completed, isFalse);
      expect(cubit.state.error, PinSetupError.wrongPin);
      expect(cubit.state.shake, isTrue);
      expect(cubit.state.digitCount, 0);
      expect(holder.hasConfirmedPin, isFalse);
      await cubit.close();
    });

    test('ignores keypad input while the check is running', () async {
      final cubit = PinSetupCubit(
        step: PinStep.verify,
        pinHolder: holder,
        vault: vault,
      );
      ['4', '8', '1', '5', '9', '2'].forEach(cubit.addDigit);
      expect(cubit.state.verifying, isTrue);
      cubit.addDigit('7');
      expect(cubit.state.digitCount, 6);
      await Future<void>.delayed(const Duration(seconds: 1));
      await cubit.close();
    });
  });
}
