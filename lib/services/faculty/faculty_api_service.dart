import 'package:flutter/foundation.dart';
import '../../models/faculty/faculty_models.dart';
import '../../core/network/api_client.dart';

class FacultyApiService {
  static final FacultyApiService _instance = FacultyApiService._internal();
  factory FacultyApiService() => _instance;
  FacultyApiService._internal();

  final ApiClient _apiClient = ApiClient();
  FacultyProfile? _cachedProfile;

  // --- Faculty Endpoints ---

  Future<FacultyProfile> getProfile({bool forceRefresh = false}) async {
    if (_cachedProfile != null && !forceRefresh) {
      return _cachedProfile!;
    }
    try {
      final data = await _apiClient.get('/faculty/profile');
      _cachedProfile = FacultyProfile.fromJson(data['faculty'] ?? {});
      return _cachedProfile!;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<FacultyProfile> updateProfile(Map<String, dynamic> body) async {
    try {
      final data = await _apiClient.post('/faculty/profile', body: body);
      _cachedProfile = FacultyProfile.fromJson(data['faculty'] ?? {});
      return _cachedProfile!;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Course>> listCourses() async {
    try {
      final data = await _apiClient.get('/faculty/courses');
      final List coursesJson = data['courses'] ?? [];
      return coursesJson.map((json) => Course.fromJson(json)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _apiClient.delete('/faculty/courses/$courseId');
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
      debugPrint('FacultyApiService: getRooms response type: ${data.runtimeType}');
      
      // If server returns HTML (404), 'data' will be a String, not a List
      if (data is! List) {
        debugPrint('FacultyApiService: getRooms expected List but got ${data.runtimeType}');
        return [];
      }

      final List roomsJson = data;
      return roomsJson.map((json) => RoomModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      debugPrint('FacultyApiService: getRooms error: ${e.message}');
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
      return await _apiClient.post('/faculty/classes/full', body: payload);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getCourseAttendanceGrid(String courseId) async {
    try {
      return await _apiClient.get('/faculty/course/$courseId/attendance-grid');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> updateCourseSchedule({
    required String courseId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      return await _apiClient.put('/faculty/courses/$courseId', body: payload);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
