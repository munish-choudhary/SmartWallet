import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'settings_palette.dart';

/// The Lexor compass emblem on Help & About: an 80px disc holding a dashed
/// ring, a solid ring and a four-point needle, with a slow breathing glow
/// behind it. The glow stays still when the platform asks for reduced motion.
class LexorEmblem extends StatefulWidget {
  const LexorEmblem({super.key});

  @override
  State<LexorEmblem> createState() => _LexorEmblemState();
}

class _LexorEmblemState extends State<LexorEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool? _animate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate == _animate) return;
    _animate = animate;
    if (animate) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -8,
                right: -8,
                top: -8,
                bottom: -8,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(_pulse.value);
                    return Opacity(
                      opacity: lerpDouble(0.35, 0.75, t)!,
                      child: Transform.scale(
                        scale: lerpDouble(0.94, 1.04, t)!,
                        child: child,
                      ),
                    );
                  },
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SettingsPalette.accent.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SettingsPalette.chip,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                      spreadRadius: -3,
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: SizedBox.square(dimension: 80),
              ),
              const SizedBox.square(
                dimension: 44,
                child: CustomPaint(painter: _CompassPainter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter();

  static const _dashCount = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final w = size.width;

    // Dashed outer ring (38.5px across at the 44px design size).
    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03125
      ..color = SettingsPalette.accent.withValues(alpha: 0.45);
    final dashedRect = Rect.fromCircle(center: center, radius: w * 0.4375);
    const step = 2 * math.pi / _dashCount;
    for (var i = 0; i < _dashCount; i++) {
      canvas.drawArc(dashedRect, i * step, step * 0.5, false, dashed);
    }

    // Solid inner ring.
    canvas.drawCircle(
      center,
      w * 0.3333,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.0417
        ..color = SettingsPalette.accent.withValues(alpha: 0.8),
    );

    // Four-point needle.
    final outer = w * 0.375;
    final inner = outer * 0.3;
    final needle = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? outer : inner;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0 ? needle.moveTo(p.dx, p.dy) : needle.lineTo(p.dx, p.dy);
    }
    needle.close();
    canvas.drawPath(needle, Paint()..color = SettingsPalette.accent);

    // Pivot.
    canvas.drawCircle(
      center,
      w * 0.0729,
      Paint()..color = SettingsPalette.background,
    );
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) => false;
}
