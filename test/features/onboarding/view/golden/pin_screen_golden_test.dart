import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/app/theme/app_theme.dart';
import 'package:smart_wallet/features/onboarding/data/onboarding_pin_holder.dart';
import 'package:smart_wallet/features/onboarding/view/pin_screen.dart';
import 'package:smart_wallet/features/onboarding/view_model/pin_setup_cubit.dart';
import 'package:smart_wallet/l10n/gen/app_localizations.dart';

Widget _harness(Widget child) {
  return RepositoryProvider<OnboardingPinHolder>(
    create: (_) => OnboardingPinHolder(),
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('Create Passcode screen — empty state', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(
        PinScreen(
          step: PinStep.create,
          onCompleted: () {},
          onTooManyMismatches: () {},
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(PinScreen),
      matchesGoldenFile('goldens/pin_screen_create_empty.png'),
    );
  });

  testWidgets('Create Passcode screen — 3 of 6 digits entered', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(
        PinScreen(
          step: PinStep.create,
          onCompleted: () {},
          onTooManyMismatches: () {},
        ),
      ),
    );
    await tester.tap(find.text('4'));
    await tester.tap(find.text('8'));
    await tester.tap(find.text('1'));
    await tester.pump();

    await expectLater(
      find.byType(PinScreen),
      matchesGoldenFile('goldens/pin_screen_create_partial.png'),
    );
  });
}
