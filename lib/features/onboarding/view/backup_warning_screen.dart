import 'dart:async' show unawaited;


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/checkbox_list_item.dart';
import '../../../core/design_system/icon_badge.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../core/result/result.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../view_model/onboarding_flow_cubit.dart';

class BackupWarningScreen extends StatefulWidget {
  const BackupWarningScreen({super.key});

  @override
  State<BackupWarningScreen> createState() => _BackupWarningScreenState();
}

class _BackupWarningScreenState extends State<BackupWarningScreen> {
  final _checked = [false, false, false];

  bool get _allChecked => _checked.every((c) => c);

  /// Generates the pending mnemonic (held in the vault, never in state)
  /// that the recovery-phrase and verify screens read from.
  Future<void> _continue() async {
    final wordCount = context.read<OnboardingFlowCubit>().state.wordCount;
    final started = await context.read<Vault>().startPendingWallet(
      words: wordCount,
    );
    if (!mounted) return;
    if (started.isOk) unawaited(context.push(Routes.recoveryPhrase));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wordCount = context.watch<OnboardingFlowCubit>().state.wordCount;

    return OnboardingScaffold(
      onBack: () => context.pop(),
      currentStep: 1,
      totalSteps: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Center(child: IconBadge(icon: Icons.shield_outlined)),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.backupWarningTitle,
            textAlign: TextAlign.center,
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.backupWarningBody(wordCount),
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xxl),
          CheckboxListItem(
            title: l10n.backupWarningItem1Title,
            subtitle: l10n.backupWarningItem1Body,
            checked: _checked[0],
            onChanged: (v) => setState(() => _checked[0] = v),
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListItem(
            title: l10n.backupWarningItem2Title,
            subtitle: l10n.backupWarningItem2Body,
            checked: _checked[1],
            onChanged: (v) => setState(() => _checked[1] = v),
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListItem(
            title: l10n.backupWarningItem3Title,
            subtitle: l10n.backupWarningItem3Body,
            checked: _checked[2],
            onChanged: (v) => setState(() => _checked[2] = v),
          ),
        ],
      ),
      footer: PillButton(
        label: l10n.backupWarningContinue,
        icon: Icons.arrow_forward,
        onPressed: _allChecked ? () => unawaited(_continue()) : null,
      ),
    );
  }
}
