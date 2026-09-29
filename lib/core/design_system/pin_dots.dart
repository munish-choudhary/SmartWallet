import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_durations.dart';

/// The row of PIN dots shown on Create/Confirm Passcode screens. Filled
/// dots animate in, and [shake] triggers the CLAUDE.md-required mismatch
/// shake animation.
class PinDots extends StatefulWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.shake = false,
    this.error = false,
  });

  final int length;
  final int filled;
  final bool shake;
  final bool error;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
  }

  @override
  void didUpdateWidget(covariant PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final dx = reduceMotion
            ? 0.0
            : (t == 0 ? 0.0 : 8 * (1 - t) * _shakeWave(t));
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            _Dot(
              filled: i < widget.filled,
              error: widget.error,
              reduceMotion: reduceMotion,
            ),
          ],
        ],
      ),
    );
  }

  double _shakeWave(double t) => (t * 6 * 3.14159).remainder(2 * 3.14159) < 3.14159
      ? 1
      : -1;
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.filled,
    required this.error,
    required this.reduceMotion,
  });

  final bool filled;
  final bool error;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? AppColors.danger
        : (filled ? AppColors.accent : AppColors.dotEmpty);
    final size = filled ? 14.0 : 12.0;
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
