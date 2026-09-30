import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../data/wallet_profile_repository.dart';
import 'wallet_details_state.dart';

class WalletDetailsCubit extends Cubit<WalletDetailsState> {
  WalletDetailsCubit({
    required WalletProfileRepository profiles,
    required PortfolioRepository portfolio,
  })  : _profiles = profiles,
        _portfolio = portfolio,
        super(const WalletDetailsState.loading()) {
    load();
  }

  final WalletProfileRepository _profiles;
  final PortfolioRepository _portfolio;

  Future<void> load() async {
    emit(const WalletDetailsState.loading());
    await _fetch();
  }

  /// Re-reads everything without dropping back to the spinner — used after
  /// returning from Rename Wallet.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final profile = await _profiles.load();
    if (isClosed) return;
    switch (profile) {
      case Err(:final failure):
        emit(WalletDetailsState.failure(failure));
      case Ok(:final value):
        final snapshot = await _portfolio.getSnapshot();
        if (isClosed) return;
        emit(WalletDetailsState.loaded(value, portfolio: snapshot.valueOrNull));
    }
  }
}
