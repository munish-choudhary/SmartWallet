import 'package:intl/intl.dart';

/// "just now", "2 min ago", "5 h ago", "3 d ago".
String formatRelative(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

/// "6d 21h", "3h 12m", "8m", "Expired".
String formatRemaining(DateTime expiresAt, {DateTime? now}) {
  final diff = expiresAt.difference(now ?? DateTime.now());
  if (diff.isNegative || diff == Duration.zero) return 'Expired';
  if (diff.inDays >= 1) {
    return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }
  return '${diff.inMinutes.clamp(1, 59)}m';
}

/// "Oct 24, 2023 · 14:32"
String formatDateTime(DateTime time) =>
    DateFormat('MMM d, y · HH:mm').format(time.toLocal());
