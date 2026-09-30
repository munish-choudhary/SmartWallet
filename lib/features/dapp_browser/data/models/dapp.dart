enum DappCategory {
  defi('DeFi'),
  nft('NFT'),
  games('Games'),
  bridge('Bridges'),
  tools('Tools');

  const DappCategory(this.label);
  final String label;
}

/// A curated entry in the discovery list. Curated means *we* vouch that
/// [url] is the project's real site — the browser uses that to mark the
/// origin verified, so never add an entry from user input.
final class Dapp {
  const Dapp({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.category,
    required this.brandColor,
  });

  final String id;
  final String name;
  final String url;
  final String description;
  final DappCategory category;
  final int brandColor;

  String get host => Uri.parse(url).host;
}
