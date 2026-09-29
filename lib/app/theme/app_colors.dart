import 'package:flutter/material.dart';

/// Color tokens for Lexor Pocket's dark theme, distilled from the Figma
/// design (`Lexor`, fileKey xz94pzT4dRm4NBGnsicVnw). Screens must reference
/// these, never inline hex values.
abstract final class AppColors {
  // Backgrounds
  static const background = Color(0xFF0A0710);
  static const backgroundGlowPurple = Color(0xFF3A1E63);
  static const backgroundGlowMagenta = Color(0xFF4A1F3D);

  // Surfaces (glass cards)
  static const surface = Color(0xB3141019); // ~70% opacity dark
  static const surfaceElevated = Color(0xCC1B1622);
  static const surfaceBorder = Color(0x1FFFFFFF); // 12% white

  // Accent
  static const accent = Color(0xFFD7FF4D); // lime
  static const accentDim = Color(0xFF9AB238);
  static const onAccent = Color(0xFF0A0710);

  // Text
  static const textPrimary = Color(0xFFF5F3F7);
  static const textSecondary = Color(0xFFA79FB0);
  static const textTertiary = Color(0xFF6E6676);
  static const textDisabled = Color(0xFF4A4551);

  // Semantic
  static const danger = Color(0xFFFF6B6B);
  static const dangerSurface = Color(0x26FF6B6B);
  static const success = accent;
  static const warning = Color(0xFFFFC24D);

  // Keypad / interactive
  static const keyFill = Color(0xFF1C1722);
  static const keyFillPressed = Color(0xFF272030);
  static const dotEmpty = Color(0xFF322B3A);
}
