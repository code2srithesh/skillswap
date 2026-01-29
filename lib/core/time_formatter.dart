class TimeFormatter {
  /// Format timestamp for display
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      // Format: Jan 15, 2026
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
    }
  }

  /// Format timestamp for full display
  static String formatFullTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final ampm = dateTime.hour < 12 ? 'AM' : 'PM';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    return "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} - ${hour}:${dateTime.minute.toString().padLeft(2, '0')} $ampm";
  }

  /// Get time remaining until expiry
  static String getTimeRemaining(DateTime createdAt, int expiryDays) {
    if (expiryDays == 0) return "No expiry";

    final expiryDate = createdAt.add(Duration(days: expiryDays));
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return "Expired";
    } else if (difference.inHours < 1) {
      return "Expires in < 1 hour";
    } else if (difference.inHours < 24) {
      return "Expires in ${difference.inHours}h";
    } else {
      return "Expires in ${difference.inDays}d";
    }
  }
}
