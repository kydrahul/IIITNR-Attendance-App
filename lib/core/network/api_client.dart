import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../config/app_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final AuthService _authService = AuthService();
  final DeviceService _deviceService = DeviceService();

  ApiClient._internal();

  /// Generic GET request
  Future<dynamic> get(String endpoint, {bool useToken = true}) async {
    return _request('GET', endpoint, useToken: useToken);
  }

  /// Generic POST request
  Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? body, bool useToken = true}) async {
    return _request('POST', endpoint, body: body, useToken: useToken);
  }

  /// Generic DELETE request
  Future<dynamic> delete(String endpoint, {bool useToken = true}) async {
    return _request('DELETE', endpoint, useToken: useToken);
  }

  /// Generic PUT request
  Future<dynamic> put(String endpoint,
      {Map<String, dynamic>? body, bool useToken = true}) async {
    return _request('PUT', endpoint, body: body, useToken: useToken);
  }

  Future<dynamic> _request(String method, String endpoint,
      {Map<String, dynamic>? body, bool useToken = true}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (useToken) {
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      try {
        final deviceId = await _deviceService.getDeviceId();
        headers['x-device-id'] = deviceId;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error getting device ID for headers: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('api_client: $method $url');
    }

    http.Response response;
    try {
      if (method == 'GET') {
        response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 30));
      } else if (method == 'POST') {
        response = await http
            .post(url,
                headers: headers, body: body != null ? json.encode(body) : null)
            .timeout(const Duration(seconds: 30));
      } else if (method == 'DELETE') {
        response = await http
            .delete(url, headers: headers)
            .timeout(const Duration(seconds: 30));
      } else if (method == 'PUT') {
        response = await http
            .put(url,
                headers: headers, body: body != null ? json.encode(body) : null)
            .timeout(const Duration(seconds: 30));
      } else {
        throw Exception('Unsupported HTTP method');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('api_client: Network error on $method $url - $e');
      }
      throw Exception(
          'Network error: Ensure you are connected to the internet.');
    }

    return _handleResponse(response, url.toString());
  }

  dynamic _handleResponse(http.Response response, String url) {
    if (kDebugMode) {
      debugPrint(
          'api_client: Response from $url -> Status: ${response.statusCode}');
    }

    final String body = response.body;
    dynamic data;
    if (body.isNotEmpty) {
      try {
        data = json.decode(body);
      } catch (_) {
        data = body;
      }
    } else {
      data = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      String errorMessage = 'Request failed';
      if (data is Map && data['error'] != null) {
        errorMessage = data['error'].toString();
      } else if (data is Map && data['message'] != null) {
        errorMessage = data['message'].toString();
      } else if (data is Map && data['details'] != null) {
        errorMessage = data['details'].toString();
      } else if (body.isNotEmpty) {
        errorMessage = body;
      }

      if (kDebugMode) {
        debugPrint('api_client: Error $errorMessage');
      }
      throw ApiException(response.statusCode, errorMessage);
    }
  }
}
