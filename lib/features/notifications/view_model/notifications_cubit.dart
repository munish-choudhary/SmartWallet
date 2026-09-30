import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsState.loading()) {
    _subscription = _repository
        .watch()
        .listen((items) => emit(NotificationsState.loaded(items)));
  }

  final NotificationsRepository _repository;
  StreamSubscription<dynamic>? _subscription;

  Future<void> markRead(String id) => _repository.markRead(id);

  Future<void> markAllRead() => _repository.markAllRead();

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
