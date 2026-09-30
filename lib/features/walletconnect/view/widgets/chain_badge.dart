import 'package:flutter/material.dart';

import '../../data/models/wc_chain.dart';

/// Round chain marker: the chain's brand color at 20% with its ticker
/// initial in the full color (no remote icons — works offline).
class ChainBadge extends StatelessWidget {
  const ChainBadge({super.key, required this.chain, this.size = 28});

  final WcChain chain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(chain.color);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
      ),
      child: Text(
        chain.name.characters.first,
        style: TextStyle(
          color: color,
          fontSize: size * 0.43,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
