import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(message, name: name ?? 'AppLogger', level: 0);
    }
  }

  static void i(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(message, name: name ?? 'AppLogger', level: 800);
    }
  }

  static void w(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(message, name: name ?? 'AppLogger', level: 900);
    }
  }

  static void e(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(message, name: name ?? 'AppLogger', level: 1000, error: error, stackTrace: stackTrace);
    }
  }
}
