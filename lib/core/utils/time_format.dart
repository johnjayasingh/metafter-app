import 'package:intl/intl.dart';

/// Time formatting shared by Messages, Discover and Chat.
abstract final class TimeFormat {
  /// Compact relative age used in the chat list: "3h", "22h", "2d", "now".
  static String relativeAge(DateTime t, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final d = n.difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return DateFormat('d MMM').format(t);
  }

  /// Sighting time in the Discover list: "4:28 PM" or "16:28".
  static String clock(DateTime t, {required bool use24h}) =>
      DateFormat(use24h ? 'HH:mm' : 'h:mm a').format(t);

  /// Discover date band: "Today - 25 Jan, 2026" / "Yesterday - …" /
  /// "Wed - 21 Jan, 2026".
  static String dateBand(DateTime day, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final d = DateTime(day.year, day.month, day.day);
    final suffix = DateFormat('d MMM, yyyy').format(d);
    if (d == today) return 'Today - $suffix';
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday - $suffix';
    }
    return '${DateFormat('EEE').format(d)} - $suffix';
  }

  /// Chat date separator: "Mon, 10:38 am" style.
  static String chatSeparator(DateTime t, {required bool use24h}) =>
      DateFormat(use24h ? 'EEE, HH:mm' : 'EEE, h:mm a').format(t);

  /// Session countdown "h:mm:ss" (or "mm:ss" under an hour).
  static String countdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
