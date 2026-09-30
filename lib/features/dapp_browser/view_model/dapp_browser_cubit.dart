import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/browser_url_resolver.dart';
import '../data/dapp_browser_repository.dart';
import '../data/models/dapp.dart';
import 'dapp_browser_state.dart';

/// Backs the dApp discovery screen: catalog, favorites, history, and
/// resolving what the user typed into the search bar.
class DappBrowserCubit extends Cubit<DappBrowserState> {
  DappBrowserCubit({required DappBrowserRepository repository})
      : _repository = repository,
        super(const DappBrowserState.loading()) {
    _subscription = _repository.watch().listen(
      _onSnapshot,
      onError: (Object _) => emit(
        const DappBrowserState.failure(
          AppFailure.unknown('Could not load dApps.'),
        ),
      ),
    );
  }

  final DappBrowserRepository _repository;
  late final StreamSubscription<DappBrowserSnapshot> _subscription;

  void _onSnapshot(DappBrowserSnapshot snapshot) {
    final current = state;
    emit(
      DappBrowserState.loaded(
        catalog: snapshot.catalog,
        favoriteIds: snapshot.favoriteIds,
        recents: snapshot.recents,
        category: current is DappBrowserLoaded ? current.category : null,
      ),
    );
  }

  void selectCategory(DappCategory? category) {
    final current = state;
    if (current is! DappBrowserLoaded) return;
    emit(current.copyWith(category: category));
  }

  Future<void> toggleFavorite(String dappId) =>
      _repository.toggleFavorite(dappId);

  Future<void> clearRecents() => _repository.clearRecents();

  /// What the search bar's text means: a URL to open, a web search, or
  /// something we refuse to load.
  ResolvedInput resolve(String input) => BrowserUrlResolver.resolve(input);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
