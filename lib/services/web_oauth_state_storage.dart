// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

class WebOAuthStateStorage {
  static const _fragmentKey = 'google_oauth_fragment';
  static const _queryKey = 'google_oauth_query';

  static String? readFragment() => html.window.sessionStorage[_fragmentKey];

  static String? readQuery() => html.window.sessionStorage[_queryKey];

  static void clear() {
    html.window.sessionStorage.remove(_fragmentKey);
    html.window.sessionStorage.remove(_queryKey);
  }
}
