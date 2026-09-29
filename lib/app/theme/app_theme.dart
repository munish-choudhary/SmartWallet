import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: AppColors.surface,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTypography.displayLarge,
        headlineMedium: AppTypography.headline,
        titleMedium: AppTypography.title,
        bodyMedium: AppTypography.body,
        bodyLarge: AppTypography.bodyStrong,
        labelLarge: AppTypography.label,
        bodySmall: AppTypography.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
