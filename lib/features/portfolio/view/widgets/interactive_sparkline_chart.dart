import 'dart:ui';

import 'package:flutter/material.dart';

class InteractiveSparklineChart extends StatefulWidget {
  const InteractiveSparklineChart({
    super.key,
    required this.points,
    required this.currentPrice,
    this.isPositive = true,
  });

  final List<double> points;
  final double currentPrice;
  final bool isPositive;

  @override
  State<InteractiveSparklineChart> createState() =>
      _InteractiveSparklineChartState();
}

class _InteractiveSparklineChartState extends State<InteractiveSparklineChart> {
  int _selectedIntervalIndex = 1; // 24H default
  final List<String> _intervals = const ['1H', '24H', '1W', '1M', '1Y', 'ALL'];

  int? _hoverIndex;
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    final activePoints = widget.points.isNotEmpty
        ? widget.points
        : const [3250.0, 3280.0, 3310.0, 3380.0, 3420.5];

    final displayPrice = _hoverIndex != null && _hoverIndex! < activePoints.length
        ? activePoints[_hoverIndex!]
        : widget.currentPrice;

    return Container(
      width: double.infinity,
      height: 208,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 27, 31, 0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.4),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chart canvas with touch handler
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          _updateHover(details.localPosition, constraints.maxWidth, activePoints);
                        },
                        onHorizontalDragEnd: (_) {
                          setState(() {
                            _hoverIndex = null;
                            _hoverPosition = null;
                          });
                        },
                        onTapDown: (details) {
                          _updateHover(details.localPosition, constraints.maxWidth, activePoints);
                        },
                        onTapUp: (_) {
                          setState(() {
                            _hoverIndex = null;
                            _hoverPosition = null;
                          });
                        },
                        child: Stack(
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: _SparklinePainter(
                                  points: activePoints,
                                  isPositive: widget.isPositive,
                                ),
                              ),
                            ),
                            // Tooltip & cursor overlay
                            if (_hoverPosition != null && _hoverIndex != null) ...[
                              // Vertical dashed line
                              Positioned(
                                left: _hoverPosition!.dx,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color: const Color(0xFFD4EE6B).withValues(alpha: 0.6),
                                ),
                              ),
                              // Live Cursor Dot
                              Positioned(
                                left: _hoverPosition!.dx - 7,
                                top: _hoverPosition!.dy - 7,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color.fromRGBO(212, 238, 107, 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD4EE6B),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFFD4EE6B),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Floating Tooltip Badge
                              Positioned(
                                left: (_hoverPosition!.dx - 70)
                                    .clamp(8.0, constraints.maxWidth - 150),
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(57, 57, 61, 0.95),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.2),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFD4EE6B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '\$${displayPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.44,
                                          color: Color(0xFFD4EE6B),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '14:32',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.07,
                                          color: Color(0xFFC6C8B2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Time Interval Selection Dock (1H, 24H, 1W, 1M, 1Y, ALL)
                Container(
                  height: 30,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(42, 41, 46, 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_intervals.length, (index) {
                      final isSelected = _selectedIntervalIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIntervalIndex = index;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD4EE6B)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: Color.fromRGBO(212, 238, 107, 0.35),
                                      blurRadius: 14,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              _intervals[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                letterSpacing: 0.44,
                                color: isSelected
                                    ? const Color(0xFF181E00)
                                    : const Color(0xFFC6C8B2),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateHover(Offset localPosition, double width, List<double> points) {
    if (points.isEmpty) return;
    final dx = localPosition.dx.clamp(0.0, width);
    final index = ((dx / width) * (points.length - 1)).round().clamp(0, points.length - 1);

    final minPrice = points.reduce((a, b) => a < b ? a : b);
    final maxPrice = points.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice == 0 ? 1.0 : maxPrice - minPrice;
    final normalizedY = (points[index] - minPrice) / range;
    final dy = (1.0 - normalizedY) * 120 + 10;

    setState(() {
      _hoverIndex = index;
      _hoverPosition = Offset(dx, dy);
    });
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.isPositive,
  });

  final List<double> points;
  final bool isPositive;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minPrice = points.reduce((a, b) => a < b ? a : b);
    final maxPrice = points.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice == 0 ? 1.0 : maxPrice - minPrice;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (points.length - 1);
    const topPadding = 12.0;
    final chartHeight = size.height - 24;

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalizedY = (points[i] - minPrice) / range;
      final y = size.height - (normalizedY * chartHeight) - topPadding;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height -
            (((points[i - 1] - minPrice) / range) * chartHeight) -
            topPadding;
        final controlX1 = prevX + (x - prevX) / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + (x - prevX) / 2;
        final controlY2 = y;
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Gradient fill under curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4EE6B).withValues(alpha: 0.32),
          const Color(0xFFD4EE6B).withValues(alpha: 0.08),
          const Color(0xFF131317).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = const Color(0xFFD4EE6B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.isPositive != isPositive;
  }
}
