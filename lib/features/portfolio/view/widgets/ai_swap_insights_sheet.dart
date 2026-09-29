import 'dart:ui';

import 'package:flutter/material.dart';

class AiSwapInsightsSheet extends StatelessWidget {
  const AiSwapInsightsSheet({
    super.key,
    required this.onApplyOptimalRoute,
  });

  final VoidCallback onApplyOptimalRoute;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(53, 52, 57, 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color.fromRGBO(69, 72, 55, 0.2),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.9),
                blurRadius: 52,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF5B3E8C),
                              Color(0xFFC8733A),
                              Color(0xFFE4FF7A),
                            ],
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF131317),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFFD4EE6B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Route Optimizer',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.07,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Color(0xFFD4EE6B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Active Analysis',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.07,
                                  color: Color(0xFFD4EE6B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Material(
                    color: const Color(0xFF353439),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Insight Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(27, 27, 31, 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromRGBO(69, 72, 55, 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Color(0xFFD4EE6B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Optimal Route Detected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.07,
                            color: Color(0xFFD4EE6B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFFC6C8B2),
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Smart Routing Detected: By splitting trade 60% on Uniswap v3 & 40% on Curve, you save ',
                          ),
                          TextSpan(
                            text: '\$48.20',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD4EE6B),
                            ),
                          ),
                          TextSpan(
                            text: ' with minimal slippage and 0.02% price impact.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action button
              GestureDetector(
                onTap: () {
                  onApplyOptimalRoute();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EE6B),
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(212, 238, 107, 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Color(0xFF181E00),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Apply Optimal Route',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.07,
                          color: Color(0xFF181E00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
