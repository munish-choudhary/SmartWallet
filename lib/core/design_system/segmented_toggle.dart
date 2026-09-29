import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_durations.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// A two-option pill segmented control (e.g. "Secret Phrase" / "Private
/// Key", "12 Words" / "24 Words").
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T value, String label)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.keyFill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: _Segment(
                label: label,
                selected: value == selected,
                onTap: () => onChanged(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyStrong.copyWith(
            color: selected ? AppColors.onAccent : AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
