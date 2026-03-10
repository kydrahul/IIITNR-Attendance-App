import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/utils/logger.dart';

class GlobalErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.e('Flutter Error: ${details.exceptionAsString()}', error: details.exception, stackTrace: details.stack);
    };

    // Handle all other errors (Dart errors, async errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.e('Async Error: $error', error: error, stackTrace: stack);
      return true; // Prevent default error handling
    };

    // Custom Error Widget for UI
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode ? details.exceptionAsString() : 'An unexpected error occurred. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }
}
