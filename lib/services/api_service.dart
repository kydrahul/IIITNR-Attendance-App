import '../core/network/api_client.dart';

class ApiService {
  final ApiClient _apiClient = ApiClient();

  // Get Student Profile
  Future<Map<String, dynamic>> getProfile(
      {bool checkProfileExists = false}) async {
    final endpoint = checkProfileExists
        ? '/student/profile?nocache=true'
        : '/student/profile';
    try {
      final data = await _apiClient.get(endpoint);
      return data['student'];
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Profile not found');
      } else {
        throw Exception('Server Error ${e.statusCode}: ${e.message}');
      }
    }
  }

  // Verify Location (Geofence check)
  Future<Map<String, dynamic>> verifyLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      return await _apiClient.post('/student/verify-location', body: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create/Update Student Profile
  Future<Map<String, dynamic>> createProfile({
    required String name,
    required int rollNo,
    required String department,
    required int passingYear,
  }) async {
    try {
      return await _apiClient.post('/student/profile', body: {
        'name': name,
        'rollNo': rollNo,
        'department': department,
        'passingYear': passingYear,
      });
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw DeviceMismatchException(e.message);
      }
      throw Exception('Failed to create profile: ${e.message}');
    }
  }

  // Get Student Dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      return await _apiClient.get('/student/dashboard');
    } on ApiException catch (e) {
      throw Exception('Failed to fetch dashboard: ${e.message}');
    }
  }

  // Scan QR Code
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

  // Join Course
  Future<Map<String, dynamic>> joinCourse(String joinCode) async {
    try {
      return await _apiClient
          .post('/student/join-course', body: {'joinCode': joinCode});
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get Enrolled Courses
  Future<List<dynamic>> getCourses() async {
    try {
      final data = await _apiClient.get('/student/courses');
      return data['courses'] ?? [];
    } on ApiException catch (e) {
      throw Exception('Failed to fetch courses: ${e.message}');
    }
  }

  // Get Timetable
  Future<Map<String, dynamic>> getTimetable() async {
    try {
      final data = await _apiClient.get('/student/timetable');
      return data['timetable'] ?? {};
    } on ApiException catch (e) {
      throw Exception('Failed to fetch timetable: ${e.message}');
    }
  }

  // Get Attendance History
  Future<List<dynamic>> getAttendanceHistory({String? courseId}) async {
    String endpoint = '/student/attendance-history';
    if (courseId != null) {
      endpoint += '?courseId=$courseId';
    }
    try {
      final data = await _apiClient.get(endpoint);
      return data['attendanceRecords'] ?? [];
    } on ApiException catch (e) {
      throw Exception('Failed to fetch attendance history: ${e.message}');
    }
  }
}

// Custom exception for device mismatch
class DeviceMismatchException implements Exception {
  final String message;
  DeviceMismatchException(this.message);

  @override
  String toString() => message;
}
