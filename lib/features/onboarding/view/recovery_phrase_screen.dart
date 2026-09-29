import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/glass_card.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../core/design_system/warning_card.dart';
import '../../../core/design_system/word_chip.dart';
import '../../../core/result/result.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'discard_wallet_dialog.dart';

class RecoveryPhraseScreen extends StatefulWidget {
  const RecoveryPhraseScreen({super.key});

  @override
  State<RecoveryPhraseScreen> createState() => RecoveryPhraseScreenState();
}

/// Not private — a widget test asserts words are cleared on dispose via a
/// `GlobalKey<RecoveryPhraseScreenState>` and [wordsForTest].
class RecoveryPhraseScreenState extends State<RecoveryPhraseScreen>
    with ScreenProtectionMixin<RecoveryPhraseScreen> {
  // Local widget state only — per this feature's security spec, the
  // phrase must never enter Cubit/Bloc state. Cleared in dispose().
  List<String>? _words;
  bool _loading = true;
  bool _revealed = false;

  @visibleForTesting
  List<String>? get wordsForTest => _words;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<Vault>().pendingPhraseForDisplay();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _words = result.valueOrNull;
    });
  }

  Future<void> _copyToClipboard(List<String> words) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: words.join(' ')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.recoveryPhraseCopiedSnackbar)),
    );
    unawaited(
      Future.delayed(
        const Duration(seconds: 60),
        () => Clipboard.setData(const ClipboardData(text: '')),
      ),
    );
  }

  Future<void> _handleBack() async {
    final left = await confirmDiscardPendingWallet(context);
    if (left && mounted) context.go(Routes.backupWarning);
  }

  @override
  void dispose() {
    _words = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final words = _words;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: OnboardingScaffold(
        onBack: _handleBack,
        currentStep: 2,
        totalSteps: 3,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : words == null
            ? Center(child: Text(l10n.recoveryPhraseTitle))
            : _PhraseBody(
                words: words,
                revealed: _revealed,
                onToggleReveal: () => setState(() => _revealed = !_revealed),
                onCopy: () => _copyToClipboard(words),
              ),
        footer: words == null
            ? null
            : PillButton(
                label: l10n.recoveryPhraseSaved,
                icon: Icons.arrow_forward,
                onPressed: () => context.push(Routes.verifyPhrase),
              ),
      ),
    );
  }
}

class _PhraseBody extends StatelessWidget {
  const _PhraseBody({
    required this.words,
    required this.revealed,
    required this.onToggleReveal,
    required this.onCopy,
  });

  final List<String> words;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.recoveryPhraseHeadline,
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.recoveryPhraseSubtitle(words.length),
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onToggleReveal,
            icon: Icon(
              revealed ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: AppColors.accent,
            ),
            label: Text(
              revealed ? l10n.recoveryPhraseHide : l10n.recoveryPhraseReveal,
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        GlassCard(
          child: Column(
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < words.length; i++)
                    FractionallySizedBox(
                      widthFactor: 0.46,
                      child: WordChip(
                        word: words[i],
                        index: i + 1,
                        blurred: !revealed,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: l10n.recoveryPhraseCopy,
          variant: PillButtonVariant.secondary,
          icon: Icons.copy_outlined,
          onPressed: revealed ? onCopy : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        WarningCard(
          title: l10n.recoveryPhraseScreenshotWarningTitle,
          subtitle: l10n.recoveryPhraseScreenshotWarningBody,
        ),
      ],
    );
  }
}
