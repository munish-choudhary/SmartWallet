import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_durations.dart';

/// The lime check-draw + glow-burst animation shown on the
/// Creation/Import Success screens. No Rive asset was available from the
/// Figma file (design-to-code fidelity extraction hit the MCP rate limit
/// before any asset export), so this is a lightweight `CustomPainter`
/// equivalent instead, per the spec's documented fallback.
class SuccessCheckBadge extends StatefulWidget {
  const SuccessCheckBadge({super.key, this.size = 96});

  final double size;

  @override
  State<SuccessCheckBadge> createState() => _SuccessCheckBadgeState();
}

class _SuccessCheckBadgeState extends State<SuccessCheckBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.slow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) _controller.duration = Duration.zero;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final glowT = Curves.easeOut.transform(t);
        final scaleT = Curves.elasticOut.transform(t.clamp(0, 1));
        return SizedBox(
          width: widget.size * 1.8,
          height: widget.size * 1.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: glowT * 0.5,
                child: Container(
                  width: widget.size * (1 + glowT * 0.8),
                  height: widget.size * (1 + glowT * 0.8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.6 + 0.4 * scaleT,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: CustomPaint(
                    painter: _CheckPainter(progress: t.clamp(0, 1)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.32);

    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(
      0,
      metrics.length * progress.clamp(0.0, 1.0),
    );

    final paint = Paint()
      ..color = AppColors.onAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
