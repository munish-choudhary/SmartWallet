import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../view_model/onboarding_flow_cubit.dart';
import '../view_model/pin_setup_cubit.dart';
import 'pin_screen.dart';

/// Add-wallet flow only: proves the existing PIN, then carries on to the
/// backup warning (create) or the import commit (import). Biometrics are
/// not offered again — they stay as already configured for the vault.
class VerifyPinScreen extends StatelessWidget {
  const VerifyPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      step: PinStep.verify,
      onBack: () => context.pop(),
      onCompleted: () {
        final creating =
            context.read<OnboardingFlowCubit>().state.mode ==
            OnboardingMode.create;
        context.go(creating ? Routes.backupWarning : Routes.importing);
      },
      onTooManyMismatches: () {}, // not reachable on the verify step
    );
  }
}
