import 'package:flutter/foundation.dart';

class AppConfig {
  /// Production backend URL (Render).
  static const String _prodBaseUrl =
      'https://iiitnrattendence-backend.onrender.com';

  /// Local backend URL for development/testing.
  /// Uncomment the apiBaseUrl line below to use local backend.
  // static const String _localBaseUrl = 'http://192.168.137.1:4000';

  static const String apiVersion = '/api';

  /// Use production URL always. Switch to _localBaseUrl when running backend locally.
  // static String get apiBaseUrl => kDebugMode ? _localBaseUrl : _prodBaseUrl;
  static String get apiBaseUrl => _prodBaseUrl;

  static String get baseUrl => '$apiBaseUrl$apiVersion';
}
