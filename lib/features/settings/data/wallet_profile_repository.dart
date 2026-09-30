import '../../../core/result/result.dart';
import '../../../core/vault/vault.dart';
import 'wallet_name.dart';
import 'wallet_name_store.dart';
import 'wallet_profile.dart';

/// Every wallet on the device, plus which one the app currently operates on.
final class WalletRoster {
  const WalletRoster({required this.wallets, required this.activeId});

  final List<WalletProfile> wallets;
  final WalletId activeId;
}

abstract interface class WalletProfileRepository {
  Future<Result<WalletProfile>> load();

  /// All wallets in creation order, with the active one marked by id.
  Future<Result<WalletRoster>> loadAll();

  /// Makes [walletId] the wallet the rest of the app operates on.
  Future<Result<void>> switchTo(WalletId walletId);

  /// Stores [name] (trimmed) as the active wallet's name.
  Future<Result<void>> rename(String name);
}

class VaultWalletProfileRepository implements WalletProfileRepository {
  VaultWalletProfileRepository({
    required Vault vault,
    required WalletNameStore names,
  })  : _vault = vault,
        _names = names;

  final Vault _vault;
  final WalletNameStore _names;

  /// Wallet Core's default path for the Ethereum account, which is the
  /// account shown here. The Vault doesn't yet say whether a wallet is
  /// mnemonic- or key-based, and a key-only wallet has no path — once it
  /// does, return `null` for those so the row is hidden.
  static const _defaultEvmPath = "m/44'/60'/0'/0/0";

  @override
  Future<Result<WalletProfile>> load() async {
    final id = await _vault.activeWalletId();
    final walletId = id.valueOrNull;
    if (walletId == null) return Result.err(id.failureOrNull!);
    final position = (await _vault.walletIds()).indexOf(walletId);
    return _profileFor(walletId, position < 0 ? 0 : position);
  }

  @override
  Future<Result<WalletRoster>> loadAll() async {
    final active = await _vault.activeWalletId();
    final activeId = active.valueOrNull;
    if (activeId == null) return Result.err(active.failureOrNull!);

    final wallets = <WalletProfile>[];
    AppFailure? lastFailure;
    final ids = await _vault.walletIds();
    for (var i = 0; i < ids.length; i++) {
      final profile = await _profileFor(ids[i], i);
      final value = profile.valueOrNull;
      if (value != null) {
        wallets.add(value);
      } else {
        lastFailure = profile.failureOrNull;
      }
    }
    if (wallets.isEmpty) {
      return Result.err(lastFailure ?? const AppFailure.walletNotFound());
    }
    return Result.ok(WalletRoster(wallets: wallets, activeId: activeId));
  }

  @override
  Future<Result<void>> switchTo(WalletId walletId) =>
      _vault.setActiveWallet(walletId);

  /// [position] (0-based creation order) only picks the default name, so
  /// several unnamed wallets stay tellable apart: "My Wallet", "Wallet 2", …
  Future<Result<WalletProfile>> _profileFor(
    WalletId walletId,
    int position,
  ) async {
    final accounts = await _vault.accounts(walletId);
    final list = accounts.valueOrNull;
    if (list == null || list.isEmpty) {
      return Result.err(
        accounts.failureOrNull ?? const AppFailure.walletNotFound(),
      );
    }

    String? stored;
    try {
      stored = await _names.read(walletId);
    } catch (_) {
      // A name we can't read shouldn't hide the wallet; fall back to default.
    }
    return Result.ok(
      WalletProfile(
        walletId: walletId,
        name: stored ??
            (position == 0 ? WalletName.fallback : 'Wallet ${position + 1}'),
        // Wallet Core lists the Ethereum account first for HD wallets.
        address: list.first.address,
        derivationPath: _defaultEvmPath,
      ),
    );
  }

  @override
  Future<Result<void>> rename(String name) async {
    final normalized = WalletName.normalize(name);
    if (!WalletName.isValid(normalized)) {
      return const Result.err(AppFailure.unknown('Invalid wallet name'));
    }
    final id = await _vault.activeWalletId();
    final walletId = id.valueOrNull;
    if (walletId == null) return Result.err(id.failureOrNull!);
    try {
      await _names.write(walletId, normalized);
    } catch (_) {
      return const Result.err(AppFailure.unknown('Could not save the name'));
    }
    return const Result.ok(null);
  }
}
