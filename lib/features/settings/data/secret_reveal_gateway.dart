import 'dart:typed_data';

import '../../../core/result/result.dart';
import '../../../core/vault/envelope.dart' show SecretType;
import '../../../core/vault/pin.dart';
import '../../../core/vault/secrets.dart';
import '../../../core/vault/vault.dart';

/// Account shown on the export screen (public data only).
final class ExportAccount {
  const ExportAccount({
    required this.name,
    required this.address,
    required this.network,
  });
  final String name;
  final String address;
  final String network;
}

/// Reveals wallet secrets after a manual PIN check. Callers own the
/// returned bytes and must zeroize them (CLAUDE.md memory hygiene).
abstract interface class SecretRevealGateway {
  /// Public account info; `Err(vaultLocked)` while the session is locked.
  Future<Result<ExportAccount>> loadAccount();
  Future<Result<Uint8List>> revealPrivateKey(Pin pin);
  Future<Result<Uint8List>> revealRecoveryPhrase(Pin pin);
}

class VaultSecretRevealGateway implements SecretRevealGateway {
  VaultSecretRevealGateway(this._vault);

  final Vault _vault;

  @override
  Future<Result<ExportAccount>> loadAccount() async {
    final id = await _vault.activeWalletId();
    final walletId = id.valueOrNull;
    if (walletId == null) return Result.err(id.failureOrNull!);
    final accounts = await _vault.accounts(walletId);
    final list = accounts.valueOrNull;
    if (list == null || list.isEmpty) {
      return Result.err(accounts.failureOrNull ?? const AppFailure.walletNotFound());
    }
    // Wallet Core lists the Ethereum account first for HD wallets.
    return Result.ok(
      ExportAccount(
        name: 'Main Account',
        address: list.first.address,
        network: 'Ethereum',
      ),
    );
  }

  @override
  Future<Result<Uint8List>> revealPrivateKey(Pin pin) async {
    final id = await _vault.activeWalletId();
    final walletId = id.valueOrNull;
    if (walletId == null) return Result.err(id.failureOrNull!);
    return _vault.exportPrivateKey(walletId, coin: CoinType.ethereum, pin: pin);
  }

  @override
  Future<Result<Uint8List>> revealRecoveryPhrase(Pin pin) =>
      _reveal(pin, SecretType.mnemonic);

  Future<Result<Uint8List>> _reveal(Pin pin, SecretType expected) async {
    final id = await _vault.activeWalletId();
    final walletId = id.valueOrNull;
    if (walletId == null) return Result.err(id.failureOrNull!);
    final result = await _vault.revealSecret(walletId, pin: pin);
    final reveal = result.valueOrNull;
    if (reveal == null) return Result.err(result.failureOrNull!);
    if (reveal.type != expected) {
      zeroize(reveal.secret);
      return const Result.err(AppFailure.notImplemented());
    }
    return Result.ok(reveal.secret);
  }
}
