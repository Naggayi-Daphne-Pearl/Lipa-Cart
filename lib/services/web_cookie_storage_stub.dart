class WebCookieStorage {
  static bool get isSupported => false;

  static String? read(String key) {
    return null;
  }

  static void write(String key, String value, {int maxAgeDays = 30}) {}

  static void delete(String key) {}
}
