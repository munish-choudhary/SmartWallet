import 'package:flutter/material.dart';

import '../../data/models/portfolio_filter.dart';

class PortfolioFilterBar extends StatelessWidget {
  const PortfolioFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.onTunePressed,
  });

  final PortfolioFilter selectedFilter;
  final ValueChanged<PortfolioFilter> onFilterChanged;
  final VoidCallback? onTunePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Capsule dock with All, Tokens, DeFi
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1F),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterTab(
                label: 'All',
                filter: PortfolioFilter.all,
              ),
              _filterTab(
                label: 'Tokens',
                filter: PortfolioFilter.tokens,
              ),
              _filterTab(
                label: 'DeFi',
                filter: PortfolioFilter.defi,
              ),
            ],
          ),
        ),

        // Filter / Tune button
        Material(
          color: const Color(0xFF1B1B1F),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTunePressed,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Color(0xFFC6C6C7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterTab({
    required String label,
    required PortfolioFilter filter,
  }) {
    final isSelected = selectedFilter == filter;
    return GestureDetector(
      onTap: () => onFilterChanged(filter),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4EE6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.44,
            color: isSelected
                ? const Color(0xFF181E00)
                : const Color(0xFFC6C6C7),
          ),
        ),
      ),
    );
  }
}
