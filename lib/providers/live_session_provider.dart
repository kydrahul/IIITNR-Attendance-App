import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    await _loadRadius();
    await _initializeStudents();
  }

  Future<void> _loadRadius() async {
    final prefs = await SharedPreferences.getInstance();
    _locationRadius = prefs.getInt('default_scan_radius') ?? 50;
    notifyListeners();
  }

  Future<void> _initializeStudents() async {
    try {
      final listed = await _apiService.listCourseStudents(course['id']);
      _students.clear();
      for (var student in listed) {
        _students.add({
          'id': student.id,
          'name': student.name,
          'rollNo': student.rollNo,
          'isPresent': student.status?.toLowerCase() == 'present',
          'isEdited': false,
          'markedTime': student.markedAt ?? '',
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch students: $e');
    }
  }

  Future<void> updateAttendance(Map<String, dynamic> student, bool isPresent) async {
    if (student['isPresent'] != isPresent) {
      if (_sessionId != null && student['id'] != null) {
        await _apiService.saveManualAttendance(
            _sessionId!, student['id'], isPresent ? 'Present' : 'Absent');
      }

      student['isPresent'] = isPresent;
      student['isEdited'] = true;

      final now = DateTime.now();
      String ampm = now.hour >= 12 ? 'PM' : 'AM';
      int hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      String minute = now.minute.toString().padLeft(2, '0');
      student['markedTime'] = '$hour:$minute $ampm';

      _expandedStudentRollNo = null;
      notifyListeners();
    } else {
      _expandedStudentRollNo = null;
      notifyListeners();
    }
  }

  Future<void> generateQR() async {
    if (_selectedRoom == null) throw Exception("Please select a classroom");

    final response = await _apiService.generateQr(
      courseId: course['id']!,
      radius: _locationRadius,
      validitySeconds: _qrDuration * 60,
      classType: 'Theory',
    );

    final session = AttendanceSession.fromJson(response['session']);

    _sessionId = session.id;
    _qrValue = session.qrData;
    _qrActive = true;
    _sessionEnded = false;
    _sessionTimeRemaining = _qrDuration * 60;
    _qrRefreshCountdown = _autoRefreshInterval;
    _qrVersion = session.qrVersion;
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
        if (_qrRefreshCountdown <= 1) {
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
      final session = AttendanceSession.fromJson(response['session']);
      _qrVersion = session.qrVersion;
      _qrValue = session.qrData;
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
          if (_students[index]['isPresent'] != isPresent) {
            _students[index]['isPresent'] = isPresent;
            updated = true;
          }
          if (updatedStudent.markedAt != null && _students[index]['markedTime'] != updatedStudent.markedAt) {
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
