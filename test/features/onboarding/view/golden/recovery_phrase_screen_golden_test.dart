import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/app/theme/app_theme.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
import 'package:smart_wallet/features/onboarding/view/recovery_phrase_screen.dart';
import 'package:smart_wallet/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('Recovery Phrase screen — words hidden by default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final wordlist = await Bip39Wordlist.load();
    // Fixed seed so the golden is deterministic across runs.
    final vault = FakeVault(wordlist: wordlist, random: Random(42));
    await vault.startPendingWallet(words: 12);

    await tester.pumpWidget(
      RepositoryProvider<Vault>.value(
        value: vault,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RecoveryPhraseScreen(),
        ),
      ),
    );
    await tester.pump(); // let pendingPhraseForDisplay() resolve
    await tester.pump();

    await expectLater(
      find.byType(RecoveryPhraseScreen),
      matchesGoldenFile('goldens/recovery_phrase_screen_hidden.png'),
    );
  });
}
