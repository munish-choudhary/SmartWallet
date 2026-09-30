enum AlertDirection { above, below }

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.tokenId,
    required this.symbol,
    required this.targetUsd,
    required this.direction,
    this.enabled = true,
  });

  final String id;
  final String tokenId;
  final String symbol;
  final double targetUsd;
  final AlertDirection direction;
  final bool enabled;

  PriceAlert copyWith({bool? enabled}) => PriceAlert(
        id: id,
        tokenId: tokenId,
        symbol: symbol,
        targetUsd: targetUsd,
        direction: direction,
        enabled: enabled ?? this.enabled,
      );
}
