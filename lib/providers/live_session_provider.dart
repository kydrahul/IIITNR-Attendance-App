import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/faculty/faculty_api_service.dart';
import '../services/live_session_timer_service.dart';
import '../models/faculty/faculty_models.dart';
import '../services/connectivity_service.dart';

/// Holds all UI-visible state for an active live QR attendance session.
///
/// Timer/polling concerns are fully delegated to [LiveSessionTimerService];
/// this class only receives callbacks from the service and calls
/// [notifyListeners] so the widget tree can rebuild.
class LiveSessionProvider extends ChangeNotifier {
  final FacultyApiService _apiService = FacultyApiService();
  final Map<String, dynamic> course;

  LiveSessionProvider({required this.course}) {
    _init();
  }

  // ─── Session state ─────────────────────────────────────────────────────────
  bool _qrActive = false;
  bool get qrActive => _qrActive;

  bool _sessionEnded = false;
  bool get sessionEnded => _sessionEnded;

  String? _sessionId;
  String? get sessionId => _sessionId;

  // ─── QR / timer display values ────────────────────────────────────────────
  String _qrValue = 'SessionData_v1';
  String get qrValue => _qrValue;

  int _qrVersion = 1;
  int get qrVersion => _qrVersion;

  int _sessionTimeRemaining = 300;
  int get sessionTimeRemaining => _sessionTimeRemaining;

  int _qrRefreshCountdown = 10;
  int get qrRefreshCountdown => _qrRefreshCountdown;

  // ─── Settings ─────────────────────────────────────────────────────────────
  int _qrDuration = 5; // minutes
  int get qrDuration => _qrDuration;
  set qrDuration(int val) { _qrDuration = val; notifyListeners(); }

  int _locationRadius = 25;
  int get locationRadius => _locationRadius;
  set locationRadius(int val) { _locationRadius = val; notifyListeners(); }

  String? _selectedRoom;
  String? get selectedRoom => _selectedRoom;
  set selectedRoom(String? val) { _selectedRoom = val; notifyListeners(); }

  bool _autoRefresh = true;
  bool get autoRefresh => _autoRefresh;
  set autoRefresh(bool val) { _autoRefresh = val; notifyListeners(); }

  int _autoRefreshInterval = 10;
  int get autoRefreshInterval => _autoRefreshInterval;
  set autoRefreshInterval(int val) { _autoRefreshInterval = val; notifyListeners(); }

  String _classType = 'Theory';
  String get classType => _classType;
  set classType(String val) { _classType = val; notifyListeners(); }

  bool _isLocationRequired = true;
  bool get isLocationRequired => _isLocationRequired;
  set isLocationRequired(bool val) { _isLocationRequired = val; notifyListeners(); }

  // ─── Rooms ────────────────────────────────────────────────────────────────
  List<RoomModel> _rooms = [];
  List<RoomModel> get rooms => _rooms;

  bool _isLoadingRooms = false;
  bool get isLoadingRooms => _isLoadingRooms;

  // ─── Student list (manual attendance) ─────────────────────────────────────
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> get students => _students;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }

  String? _expandedStudentRollNo;
  String? get expandedStudentRollNo => _expandedStudentRollNo;
  void toggleExpandedStudent(String rollNo) {
    _expandedStudentRollNo = _expandedStudentRollNo == rollNo ? null : rollNo;
    notifyListeners();
  }

  // ─── Timer service (owned here, delegates work outwards) ──────────────────
  LiveSessionTimerService? _timerService;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _timerService?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    debugPrint('LiveSessionProvider: Starting parallel initialization...');
    await Future.wait([
      _loadSettings()
          .then((_) => debugPrint('LiveSessionProvider: Settings loaded')),
      fetchRooms().then((_) =>
          debugPrint('LiveSessionProvider: Rooms loaded (${_rooms.length})')),
      _initializeStudents()
          .then((_) => debugPrint('LiveSessionProvider: Students loaded')),
    ]).catchError((e) {
      debugPrint('LiveSessionProvider: Initialization error: $e');
      return <void>[];
    });
    debugPrint('LiveSessionProvider: Initialization complete.');
  }

  // ─── Rooms & proximity ────────────────────────────────────────────────────

  Future<void> fetchRooms() async {
    if (!ConnectivityService().isOnline) {
      debugPrint('LiveSessionProvider: fetchRooms skipped — offline');
      _isLoadingRooms = false;
      notifyListeners();
      return;
    }
    _isLoadingRooms = true;
    notifyListeners();
    try {
      _rooms = await _apiService.getRooms();
    } catch (e) {
      debugPrint('LiveSessionProvider: Failed to fetch rooms: $e');
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  Future<List<RoomModel>> detectNearestRoom() async {
    if (!_isLocationRequired) return [];
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
                'GPS timed out. Move to an open area and try again.'),
          );

      final candidates = <RoomModel>[];
      for (final room in _rooms) {
        final distance = Geolocator.distanceBetween(
            position.latitude, position.longitude,
            room.latitude, room.longitude);
        if (distance < 30) candidates.add(room);
      }

      if (candidates.length > 1) {
        candidates.sort((a, b) {
          final dA = Geolocator.distanceBetween(
              position.latitude, position.longitude, a.latitude, a.longitude);
          final dB = Geolocator.distanceBetween(
              position.latitude, position.longitude, b.latitude, b.longitude);
          return dA.compareTo(dB);
        });
        return candidates;
      } else if (candidates.length == 1) {
        _selectedRoom = candidates.first.name;
        notifyListeners();
        return candidates;
      }
      return [];
    } catch (e) {
      debugPrint('Proximity detection failed: $e');
      rethrow;
    }
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _locationRadius = prefs.getInt('default_scan_radius') ?? 50;
    _autoRefreshInterval = prefs.getInt('default_qr_refresh_interval') ?? 10;
    _qrRefreshCountdown = _autoRefreshInterval;
    try {
      final profile = await _apiService.getProfile();
      final settings = profile.settings;
      if (settings.containsKey('defaultIsLocationRequired')) {
        _isLocationRequired = settings['defaultIsLocationRequired'] == true;
      }
    } catch (e) {
      debugPrint('Failed to load profile settings for location: $e');
    }
    notifyListeners();
  }

  // ─── Students ─────────────────────────────────────────────────────────────

  Future<void> _initializeStudents() async {
    try {
      final listed = await _apiService.listCourseStudents(
          course['id'], sessionId: _sessionId);
      _students = listed
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'rollNo': s.rollNo,
                'isPresent': s.status?.toLowerCase() == 'present',
                'isEdited': false,
                'markedTime': s.markedAt ?? '',
                'isUpdating': false,
              })
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch students: $e');
    }
  }

  Future<void> updateAttendance(
      Map<String, dynamic> student, bool isPresent) async {
    final originalStatus = student['isPresent'];
    if (originalStatus == isPresent) {
      _expandedStudentRollNo = null;
      notifyListeners();
      return;
    }

    // Optimistic update
    student['isPresent'] = isPresent;
    student['isEdited'] = true;
    student['isUpdating'] = true;
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    student['markedTime'] =
        '$h:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _expandedStudentRollNo = null;
    notifyListeners();

    try {
      if (_sessionId != null && student['id'] != null) {
        await _apiService.saveManualAttendance(
            _sessionId!, student['id'], isPresent ? 'present' : 'absent');
      }
    } catch (e) {
      debugPrint('Failed to save manual attendance: $e');
      student['isPresent'] = originalStatus;
      student['isEdited'] = false;
      notifyListeners();
    } finally {
      student['isUpdating'] = false;
    }
  }

  // ─── Session lifecycle ────────────────────────────────────────────────────

  Future<void> generateQR() async {
    // ── Offline guard ───────────────────────────────────────────────────────
    if (!ConnectivityService().isOnline) {
      throw Exception(
          'No internet connection. Connect to the network and try again.');
    }

    if (_isLocationRequired && _selectedRoom == null) {
      throw Exception('Please select a classroom');
    }

    RoomModel? room;
    if (_selectedRoom != null) {
      try {
        room = _rooms.firstWhere((r) => r.name == _selectedRoom);
      } catch (_) {}
    }

    final response = await _apiService.generateQr(
      courseId: course['id']!,
      radius: _locationRadius,
      validitySeconds: _qrDuration * 60,
      classType: _classType,
      roomNumber: _selectedRoom,
      latitude: room?.latitude,
      longitude: room?.longitude,
      isLocationRequired: _isLocationRequired,
    );

    final session = AttendanceSession.fromJson(response['session']);
    _sessionId = session.id;
    _qrValue = response['qrData'] ?? session.qrData;
    _qrVersion = response['qrVersion'] ?? session.qrVersion;
    _qrActive = true;
    _sessionEnded = false;
    _sessionTimeRemaining = _qrDuration * 60;
    _qrRefreshCountdown = _autoRefreshInterval;
    notifyListeners();

    // Hand off all timer responsibility to the service
    _timerService?.dispose();
    _timerService = LiveSessionTimerService(
      apiService: _apiService,
      sessionId: _sessionId!,
      sessionDurationSeconds: _qrDuration * 60,
      autoRefreshInterval: _autoRefreshInterval,
      autoRefresh: _autoRefresh,
      // ── Callbacks: service → provider ──────────────────────────────────
      onTick: (remaining) {
        _sessionTimeRemaining = remaining;
        notifyListeners();
      },
      onSessionExpired: () {
        _qrActive = false;
        _sessionEnded = true;
        notifyListeners();
      },
      onQrRefreshed: (qrData, version, countdown) {
        _qrValue = qrData;
        _qrVersion = version;
        _qrRefreshCountdown = countdown;
        notifyListeners();
      },
      onAttendancePolled: _applyPolledAttendance,
    );
    _timerService!.start();

    await _initializeStudents();
  }

  /// Applies polled attendance updates, skipping students currently being
  /// manually updated (optimistic-update guard).
  void _applyPolledAttendance(List<dynamic> polled) {
    bool updated = false;
    for (final updated_ in polled) {
      final isPresent = updated_.status?.toLowerCase() == 'present';
      final idx = _students.indexWhere((s) => s['id'] == updated_.id);
      if (idx == -1) continue;
      if (_students[idx]['isUpdating'] == true) continue;
      if (_students[idx]['isPresent'] != isPresent) {
        _students[idx]['isPresent'] = isPresent;
        updated = true;
      }
      if (updated_.markedAt != null &&
          _students[idx]['markedTime'] != updated_.markedAt) {
        _students[idx]['markedTime'] = updated_.markedAt!;
        updated = true;
      }
    }
    if (updated) notifyListeners();
  }

  /// Manually triggers a QR refresh (used when [autoRefresh] is false).
  Future<void> regenerateQR() async {
    if (_autoRefresh || _timerService == null) return;
    await _timerService!.forceRefreshQr();
  }

  Future<void> endSession() async {
    _timerService?.dispose();
    _timerService = null;

    if (_sessionId != null) {
      try {
        await _apiService.stopSession(_sessionId!);
      } catch (e) {
        debugPrint('Failed to stop session: $e');
      }
    }

    _qrActive = false;
    _sessionEnded = true;
    notifyListeners();
  }

  void startNewSession() {
    _sessionEnded = false;
    _qrActive = false;
    notifyListeners();
  }
}
