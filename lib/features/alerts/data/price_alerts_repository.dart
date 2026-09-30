import 'dart:async';

import '../../../core/result/result.dart';
import 'price_alert.dart';

abstract interface class PriceAlertsRepository {
  Stream<List<PriceAlert>> watch();
  Future<Result<void>> add(PriceAlert alert);
  Future<Result<void>> setEnabled(String id, {required bool enabled});
  Future<Result<void>> remove(String id);
}

/// Drift persistence is a follow-up (CLAUDE.md: price alerts live in Drift).
class InMemoryPriceAlertsRepository implements PriceAlertsRepository {
  List<PriceAlert> _items = const [
    PriceAlert(
      id: 'a1',
      tokenId: 'ethereum',
      symbol: 'ETH',
      targetUsd: 3600,
      direction: AlertDirection.above,
    ),
    PriceAlert(
      id: 'a2',
      tokenId: 'bitcoin',
      symbol: 'BTC',
      targetUsd: 60000,
      direction: AlertDirection.below,
      enabled: false,
    ),
  ];
  final _controller = StreamController<List<PriceAlert>>.broadcast();

  @override
  Stream<List<PriceAlert>> watch() async* {
    yield _items;
    yield* _controller.stream;
  }

  @override
  Future<Result<void>> add(PriceAlert alert) async {
    _emit([alert, ..._items]);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setEnabled(String id, {required bool enabled}) async {
    _emit([for (final a in _items) a.id == id ? a.copyWith(enabled: enabled) : a]);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> remove(String id) async {
    _emit(_items.where((a) => a.id != id).toList());
    return const Result.ok(null);
  }

  void _emit(List<PriceAlert> items) {
    _items = items;
    _controller.add(_items);
  }
}
