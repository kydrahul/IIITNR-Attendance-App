import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/faculty/faculty_api_service.dart';
import '../models/faculty/faculty_models.dart';

class LiveSessionProvider extends ChangeNotifier {
  final FacultyApiService _apiService = FacultyApiService();

  final Map<String, dynamic> course;

  LiveSessionProvider({required this.course}) {
    _init();
  }

  // Session States
  bool _qrActive = false;
  bool get qrActive => _qrActive;

  bool _sessionEnded = false;
  bool get sessionEnded => _sessionEnded;

  String? _sessionId;
  String? get sessionId => _sessionId;

  // Settings
  int _qrDuration = 5;
  int get qrDuration => _qrDuration;
  set qrDuration(int val) {
    _qrDuration = val;
    notifyListeners();
  }

  int _locationRadius = 25;
  int get locationRadius => _locationRadius;
  set locationRadius(int val) {
    _locationRadius = val;
    notifyListeners();
  }

  String? _selectedRoom;
  String? get selectedRoom => _selectedRoom;
  set selectedRoom(String? val) {
    _selectedRoom = val;
    notifyListeners();
  }

  bool _autoRefresh = true;
  bool get autoRefresh => _autoRefresh;
  set autoRefresh(bool val) {
    _autoRefresh = val;
    notifyListeners();
  }

  int _autoRefreshInterval = 10;
  int get autoRefreshInterval => _autoRefreshInterval;
  set autoRefreshInterval(int val) {
    _autoRefreshInterval = val;
    notifyListeners();
  }

  String _classType = 'Theory';
  String get classType => _classType;
  set classType(String val) {
    _classType = val;
    notifyListeners();
  }

  // Room & Proximity Info
  List<RoomModel> _rooms = [];
  List<RoomModel> get rooms => _rooms;

  bool _isLoadingRooms = false;
  bool get isLoadingRooms => _isLoadingRooms;

  bool _isLocationRequired = true;
  bool get isLocationRequired => _isLocationRequired;
  set isLocationRequired(bool val) {
    _isLocationRequired = val;
    notifyListeners();
  }

  // Timers Data
  Timer? _sessionTimer;
  Timer? _refreshTimer;
  Timer? _attendancePollTimer;

  int _sessionTimeRemaining = 300;
  int get sessionTimeRemaining => _sessionTimeRemaining;

  int _qrRefreshCountdown = 10;
  int get qrRefreshCountdown => _qrRefreshCountdown;

  int _qrVersion = 1;
  int get qrVersion => _qrVersion;

  String _qrValue = 'SessionData_v1';
  String get qrValue => _qrValue;

  // Manual Attendance States
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> get students => _students;

  String? _expandedStudentRollNo;
  String? get expandedStudentRollNo => _expandedStudentRollNo;
  void toggleExpandedStudent(String rollNo) {
    _expandedStudentRollNo = _expandedStudentRollNo == rollNo ? null : rollNo;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _refreshTimer?.cancel();
    _attendancePollTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    debugPrint('LiveSessionProvider: Starting parallel initialization...');

    // We run these in parallel so one slow API doesn't block the others
    await Future.wait([
      _loadSettings()
          .then((_) => debugPrint('LiveSessionProvider: Settings loaded')),
      fetchRooms().then((_) =>
          debugPrint('LiveSessionProvider: Rooms loaded (${_rooms.length})')),
      _initializeStudents()
          .then((_) => debugPrint('LiveSessionProvider: Students loaded')),
    ]).catchError((e) {
      debugPrint('LiveSessionProvider: Initialization error: $e');
      return []; // Return empty list to satisfy Future.wait
    });

    debugPrint('LiveSessionProvider: Initialization complete.');
  }

  Future<void> fetchRooms() async {
    _isLoadingRooms = true;
    notifyListeners();
    try {
      debugPrint('LiveSessionProvider: Calling _apiService.getRooms()...');
      _rooms = await _apiService.getRooms();
      debugPrint(
          'LiveSessionProvider: Successfully fetched ${_rooms.length} rooms.');
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
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      List<RoomModel> candidates = [];

      for (var room in _rooms) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          room.latitude,
          room.longitude,
        );

        // Potential candidate if within 30m
        if (distance < 30) {
          candidates.add(room);
        }
      }

      // Sort by distance if multiple candidates
      if (candidates.length > 1) {
        candidates.sort((a, b) {
          final distA = Geolocator.distanceBetween(
              position.latitude, position.longitude, a.latitude, a.longitude);
          final distB = Geolocator.distanceBetween(
              position.latitude, position.longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
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
      rethrow; // Rethrow to allow UI to show snackbar
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Local overrides (Radius, Interval)
    _locationRadius = prefs.getInt('default_scan_radius') ?? 50;
    _autoRefreshInterval = prefs.getInt('default_qr_refresh_interval') ?? 10;
    _qrRefreshCountdown = _autoRefreshInterval;

    // 2. Fetch Profile to get Global Location Preference
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

  Future<void> _initializeStudents() async {
    try {
      final listed = await _apiService.listCourseStudents(course['id'],
          sessionId: _sessionId);
      _students.clear();
      for (var student in listed) {
        _students.add({
          'id': student.id,
          'name': student.name,
          'rollNo': student.rollNo,
          'isPresent': student.status?.toLowerCase() == 'present',
          'isEdited': false,
          'markedTime': student.markedAt ?? '',
          'isUpdating': false,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch students: $e');
    }
  }

  Future<void> updateAttendance(
      Map<String, dynamic> student, bool isPresent) async {
    final originalStatus = student['isPresent'];
    if (originalStatus != isPresent) {
      // 1. Update local state immediately (Optimistic UI)
      student['isPresent'] = isPresent;
      student['isEdited'] = true;
      student['isUpdating'] =
          true; // Prevent polling from overwriting while we save

      final now = DateTime.now();
      String ampm = now.hour >= 12 ? 'PM' : 'AM';
      int hour =
          now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      String minute = now.minute.toString().padLeft(2, '0');
      student['markedTime'] = '$hour:$minute $ampm';

      _expandedStudentRollNo = null;
      notifyListeners();

      try {
        if (_sessionId != null && student['id'] != null) {
          // Backend expects lowercase 'present' or 'absent'
          await _apiService.saveManualAttendance(
              _sessionId!, student['id'], isPresent ? 'present' : 'absent');
        }
      } catch (e) {
        debugPrint('Failed to save manual attendance: $e');
        // 2. Rollback on error
        student['isPresent'] = originalStatus;
        student['isEdited'] = false;
        notifyListeners();
      } finally {
        student['isUpdating'] = false;
      }
    } else {
      _expandedStudentRollNo = null;
      notifyListeners();
    }
  }

  Future<void> generateQR() async {
    if (_isLocationRequired && _selectedRoom == null)
      throw Exception("Please select a classroom");

    RoomModel? room;
    if (_selectedRoom != null) {
      try {
        room = _rooms.firstWhere((r) => r.name == _selectedRoom);
      } catch (e) {
        // Handle custom room name if needed
      }
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
    _qrActive = true;
    _sessionEnded = false;
    _sessionTimeRemaining = _qrDuration * 60;
    _qrRefreshCountdown = _autoRefreshInterval;
    _qrVersion = response['qrVersion'] ?? session.qrVersion;
    notifyListeners();

    _startTimers();
    await _initializeStudents();
  }

  void _startTimers() {
    _sessionTimer?.cancel();
    _refreshTimer?.cancel();
    _attendancePollTimer?.cancel();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionTimeRemaining <= 0) {
        endSession();
      } else {
        _sessionTimeRemaining--;
        notifyListeners();
      }
    });

    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_qrRefreshCountdown <= 0) {
          _refreshQR();
        } else {
          _qrRefreshCountdown--;
          notifyListeners();
        }
      });
    }

    _attendancePollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollAttendance();
    });
  }

  Future<void> _refreshQR() async {
    if (_sessionId == null) return;
    try {
      final response = await _apiService.refreshQr(_sessionId!);
      _qrVersion = response['qrVersion'] ?? (_qrVersion + 1);
      _qrValue = response['qrData'] ?? _qrValue;
      _qrRefreshCountdown = _autoRefreshInterval;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh QR: $e');
    }
  }

  Future<void> regenerateQR() async {
    if (_autoRefresh || _sessionId == null) return;
    await _refreshQR();
  }

  Future<void> _pollAttendance() async {
    if (_sessionId == null) return;
    try {
      final polled = await _apiService.getSessionAttendance(_sessionId!);
      bool updated = false;
      for (var updatedStudent in polled) {
        final isPresent = updatedStudent.status?.toLowerCase() == 'present';
        final index = _students.indexWhere((s) => s['id'] == updatedStudent.id);
        if (index != -1) {
          // Skip if this student is currently being manually updated
          if (_students[index]['isUpdating'] == true) continue;

          if (_students[index]['isPresent'] != isPresent) {
            _students[index]['isPresent'] = isPresent;
            updated = true;
          }
          if (updatedStudent.markedAt != null &&
              _students[index]['markedTime'] != updatedStudent.markedAt) {
            _students[index]['markedTime'] = updatedStudent.markedAt!;
            updated = true;
          }
        }
      }
      if (updated) notifyListeners();
    } catch (e) {
      debugPrint('Poll attendance error: $e');
    }
  }

  Future<void> endSession() async {
    _sessionTimer?.cancel();
    _refreshTimer?.cancel();
    _attendancePollTimer?.cancel();

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
