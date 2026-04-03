import 'dart:js_interop';

@JS('showBrowserNotification')
external void _showBrowserNotification(JSString title, JSString body);

void callShowBrowserNotification(String title, String body) {
  _showBrowserNotification(title.toJS, body.toJS);
}
