import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// The red/amber warning banner (e.g. "Do not take screenshots", "Never
/// paste private keys on untrusted devices").
class WarningCard extends StatelessWidget {
  const WarningCard({
    super.key,
    required this.title,
    this.subtitle,
    this.severity = WarningSeverity.danger,
  });

  final String title;
  final String? subtitle;
  final WarningSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = severity == WarningSeverity.danger
        ? AppColors.danger
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyStrong.copyWith(color: color),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum WarningSeverity { danger, caution }
