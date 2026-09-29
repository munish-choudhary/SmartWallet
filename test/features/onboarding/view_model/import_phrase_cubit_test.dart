import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
import 'package:smart_wallet/features/onboarding/view_model/import_phrase_cubit.dart';

void main() {
  late Bip39Wordlist wordlist;
  late FakeVault vault;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    wordlist = await Bip39Wordlist.load();
  });

  setUp(() {
    vault = FakeVault(wordlist: wordlist);
  });

  group('ImportPhraseCubit', () {
    blocTest<ImportPhraseCubit, ImportPhraseState>(
      'flags a word not in the wordlist as invalid',
      build: () => ImportPhraseCubit(vault: vault, wordlist: wordlist),
      act: (cubit) => cubit.pasteAll('notarealword abandon'),
      verify: (cubit) {
        expect(cubit.state.invalidIndices, contains(0));
        expect(cubit.state.invalidIndices, isNot(contains(1)));
        expect(cubit.state.checksumValid, isFalse);
      },
    );

    blocTest<ImportPhraseCubit, ImportPhraseState>(
      'normalizes pasted text (trim, lowercase, collapse spaces)',
      build: () => ImportPhraseCubit(vault: vault, wordlist: wordlist),
      act: (cubit) => cubit.pasteAll('  Abandon   ABILITY  '),
      verify: (cubit) {
        expect(cubit.state.words[0], 'abandon');
        expect(cubit.state.words[1], 'ability');
      },
    );

    blocTest<ImportPhraseCubit, ImportPhraseState>(
      'runs full checksum validation once all 12 words are valid wordlist words',
      build: () => ImportPhraseCubit(vault: vault, wordlist: wordlist),
      act: (cubit) async {
        // A pending wallet's mnemonic is guaranteed to be 12 valid
        // wordlist words (though not a real BIP-39 checksum — see
        // FakeVault's header) which is exactly what validateMnemonic
        // checks against here too, so this exercises the full pipeline
        // deterministically without hardcoding words that may not exist.
        await vault.startPendingWallet(words: 12);
        final words = (await vault.pendingPhraseForDisplay()).valueOrNull!;
        cubit.pasteAll(words.join(' '));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state.invalidIndices, isEmpty);
        expect(cubit.state.checksumValid, isTrue);
      },
    );

    blocTest<ImportPhraseCubit, ImportPhraseState>(
      'clear resets to an empty phrase',
      build: () => ImportPhraseCubit(vault: vault, wordlist: wordlist),
      act: (cubit) {
        cubit.pasteAll('abandon ability');
        cubit.clear();
      },
      verify: (cubit) {
        expect(cubit.state.words.every((w) => w.isEmpty), isTrue);
        expect(cubit.state.checksumValid, isFalse);
      },
    );

    blocTest<ImportPhraseCubit, ImportPhraseState>(
      'setWordCount switches between 12 and 24 words',
      build: () => ImportPhraseCubit(vault: vault, wordlist: wordlist),
      act: (cubit) => cubit.setWordCount(24),
      verify: (cubit) {
        expect(cubit.state.wordCount, 24);
        expect(cubit.state.words, hasLength(24));
      },
    );
  });
}
