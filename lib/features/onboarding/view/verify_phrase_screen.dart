import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_durations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/glass_card.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../core/design_system/word_chip.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/onboarding_pin_holder.dart';
import '../view_model/onboarding_flow_cubit.dart';
import '../view_model/verify_phrase_cubit.dart';
import 'discard_wallet_dialog.dart';

class VerifyPhraseScreen extends StatelessWidget {
  const VerifyPhraseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VerifyPhraseCubit(vault: context.read<Vault>()),
      child: const _VerifyPhraseView(),
    );
  }
}

class _VerifyPhraseView extends StatefulWidget {
  const _VerifyPhraseView();

  @override
  State<_VerifyPhraseView> createState() => _VerifyPhraseViewState();
}

class _VerifyPhraseViewState extends State<_VerifyPhraseView>
    with ScreenProtectionMixin<_VerifyPhraseView> {
  Future<void> _handleBack() async {
    final left = await confirmDiscardPendingWallet(context);
    if (left && mounted) context.go(Routes.recoveryPhrase);
  }

  void _submit() {
    final pin = context.read<OnboardingPinHolder>().takeConfirmedPin();
    if (pin == null) return; // shouldn't happen; defensive
    final alsoEnableBiometrics =
        context.read<OnboardingFlowCubit>().state.biometricsEnabled;
    context.read<VerifyPhraseCubit>().submit(
      pin: pin,
      alsoEnableBiometrics: alsoEnableBiometrics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: BlocConsumer<VerifyPhraseCubit, VerifyPhraseState>(
        listenWhen: (prev, curr) =>
            curr.completedWalletId != prev.completedWalletId ||
            (curr.shake && !prev.shake),
        listener: (context, state) {
          if (state.shake) {
            HapticFeedback.heavyImpact();
            final cubit = context.read<VerifyPhraseCubit>();
            Future.delayed(AppDurations.medium, () {
              if (!cubit.isClosed) cubit.acknowledgeShake();
            });
          }
          final walletId = state.completedWalletId;
          if (walletId != null) {
            context.read<OnboardingFlowCubit>().setCompletedWalletId(walletId);
            context.go(Routes.creationSuccess);
          }
        },
        builder: (context, state) {
          return OnboardingScaffold(
            onBack: _handleBack,
            currentStep: 3,
            totalSteps: 3,
            body: state.loading
                ? const Center(child: CircularProgressIndicator())
                : _Body(state: state),
            footer: state.loading
                ? null
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PillButton(
                        label: l10n.verifyPhraseConfirm,
                        icon: Icons.check,
                        loading: state.submitting,
                        onPressed:
                            context.read<VerifyPhraseCubit>().isReadyToSubmit &&
                                !state.submitting
                            ? _submit
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => context.push(Routes.recoveryPhrase),
                        child: Text(l10n.verifyPhraseShowAgain),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final VerifyPhraseState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final answeredCount = state.answers.where((a) => a != null).length;
    final atEnd = state.currentIndex >= state.challenges.length;
    final currentChallenge = atEnd
        ? null
        : state.challenges[state.currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.verifyPhraseHeadline,
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.verifyPhraseSubtitle,
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.recoveryPhraseHeadline, style: AppTypography.label),
                  Text(
                    l10n.verifyPhraseProgress(
                      answeredCount,
                      state.challenges.length,
                    ),
                    style: AppTypography.label.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < state.challenges.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _ChallengeRow(
                  wordIndex: state.challenges[i].wordIndex,
                  answer: state.answers[i],
                  isActive: i == state.currentIndex,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (currentChallenge != null) ...[
          Text(l10n.verifyPhraseWordPrompt(currentChallenge.wordIndex),
              style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in currentChallenge.options)
                WordChip(
                  word: option,
                  onTap: () =>
                      context.read<VerifyPhraseCubit>().selectOption(option),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({
    required this.wordIndex,
    required this.answer,
    required this.isActive,
  });

  final int wordIndex;
  final String? answer;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = answer != null;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.keyFill,
            shape: BoxShape.circle,
          ),
          child: Text(
            '#$wordIndex',
            style: AppTypography.caption.copyWith(
              color: done ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            answer ?? l10n.verifyPhraseWordPrompt(wordIndex),
            style: AppTypography.bodyStrong,
          ),
        ),
        Icon(
          done ? Icons.check_circle : (isActive ? Icons.edit : Icons.lock_outline),
          size: 18,
          color: done
              ? AppColors.accent
              : (isActive ? AppColors.textSecondary : AppColors.textDisabled),
        ),
      ],
    );
  }
}
