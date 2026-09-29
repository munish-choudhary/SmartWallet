import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens. Figma uses a bold grotesque display face for
/// headlines and a plain sans for body text; until real font assets are
/// supplied we use the platform default sans with matching weights/sizes
/// rather than guessing a specific font family.
abstract final class AppTypography {
  static const _base = TextStyle(color: AppColors.textPrimary, height: 1.3);

  static final displayLarge = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static final headline = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static final title = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static final body = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static final bodyStrong = body.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final label = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  static final caption = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static final buttonLabel = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onAccent,
  );

  static final mono = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
