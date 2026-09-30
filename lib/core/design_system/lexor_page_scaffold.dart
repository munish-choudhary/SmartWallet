import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'lexor_palette.dart';

/// Page shell shared by the Lexor frames: dark background, two ambient
/// glows, a pinned blurred 64px header (back button, title, optional
/// trailing action) and a body below it.
///
/// [scrollable] wraps [child] in a scroll view with the screens' standard
/// gutters. Pass `false` when the body manages its own scrolling.
class LexorPageScaffold extends StatelessWidget {
  const LexorPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.bottom,
    this.onBack,
    this.scrollable = false,
    this.showGlows = true,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? bottom;
  final VoidCallback? onBack;
  final bool scrollable;
  final bool showGlows;

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
            child: child,
          )
        : child;
    return Scaffold(
      backgroundColor: LexorPalette.background,
      body: Stack(
        children: [
          if (showGlows) const _AmbientGlows(),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: LexorHeader(
                  title: title,
                  trailing: trailing,
                  onBack: onBack,
                ),
              ),
              Expanded(child: body),
              if (bottom != null) SafeArea(top: false, child: bottom!),
            ],
          ),
        ],
      ),
    );
  }
}

class LexorHeader extends StatelessWidget {
  const LexorHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(19, 19, 23, 0.75),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              LexorBackButton(onPressed: onBack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.4,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// go_router's `pop` (not `Navigator.maybePop`): screens inside a
/// ShellRoute sit in a nested navigator where the first page has nothing to
/// pop locally, so `Navigator` would silently do nothing.
void _back(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null && router.canPop()) {
    router.pop();
  } else {
    Navigator.of(context).maybePop();
  }
}

class LexorBackButton extends StatelessWidget {
  const LexorBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromRGBO(31, 31, 35, 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed ?? () => _back(context),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: LexorPalette.textPrimary,
            semanticLabel: 'Back',
          ),
        ),
      ),
    );
  }
}

/// 32px header action matching the Figma trailing circle.
class LexorHeaderAction extends StatelessWidget {
  const LexorHeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LexorPalette.chip,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 16,
            color: LexorPalette.accent,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}

class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(right: -96, top: -96, child: _glow(320, LexorPalette.glowLime, 60)),
            Positioned(left: -128, top: 260, child: _glow(288, LexorPalette.glowGrey, 50)),
          ],
        ),
      ),
    );
  }

  static Widget _glow(double size, Color color, double sigma) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
