import '../../../walletconnect/data/models/wc_chain.dart';

/// A site the user allowed to see their account in the in-app browser.
/// Keyed by origin (`https://app.uniswap.org`) — permissions never carry
/// over to another origin, including another subdomain.
final class DappConnection {
  const DappConnection({
    required this.origin,
    required this.address,
    required this.chain,
    required this.connectedAt,
  });

  final String origin;
  final String address;
  final WcChain chain;
  final DateTime connectedAt;

  DappConnection withChain(WcChain chain) => DappConnection(
        origin: origin,
        address: address,
        chain: chain,
        connectedAt: connectedAt,
      );
}
