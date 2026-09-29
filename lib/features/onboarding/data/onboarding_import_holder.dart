import 'dart:typed_data';

import '../../../core/vault/secrets.dart';
import '../../../core/vault/vault.dart';

/// Carries the validated import payload (mnemonic or private key) from
/// the Import Phrase / Import Private Key screens to the Importing
/// screen, which is where it's actually handed to the vault. Like
/// [OnboardingPinHolder], this exists specifically so the secret never
/// has to pass through go_router's `extra`, a route param, or any
/// Cubit/Bloc state — those are all forbidden for secret material per
/// this feature's security spec.
sealed class PendingImport {
  const PendingImport();
}

final class PendingMnemonicImport extends PendingImport {
  const PendingMnemonicImport(this.mnemonic);
  final String mnemonic;
}

final class PendingPrivateKeyImport extends PendingImport {
  const PendingPrivateKeyImport(this.key, this.coin);
  final Uint8List key;
  final CoinType coin;
}

final class OnboardingImportHolder {
  PendingImport? _pending;

  void storeMnemonic(String mnemonic) {
    _pending = PendingMnemonicImport(mnemonic);
  }

  void storePrivateKey(Uint8List key, CoinType coin) {
    _pending = PendingPrivateKeyImport(key, coin);
  }

  bool get hasPending => _pending != null;

  /// Consumes the pending import. Can only be called once.
  PendingImport? take() {
    final value = _pending;
    _pending = null;
    return value;
  }

  void discard() {
    final pending = _pending;
    if (pending is PendingPrivateKeyImport) zeroize(pending.key);
    _pending = null;
  }
}
