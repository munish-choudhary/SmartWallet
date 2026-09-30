/// Quick-fill values for the "Add Custom Network" form. These are the public
/// endpoints each chain's team or a neutral provider publishes; the form
/// still re-verifies the chain ID against the RPC before saving.
final class NetworkPreset {
  const NetworkPreset({
    required this.label,
    required this.name,
    required this.rpcUrl,
    required this.chainId,
    required this.currencySymbol,
    required this.explorerUrl,
  });

  /// Short chip label.
  final String label;
  final String name;
  final String rpcUrl;
  final int chainId;
  final String currencySymbol;
  final String explorerUrl;

  static const all = <NetworkPreset>[
    NetworkPreset(
      label: 'Ethereum',
      name: 'Ethereum Mainnet',
      rpcUrl: 'https://ethereum-rpc.publicnode.com',
      chainId: 1,
      currencySymbol: 'ETH',
      explorerUrl: 'https://etherscan.io',
    ),
    NetworkPreset(
      label: 'Base',
      name: 'Base',
      rpcUrl: 'https://mainnet.base.org',
      chainId: 8453,
      currencySymbol: 'ETH',
      explorerUrl: 'https://basescan.org',
    ),
    NetworkPreset(
      label: 'Arbitrum',
      name: 'Arbitrum One',
      rpcUrl: 'https://arb1.arbitrum.io/rpc',
      chainId: 42161,
      currencySymbol: 'ETH',
      explorerUrl: 'https://arbiscan.io',
    ),
    NetworkPreset(
      label: 'Polygon',
      name: 'Polygon',
      rpcUrl: 'https://polygon-bor-rpc.publicnode.com',
      chainId: 137,
      currencySymbol: 'POL',
      explorerUrl: 'https://polygonscan.com',
    ),
    NetworkPreset(
      label: 'BNB Chain',
      name: 'BNB Smart Chain',
      rpcUrl: 'https://bsc-dataseed.binance.org',
      chainId: 56,
      currencySymbol: 'BNB',
      explorerUrl: 'https://bscscan.com',
    ),
  ];
}
