import 'dart:async';

import '../../../core/result/result.dart';
import 'dapp_catalog.dart';
import 'models/browser_visit.dart';
import 'models/dapp.dart';

final class DappBrowserSnapshot {
  const DappBrowserSnapshot({
    required this.catalog,
    required this.favoriteIds,
    required this.recents,
  });

  final List<Dapp> catalog;
  final Set<String> favoriteIds;
  final List<BrowserVisit> recents;

  List<Dapp> get favorites =>
      [for (final dapp in catalog) if (favoriteIds.contains(dapp.id)) dapp];
}

/// Discovery data and browsing history for the dApp browser.
abstract interface class DappBrowserRepository {
  /// Emits the current snapshot immediately, then on every change.
  Stream<DappBrowserSnapshot> watch();

  Future<Result<void>> toggleFavorite(String dappId);
  Future<Result<void>> recordVisit(BrowserVisit visit);
  Future<Result<void>> clearRecents();
}

/// Session-only implementation; Drift-backed persistence is the follow-up
/// (CLAUDE.md lists address book / history as Drift-cached data).
class InMemoryDappBrowserRepository implements DappBrowserRepository {
  InMemoryDappBrowserRepository({
    List<Dapp> catalog = DappCatalog.featured,
    Set<String> favoriteIds = const {},
    List<BrowserVisit> recents = const [],
  })  : _catalog = catalog,
        _favoriteIds = {...favoriteIds},
        _recents = [...recents];

  static const maxRecents = 20;

  final List<Dapp> _catalog;
  final Set<String> _favoriteIds;
  final List<BrowserVisit> _recents;
  final List<StreamController<DappBrowserSnapshot>> _watchers = [];

  DappBrowserSnapshot _snapshot() => DappBrowserSnapshot(
        catalog: List.unmodifiable(_catalog),
        favoriteIds: Set.unmodifiable(_favoriteIds),
        recents: List.unmodifiable(_recents),
      );

  void _notify() {
    final snapshot = _snapshot();
    for (final watcher in List.of(_watchers)) {
      watcher.add(snapshot);
    }
  }

  @override
  Stream<DappBrowserSnapshot> watch() {
    late final StreamController<DappBrowserSnapshot> controller;
    controller = StreamController<DappBrowserSnapshot>(
      onListen: () {
        _watchers.add(controller);
        controller.add(_snapshot());
      },
      onCancel: () => _watchers.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<Result<void>> toggleFavorite(String dappId) async {
    if (!_catalog.any((d) => d.id == dappId)) {
      return const Result.err(AppFailure.unknown('Unknown dApp'));
    }
    if (!_favoriteIds.remove(dappId)) _favoriteIds.add(dappId);
    _notify();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> recordVisit(BrowserVisit visit) async {
    _recents.removeWhere((v) => v.url == visit.url);
    _recents.insert(0, visit);
    if (_recents.length > maxRecents) {
      _recents.removeRange(maxRecents, _recents.length);
    }
    _notify();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> clearRecents() async {
    _recents.clear();
    _notify();
    return const Result.ok(null);
  }
}
