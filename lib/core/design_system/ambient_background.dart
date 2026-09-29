import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The soft ambient glow blobs behind every onboarding screen in Figma
/// (purple/magenta radial blurs on a near-black background).
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _glow(AppColors.backgroundGlowPurple),
          ),
          Positioned(
            top: -80,
            right: -100,
            child: _glow(AppColors.backgroundGlowMagenta),
          ),
          child,
        ],
      ),
    );
  }

  Widget _glow(Color color) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
