import 'dart:ui';

import 'package:flutter/material.dart';

import 'settings_palette.dart';

/// Blurred 64px top bar with a back button and title, shared by every
/// Settings sub-screen.
class SettingsSubHeader extends StatelessWidget {
  const SettingsSubHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: const Color.fromRGBO(19, 19, 23, 0.8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: SettingsPalette.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Page scaffold: dark background, ambient glows, pinned header, scrolling body.
class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.glow = SettingsPalette.glowPurple,
    this.bottom,
    this.ambient,
    this.headerTrailing,
  });

  final String title;
  final Widget child;
  final Color glow;
  final Widget? bottom;

  /// Replaces the default single-glow backdrop. It fills the screen, so it
  /// positions its own blobs (e.g. with a `Stack` of `Positioned`s).
  final Widget? ambient;

  /// Shown at the end of the header, after the title.
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsPalette.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ambient ?? _DefaultGlow(color: glow),
            ),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: SettingsSubHeader(
                  title: title,
                  trailing: headerTrailing,
                ),
              ),
              Expanded(child: child),
              if (bottom != null) SafeArea(top: false, child: bottom!),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultGlow extends StatelessWidget {
  const _DefaultGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -48,
          top: -40,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
