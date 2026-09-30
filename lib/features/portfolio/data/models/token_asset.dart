import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_asset.freezed.dart';

@freezed
sealed class TokenAsset with _$TokenAsset {
  const TokenAsset._();

  const factory TokenAsset({
    required String id,
    required String name,
    required String symbol,
    required String network,
    required double balance,
    required double priceUsd,
    required double change24h,
    required int iconBgColor,
    required String contractAddress,
    required String marketCap,
    required String volume24h,
    required List<double> sparklinePoints,
    @Default(0.0) double stakedBalance,
    @Default(false) bool isFavorite,
    @Default(false) bool isHidden,
  }) = _TokenAsset;

  double get fiatValue => balance * priceUsd;

  double get stakedFiatValue => stakedBalance * priceUsd;

  bool get isPositiveChange => change24h >= 0;

  String get formattedPrice {
    if (priceUsd >= 1000) {
      return '\$${priceUsd.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}';
    }
    return '\$${priceUsd.toStringAsFixed(2)}';
  }

  String get formattedFiatValue {
    final val = fiatValue;
    if (val >= 1000) {
      return '\$${val.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}';
    }
    return '\$${val.toStringAsFixed(2)}';
  }

  String get formattedBalance {
    if (balance == balance.toInt().toDouble()) {
      return balance.toInt().toString();
    }
    return balance.toStringAsFixed(balance < 1 ? 4 : 2);
  }

  String get formattedChange {
    final prefix = isPositiveChange ? '+' : '';
    return '$prefix${change24h.toStringAsFixed(1)}%';
  }
}
