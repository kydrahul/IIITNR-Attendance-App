import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final ApiClient _apiClient = ApiClient();

  // In-Memory Cache
  Map<String, dynamic>? _cachedProfile;
  Map<String, dynamic>? _cachedDashboard;
  List<dynamic>? _cachedCourses;
  Map<String, dynamic>? _cachedTimetable;

  // Cache Keys
  static const String _kProfileKey = 'student_profile_cache';
  static const String _kDashboardKey = 'student_dashboard_cache';
  static const String _kCoursesKey = 'student_courses_cache';
  static const String _kTimetableKey = 'student_timetable_cache';
  static const String _kHistoryKey = 'student_history_cache';

  // --- Helpers ---

  Future<void> _saveToPrefs(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      debugPrint('ApiService: Error saving to prefs: $e');
    }
  }

  Future<dynamic> _loadFromPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString(key);
      if (cached != null) {
        return json.decode(cached);
      }
    } catch (e) {
      debugPrint('ApiService: Error loading from prefs: $e');
    }
    return null;
  }

  // --- Student Endpoints ---

  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false, bool checkProfileExists = false}) async {
    if (!forceRefresh && !checkProfileExists) {
      if (_cachedProfile != null) return _cachedProfile!;
      final cached = await _loadFromPrefs(_kProfileKey);
      if (cached != null) {
        _cachedProfile = cached;
        return cached;
      }
    }

    final endpoint = checkProfileExists
        ? '/student/profile?nocache=true'
        : '/student/profile';
    try {
      final data = await _apiClient.get(endpoint);
      final profile = data['student'] ?? {};
      _cachedProfile = profile;
      _saveToPrefs(_kProfileKey, profile);
      return profile;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Profile not found');
      } else {
        throw Exception('Server Error ${e.statusCode}: ${e.message}');
      }
    }
  }

  // [verifyLocation() removed: Campus-wide geofencing endpoint was deleted from backend]

  Future<Map<String, dynamic>> createProfile({
    required String name,
    required int rollNo,
    required String department,
    required int passingYear,
  }) async {
    try {
      final response = await _apiClient.post('/student/profile', body: {
        'name': name,
        'rollNo': rollNo,
        'department': department,
        'passingYear': passingYear,
      });
      _cachedProfile = response['student'];
      _saveToPrefs(_kProfileKey, _cachedProfile);
      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw DeviceMismatchException(e.message);
      }
      throw Exception('Failed to create profile: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getDashboard({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_cachedDashboard != null) return _cachedDashboard!;
      final cached = await _loadFromPrefs(_kDashboardKey);
      if (cached != null) {
        _cachedDashboard = cached;
        return cached;
      }
    }

    try {
      final data = await _apiClient.get('/student/dashboard');
      _cachedDashboard = data;
      _saveToPrefs(_kDashboardKey, data);
      return data;
    } on ApiException catch (e) {
      throw Exception('Failed to fetch dashboard: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> scanQR({
    required String qrData,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      return await _apiClient.post('/student/scan-qr', body: {
        'qrData': qrData,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> joinCourse(String joinCode) async {
    try {
      final response = await _apiClient.post('/student/join-course', body: {'joinCode': joinCode});
      _cachedCourses = null; // Invalidate
      return response;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<dynamic>> getCourses({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_cachedCourses != null) return _cachedCourses!;
      final cached = await _loadFromPrefs(_kCoursesKey);
      if (cached != null) {
        _cachedCourses = cached as List;
        return _cachedCourses!;
      }
    }

    try {
      final data = await _apiClient.get('/student/courses');
      final list = data['courses'] ?? [];
      _cachedCourses = list;
      _saveToPrefs(_kCoursesKey, list);
      return list;
    } on ApiException catch (e) {
      throw Exception('Failed to fetch courses: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getTimetable({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_cachedTimetable != null) return _cachedTimetable!;
      final cached = await _loadFromPrefs(_kTimetableKey);
      if (cached != null) {
        _cachedTimetable = cached as Map<String, dynamic>;
        return _cachedTimetable!;
      }
    }

    try {
      final data = await _apiClient.get('/student/timetable');
      final timetable = data['timetable'] ?? {};
      _cachedTimetable = timetable;
      _saveToPrefs(_kTimetableKey, timetable);
      return timetable;
    } on ApiException catch (e) {
      throw Exception('Failed to fetch timetable: ${e.message}');
    }
  }

  Future<List<dynamic>> getAttendanceHistory({String? courseId, bool forceRefresh = false}) async {
    if (!forceRefresh && courseId == null) {
      final cached = await _loadFromPrefs(_kHistoryKey);
      if (cached != null) return cached;
    }

    String endpoint = '/student/attendance-history';
    if (courseId != null) {
      endpoint += '?courseId=$courseId';
    }
    try {
      final data = await _apiClient.get(endpoint);
      final history = data['attendanceRecords'] ?? [];
      if (courseId == null) {
        _saveToPrefs(_kHistoryKey, history);
      }
      return history;
    } on ApiException catch (e) {
      throw Exception('Failed to fetch attendance history: ${e.message}');
    }
  }

  Future<void> clearCache() async {
    _cachedProfile = null;
    _cachedDashboard = null;
    _cachedCourses = null;
    _cachedTimetable = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileKey);
    await prefs.remove(_kDashboardKey);
    await prefs.remove(_kCoursesKey);
    await prefs.remove(_kTimetableKey);
    await prefs.remove(_kHistoryKey);
  }
}

class DeviceMismatchException implements Exception {
  final String message;
  DeviceMismatchException(this.message);

  @override
  String toString() => message;
}
