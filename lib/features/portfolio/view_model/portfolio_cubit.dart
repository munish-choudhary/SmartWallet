import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/models/portfolio_filter.dart';
import '../data/models/token_asset.dart';
import '../data/portfolio_repository.dart';
import 'portfolio_state.dart';

class PortfolioCubit extends Cubit<PortfolioState> {
  PortfolioCubit({required PortfolioRepository repository})
      : _repository = repository,
        super(const PortfolioState.loading()) {
    _init();
  }

  final PortfolioRepository _repository;
  StreamSubscription<Result<dynamic>>? _subscription;

  void _init() {
    _subscription = _repository.watchSnapshot().listen(
      (result) {
        result.when(
          ok: (snapshot) {
            final currentState = state;
            if (currentState is PortfolioLoaded) {
              emit(currentState.copyWith(
                data: snapshot,
                refreshing: false,
              ));
            } else {
              emit(PortfolioState.loaded(snapshot));
            }
          },
          err: (failure) {
            emit(PortfolioState.failure(failure));
          },
        );
      },
      onError: (Object error) {
        emit(PortfolioState.failure(
          AppFailure.unknown(error.toString()),
        ));
      },
    );
  }

  Future<void> refresh() async {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      emit(currentState.copyWith(refreshing: true));
    }

    final result = await _repository.refresh();
    result.when(
      ok: (snapshot) {
        if (state is PortfolioLoaded) {
          emit((state as PortfolioLoaded).copyWith(
            data: snapshot,
            refreshing: false,
          ));
        } else {
          emit(PortfolioState.loaded(snapshot));
        }
      },
      err: (failure) {
        if (state is! PortfolioLoaded) {
          emit(PortfolioState.failure(failure));
        } else {
          emit((state as PortfolioLoaded).copyWith(refreshing: false));
        }
      },
    );
  }

  void setFilter(PortfolioFilter filter) {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      emit(currentState.copyWith(activeFilter: filter));
    }
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void selectToken(TokenAsset? token) {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      emit(currentState.copyWith(selectedToken: token));
    }
  }

  Future<void> toggleFavorite(String tokenId) async {
    await _repository.toggleFavorite(tokenId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
