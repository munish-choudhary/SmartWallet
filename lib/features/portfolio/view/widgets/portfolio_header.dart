import 'dart:ui';

import 'package:flutter/material.dart';

class PortfolioHeader extends StatelessWidget {
  const PortfolioHeader({
    super.key,
    this.networkName = 'MAINNET',
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  final String networkName;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(19, 19, 23, 0.8),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand logo & title
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B3E8C), Color(0xFFE4FF7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: Color(0xFF131317),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LEXOR POCKET',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          letterSpacing: -0.3,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        networkName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: 0.44,
                          color: Color(0xFFC6C8B2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action buttons (Notifications & Profile)
              Row(
                children: [
                  _circleButton(
                    onTap: onNotificationPressed,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: Color(0xFFC6C6C7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _circleButton(
                    onTap: onProfilePressed,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF7255A5), Color(0xFFD4EE6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: Color(0xFF131317),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}
