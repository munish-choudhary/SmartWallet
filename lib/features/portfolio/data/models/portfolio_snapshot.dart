import 'package:freezed_annotation/freezed_annotation.dart';

import 'token_asset.dart';
import 'transaction_record.dart';

part 'portfolio_snapshot.freezed.dart';

@freezed
sealed class PortfolioSnapshot with _$PortfolioSnapshot {
  const PortfolioSnapshot._();

  const factory PortfolioSnapshot({
    required double totalBalanceUsd,
    required double change24hPercent,
    required double change24hUsd,
    required List<TokenAsset> assets,
    required List<TransactionRecord> recentTransactions,
    @Default('ALL NETWORKS') String activeNetwork,
    @Default('High ETH Liquidity • Optimal window') String marketSentiment,
  }) = _PortfolioSnapshot;

  bool get isPositiveChange => change24hPercent >= 0;

  String get formattedTotalBalance {
    return '\$${totalBalanceUsd.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String get formattedChangePercent {
    final prefix = isPositiveChange ? '+' : '';
    return '$prefix${change24hPercent.toStringAsFixed(1)}% (24H)';
  }

  String get formattedChangeUsd {
    final prefix = isPositiveChange ? '+\$' : '-\$';
    return '$prefix${change24hUsd.abs().toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
