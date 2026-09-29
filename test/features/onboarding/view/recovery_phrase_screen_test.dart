import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
import 'package:smart_wallet/features/onboarding/view/recovery_phrase_screen.dart';
import 'package:smart_wallet/l10n/gen/app_localizations.dart';

void main() {
  testWidgets(
    'RecoveryPhraseScreen loads the pending phrase into local state and '
    'clears it on dispose',
    (tester) async {
      final wordlist = await Bip39Wordlist.load();
      final vault = FakeVault(wordlist: wordlist);
      await vault.startPendingWallet(words: 12);

      final key = GlobalKey<RecoveryPhraseScreenState>();

      await tester.pumpWidget(
        RepositoryProvider<Vault>.value(
          value: vault,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RecoveryPhraseScreen(key: key),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(key.currentState!.wordsForTest, hasLength(12));

      final state = key.currentState!;
      await tester.pumpWidget(const SizedBox.shrink());

      expect(state.wordsForTest, isNull);
    },
  );
}
