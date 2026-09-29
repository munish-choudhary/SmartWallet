import 'dart:async';
import 'dart:typed_data';

import 'secrets.dart';

enum VaultStatus { locked, unlocked }

/// Holds the unlocked session's KEKs in memory — nothing else, per
/// CLAUDE.md's Memory Hygiene rules. One vault may hold several wallets
/// (an HD wallet plus imported-key wallets), each with its own salt and
/// therefore its own KEK, all unlocked by the same PIN. Cleared on
/// auto-lock timeout, app backgrounded beyond timeout, manual lock, and
/// wallet removal.
final class VaultSession {
  final Map<String, Uint8List> _keksByWalletId = {};
  final _statusController = StreamController<VaultStatus>.broadcast();

  Stream<VaultStatus> get status => _statusController.stream;

  bool get isUnlocked => _keksByWalletId.isNotEmpty;

  Uint8List? kekFor(String walletId) => _keksByWalletId[walletId];

  void open(Map<String, Uint8List> keksByWalletId) {
    _keksByWalletId.addAll(keksByWalletId);
    _statusController.add(VaultStatus.unlocked);
  }

  void forgetWallet(String walletId) {
    final current = _keksByWalletId.remove(walletId);
    if (current != null) zeroize(current);
  }

  /// Zeroizes all in-memory KEKs and marks the session locked. Idempotent.
  void clear() {
    for (final kek in _keksByWalletId.values) {
      zeroize(kek);
    }
    _keksByWalletId.clear();
    _statusController.add(VaultStatus.locked);
  }

  Future<void> dispose() async {
    clear();
    await _statusController.close();
  }
}
