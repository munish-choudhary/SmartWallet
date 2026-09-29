import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../view_model/pin_setup_cubit.dart';
import 'pin_screen.dart';

class ConfirmPinScreen extends StatelessWidget {
  const ConfirmPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      step: PinStep.confirm,
      onBack: () => context.pop(),
      onCompleted: () => context.push(Routes.biometricsPrompt),
      // Per CLAUDE.md's onboarding spec: 3 mismatches sends the user back
      // to re-enter the PIN from scratch.
      onTooManyMismatches: () => context.go(Routes.createPin),
    );
  }
}
