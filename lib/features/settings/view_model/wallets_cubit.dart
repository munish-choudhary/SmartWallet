import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../../core/vault/vault.dart' show WalletId;
import '../data/wallet_profile_repository.dart';
import 'wallets_state.dart';

class WalletsCubit extends Cubit<WalletsState> {
  WalletsCubit({required WalletProfileRepository profiles})
      : _profiles = profiles,
        super(const WalletsState.loading()) {
    load();
  }

  final WalletProfileRepository _profiles;

  Future<void> load() async {
    emit(const WalletsState.loading());
    await _fetch();
  }

  /// Re-reads the list without the spinner — used after a wallet was added.
  Future<void> refresh() => _fetch();

  /// Makes [walletId] the active wallet. Returns whether it is active now.
  Future<bool> select(WalletId walletId) async {
    final current = state;
    if (current is! WalletsLoaded || current.activeId == walletId) return false;
    emit(current.copyWith(switchingTo: walletId));
    final result = await _profiles.switchTo(walletId);
    if (isClosed) return false;
    if (result case Err()) {
      emit(current);
      return false;
    }
    emit(current.copyWith(activeId: walletId, switchingTo: null));
    return true;
  }

  Future<void> _fetch() async {
    final result = await _profiles.loadAll();
    if (isClosed) return;
    switch (result) {
      case Err(:final failure):
        emit(WalletsState.failure(failure));
      case Ok(:final value):
        emit(WalletsState.loaded(value.wallets, activeId: value.activeId));
    }
  }
}
