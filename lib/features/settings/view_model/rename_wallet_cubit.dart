import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/wallet_name.dart';
import '../data/wallet_profile_repository.dart';
import 'rename_wallet_state.dart';

class RenameWalletCubit extends Cubit<RenameWalletState> {
  RenameWalletCubit({required WalletProfileRepository repository})
      : _repository = repository,
        super(const RenameWalletState.loading()) {
    load();
  }

  final WalletProfileRepository _repository;

  Future<void> load() async {
    emit(const RenameWalletState.loading());
    final result = await _repository.load();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => RenameWalletState.ready(
          currentName: value.name,
          shortAddress: value.shortAddress,
          draft: value.name,
        ),
      Err(:final failure) => RenameWalletState.failure(failure),
    });
  }

  void draftChanged(String draft) {
    final s = state;
    if (s is! RenameWalletReady || s.saving) return;
    emit(s.copyWith(draft: draft, saveFailure: null));
  }

  Future<void> save() async {
    final s = state;
    if (s is! RenameWalletReady || !s.canSave) return;
    emit(s.copyWith(saving: true, saveFailure: null));
    final name = WalletName.normalize(s.draft);
    final result = await _repository.rename(name);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => RenameWalletState.saved(name),
      Err(:final failure) => s.copyWith(saving: false, saveFailure: failure),
    });
  }
}
