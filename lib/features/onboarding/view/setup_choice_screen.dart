import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/glass_card.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'pin_entry_navigation.dart';
import '../view_model/onboarding_flow_cubit.dart';

/// Create-vs-import choice. With [addMode] it is the entry of the
/// add-another-wallet flow (reached from the Wallets screen) rather than
/// first-run onboarding.
class SetupChoiceScreen extends StatefulWidget {
  const SetupChoiceScreen({super.key, this.addMode = false});

  final bool addMode;

  @override
  State<SetupChoiceScreen> createState() => _SetupChoiceScreenState();
}

class _SetupChoiceScreenState extends State<SetupChoiceScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.addMode) {
      context.read<OnboardingFlowCubit>().startAddingWallet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      title: l10n.setupChoiceTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.setupChoiceHeadline,
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.setupChoiceSubtitle, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xl),
          GlassCard(
            borderColor: AppColors.accent,
            onTap: () {
              context.read<OnboardingFlowCubit>().selectCreate();
              context.pushPinEntry();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppColors.accent),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        l10n.setupChoiceCreateBadge,
                        style: AppTypography.label.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.setupChoiceCreateTitle, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.setupChoiceCreateBody, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            onTap: () {
              context.read<OnboardingFlowCubit>().selectImport();
              context.push(Routes.importMethod);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.download_outlined, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.setupChoiceImportTitle, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.setupChoiceImportBody, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
      footer: Text(
        l10n.setupChoiceFooter,
        textAlign: TextAlign.center,
        style: AppTypography.caption,
      ),
    );
  }
}
