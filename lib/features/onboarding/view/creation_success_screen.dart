import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../view_model/onboarding_flow_cubit.dart';
import 'success_check_badge.dart';

class CreationSuccessScreen extends StatefulWidget {
  const CreationSuccessScreen({super.key});

  @override
  State<CreationSuccessScreen> createState() => _CreationSuccessScreenState();
}

class _CreationSuccessScreenState extends State<CreationSuccessScreen> {
  @override
  void initState() {
    super.initState();
    if (!MediaQuery.of(context).disableAnimations) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.huge),
          const Center(child: SuccessCheckBadge()),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.creationSuccessTitle,
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.creationSuccessSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
        ],
      ),
      footer: PillButton(
        label: l10n.creationSuccessGoToWallet,
        icon: Icons.arrow_forward,
        onPressed: () {
          context.read<OnboardingFlowCubit>().reset();
          context.go(Routes.portfolio);
        },
      ),
    );
  }
}
