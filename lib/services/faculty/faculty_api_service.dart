import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/faculty/faculty_models.dart';
import '../../core/network/api_client.dart';

class FacultyApiService {
  static final FacultyApiService _instance = FacultyApiService._internal();
  factory FacultyApiService() => _instance;
  FacultyApiService._internal();

  final ApiClient _apiClient = ApiClient();
  
  // In-Memory Cache
  FacultyProfile? _cachedProfile;
  List<Course>? _cachedCourses;
  final Map<String, dynamic> _cachedGrids = {};

  // Cache Keys
  static const String _kProfileKey = 'faculty_profile_cache';
  static const String _kCoursesKey = 'faculty_courses_cache';

  // --- Helpers ---

  Future<void> _saveToPrefs(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      debugPrint('FacultyApiService: Error saving to prefs: $e');
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
      debugPrint('FacultyApiService: Error loading from prefs: $e');
    }
    return null;
  }

  // --- Faculty Endpoints ---

  Future<FacultyProfile> getProfile({bool forceRefresh = false}) async {
    // 1. Check memory cache
    if (_cachedProfile != null && !forceRefresh) {
      return _cachedProfile!;
    }

    // 2. Check persistent cache
    if (!forceRefresh) {
      final cachedData = await _loadFromPrefs(_kProfileKey);
      if (cachedData != null) {
        _cachedProfile = FacultyProfile.fromJson(cachedData['faculty'] ?? cachedData);
        return _cachedProfile!;
      }
    }

    // 3. Fetch from API
    try {
      final data = await _apiClient.get('/faculty/profile');
      final facultyData = data['faculty'] ?? {};
      _cachedProfile = FacultyProfile.fromJson(facultyData);
      
      // Save for next time
      _saveToPrefs(_kProfileKey, facultyData);
      
      return _cachedProfile!;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Check if the authenticated user is allowed to access faculty features.
  /// Returns true if allowed (email pattern match or whitelist exception).
  Future<bool> verifyFacultyAccess() async {
    try {
      final data = await _apiClient.get('/auth/verify-faculty');
      return data['allowed'] == true;
    } catch (e) {
      debugPrint('FacultyApiService: verifyFacultyAccess error: $e');
      return false;
    }
  }

  Future<FacultyProfile> updateProfile(Map<String, dynamic> body) async {
    try {
      final data = await _apiClient.post('/faculty/profile', body: body);
      final facultyData = data['faculty'] ?? {};
      _cachedProfile = FacultyProfile.fromJson(facultyData);
      _saveToPrefs(_kProfileKey, facultyData);
      return _cachedProfile!;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Course>> listCourses({bool forceRefresh = false}) async {
    // 1. Check memory cache
    if (_cachedCourses != null && !forceRefresh) {
      return _cachedCourses!;
    }

    // 2. Check persistent cache
    if (!forceRefresh) {
      final cachedData = await _loadFromPrefs(_kCoursesKey);
      if (cachedData != null) {
        final List list = cachedData is List ? cachedData : (cachedData['courses'] ?? []);
        _cachedCourses = list.map((json) => Course.fromJson(json)).toList();
        return _cachedCourses!;
      }
    }

    // 3. Fetch from API
    try {
      final data = await _apiClient.get('/faculty/courses');
      final List coursesJson = data['courses'] ?? [];
      _cachedCourses = coursesJson.map((json) => Course.fromJson(json)).toList();
      
      // Save for next time
      _saveToPrefs(_kCoursesKey, coursesJson);
      
      return _cachedCourses!;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _apiClient.delete('/faculty/courses/$courseId');
      // Invalidate course cache
      _cachedCourses = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCoursesKey);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> generateQr({
    required String courseId,
    double? latitude,
    double? longitude,
    int? radius,
    int? validitySeconds,
    String? classType,
    String? roomNumber,
    bool isLocationRequired = true,
  }) async {
    try {
      final body = {
        'courseId': courseId,
        if (roomNumber != null) 'roomNumber': roomNumber,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radius != null) 'radius': radius,
        if (validitySeconds != null) 'validitySeconds': validitySeconds,
        'classType': classType ?? 'Theory',
        'isLocationRequired': isLocationRequired,
      };
      return await _apiClient.post('/faculty/generate-qr', body: body);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<RoomModel>> getRooms() async {
    try {
      final data = await _apiClient.get('/rooms');
      // Backend may return a raw List or a {success, rooms: [...]} wrapper
      final List roomsList = data is List ? data : (data['rooms'] ?? []);
      return roomsList.map((json) => RoomModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> refreshQr(String sessionId) async {
    try {
      return await _apiClient
          .post('/faculty/refresh-qr', body: {'sessionId': sessionId});
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> stopSession(String sessionId) async {
    try {
      await _apiClient.post('/faculty/session/$sessionId/stop');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Student>> getSessionAttendance(String sessionId) async {
    try {
      final data =
          await _apiClient.get('/faculty/session/$sessionId/attendance');
      final List attendeesJson = data['attendees'] ?? [];
      return attendeesJson.map((json) => Student.fromJson(json)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Student>> listCourseStudents(String courseId,
      {String? sessionId}) async {
    String endpoint = '/faculty/course/$courseId/students';
    if (sessionId != null) {
      endpoint += '?sessionId=${Uri.encodeComponent(sessionId)}';
    }
    try {
      final data = await _apiClient.get(endpoint);
      final List studentsJson = data['students'] ?? [];
      return studentsJson.map((json) => Student.fromJson(json)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> saveManualAttendance(
      String sessionId, String studentId, String status) async {
    try {
      await _apiClient.post('/faculty/session/$sessionId/manual-attendance',
          body: {'studentId': studentId, 'status': status});
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> createFullClass(
      Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.post('/faculty/classes/full', body: payload);
      // Invalidate course cache
      _cachedCourses = null;
      return response;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getCourseAttendanceGrid(String courseId, {bool forceRefresh = false}) async {
    if (_cachedGrids.containsKey(courseId) && !forceRefresh) {
      return _cachedGrids[courseId];
    }
    
    try {
      final data = await _apiClient.get('/faculty/course/$courseId/attendance-grid');
      _cachedGrids[courseId] = data;
      return data;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> updateCourseSchedule({
    required String courseId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _apiClient.put('/faculty/courses/$courseId', body: payload);
      _cachedCourses = null; // Invalidate
      return response;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Clears all local caches. Use this on logout.
  Future<void> clearCache() async {
    _cachedProfile = null;
    _cachedCourses = null;
    _cachedGrids.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileKey);
    await prefs.remove(_kCoursesKey);
  }
}
