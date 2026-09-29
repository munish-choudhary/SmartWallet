import 'vault.dart' show ChainFamily;

/// Shared format-only validation for a raw private-key string, used by
/// both [FakeVault] and [VaultImpl] for the import-private-key screen's
/// live "Format valid" check. This is intentionally just shape validation
/// (hex/base58, length) — it does not confirm the key is on-curve for its
/// chain; that happens later via Trust Wallet Core when the key is
/// actually imported.
bool isValidPrivateKeyFormat(String key, ChainFamily chain) {
  final normalized = key.startsWith('0x') ? key.substring(2) : key;
  return switch (chain) {
    ChainFamily.evm ||
    ChainFamily.tron ||
    ChainFamily.bitcoin => RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(normalized),
    ChainFamily.solana => RegExp(
      r'^[1-9A-HJ-NP-Za-km-z]{64,128}$',
    ).hasMatch(key),
  };
}
