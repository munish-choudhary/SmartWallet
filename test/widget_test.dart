import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/app/app.dart';
import 'package:smart_wallet/app/theme/app_durations.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';

void main() {
  testWidgets('SmartWalletApp boots to the splash screen, then Welcome', (
    WidgetTester tester,
  ) async {
    final wordlist = await Bip39Wordlist.load();
    final vault = FakeVault(wordlist: wordlist);

    await tester.pumpWidget(SmartWalletApp(vault: vault, wordlist: wordlist));
    await tester.pump();

    expect(find.text('Lexor Pocket'), findsOneWidget);

    // Let the splash screen's timed navigation fire so no Timer leaks
    // past the end of the test.
    await tester.pump(AppDurations.splash + const Duration(milliseconds: 100));
    await tester.pump();
  });
}
