/// Cross-platform wrapper for forcing a full-page navigation on web.
///
/// On web this resolves to `package:web`'s `window.location.assign`. On mobile
/// (and anywhere else `dart.library.js_interop` is unavailable) it resolves to
/// a no-op — mobile uses in-app routing only.
library;

export 'web_location_stub.dart'
    if (dart.library.js_interop) 'web_location_web.dart';
