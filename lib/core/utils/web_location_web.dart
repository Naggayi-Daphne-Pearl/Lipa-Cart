import 'package:web/web.dart' as web;

/// Forces a full-page navigation to [url] (crosses origin boundaries).
void assignWebLocation(String url) {
  web.window.location.assign(url);
}
