import 'dart:ui';

import 'package:flutter/material.dart';

enum PortfolioNavTab {
  portfolio,
  swap,
  activity,
  browser,
  settings,
}

class PortfolioBottomNavBar extends StatelessWidget {
  const PortfolioBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final PortfolioNavTab currentTab;
  final ValueChanged<PortfolioNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 384),
      height: 64,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(14, 14, 18, 0.8),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.8),
            blurRadius: 32,
            offset: Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  tab: PortfolioNavTab.portfolio,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _navItem(
                  tab: PortfolioNavTab.swap,
                  icon: Icons.sync_alt_rounded,
                ),
                _navItem(
                  tab: PortfolioNavTab.activity,
                  icon: Icons.receipt_long_rounded,
                ),
                _navItem(
                  tab: PortfolioNavTab.browser,
                  icon: Icons.explore_rounded,
                ),
                _navItem(
                  tab: PortfolioNavTab.settings,
                  icon: Icons.settings_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required PortfolioNavTab tab,
    required IconData icon,
  }) {
    final isSelected = currentTab == tab;
    return GestureDetector(
      onTap: () => onTabSelected(tab),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFFD4EE6B)
                  : const Color(0xFFC6C6C7),
            ),
            if (isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
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
          ],
        ),
      ),
    );
  }
}
