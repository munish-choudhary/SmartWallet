enum NotificationKind { transaction, priceAlert, security, dapp }

/// Plain text only: title/body come from the app itself, never from on-chain
/// or dApp-supplied strings (those are untrusted per CLAUDE.md).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  AppNotification markRead() => AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: true,
      );
}
