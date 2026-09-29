import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'glass_card.dart';

/// A checkable info row used on the Backup Warning screen's three
/// acknowledgement items.
class CheckboxListItem extends StatelessWidget {
  const CheckboxListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: checked ? AppColors.accent : AppColors.surfaceBorder,
      onTap: () => onChanged(!checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Checkbox(checked: checked),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyStrong),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.accent : AppColors.textTertiary,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: AppColors.onAccent)
          : null,
    );
  }
}
