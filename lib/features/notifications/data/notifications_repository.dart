import 'dart:async';

import '../../../core/result/result.dart';
import 'app_notification.dart';

abstract interface class NotificationsRepository {
  Stream<List<AppNotification>> watch();
  Future<Result<void>> markRead(String id);
  Future<Result<void>> markAllRead();
}

class InMemoryNotificationsRepository implements NotificationsRepository {
  InMemoryNotificationsRepository({List<AppNotification>? seed})
      : _items = seed ?? _defaultSeed();

  List<AppNotification> _items;
  final _controller = StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watch() async* {
    yield _items;
    yield* _controller.stream;
  }

  @override
  Future<Result<void>> markRead(String id) async {
    _emit([for (final n in _items) n.id == id ? n.markRead() : n]);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> markAllRead() async {
    _emit([for (final n in _items) n.markRead()]);
    return const Result.ok(null);
  }

  void _emit(List<AppNotification> items) {
    _items = items;
    _controller.add(_items);
  }

  static List<AppNotification> _defaultSeed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        kind: NotificationKind.transaction,
        title: 'Received 1.50 ETH',
        body: 'Deposit confirmed on Ethereum Mainnet.',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n2',
        kind: NotificationKind.priceAlert,
        title: 'BTC crossed \$64,000',
        body: 'Your price alert for Bitcoin was triggered.',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n3',
        kind: NotificationKind.security,
        title: 'New device check passed',
        body: 'Your wallet was unlocked with biometrics.',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'n4',
        kind: NotificationKind.dapp,
        title: 'Session request expired',
        body: 'A connection request was not approved in time.',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }
}
