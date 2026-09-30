import 'dart:typed_data';

import 'package:wallet_core_ffi/wallet_core_ffi.dart' show CoinType;

import '../result/result.dart';
import 'envelope.dart';
import 'pin.dart';
import 'vault_session.dart';

export 'package:wallet_core_ffi/wallet_core_ffi.dart' show CoinType;

typedef WalletId = String;

/// Minimal placeholder — the real `Account` (with chain, index, address,
/// label, ...) belongs to `core/chains` once that's built. Kept here only
/// so `Vault.accounts` compiles.
final class Account {
  const Account({required this.walletId, required this.address});
  final WalletId walletId;
  final String address;
}

/// Placeholder for `core/signing`'s real `SignRequest`/`SignedPayload`.
/// `Vault.sign` will take the real types once `core/signing/` exists;
/// until then this is enough to keep the `Vault` interface shape stable.
final class SignRequest {
  const SignRequest({
    required this.walletId,
    required this.coin,
    required this.signingInputProto,
  });
  final WalletId walletId;
  final CoinType coin;
  final Uint8List signingInputProto;
}

final class SignedPayload {
  const SignedPayload(this.bytes);
  final Uint8List bytes;
}

/// Result of [Vault.revealSecret]. Caller must zeroize [secret] via
/// `zeroize()` in a `finally` block immediately after use, and must never
/// let it enter Bloc state, logs, or route params.
final class SecretReveal {
  const SecretReveal({required this.type, required this.secret});
  final SecretType type;
  final Uint8List secret;
}

/// Format family for a raw private-key import, used only to pick the
/// right validation rule (hex vs base58, key length). Lighter than
/// [CoinType] — the private-key screen separately lets the user pick the
/// specific [CoinType]/network for display and later signing, but
/// validation only cares about the family. May move to `core/chains`
/// alongside a real chain-agnostic type once that layer exists.
enum ChainFamily { evm, solana, tron, bitcoin }

extension CoinTypeChainFamily on CoinType {
  ChainFamily get chainFamily => switch (this) {
    CoinType.solana => ChainFamily.solana,
    CoinType.tron => ChainFamily.tron,
    CoinType.bitcoin => ChainFamily.bitcoin,
    CoinType.ethereum ||
    CoinType.smartChain ||
    CoinType.polygon ||
    CoinType.arbitrum ||
    CoinType.base => ChainFamily.evm,
  };
}

/// One slot of a recovery-phrase verification challenge: the user must
/// tap the word that belongs at [wordIndex] (1-based position in the
/// mnemonic) out of the shuffled [options] (which includes the correct
/// word plus distractors).
final class WordChallenge {
  const WordChallenge({required this.wordIndex, required this.options});
  final int wordIndex;
  final List<String> options;
}

/// Returned by [Vault.verificationChallenge]: the set of word-position
/// challenges (per CLAUDE.md's onboarding spec, 3 of them) the user must
/// answer correctly before [Vault.confirmPendingWallet] will persist the
/// wallet.
final class VerificationChallenge {
  const VerificationChallenge(this.challenges);
  final List<WordChallenge> challenges;
}

/// The single facade for all key material and signing. Per CLAUDE.md, no
/// other code may call Wallet Core key/signing APIs or read the encrypted
/// envelope directly.
abstract interface class Vault {
  /// Whether any wallet has been created/imported on this device — used
  /// by routing to decide whether onboarding is reachable at all.
  Future<bool> hasAnyWallet();

  /// The id of the wallet the app operates on: the one chosen with
  /// [setActiveWallet], or the first stored one if none was chosen (or the
  /// chosen one was removed). `walletNotFound` when no wallet exists.
  Future<Result<WalletId>> activeWalletId();

  /// Every stored wallet id, in creation order.
  Future<List<WalletId>> walletIds();

  /// Makes [id] the wallet [activeWalletId] returns. `walletNotFound` if
  /// no such wallet is stored. Needs no PIN: it only selects, it reveals
  /// and signs nothing.
  Future<Result<void>> setActiveWallet(WalletId id);

  Future<Result<WalletId>> createWallet({required Pin pin, int words = 12});
  Future<Result<WalletId>> importMnemonic(String mnemonic, {required Pin pin});
  // CoinType is re-exported from wallet_core_ffi for now — it moves to a
  // chain-agnostic type in core/chains once that layer exists.
  Future<Result<WalletId>> importPrivateKey(
    Uint8List key,
    CoinType coin, {
    required Pin pin,
  });

  // ---- Pending-wallet flow (create-with-verification) ----
  // 1. startPendingWallet() generates a mnemonic held in memory only.
  // 2. pendingPhraseForDisplay() lets the recovery-phrase screen show it.
  // 3. verificationChallenge() gives the verify-phrase screen its quiz.
  // 4. confirmPendingWallet() re-checks the answers, then — only on
  //    success — encrypts and persists the wallet (this is the sole
  //    point at which a pending wallet becomes a real, stored one).
  // discardPendingWallet() drops everything (back navigation, app killed
  // mid-flow, user cancels): no partial wallet is ever left behind.

  Future<Result<void>> startPendingWallet({int words = 12});
  Future<Result<List<String>>> pendingPhraseForDisplay();
  Future<Result<VerificationChallenge>> verificationChallenge();
  Future<Result<WalletId>> confirmPendingWallet({
    required List<String> answers,
    required Pin pin,
  });
  void discardPendingWallet();

  /// Full mnemonic validation (wordlist membership + BIP-39 checksum),
  /// for the import-phrase screen's final "Import Wallet" gate.
  Future<Result<void>> validateMnemonic(String mnemonic);

  /// Format/length validation for a raw private-key import, for the
  /// import-private-key screen's "Import Wallet" gate.
  Future<Result<void>> validatePrivateKey(String key, ChainFamily chain);

  Future<Result<void>> unlock(Pin pin);
  Future<Result<void>> unlockWithBiometrics();
  Future<Result<void>> enableBiometrics({required Pin pin});
  Future<Result<void>> disableBiometrics({required Pin pin});
  Future<bool> get isBiometricAvailable;
  void lock();
  Stream<VaultStatus> get status;

  Future<Result<List<Account>>> accounts(WalletId id);
  Future<Result<SignedPayload>> sign(SignRequest request);
  Future<Result<SecretReveal>> revealSecret(WalletId id, {required Pin pin});

  /// Raw private key for [coin], for the export screen. Mnemonic wallets
  /// derive it at the default path (in an isolate); imported-key wallets
  /// return the stored key. PIN always required. Caller must zeroize.
  Future<Result<Uint8List>> exportPrivateKey(
    WalletId id, {
    required CoinType coin,
    required Pin pin,
  });
  Future<Result<void>> changePin({required Pin current, required Pin next});
  Future<Result<void>> removeWallet(WalletId id, {required Pin pin});
}
