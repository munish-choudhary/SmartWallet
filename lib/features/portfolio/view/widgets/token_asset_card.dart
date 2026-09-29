import 'package:flutter/material.dart';

import '../../data/models/token_asset.dart';

class TokenAssetCard extends StatelessWidget {
  const TokenAssetCard({
    super.key,
    required this.asset,
    this.onTap,
  });

  final TokenAsset asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F23),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Token Icon + Name + Tag + Price + Change
                Row(
                  children: [
                    // Token Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF353439),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.05),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _tokenIcon(asset.symbol, asset.iconBgColor),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Token metadata
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + network tag
                        Row(
                          children: [
                            Text(
                              asset.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF353439),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                asset.network,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.07,
                                  color: Color(0xFFC6C6C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Price + Change %
                        Row(
                          children: [
                            Text(
                              asset.formattedPrice,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.44,
                                color: Color(0xFFC6C8B2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              asset.formattedChange,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.07,
                                color: asset.isPositiveChange
                                    ? const Color(0xFFD4EE6B)
                                    : const Color(0xFFFFB4AB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Right: Fiat Value + Token Balance
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      asset.formattedFiatValue,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.16,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${asset.formattedBalance} ${asset.symbol}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.44,
                        color: Color(0xFFC6C6C7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tokenIcon(String symbol, int colorHex) {
    final color = Color(colorHex);
    switch (symbol.toUpperCase()) {
      case 'ETH':
        return Icon(
          Icons.diamond_outlined,
          size: 22,
          color: color,
        );
      case 'BTC':
        return Text(
          '₿',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        );
      case 'SOL':
        return Icon(
          Icons.blur_on_rounded,
          size: 22,
          color: color,
        );
      case 'AVAX':
        return Icon(
          Icons.change_history_rounded,
          size: 22,
          color: color,
        );
      default:
        return Icon(
          Icons.currency_exchange_rounded,
          size: 20,
          color: color,
        );
    }
  }
}
