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
    final expires = DateTime.now()
        .toUtc()
        .add(Duration(days: maxAgeDays))
        .toIso8601String();
    final encoded = Uri.encodeComponent(value);
    html.document.cookie =
        '$key=$encoded; Path=/; Expires=$expires; SameSite=Lax';
  }

  static void delete(String key) {
    html.document.cookie = '$key=; Path=/; Max-Age=0; SameSite=Lax';
  }
}
