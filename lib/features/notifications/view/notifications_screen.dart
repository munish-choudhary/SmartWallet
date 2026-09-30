import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../data/app_notification.dart';
import '../view_model/notifications_cubit.dart';
import '../view_model/notifications_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final items = switch (state) {
          NotificationsLoaded(:final items) => items,
          _ => const <AppNotification>[],
        };
        return LexorPageScaffold(
          title: 'Notifications',
          trailing: state.unreadCount == 0
              ? null
              : TextButton(
                  onPressed: () => context.read<NotificationsCubit>().markAllRead(),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: LexorPalette.accent, fontSize: 13),
                  ),
                ),
          child: state is NotificationsLoading
              ? const Center(
                  child: CircularProgressIndicator(color: LexorPalette.accent),
                )
              : items.isEmpty
                  ? const Center(
                      child: Text(
                        'You\'re all caught up',
                        style: TextStyle(color: LexorPalette.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _NotificationTile(
                        item: items[i],
                        onTap: () => context
                            .read<NotificationsCubit>()
                            .markRead(items[i].id),
                      ),
                    ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  static IconData _icon(NotificationKind kind) => switch (kind) {
        NotificationKind.transaction => Icons.swap_vert_rounded,
        NotificationKind.priceAlert => Icons.show_chart_rounded,
        NotificationKind.security => Icons.shield_outlined,
        NotificationKind.dapp => Icons.link_rounded,
      };

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      radius: 16,
      onTap: item.isRead ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: LexorPalette.chip,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(_icon(item.kind), size: 20, color: LexorPalette.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _ago(item.timestamp),
                  style: const TextStyle(
                    color: LexorPalette.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!item.isRead)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LexorPalette.accent,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 8, height: 8),
              ),
            ),
        ],
      ),
    );
  }
}
