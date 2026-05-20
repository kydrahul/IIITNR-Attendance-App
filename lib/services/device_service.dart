import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Get or generate device ID
  Future<String> getDeviceId() async {
    // Check if device ID already exists in storage
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
      // Use kIsWeb guard — dart:io Platform class is not available on web
      if (kIsWeb) {
        // On web: generate a stable UUID stored in secure storage (localStorage).
        // Students use web only for viewing stats, not for QR scanning.
        // Faculty on web get a browser-scoped ID — device binding is not enforced for faculty.
        return _generateUuid(prefix: 'web');
      }

      // Use conditional import-safe approach via device_info_plus
      final webInfo = await _tryGetMobileDeviceId();
      if (webInfo != null) return webInfo;
    } catch (e) {
      debugPrint('Error generating device ID: $e');
    }

    // Fallback: generate a UUID v4
    return _generateUuid(prefix: 'device');
  }

  Future<String?> _tryGetMobileDeviceId() async {
    try {
      // device_info_plus handles platform detection internally
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'android_${androidInfo.id}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor}';
      }
    } catch (e) {
      debugPrint('Mobile device ID fetch failed: $e');
    }
    return null;
  }

  String _generateUuid({String prefix = 'device'}) {
    final random = Random.secure();
    String hex(int n) => random.nextInt(n).toRadixString(16).padLeft(2, '0');
    final uuid = [
      List.generate(4, (_) => hex(256)).join(),
      List.generate(2, (_) => hex(256)).join(),
      '4${hex(16)}${hex(256)}',
      ((random.nextInt(4) + 8).toRadixString(16)) +
          List.generate(3, (_) => hex(256)).join(),
      List.generate(6, (_) => hex(256)).join(),
    ].join('-');
    return '${prefix}_$uuid';
  }

  // Clear device ID (for admin unbinding)
  Future<void> clearDeviceId() async {
    await _storage.delete(key: 'device_id');
  }

  // Get device info for display
  Future<Map<String, String>> getDeviceInfo() async {
    if (kIsWeb) {
      return {'platform': 'Web Browser'};
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
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
