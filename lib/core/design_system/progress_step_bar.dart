import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_durations.dart';
import '../../app/theme/app_spacing.dart';

/// The thin segmented progress bar shown at the top of multi-step
/// onboarding screens (e.g. "STEP 2 OF 3" on Recovery Phrase / Verify
/// Phrase).
class ProgressStepBar extends StatelessWidget {
  const ProgressStepBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < totalSteps; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.medium,
              height: 4,
              decoration: BoxDecoration(
                color: i < currentStep
                    ? AppColors.accent
                    : AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
