import 'package:flutter/material.dart';

/// Colors for the Settings/Security screens, taken from the Figma
/// "Auto-Lock Timer" / "Export Private Key" frames (same palette the
/// Portfolio screen uses inline).
abstract final class SettingsPalette {
  static const background = Color(0xFF131317);
  static const card = Color(0xFF1F1F23);
  static const cardAlt = Color(0xFF2A292E);
  static const cardMuted = Color(0xFF1B1B1F);
  static const chip = Color(0xFF353439);
  static const accent = Color(0xFFD4EE6B);
  static const onAccent = Color(0xFF2A3400);
  static const textPrimary = Color(0xFFE4E1E7);
  static const textSecondary = Color(0xFFC6C8B2);
  static const danger = Color(0xFFFFB4AB);
  static const dangerText = Color(0xFFFFDAD6);
  static const dangerBadge = Color(0xFF93000A);
  static const dangerOnBadge = Color(0xFF690005);
  static const keyPanel = Color(0xFF0E0E12);
  static const glowPurple = Color(0xFF7255A5);

  // Help & About frame.
  static const onAccentMuted = Color(0xFF596C00);
  static const iconMuted = Color(0xFFC6C6C7);
  static const glowGrey = Color(0xFF353439);

  // Translucent "glass" fills. Static alpha instead of live blur on list
  // content, per CLAUDE.md's performance rules.
  static const glassCard = Color.fromRGBO(31, 31, 35, 0.7);
  static const glassCardSoft = Color.fromRGBO(31, 31, 35, 0.6);
  static const glassBanner = Color.fromRGBO(42, 41, 46, 0.6);
  static const glassChip = Color.fromRGBO(42, 41, 46, 0.8);
  static const textFaint = Color.fromRGBO(198, 200, 178, 0.7);
}
