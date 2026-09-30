import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/portfolio_repository.dart';
import 'manage_tokens_state.dart';

class ManageTokensCubit extends Cubit<ManageTokensState> {
  ManageTokensCubit({required PortfolioRepository repository})
      : _repository = repository,
        super(const ManageTokensState.loading()) {
    _subscription = repository.watchSnapshot().listen((result) {
      if (result case Ok(:final value)) {
        final query = switch (state) {
          ManageTokensLoaded(:final query) => query,
          _ => '',
        };
        emit(ManageTokensState.loaded(assets: value.assets, query: query));
      }
    });
  }

  final PortfolioRepository _repository;
  StreamSubscription<dynamic>? _subscription;

  void setQuery(String query) {
    if (state case ManageTokensLoaded(:final assets)) {
      emit(ManageTokensState.loaded(assets: assets, query: query));
    }
  }

  Future<void> toggleHidden(String tokenId) => _repository.toggleHidden(tokenId);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
