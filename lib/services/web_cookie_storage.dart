// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class WebCookieStorage {
  static bool get isSupported => true;

  static String? read(String key) {
    final cookies = html.document.cookie ?? '';
    final parts = cookies.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('$key=')) {
        return Uri.decodeComponent(trimmed.substring(key.length + 1));
      }
    }
    return null;
  }

  static void write(String key, String value, {int maxAgeDays = 30}) {
    final expiresAt = DateTime.now().toUtc().add(Duration(days: maxAgeDays));
    final encoded = Uri.encodeComponent(value);
    final secure =
        html.window.location.protocol == 'https:' ? '; Secure' : '';

    html.document.cookie =
        '$key=$encoded; Path=/; Max-Age=${Duration(days: maxAgeDays).inSeconds}; '
        'Expires=${_formatCookieDate(expiresAt)}; SameSite=Lax$secure';
  }

  static void delete(String key) {
    final secure =
        html.window.location.protocol == 'https:' ? '; Secure' : '';
    html.document.cookie =
        '$key=; Path=/; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; SameSite=Lax$secure';
  }

  static String _formatCookieDate(DateTime dateTime) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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

    final utc = dateTime.toUtc();
    final weekday = weekdays[utc.weekday - 1];
    final month = months[utc.month - 1];
    final day = utc.day.toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');

    return '$weekday, $day $month ${utc.year} $hour:$minute:$second GMT';
  }
}
