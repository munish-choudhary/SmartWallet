import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../data/models/browser_visit.dart';
import '../data/models/dapp.dart';

part 'dapp_browser_state.freezed.dart';

@freezed
sealed class DappBrowserState with _$DappBrowserState {
  const DappBrowserState._();

  const factory DappBrowserState.loading() = DappBrowserLoading;

  const factory DappBrowserState.loaded({
    required List<Dapp> catalog,
    required Set<String> favoriteIds,
    required List<BrowserVisit> recents,

    /// Active category filter; null shows every category.
    DappCategory? category,
  }) = DappBrowserLoaded;

  const factory DappBrowserState.failure(AppFailure failure) =
      DappBrowserFailure;
}

extension DappBrowserLoadedX on DappBrowserLoaded {
  List<Dapp> get visible => category == null
      ? catalog
      : [for (final d in catalog) if (d.category == category) d];

  List<Dapp> get favorites =>
      [for (final d in catalog) if (favoriteIds.contains(d.id)) d];
}
