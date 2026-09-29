import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum PillButtonVariant { primary, secondary, outline }

/// The large pill-shaped call-to-action button used across every
/// onboarding screen in Figma.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final Color background;
    final Color foreground;
    final BorderSide side;
    switch (variant) {
      case PillButtonVariant.primary:
        background = enabled ? AppColors.accent : AppColors.dotEmpty;
        foreground = enabled ? AppColors.onAccent : AppColors.textDisabled;
        side = BorderSide.none;
      case PillButtonVariant.secondary:
        background = AppColors.surfaceElevated;
        foreground = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.surfaceBorder);
      case PillButtonVariant.outline:
        background = Colors.transparent;
        foreground = enabled ? AppColors.accent : AppColors.textDisabled;
        side = BorderSide(
          color: enabled ? AppColors.accent : AppColors.surfaceBorder,
        );
    }

    return SizedBox(
      height: 56,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: side,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ] else ...[
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.buttonLabel.copyWith(
                        color: foreground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(icon, size: 20, color: foreground),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
