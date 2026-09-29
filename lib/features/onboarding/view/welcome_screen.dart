import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/ambient_background.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../l10n/gen/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _float,
                  builder: (context, child) {
                    final dy = reduceMotion ? 0.0 : (_float.value - 0.5) * 12;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 80,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.currency_bitcoin,
                      size: 96,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  l10n.welcomeEyebrow,
                  style: AppTypography.label.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.welcomeHeadline,
                  textAlign: TextAlign.center,
                  style: AppTypography.displayLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const Spacer(),
                PillButton(
                  label: l10n.welcomeGetStarted,
                  icon: Icons.arrow_forward,
                  onPressed: () => context.push(Routes.setupChoice),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.welcomeTerms,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
