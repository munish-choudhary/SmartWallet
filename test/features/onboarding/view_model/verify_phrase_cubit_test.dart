import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/pin.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
import 'package:smart_wallet/features/onboarding/view_model/verify_phrase_cubit.dart';

void main() {
  late Bip39Wordlist wordlist;
  late FakeVault vault;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    wordlist = await Bip39Wordlist.load();
  });

  setUp(() async {
    vault = FakeVault(wordlist: wordlist);
    await vault.startPendingWallet(words: 12);
  });

  group('VerifyPhraseCubit', () {
    test('loads a 3-slot challenge on construction', () async {
      final cubit = VerifyPhraseCubit(vault: vault);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.challenges, hasLength(3));
      expect(cubit.state.answers, hasLength(3));
      await cubit.close();
    });

    test('selectOption fills the current answer and advances the index', () async {
      final cubit = VerifyPhraseCubit(vault: vault);
      await Future<void>.delayed(Duration.zero);

      cubit.selectOption(cubit.state.challenges[0].options.first);

      expect(cubit.state.answers[0], cubit.state.challenges[0].options.first);
      expect(cubit.state.currentIndex, 1);
      await cubit.close();
    });

    test('submit with correct answers persists the wallet', () async {
      final cubit = VerifyPhraseCubit(vault: vault);
      await Future<void>.delayed(Duration.zero);

      final words = (await vault.pendingPhraseForDisplay()).valueOrNull!;
      for (final challenge in cubit.state.challenges) {
        cubit.selectOption(words[challenge.wordIndex - 1]);
      }

      await cubit.submit(pin: Pin('123456'), alsoEnableBiometrics: false);

      expect(cubit.state.completedWalletId, isNotNull);
      expect(await vault.hasAnyWallet(), isTrue);
      await cubit.close();
    });

    test('submit with a wrong answer shakes and reloads a fresh challenge', () async {
      final cubit = VerifyPhraseCubit(vault: vault);
      await Future<void>.delayed(Duration.zero);

      final firstChallenges = cubit.state.challenges;
      final words = (await vault.pendingPhraseForDisplay()).valueOrNull!;
      for (final challenge in firstChallenges) {
        // Pick a deliberately wrong option for every slot.
        final wrong = challenge.options.firstWhere(
          (o) => o != words[challenge.wordIndex - 1],
        );
        cubit.selectOption(wrong);
      }

      await cubit.submit(pin: Pin('123456'), alsoEnableBiometrics: false);

      expect(cubit.state.completedWalletId, isNull);
      expect(cubit.state.shake, isTrue);
      expect(await vault.hasAnyWallet(), isFalse);
      await cubit.close();
    });
  });
}
