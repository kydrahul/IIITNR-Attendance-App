import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralised wrapper for Firebase Analytics.
///
/// All four required pre-deployment events are tracked here:
/// - [logLoginSuccess] — user authenticated successfully (with role).
/// - [logLoginFailure] — authentication failed (with error_code).
/// - [logAttendanceMarked] — student marked attendance via QR scan.
/// - [logQrGenerated] — faculty generated a QR code for a session.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Returns a [NavigatorObserver] so route changes are tracked automatically.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Called when a user successfully signs in.
  ///
  /// [role] — one of `student`, `faculty`, or `intern`.
  Future<void> logLoginSuccess({required String role}) async {
    await _analytics.logLogin(loginMethod: 'google');
    await _analytics.logEvent(
      name: 'login_success',
      parameters: {'role': role},
    );
  }

  /// Called when authentication fails.
  ///
  /// [errorCode] — a Firebase Auth error code or descriptive string.
  Future<void> logLoginFailure({required String errorCode}) async {
    await _analytics.logEvent(
      name: 'login_failure',
      parameters: {'error_code': errorCode},
    );
  }

  /// Called after a student successfully marks attendance by scanning a QR code.
  ///
  /// [sessionId] — the Firestore session document ID.
  Future<void> logAttendanceMarked({required String sessionId}) async {
    await _analytics.logEvent(
      name: 'attendance_marked',
      parameters: {
        'session_id': sessionId,
        'method': 'qr_scan',
      },
    );
  }

  /// Called after faculty successfully generates a QR code for a session.
  ///
  /// [sessionId] — the Firestore session document ID.
  Future<void> logQrGenerated({required String sessionId}) async {
    await _analytics.logEvent(
      name: 'qr_generated',
      parameters: {'session_id': sessionId},
    );
  }
}
