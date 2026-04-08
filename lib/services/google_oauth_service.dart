import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import 'web_oauth_state_storage_stub.dart'
    if (dart.library.html) 'web_oauth_state_storage.dart';

class GoogleOAuthProfile {
  final String idToken;
  final String email;
  final String? name;
  final String? pictureUrl;
  final Map<String, String> stateParams;

  const GoogleOAuthProfile({
    required this.idToken,
    required this.email,
    this.name,
    this.pictureUrl,
    this.stateParams = const {},
  });
}

/// Lightweight Google OAuth helper for Flutter web.
///
/// This opens Google's consent screen and reads the returned ID token so the
/// app can prefill a user's name/email during sign-up.
class GoogleOAuthService {
  GoogleOAuthService._();

  static bool get isConfigured => AppConfig.isGoogleOAuthConfigured;

  static Uri buildConsentUri({
    Map<String, String?> queryParameters = const {},
    String callbackPath = '/auth/google/callback',
  }) {
    final stateParams = <String, String>{
      for (final entry in queryParameters.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!,
    };

    final encodedState = stateParams.isEmpty
        ? null
        : base64Url.encode(utf8.encode(jsonEncode(stateParams)));

    final normalizedCallbackPath = callbackPath.startsWith('/')
        ? callbackPath
        : '/$callbackPath';

    final redirectUri = Uri(
      scheme: Uri.base.scheme,
      host: Uri.base.host,
      port: Uri.base.hasPort ? Uri.base.port : null,
      path: normalizedCallbackPath,
    ).toString();

    return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': AppConfig.googleWebClientId,
      'redirect_uri': redirectUri,
      'response_type': 'id_token',
      'response_mode': 'fragment',
      'scope': 'openid email profile',
      'prompt': 'select_account',
      'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      if (encodedState != null) 'state': encodedState,
    });
  }

  static Future<bool> launchConsentScreen({
    Map<String, String?> queryParameters = const {},
    String callbackPath = '/auth/google/callback',
  }) async {
    if (!kIsWeb || !isConfigured) return false;

    return launchUrl(
      buildConsentUri(
        queryParameters: queryParameters,
        callbackPath: callbackPath,
      ),
      webOnlyWindowName: '_self',
    );
  }

  static GoogleOAuthProfile? readProfileFromCurrentUrl() {
    if (!kIsWeb) return null;

    final savedFragment = WebOAuthStateStorage.readFragment();
    final savedQuery = WebOAuthStateStorage.readQuery();
    final fragment = Uri.base.fragment.isNotEmpty
        ? Uri.base.fragment
        : (savedFragment ?? '');
    final query = Uri.base.query.isNotEmpty
        ? Uri.base.query
        : (savedQuery ?? '');

    String? idToken;
    Map<String, String> params = const {};

    if (fragment.contains('id_token=')) {
      params = Uri.splitQueryString(fragment);
      idToken = params['id_token'];
    } else if (query.contains('id_token=')) {
      params = Uri.splitQueryString(query);
      idToken = params['id_token'];
    } else {
      return null;
    }
    if (idToken == null || idToken.isEmpty) {
      return null;
    }

    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;

      final email = claims['email'] as String?;
      if (email == null || email.isEmpty) {
        return null;
      }

      Map<String, String> stateParams = const {};
      final encodedState = params['state'];
      if (encodedState != null && encodedState.isNotEmpty) {
        final decodedState = utf8.decode(
          base64Url.decode(base64Url.normalize(encodedState)),
        );
        final stateJson = jsonDecode(decodedState);
        if (stateJson is Map) {
          stateParams = {
            for (final entry in stateJson.entries)
              entry.key.toString(): entry.value?.toString() ?? '',
          };
        }
      }

      final profile = GoogleOAuthProfile(
        idToken: idToken,
        email: email,
        name: claims['name'] as String?,
        pictureUrl: claims['picture'] as String?,
        stateParams: stateParams,
      );

      WebOAuthStateStorage.clear();
      return profile;
    } catch (_) {
      return null;
    }
  }
}
