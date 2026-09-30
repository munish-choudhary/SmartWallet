/// An EVM chain a session/request can target, keyed by its CAIP-2 id
/// (`eip155:<chainId>`). The app supports exactly these five EVM chains
/// (CLAUDE.md) — anything else a dApp asks for is shown as unsupported.
final class WcChain {
  const WcChain({
    required this.chainId,
    required this.name,
    required this.symbol,
    required this.color,
  });

  final int chainId;
  final String name;
  final String symbol;

  /// ARGB brand color, used for the chain badge.
  final int color;

  String get caip2 => 'eip155:$chainId';
  String get hexChainId => '0x${chainId.toRadixString(16)}';

  @override
  bool operator ==(Object other) =>
      other is WcChain && other.chainId == chainId;

  @override
  int get hashCode => chainId.hashCode;

  @override
  String toString() => 'WcChain($caip2)';
}

abstract final class WcChains {
  static const ethereum = WcChain(
    chainId: 1,
    name: 'Ethereum Mainnet',
    symbol: 'ETH',
    color: 0xFF627EEA,
  );
  static const bnbChain = WcChain(
    chainId: 56,
    name: 'BNB Chain',
    symbol: 'BNB',
    color: 0xFFF0B90B,
  );
  static const polygon = WcChain(
    chainId: 137,
    name: 'Polygon',
    symbol: 'POL',
    color: 0xFF8247E5,
  );
  static const arbitrum = WcChain(
    chainId: 42161,
    name: 'Arbitrum One',
    symbol: 'ETH',
    color: 0xFF28A0F0,
  );
  static const base = WcChain(
    chainId: 8453,
    name: 'Base',
    symbol: 'ETH',
    color: 0xFF0052FF,
  );

  static const all = [ethereum, bnbChain, polygon, arbitrum, base];

  static WcChain? byChainId(int chainId) {
    for (final chain in all) {
      if (chain.chainId == chainId) return chain;
    }
    return null;
  }

  /// Parses `eip155:1` (CAIP-2) or `0x1` (hex, as used by EIP-1193).
  static WcChain? parse(String value) {
    if (value.startsWith('eip155:')) {
      final id = int.tryParse(value.substring('eip155:'.length));
      return id == null ? null : byChainId(id);
    }
    if (value.startsWith('0x') || value.startsWith('0X')) {
      final id = int.tryParse(value.substring(2), radix: 16);
      return id == null ? null : byChainId(id);
    }
    return null;
  }
}
