import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../data/wallet_name.dart';

part 'rename_wallet_state.freezed.dart';

@freezed
sealed class RenameWalletState with _$RenameWalletState {
  const factory RenameWalletState.loading() = RenameWalletLoading;

  const factory RenameWalletState.ready({
    required String currentName,
    required String shortAddress,

    /// Exactly what is in the text field right now (untrimmed).
    required String draft,
    @Default(false) bool saving,

    /// Set when the last save attempt failed; cleared on the next edit.
    AppFailure? saveFailure,
  }) = RenameWalletReady;

  /// The new (trimmed) name has been stored; the screen closes.
  const factory RenameWalletState.saved(String name) = RenameWalletSaved;

  const factory RenameWalletState.failure(AppFailure failure) =
      RenameWalletFailure;
}

extension RenameWalletReadyX on RenameWalletReady {
  bool get isDraftValid => WalletName.isValid(draft);
  int get draftLength => WalletName.lengthOf(draft);

  /// Saving an unchanged name is pointless, so it stays disabled.
  bool get canSave =>
      !saving && isDraftValid && WalletName.normalize(draft) != currentName;
}
