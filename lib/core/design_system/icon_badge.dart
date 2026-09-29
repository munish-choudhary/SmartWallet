import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The circular glowing icon badge used at the top of prompt/success
/// screens (biometrics, backup warning, creation success).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 64,
    this.color = AppColors.accent,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
