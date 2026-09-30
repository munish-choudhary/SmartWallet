import 'package:flutter/material.dart';

/// Colors for the "Lexor" Figma frames (Connected App, dApp browser,
/// WalletConnect flows). Same palette the Portfolio/Settings screens use
/// inline — centralised here so new screens don't copy hex values again.
abstract final class LexorPalette {
  static const background = Color(0xFF131317);

  /// Glass card fill. Static translucency, not a live blur — per CLAUDE.md
  /// live `BackdropFilter` is reserved for headers, sheets and the tab bar.
  static const card = Color.fromRGBO(31, 31, 35, 0.7);
  static const cardSolid = Color(0xFF1F1F23);
  static const sheet = Color(0xFF1B1B1F);
  static const inset = Color.fromRGBO(27, 27, 31, 0.4);

  static const chip = Color(0xFF2A292E);
  static const chipSoft = Color.fromRGBO(42, 41, 46, 0.5);
  static const chipMuted = Color.fromRGBO(53, 52, 57, 0.6);
  static const badge = Color(0xFF454747);
  static const divider = Color.fromRGBO(53, 52, 57, 0.4);

  static const accent = Color(0xFFD4EE6B);
  static const accentMuted = Color(0xFFB8D253);
  static const onAccent = Color(0xFF2A3400);
  static const onAccentDark = Color(0xFF181E00);

  static const textPrimary = Color(0xFFE4E1E7);
  static const textSecondary = Color(0xFFC6C8B2);
  static const textDisabled = Color(0xFF8E9079);

  static const danger = Color(0xFFFFB4AB);
  static const dangerFill = Color.fromRGBO(255, 180, 171, 0.1);
  static const dangerBorder = Color.fromRGBO(255, 180, 171, 0.35);

  static const caution = Color(0xFFFFD27A);
  static const cautionFill = Color.fromRGBO(255, 210, 122, 0.1);
  static const cautionBorder = Color.fromRGBO(255, 210, 122, 0.35);

  static const glowLime = Color.fromRGBO(212, 238, 107, 0.05);
  static const glowGrey = Color.fromRGBO(53, 52, 57, 0.3);
}
