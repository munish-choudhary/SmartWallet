import 'package:flutter/material.dart';

import '../../../../core/design_system/lexor_palette.dart';

/// Gradient-ringed AI orb. Static (no animation) so it is cheap to repeat in
/// a message list; the animated variant is the floating button.
class AiOrb extends StatelessWidget {
  const AiOrb({super.key, this.size = 32, this.glow = false});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [LexorPalette.accent, Color(0xFFD5BBFF), Color(0xFF39393D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: glow
            ? const [
                BoxShadow(
                  color: Color.fromRGBO(212, 238, 107, 0.22),
                  blurRadius: 35,
                ),
              ]
            : null,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC2A292E), Color(0xF21B1B1F), Color(0xFF0E0E12)],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            size: size * 0.4,
            color: LexorPalette.accent,
          ),
        ),
      ),
    );
  }
}
