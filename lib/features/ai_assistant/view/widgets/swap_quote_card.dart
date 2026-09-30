import 'package:flutter/material.dart';

import '../../../../core/design_system/lexor_palette.dart';
import '../../data/ai_message.dart';

class SwapQuoteCard extends StatelessWidget {
  const SwapQuoteCard({super.key, required this.quote, required this.onReview});

  final SwapQuote quote;
  final VoidCallback onReview;

  static String _amt(double v) =>
      v >= 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(4);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 27, 31, 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 50,
            offset: Offset(0, 25),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: LexorPalette.accent),
              SizedBox(width: 6),
              Text(
                'SWAP INTENT',
                style: TextStyle(
                  color: LexorPalette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.55,
                ),
              ),
              Spacer(),
              Text(
                'Prepared by AI',
                style: TextStyle(
                  color: LexorPalette.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  _TokenRow(
                    label: 'You pay',
                    amount: _amt(quote.payAmount),
                    sub:
                        'Balance: ${quote.from.formattedBalance} ${quote.from.symbol}',
                    symbol: quote.from.symbol,
                    color: Color(quote.from.iconBgColor),
                  ),
                  const SizedBox(height: 8),
                  _TokenRow(
                    label: 'You receive',
                    amount: '~ ${_amt(quote.receiveAmount)}',
                    sub: '≈ \$${quote.receiveUsd.toStringAsFixed(2)} USD',
                    symbol: quote.to.symbol,
                    color: Color(quote.to.iconBgColor),
                    highlight: true,
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF353439),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.south_rounded,
                  size: 16,
                  color: LexorPalette.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Line('Route', quote.route),
          _Line('Price impact', '${quote.priceImpactPercent}%', accent: true),
          _Line('Network fee', '~\$${quote.networkFeeUsd.toStringAsFixed(2)}'),
          _Line('Slippage', '${quote.slippagePercent}%'),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onReview,
              style: FilledButton.styleFrom(
                backgroundColor: LexorPalette.accent,
                foregroundColor: const Color(0xFF596C00),
                shape: const StadiumBorder(),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Review Swap', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.label,
    required this.amount,
    required this.sub,
    required this.symbol,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String amount;
  final String sub;
  final String symbol;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(31, 31, 35, 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: TextStyle(
                      color: highlight
                          ? LexorPalette.accent
                          : LexorPalette.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(42, 41, 46, 0.9),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color,
                  child: Text(
                    symbol.isEmpty ? '?' : symbol[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  symbol,
                  style: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LexorPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent ? LexorPalette.accent : LexorPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
            ),
          ),
        ],
      ),
    );
  }
}
