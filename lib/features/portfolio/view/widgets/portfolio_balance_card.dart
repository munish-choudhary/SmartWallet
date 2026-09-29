import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/portfolio_snapshot.dart';

class PortfolioBalanceCard extends StatelessWidget {
  const PortfolioBalanceCard({
    super.key,
    required this.snapshot,
    this.onSendPressed,
    this.onReceivePressed,
    this.onSwapPressed,
    this.onBuyPressed,
    this.onSearchPressed,
    this.onAlertsPressed,
    this.onNetworkSelectorPressed,
  });

  final PortfolioSnapshot snapshot;
  final VoidCallback? onSendPressed;
  final VoidCallback? onReceivePressed;
  final VoidCallback? onSwapPressed;
  final VoidCallback? onBuyPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onAlertsPressed;
  final VoidCallback? onNetworkSelectorPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F23),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 50,
            offset: Offset(0, 25),
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Inner glow purple top right
            Positioned(
              right: -48,
              top: -64,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    width: 224,
                    height: 224,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(114, 85, 165, 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            // Inner glow lime bottom left
            Positioned(
              left: -48,
              bottom: 0,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(89, 108, 0, 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Portfolio Selector & Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Portfolio label + active network
                      GestureDetector(
                        onTap: onNetworkSelectorPressed,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Portfolio',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: Color(0xFFE4E1E7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
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
                                const SizedBox(width: 6),
                                Text(
                                  snapshot.activeNetwork,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.55,
                                    color: Color(0xFFC6C8B2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Search & Alert icons
                      Row(
                        children: [
                          _circleAction(
                            icon: Icons.search_rounded,
                            onTap: onSearchPressed,
                          ),
                          const SizedBox(width: 6),
                          Stack(
                            children: [
                              _circleAction(
                                icon: Icons.notifications_none_rounded,
                                onTap: onAlertsPressed,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Center Total Balance Block
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL BALANCE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.3,
                            color: Color(0xFFC6C8B2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.formattedTotalBalance,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(53, 52, 57, 0.9),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                snapshot.isPositiveChange
                                    ? Icons.arrow_outward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 12,
                                color: snapshot.isPositiveChange
                                    ? const Color(0xFFD4EE6B)
                                    : const Color(0xFFFFB4AB),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${snapshot.formattedChangePercent} (${snapshot.formattedChangeUsd})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.28,
                                  color: snapshot.isPositiveChange
                                      ? const Color(0xFFD4EE6B)
                                      : const Color(0xFFFFB4AB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons Row (Send, Receive, Swap, Buy)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionButton(
                        label: 'Send',
                        icon: Icons.arrow_outward_rounded,
                        onTap: onSendPressed,
                        isDominant: false,
                      ),
                      _actionButton(
                        label: 'Receive',
                        icon: Icons.arrow_downward_rounded,
                        onTap: onReceivePressed,
                        isDominant: false,
                      ),
                      _actionButton(
                        label: 'Swap',
                        icon: Icons.sync_alt_rounded,
                        onTap: onSwapPressed,
                        isDominant: false,
                      ),
                      _actionButton(
                        label: 'Buy',
                        icon: Icons.add_rounded,
                        onTap: onBuyPressed,
                        isDominant: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color.fromRGBO(42, 41, 46, 0.8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFC6C6C7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDominant,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDominant
                  ? const Color(0xFFD4EE6B)
                  : const Color.fromRGBO(53, 52, 57, 0.9),
              shape: BoxShape.circle,
              boxShadow: isDominant
                  ? const [
                      BoxShadow(
                        color: Color.fromRGBO(212, 238, 107, 0.35),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: isDominant
                    ? const Color(0xFF181E00)
                    : const Color(0xFFFFFFFF),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isDominant ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.24,
              color: isDominant
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFC6C8B2),
            ),
          ),
        ],
      ),
    );
  }
}
