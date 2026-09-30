import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/vault/vault.dart' show WalletId;

part 'wallet_profile.freezed.dart';

/// Public, non-secret facts about the active wallet, for the Wallet Details
/// and Rename Wallet screens.
@freezed
sealed class WalletProfile with _$WalletProfile {
  const WalletProfile._();

  const factory WalletProfile({
    required WalletId walletId,
    required String name,

    /// The primary (EVM) account address.
    required String address,

    /// `null` when the wallet has no derivation path to show.
    String? derivationPath,
  }) = _WalletProfile;

  /// `0x71C8...b94F9b` — enough to recognise the wallet at a glance.
  String get shortAddress => shortenAddress(address);

  String get etherscanUrl => 'https://etherscan.io/address/$address';
  String get blockscanUrl => 'https://blockscan.com/address/$address';
}

String shortenAddress(String address) {
  if (address.length <= 15) return address;
  return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
}
