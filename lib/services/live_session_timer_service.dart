import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/faculty/faculty_api_service.dart';

/// Manages all timer-based and network-polling concerns for a live QR session:
///
/// - **Session countdown** — 1-second tick, calls [onSessionExpired] when zero.
/// - **QR auto-refresh** — refreshes the QR token every [autoRefreshInterval]
///   seconds by hitting the API and notifying via [onQrRefreshed].
/// - **Attendance polling** — polls [getSessionAttendance] every 5 seconds and
///   notifies via [onAttendancePolled].
///
/// The provider creates this service when a session starts and disposes it when
/// the session ends, keeping all timer ownership out of [ChangeNotifier] state.
class LiveSessionTimerService {
  final FacultyApiService _apiService;
  final String sessionId;

  // Configuration (set before calling [start])
  int sessionDurationSeconds;
  int autoRefreshInterval; // seconds between QR token rotations
  bool autoRefresh;

  // Callbacks → provider updates UI state and calls notifyListeners()
  final void Function(int secondsRemaining) onTick;
  final void Function() onSessionExpired;
  final void Function(String qrData, int qrVersion, int refreshCountdown)
      onQrRefreshed;
  final void Function(List<dynamic> attendance) onAttendancePolled;

  // Internal
  Timer? _sessionTimer;
  Timer? _refreshTimer;
  Timer? _pollTimer;

  int _secondsRemaining = 0;
  int _qrRefreshCountdown = 0;

  LiveSessionTimerService({
    required FacultyApiService apiService,
    required this.sessionId,
    required this.sessionDurationSeconds,
    required this.autoRefreshInterval,
    required this.autoRefresh,
    required this.onTick,
    required this.onSessionExpired,
    required this.onQrRefreshed,
    required this.onAttendancePolled,
  }) : _apiService = apiService;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Starts all three timers. Call once after a QR session is created.
  void start() {
    _secondsRemaining = sessionDurationSeconds;
    _qrRefreshCountdown = autoRefreshInterval;

    _cancelAll();

    // 1. Session countdown (1 s tick)
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        dispose();
        onSessionExpired();
      } else {
        _secondsRemaining--;
        onTick(_secondsRemaining);
      }
    });

    // 2. QR auto-refresh (1 s tick, refreshes when countdown hits 0)
    if (autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_qrRefreshCountdown <= 0) {
          _doRefreshQr();
        } else {
          _qrRefreshCountdown--;
        }
      });
    }

    // 3. Attendance polling (every 5 s)
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _doPollAttendance();
    });
  }

  /// Forces an immediate QR refresh (used for manual "Regenerate" button when
  /// [autoRefresh] is false).
  Future<void> forceRefreshQr() async => _doRefreshQr();

  /// Cancels all timers. Safe to call multiple times.
  void dispose() {
    _cancelAll();
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _cancelAll() {
    _sessionTimer?.cancel();
    _refreshTimer?.cancel();
    _pollTimer?.cancel();
    _sessionTimer = null;
    _refreshTimer = null;
    _pollTimer = null;
  }

  Future<void> _doRefreshQr() async {
    try {
      final response = await _apiService.refreshQr(sessionId);
      final newQrData = response['qrData'] as String?;
      final newVersion = response['qrVersion'] as int?;
      _qrRefreshCountdown = autoRefreshInterval;

      if (newQrData != null) {
        onQrRefreshed(
          newQrData,
          newVersion ?? 0,
          _qrRefreshCountdown,
        );
      }
    } catch (e) {
      debugPrint('LiveSessionTimerService: QR refresh failed: $e');
    }
  }

  Future<void> _doPollAttendance() async {
    try {
      final polled = await _apiService.getSessionAttendance(sessionId);
      onAttendancePolled(polled);
    } catch (e) {
      debugPrint('LiveSessionTimerService: Attendance poll failed: $e');
    }
  }
}
