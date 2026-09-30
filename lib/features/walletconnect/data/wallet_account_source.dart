import '../../../core/result/result.dart';

/// The account dApps see. Placeholder boundary: `Vault.accounts` currently
/// returns a non-EVM placeholder address from the FakeVault, so this stays
/// an interface until `core/chains` can derive real addresses. Only the
/// *public* address ever crosses it — never key material.
final class WalletAccount {
  const WalletAccount({required this.address, required this.label});

  final String address;
  final String label;
}

abstract interface class WalletAccountSource {
  Future<Result<WalletAccount>> activeEvmAccount();
}

/// Fixed demo account (the address used in the Figma frames).
final class InMemoryWalletAccountSource implements WalletAccountSource {
  const InMemoryWalletAccountSource({
    this.account = const WalletAccount(
      address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
      label: 'Main Account',
    ),
  });

  final WalletAccount account;

  @override
  Future<Result<WalletAccount>> activeEvmAccount() async =>
      Result.ok(account);
}
