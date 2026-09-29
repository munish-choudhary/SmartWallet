import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The circular glass icon button used for back navigation and other
/// single-icon actions in the top bar across onboarding screens.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textPrimary,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
