import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/glass_card.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../core/design_system/segmented_toggle.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../view_model/onboarding_flow_cubit.dart';

class ImportMethodScreen extends StatelessWidget {
  const ImportMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kind =
        context.watch<OnboardingFlowCubit>().state.importKind ??
        ImportKind.phrase;

    return OnboardingScaffold(
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.importMethodTitle,
            textAlign: TextAlign.center,
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.importMethodSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          SegmentedToggle<ImportKind>(
            options: [
              (ImportKind.phrase, l10n.importMethodPhraseTab),
              (ImportKind.privateKey, l10n.importMethodKeyTab),
            ],
            selected: kind,
            onChanged: (k) =>
                context.read<OnboardingFlowCubit>().setImportKind(k),
          ),
          const SizedBox(height: AppSpacing.xl),
          GlassCard(
            borderColor: kind == ImportKind.phrase
                ? AppColors.accent
                : AppColors.surfaceBorder,
            onTap: () => context.read<OnboardingFlowCubit>().setImportKind(
              ImportKind.phrase,
            ),
            child: _MethodTile(
              icon: Icons.key_outlined,
              title: l10n.importMethodPhraseCardTitle,
              body: l10n.importMethodPhraseCardBody,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            borderColor: kind == ImportKind.privateKey
                ? AppColors.accent
                : AppColors.surfaceBorder,
            onTap: () => context.read<OnboardingFlowCubit>().setImportKind(
              ImportKind.privateKey,
            ),
            child: _MethodTile(
              icon: Icons.vpn_key_outlined,
              title: l10n.importMethodKeyCardTitle,
              body: l10n.importMethodKeyCardBody,
            ),
          ),
        ],
      ),
      footer: PillButton(
        label: kind == ImportKind.phrase
            ? l10n.importMethodContinuePhrase
            : l10n.importMethodContinueKey,
        icon: Icons.arrow_forward,
        onPressed: () => context.push(
          kind == ImportKind.phrase
              ? Routes.importPhrase
              : Routes.importPrivateKey,
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyStrong),
              const SizedBox(height: AppSpacing.xs),
              Text(body, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }
}
