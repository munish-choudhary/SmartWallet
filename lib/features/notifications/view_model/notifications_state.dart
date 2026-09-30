import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/app_notification.dart';

part 'notifications_state.freezed.dart';

@freezed
sealed class NotificationsState with _$NotificationsState {
  const NotificationsState._();

  const factory NotificationsState.loading() = NotificationsLoading;
  const factory NotificationsState.loaded(List<AppNotification> items) =
      NotificationsLoaded;

  int get unreadCount => switch (this) {
        NotificationsLoaded(:final items) => items.where((n) => !n.isRead).length,
        _ => 0,
      };
}
