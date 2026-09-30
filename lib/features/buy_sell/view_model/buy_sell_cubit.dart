import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../portfolio/data/models/token_asset.dart';
import '../../portfolio/data/portfolio_repository.dart';
import 'buy_sell_state.dart';

class BuySellCubit extends Cubit<BuySellState> {
  BuySellCubit({required PortfolioRepository repository, TradeSide? side})
      : _initialSide = side ?? TradeSide.buy,
        super(const BuySellState.loading()) {
    _load(repository);
  }

  final TradeSide _initialSide;

  Future<void> _load(PortfolioRepository repository) async {
    final result = await repository.getSnapshot();
    if (isClosed) return;
    if (result case Ok(:final value) when value.assets.isNotEmpty) {
      emit(BuySellState.ready(
        tokens: value.assets,
        token: value.assets.first,
        side: _initialSide,
      ));
    }
  }

  void setSide(TradeSide side) {
    if (state case final BuySellReady s) emit(s.copyWith(side: side));
  }

  void selectToken(TokenAsset token) {
    if (state case final BuySellReady s) emit(s.copyWith(token: token));
  }

  void setAmount(String text) {
    if (state case final BuySellReady s) emit(s.copyWith(amountText: text));
  }
}
