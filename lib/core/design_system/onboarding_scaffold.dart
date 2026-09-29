import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'ambient_background.dart';
import 'circle_icon_button.dart';
import 'progress_step_bar.dart';

/// The shared shell for onboarding screens: ambient background, an
/// optional back button + title bar, an optional step progress bar, and
/// scrollable, keyboard-safe body content.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.body,
    this.title,
    this.onBack,
    this.trailing,
    this.currentStep,
    this.totalSteps,
    this.footer,
  });

  final Widget body;
  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final int? currentStep;
  final int? totalSteps;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              if (onBack != null || title != null || trailing != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (onBack != null)
                        CircleIconButton(
                          icon: Icons.arrow_back,
                          onPressed: onBack,
                          semanticLabel: 'Back',
                        )
                      else
                        const SizedBox(width: 40),
                      Expanded(
                        child: title == null
                            ? const SizedBox.shrink()
                            : Text(
                                title!,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      trailing ?? const SizedBox(width: 40),
                    ],
                  ),
                ),
              if (currentStep != null && totalSteps != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: ProgressStepBar(
                    currentStep: currentStep!,
                    totalSteps: totalSteps!,
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                        vertical: AppSpacing.lg,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight -
                              AppSpacing.lg * 2,
                        ),
                        child: body,
                      ),
                    );
                  },
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                  ),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
