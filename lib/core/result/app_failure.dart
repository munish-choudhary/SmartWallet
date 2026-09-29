import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// Sealed failure type shared across every repository/service.
///
/// Messages here are shown to the user (mapped by the UI layer) — per
/// CLAUDE.md, they must never contain secret material (mnemonic, private
/// key, PIN, derived keys, envelope contents).
@freezed
sealed class AppFailure with _$AppFailure {
  const factory AppFailure.network(String message) = NetworkFailure;
  const factory AppFailure.insufficientFunds() = InsufficientFundsFailure;
  const factory AppFailure.invalidAddress() = InvalidAddressFailure;
  const factory AppFailure.wrongPin() = WrongPinFailure;
  const factory AppFailure.vaultLocked() = VaultLockedFailure;
  const factory AppFailure.vaultLockedOut(Duration remaining) =
      VaultLockedOutFailure;
  const factory AppFailure.userRejected() = UserRejectedFailure;
  const factory AppFailure.chainError(String message) = ChainErrorFailure;
  const factory AppFailure.biometricUnavailable() =
      BiometricUnavailableFailure;
  const factory AppFailure.biometricNotAllowedForAction() =
      BiometricNotAllowedForActionFailure;
  const factory AppFailure.invalidMnemonic() = InvalidMnemonicFailure;
  const factory AppFailure.invalidPrivateKey() = InvalidPrivateKeyFailure;
  const factory AppFailure.walletNotFound() = WalletNotFoundFailure;
  const factory AppFailure.noPendingWallet() = NoPendingWalletFailure;
  const factory AppFailure.verificationFailed() = VerificationFailedFailure;
  const factory AppFailure.notImplemented() = NotImplementedFailure;
  const factory AppFailure.unknown(String message) = UnknownFailure;
}
