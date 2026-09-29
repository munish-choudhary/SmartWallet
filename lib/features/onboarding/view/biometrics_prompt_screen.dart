import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/icon_badge.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../view_model/onboarding_flow_cubit.dart';

/// Records the user's biometrics preference on [OnboardingFlowCubit] —
/// the actual `Vault.enableBiometrics` call happens later, at the point
/// the wallet is actually persisted (Verify Phrase's confirm step for
/// Create, the Importing step for Import), using the same [Pin] instance
/// used to create/import the wallet.
class BiometricsPromptScreen extends StatelessWidget {
  const BiometricsPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.huge),
          const Center(
            child: IconBadge(icon: Icons.fingerprint, size: 72),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.biometricsTitle,
            textAlign: TextAlign.center,
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.biometricsSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(
            label: l10n.biometricsEnable,
            icon: Icons.fingerprint,
            onPressed: () {
              context.read<OnboardingFlowCubit>().setBiometricsEnabled(true);
              _continue(context);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          PillButton(
            label: l10n.biometricsSkip,
            variant: PillButtonVariant.secondary,
            onPressed: () {
              context.read<OnboardingFlowCubit>().setBiometricsEnabled(false);
              _continue(context);
            },
          ),
        ],
      ),
    );
  }

  void _continue(BuildContext context) {
    final mode = context.read<OnboardingFlowCubit>().state.mode;
    context.go(
      mode == OnboardingMode.create
          ? Routes.backupWarning
          : Routes.importing,
    );
  }
}
