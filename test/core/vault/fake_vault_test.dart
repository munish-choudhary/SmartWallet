import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/pin.dart';
import 'package:smart_wallet/core/vault/vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';

Future<FakeVault> _buildVault() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final wordlist = await Bip39Wordlist.load();
  return FakeVault(wordlist: wordlist, random: Random(1));
}

void main() {
  group('pending-wallet flow', () {
    test('start -> phrase -> challenge -> confirm succeeds with right answers', () async {
      final vault = await _buildVault();

      final start = await vault.startPendingWallet(words: 12);
      expect(start.isOk, isTrue);

      final phrase = await vault.pendingPhraseForDisplay();
      expect(phrase.valueOrNull, hasLength(12));

      final challengeResult = await vault.verificationChallenge();
      expect(challengeResult.isOk, isTrue);
      final challenge = challengeResult.valueOrNull!;
      expect(challenge.challenges, hasLength(3));

      final words = phrase.valueOrNull!;
      final answers = [
        for (final c in challenge.challenges) words[c.wordIndex - 1],
      ];

      final confirm = await vault.confirmPendingWallet(
        answers: answers,
        pin: Pin('123456'),
      );
      expect(confirm.isOk, isTrue);
      expect(await vault.hasAnyWallet(), isTrue);

      final accounts = await vault.accounts(confirm.valueOrNull!);
      expect(accounts.isOk, isTrue);
    });

    test('confirm fails with wrong answers and does not persist a wallet', () async {
      final vault = await _buildVault();
      await vault.startPendingWallet();
      final words = (await vault.pendingPhraseForDisplay()).valueOrNull!;
      final challenge = (await vault.verificationChallenge()).valueOrNull!;

      final wrongAnswers = [
        for (final c in challenge.challenges)
          c.options.firstWhere((o) => o != words[c.wordIndex - 1]),
      ];

      final confirm = await vault.confirmPendingWallet(
        answers: wrongAnswers,
        pin: Pin('123456'),
      );
      expect(confirm.failureOrNull, const AppFailure.verificationFailed());
      expect(await vault.hasAnyWallet(), isFalse);
    });

    test('pendingPhraseForDisplay fails with no pending wallet', () async {
      final vault = await _buildVault();
      final result = await vault.pendingPhraseForDisplay();
      expect(result.failureOrNull, const AppFailure.noPendingWallet());
    });

    test('discardPendingWallet clears the pending state', () async {
      final vault = await _buildVault();
      await vault.startPendingWallet();
      vault.discardPendingWallet();
      final result = await vault.pendingPhraseForDisplay();
      expect(result.failureOrNull, const AppFailure.noPendingWallet());
    });
  });

  group('validation', () {
    test('validateMnemonic accepts real wordlist words, rejects unknown ones', () async {
      final vault = await _buildVault();
      await vault.startPendingWallet();
      final words = (await vault.pendingPhraseForDisplay()).valueOrNull!;

      final valid = await vault.validateMnemonic(words.join(' '));
      expect(valid.isOk, isTrue);

      final invalid = await vault.validateMnemonic(
        'notarealword ${words.skip(1).join(' ')}',
      );
      expect(invalid.failureOrNull, const AppFailure.invalidMnemonic());
    });

    test('validatePrivateKey enforces format per chain family', () async {
      final vault = await _buildVault();
      final hex64 = 'a' * 64;
      final evmValid = await vault.validatePrivateKey(hex64, ChainFamily.evm);
      expect(evmValid.isOk, isTrue);

      final evmWithPrefix = await vault.validatePrivateKey(
        '0x$hex64',
        ChainFamily.evm,
      );
      expect(evmWithPrefix.isOk, isTrue);

      final tooShort = await vault.validatePrivateKey('abc', ChainFamily.evm);
      expect(tooShort.failureOrNull, const AppFailure.invalidPrivateKey());
    });
  });

  group('unlock / pin', () {
    test('wrong pin fails, correct pin unlocks', () async {
      final vault = await _buildVault();
      await vault.createWallet(pin: Pin('123456'));
      vault.lock();

      final wrong = await vault.unlock(Pin('000000'));
      expect(wrong.failureOrNull, const AppFailure.wrongPin());

      final right = await vault.unlock(Pin('123456'));
      expect(right.isOk, isTrue);
    });
  });
}
