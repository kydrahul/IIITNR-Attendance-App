import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Get or generate device ID
  Future<String> getDeviceId() async {
    // Check if device ID already exists
    String? deviceId = await _storage.read(key: 'device_id');

    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    // Generate new device ID based on device info
    deviceId = await _generateDeviceId();
    await _storage.write(key: 'device_id', value: deviceId);

    return deviceId;
  }

  Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use Android ID (unique per device)
        return 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor (unique per device)
        return 'ios_${iosInfo.identifierForVendor}';
      }
    } catch (e) {
      debugPrint('Error generating device ID: $e');
    }

    // Fallback: generate random UUID
    return 'device_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Clear device ID (for admin unbinding)
  Future<void> clearDeviceId() async {
    await _storage.delete(key: 'device_id');
  }

  // Get device info for display
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return {'error': 'Unable to get device info'};
  }
}
