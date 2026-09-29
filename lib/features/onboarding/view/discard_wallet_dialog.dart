import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/onboarding_pin_holder.dart';

/// Shown from the Recovery Phrase and Verify Phrase screens' back
/// navigation, per CLAUDE.md's onboarding spec: "Leaving will discard
/// this wallet." Returns true if the user confirmed leaving, having
/// already called [Vault.discardPendingWallet] and cleared the PIN
/// holder.
Future<bool> confirmDiscardPendingWallet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text(l10n.recoveryPhraseLeaveDialogTitle),
      content: Text(l10n.recoveryPhraseLeaveDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.recoveryPhraseLeaveDialogCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.recoveryPhraseLeaveDialogConfirm,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<Vault>().discardPendingWallet();
    context.read<OnboardingPinHolder>().discardAll();
  }
  return confirmed ?? false;
}
