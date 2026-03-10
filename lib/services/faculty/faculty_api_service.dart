import '../../models/faculty/faculty_models.dart';
import '../../core/network/api_client.dart';

class FacultyApiService {
  static final FacultyApiService _instance = FacultyApiService._internal();
  factory FacultyApiService() => _instance;
  FacultyApiService._internal();

  final ApiClient _apiClient = ApiClient();

  // --- Faculty Endpoints ---

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final data = await _apiClient.get('/faculty/profile');
      return data['faculty'] ?? {};
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
  }) async {
    try {
      final body = {
        'courseId': courseId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radius != null) 'radius': radius,
        if (validitySeconds != null) 'validitySeconds': validitySeconds,
        'classType': classType ?? 'Theory',
      };
      return await _apiClient.post('/faculty/generate-qr', body: body);
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
}
