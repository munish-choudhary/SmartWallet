import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_durations.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum WordChipState { normal, selected, correct, incorrect, disabled }

/// A single word chip — used both for the numbered recovery-phrase grid
/// and the tappable option chips on the verify-phrase screen.
///
/// When [blurred] is true the word itself is masked (shown as dots) rather
/// than rendered off-screen with a real Gaussian blur — this keeps the
/// "hidden" state deterministic for widget/golden tests while still
/// preventing the word from being read via `find.text`.
class WordChip extends StatefulWidget {
  const WordChip({
    super.key,
    required this.word,
    this.index,
    this.state = WordChipState.normal,
    this.onTap,
    this.blurred = false,
  });

  final String word;
  final int? index;
  final WordChipState state;
  final VoidCallback? onTap;
  final bool blurred;

  @override
  State<WordChip> createState() => _WordChipState();
}

class _WordChipState extends State<WordChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
  }

  @override
  void didUpdateWidget(covariant WordChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == WordChipState.incorrect &&
        oldWidget.state != WordChipState.incorrect) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, border, text) = switch (widget.state) {
      WordChipState.normal => (
          AppColors.keyFill,
          AppColors.surfaceBorder,
          AppColors.textPrimary,
        ),
      WordChipState.selected => (
          AppColors.surfaceElevated,
          AppColors.accent,
          AppColors.textPrimary,
        ),
      WordChipState.correct => (
          AppColors.accent.withValues(alpha: 0.18),
          AppColors.accent,
          AppColors.accent,
        ),
      WordChipState.incorrect => (
          AppColors.dangerSurface,
          AppColors.danger,
          AppColors.danger,
        ),
      WordChipState.disabled => (
          AppColors.keyFill.withValues(alpha: 0.4),
          Colors.transparent,
          AppColors.textDisabled,
        ),
    };

    final displayText = widget.blurred
        ? '•' * widget.word.length.clamp(3, 8)
        : widget.word;

    final content = Text(
      displayText,
      style: AppTypography.bodyStrong.copyWith(color: text),
      overflow: TextOverflow.ellipsis,
      semanticsLabel: widget.blurred ? 'hidden word' : null,
    );

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.index != null) ...[
            Text(
              widget.index!.toString().padLeft(2, '0'),
              style: AppTypography.label.copyWith(color: AppColors.accent),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: content),
        ],
      ),
    );

    final tappable = widget.onTap == null
        ? chip
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: widget.state == WordChipState.disabled
                  ? null
                  : widget.onTap,
              child: chip,
            ),
          );

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final dx = t == 0
            ? 0.0
            : 6 * (1 - t) * math.sin(t * 4 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: tappable,
    );
  }
}
