import 'package:flutter/foundation.dart';

class AppConfig {
  /// Production backend URL (Render).
  static const String _prodBaseUrl =
      'https://iiitnrattendence-backend.onrender.com';

  /// Local backend URL. Set via `--dart-define=LOCAL_URL=http://192.168.x.x:4000`
  /// when running locally:
  ///
  /// ```
  /// flutter run --dart-define=LOCAL_URL=http://192.168.137.1:4000
  /// ```
  static const String _localBaseUrl = String.fromEnvironment(
    'LOCAL_URL',
    defaultValue: 'http://192.168.137.1:4000',
  );

  static const String apiVersion = '/api';

  /// Returns [_localBaseUrl] in debug builds if `LOCAL_URL` is defined via
  /// `--dart-define`, otherwise always uses the production URL.
  ///
  /// This keeps prod safe by default — override only when explicitly requested.
  static String get apiBaseUrl =>
      (kDebugMode && _localBaseUrl.isNotEmpty) ? _localBaseUrl : _prodBaseUrl;

  static String get baseUrl => '$apiBaseUrl$apiVersion';
}
