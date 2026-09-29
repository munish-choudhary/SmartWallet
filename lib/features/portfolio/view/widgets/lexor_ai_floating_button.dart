import 'dart:ui';

import 'package:flutter/material.dart';

class LexorAiFloatingButton extends StatefulWidget {
  const LexorAiFloatingButton({
    super.key,
    required this.onTap,
    this.message = 'Portfolio looks healthy! ⚡',
    this.showTooltip = true,
  });

  final VoidCallback onTap;
  final String message;
  final bool showTooltip;

  @override
  State<LexorAiFloatingButton> createState() => _LexorAiFloatingButtonState();
}

class _LexorAiFloatingButtonState extends State<LexorAiFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTooltip) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(53, 52, 57, 0.9),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.1),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        blurRadius: 20,
                        offset: Offset(0, 4),
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
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFD4EE6B),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(255, 255, 255, 0.95),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Animated Pulsing Cosmic Orb
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF5B3E8C),
                      Color(0xFFC8733A),
                      Color(0xFFE4FF7A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(212, 238, 107, 0.45),
                      blurRadius: 24,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(91, 62, 140, 0.6),
                      blurRadius: 32,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(14, 14, 18, 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.2),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 24,
                      color: Color(0xFFD4EE6B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
