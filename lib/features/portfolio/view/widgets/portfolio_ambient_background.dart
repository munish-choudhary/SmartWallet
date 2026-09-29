import 'dart:ui';

import 'package:flutter/material.dart';

/// The ambient glow spheres matching the Portfolio & Token Detail CSS:
/// - Top right purple glow: `rgba(114, 85, 165, 0.2)`, blur 65px
/// - Bottom left lime glow: `rgba(184, 210, 83, 0.1)`, blur 70px
class PortfolioAmbientBackground extends StatelessWidget {
  const PortfolioAmbientBackground({
    super.key,
    required this.child,
    this.showSecondGlow = true,
  });

  final Widget child;
  final bool showSecondGlow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF131317),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Purple ambient blur (top right)
          Positioned(
            top: -128,
            right: -96,
            child: _glowCircle(
              size: 320,
              color: const Color.fromRGBO(114, 85, 165, 0.2),
              sigma: 65,
            ),
          ),
          // Lime ambient blur (mid-left)
          if (showSecondGlow)
            Positioned(
              top: 333,
              left: -128,
              child: _glowCircle(
                size: 288,
                color: const Color.fromRGBO(184, 210, 83, 0.1),
                sigma: 70,
              ),
            ),
          child,
        ],
      ),
    );
  }

  Widget _glowCircle({
    required double size,
    required Color color,
    required double sigma,
  }) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
