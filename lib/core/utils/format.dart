/// "now", "5m", "3h", "2d", or a date for anything older than a week.
String timeAgo(String? iso, {DateTime? now}) {
  final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[t.month - 1]} ${t.day}';
}

/// Two letters for an avatar: "Tom Kane" -> "TK", "hd_collector" -> "HC".
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'[\s_.-]+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

/// Cents from the API to the whole-dollar label the designs use.
String dollars(int? cents) => cents == null ? '' : '\$${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
