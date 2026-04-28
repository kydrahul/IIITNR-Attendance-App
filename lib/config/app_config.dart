import 'package:flutter/foundation.dart';

class AppConfig {
  /// Production backend URL (Render).
  static const String _prodBaseUrl =
      'https://iiitnrattendence-backend.onrender.com';

  /// Local backend URL for development/testing.
  /// Change the IP/port to match your local dev server.
  static const String _localBaseUrl = 'http://192.168.137.1:4000';

  static const String apiVersion = '/api';

  /// Automatically selects the correct base URL:
  /// - Debug builds → local backend
  /// - Release builds → production backend
  static String get apiBaseUrl => kDebugMode ? _localBaseUrl : _prodBaseUrl;

  static String get baseUrl => '$apiBaseUrl$apiVersion';
}
