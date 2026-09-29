import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_durations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/numeric_keypad.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pin_dots.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/onboarding_pin_holder.dart';
import '../view_model/pin_setup_cubit.dart';

/// Shared body for both the Create Passcode and Confirm Passcode screens
/// — same UI, different [PinSetupCubit.step] and completion behavior.
class PinScreen extends StatelessWidget {
  const PinScreen({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.onTooManyMismatches,
    this.onBack,
  });

  final PinStep step;
  final VoidCallback onCompleted;
  final VoidCallback onTooManyMismatches;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PinSetupCubit(
        step: step,
        pinHolder: context.read<OnboardingPinHolder>(),
      ),
      child: _PinScreenView(
        step: step,
        onCompleted: onCompleted,
        onTooManyMismatches: onTooManyMismatches,
        onBack: onBack,
      ),
    );
  }
}

class _PinScreenView extends StatefulWidget {
  const _PinScreenView({
    required this.step,
    required this.onCompleted,
    required this.onTooManyMismatches,
    this.onBack,
  });

  final PinStep step;
  final VoidCallback onCompleted;
  final VoidCallback onTooManyMismatches;
  final VoidCallback? onBack;

  @override
  State<_PinScreenView> createState() => _PinScreenViewState();
}

class _PinScreenViewState extends State<_PinScreenView>
    with ScreenProtectionMixin<_PinScreenView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<PinSetupCubit, PinSetupState>(
      listenWhen: (prev, curr) =>
          curr.completed != prev.completed ||
          curr.tooManyMismatches != prev.tooManyMismatches ||
          (curr.shake && !prev.shake),
      listener: (context, state) {
        if (state.shake) {
          HapticFeedback.heavyImpact();
          final cubit = context.read<PinSetupCubit>();
          Future.delayed(AppDurations.medium, () {
            if (!cubit.isClosed) cubit.acknowledgeShake();
          });
        }
        if (state.tooManyMismatches) {
          widget.onTooManyMismatches();
          return;
        }
        if (state.completed) {
          widget.onCompleted();
        }
      },
      builder: (context, state) {
        final title = widget.step == PinStep.create
            ? l10n.pinCreateTitle
            : l10n.pinConfirmTitle;
        final subtitle = widget.step == PinStep.create
            ? l10n.pinCreateSubtitle
            : l10n.pinConfirmSubtitle;
        final errorText = switch (state.error) {
          PinSetupError.trivialPin => l10n.pinTrivialError,
          PinSetupError.mismatch => l10n.pinMismatchError,
          null => null,
        };

        return OnboardingScaffold(
          title: title,
          onBack: widget.onBack,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PinDots(
                length: state.maxLength,
                filled: state.digitCount,
                shake: state.shake,
                error: state.error != null,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 20,
                child: Text(
                  errorText ??
                      l10n.pinDigitsEntered(state.digitCount, state.maxLength),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: errorText != null ? AppColors.danger : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              NumericKeypad(
                onDigit: (d) => context.read<PinSetupCubit>().addDigit(d),
                onDelete: () => context.read<PinSetupCubit>().removeDigit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.pinNeverShare,
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
          ),
        );
      },
    );
  }
}
