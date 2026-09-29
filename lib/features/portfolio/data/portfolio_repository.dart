import 'dart:async';

import '../../../core/result/result.dart';
import 'models/portfolio_snapshot.dart';
import 'models/token_asset.dart';
import 'models/transaction_record.dart';

abstract interface class PortfolioRepository {
  Future<Result<PortfolioSnapshot>> getSnapshot();
  Stream<Result<PortfolioSnapshot>> watchSnapshot();
  Future<Result<PortfolioSnapshot>> refresh();
  Future<Result<void>> toggleFavorite(String tokenId);
}

class InMemoryPortfolioRepository implements PortfolioRepository {
  InMemoryPortfolioRepository({PortfolioSnapshot? initialSnapshot}) {
    _currentSnapshot = initialSnapshot ?? _defaultSeedSnapshot;
    _controller = StreamController<Result<PortfolioSnapshot>>.broadcast(
      onListen: () {
        _controller.add(Result.ok(_currentSnapshot));
      },
    );
  }

  late PortfolioSnapshot _currentSnapshot;
  late final StreamController<Result<PortfolioSnapshot>> _controller;

  @override
  Future<Result<PortfolioSnapshot>> getSnapshot() async {
    return Result.ok(_currentSnapshot);
  }

  @override
  Stream<Result<PortfolioSnapshot>> watchSnapshot() {
    return _controller.stream;
  }

  @override
  Future<Result<PortfolioSnapshot>> refresh() async {
    // In production, this pulls the latest chain balances & token prices via indexer/RPC.
    // For now, emit current snapshot smoothly with updated timestamp.
    _controller.add(Result.ok(_currentSnapshot));
    return Result.ok(_currentSnapshot);
  }

  @override
  Future<Result<void>> toggleFavorite(String tokenId) async {
    final updatedAssets = _currentSnapshot.assets.map((asset) {
      if (asset.id == tokenId) {
        return asset.copyWith(isFavorite: !asset.isFavorite);
      }
      return asset;
    }).toList();

    _currentSnapshot = _currentSnapshot.copyWith(assets: updatedAssets);
    _controller.add(Result.ok(_currentSnapshot));
    return const Result.ok(null);
  }

  static final PortfolioSnapshot _defaultSeedSnapshot = PortfolioSnapshot(
    totalBalanceUsd: 275410.85,
    change24hPercent: 7.4,
    change24hUsd: 18920.40,
    activeNetwork: 'ALL NETWORKS',
    marketSentiment: 'High ETH Liquidity • Optimal execution window',
    assets: [
      const TokenAsset(
        id: 'ethereum',
        name: 'Ethereum',
        symbol: 'ETH',
        network: 'ERC-20',
        balance: 14.10,
        priceUsd: 3420.50,
        change24h: 5.2,
        iconBgColor: 0xFF627EEA,
        contractAddress: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
        marketCap: '\$275.4B',
        volume24h: '\$14.28B',
        stakedBalance: 3.10,
        isFavorite: true,
        sparklinePoints: [
          3250.0,
          3280.0,
          3260.0,
          3310.0,
          3300.0,
          3340.0,
          3320.0,
          3380.0,
          3370.0,
          3410.0,
          3390.0,
          3420.5,
        ],
      ),
      const TokenAsset(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'BTC',
        network: 'BTC',
        balance: 1.04,
        priceUsd: 64250.00,
        change24h: 3.1,
        iconBgColor: 0xFFF7931A,
        contractAddress: 'Native (UTXO)',
        marketCap: '\$1.26T',
        volume24h: '\$28.50B',
        stakedBalance: 0.0,
        isFavorite: true,
        sparklinePoints: [
          62100.0,
          62400.0,
          62800.0,
          63100.0,
          62900.0,
          63500.0,
          63800.0,
          64100.0,
          63900.0,
          64250.0,
        ],
      ),
      const TokenAsset(
        id: 'solana',
        name: 'Solana',
        symbol: 'SOL',
        network: 'SOL',
        balance: 38.50,
        priceUsd: 148.20,
        change24h: 8.4,
        iconBgColor: 0xFF14F195,
        contractAddress: 'Native (Solana)',
        marketCap: '\$68.9B',
        volume24h: '\$4.15B',
        stakedBalance: 12.0,
        isFavorite: false,
        sparklinePoints: [
          136.0,
          138.0,
          137.5,
          141.0,
          140.0,
          144.0,
          143.0,
          146.5,
          145.0,
          148.2,
        ],
      ),
      const TokenAsset(
        id: 'avalanche',
        name: 'Avalanche',
        symbol: 'AVAX',
        network: 'AVAX',
        balance: 120.0,
        priceUsd: 28.40,
        change24h: -1.8,
        iconBgColor: 0xFFE84142,
        contractAddress: '0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7',
        marketCap: '\$11.2B',
        volume24h: '\$890M',
        stakedBalance: 40.0,
        isFavorite: false,
        sparklinePoints: [
          29.2,
          29.0,
          28.9,
          28.6,
          28.8,
          28.5,
          28.3,
          28.6,
          28.4,
        ],
      ),
    ],
    recentTransactions: [
      TransactionRecord(
        id: 'tx-1',
        title: 'Received ETH',
        subtitle: 'From 0x7a2...4b9',
        amount: 1.50,
        amountUsd: 5130.75,
        tokenSymbol: 'ETH',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: TransactionType.inbound,
      ),
      TransactionRecord(
        id: 'tx-2',
        title: 'Swapped USDC -> ETH',
        subtitle: 'Uniswap v3',
        amount: 0.85,
        amountUsd: 2907.42,
        tokenSymbol: 'ETH',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: TransactionType.swap,
      ),
      TransactionRecord(
        id: 'tx-3',
        title: 'Sent ETH',
        subtitle: 'To 0x3d1...8f2',
        amount: -0.25,
        amountUsd: 855.12,
        tokenSymbol: 'ETH',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.outbound,
      ),
    ],
  );
}
