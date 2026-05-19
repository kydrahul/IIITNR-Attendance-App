import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/network/api_client.dart';
import '../core/utils/logger.dart';
import '../utils/geofence_utils.dart';
import '../services/connectivity_service.dart';

class ScannerProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
    autoStart: true,
    cameraResolution: const Size(1280, 720),
  );

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isTorchOn = false;
  bool get isTorchOn => _isTorchOn;

  Map<String, double>? _cachedLocation;
  DateTime? _lastScanTime;

  ScannerProvider() {
    _startLocationUpdates();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 3), // Optimization: initial timeout
        ).catchError((_) async {
            // Fallback to last known position
            final lastPosition = await Geolocator.getLastKnownPosition();
            if (lastPosition != null) return lastPosition;
            throw Exception("Initial location fetch timeout");
        });
        
        _cachedLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        };
      } catch (e) {
        AppLogger.w("Initial location fetch failed: $e");
      }
    }
  }

  Future<Map<String, double>> _getCurrentLocation() async {
    if (_cachedLocation != null) return _cachedLocation!;

    final permission = await Permission.location.request();
    if (!permission.isGranted) {
      throw Exception('Location permission denied');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // Optimization: timeout
      ).catchError((e) async {
         final lastKnown = await Geolocator.getLastKnownPosition();
         if (lastKnown != null) {
           return lastKnown;
         }
         throw e;
      });

      _cachedLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };

      return _cachedLocation!;
    } catch (e) {
       AppLogger.e('Current location fetch failed: $e');
       throw Exception('Failed to get location');
    }
  }

  void toggleTorch() {
    cameraController.toggleTorch();
    _isTorchOn = !_isTorchOn;
    notifyListeners();
  }

  Future<String> handleQRCode(String qrData, BuildContext context) async {
    if (_isProcessing) return "processing";

    if (_lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) < const Duration(seconds: 2)) {
      return "debounced";
    }
    _lastScanTime = DateTime.now();

    // ── Offline guard ───────────────────────────────────────────────────────
    if (!ConnectivityService().isOnline) {
      throw Exception(
          'No internet connection. Connect to the network and try again.');
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // Bug fix (scenario 4 & 5): Never silently fall back to (0, 0).
      // If GPS fails or permission is denied we must surface a specific error
      // instead of sending default coordinates — which the backend would
      // (correctly) reject as an out-of-bounds GPS failure anyway.
      Map<String, double> location;
      try {
        location = await _getCurrentLocation();
      } catch (e) {
        AppLogger.w('Location fetch failed: $e');
        // Propagate a distinct, user-friendly message.
        throw Exception('Location unavailable. Please enable GPS and grant location permission, then try again.');
      }

      // Bug fix (scenario 4): Extra guard — if geolocator somehow returned
      // the (0, 0) default despite no exception, reject it explicitly.
      if (GeofenceUtils.isNullIsland(
            location['latitude'] ?? 0.0, location['longitude'] ?? 0.0)) {
        throw Exception('Location unavailable. GPS returned an invalid fix (0, 0). Move to an open area and retry.');
      }

      // ── 15-second timeout so the spinner can never hang forever ──────────
      final response = await _apiClient.post(
        '/student/scan-qr',
        body: {
            'qrData': qrData,
            'latitude': location['latitude']!,
            'longitude': location['longitude']!,
            'accuracy': location['accuracy'],
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
            'The server took too long to respond. Please try again.'),
      );

      _isProcessing = false;
      notifyListeners();
      return response['message'] ?? 'Attendance marked successfully';
    } on TimeoutException catch (e) {
      _isProcessing = false;
      notifyListeners();
      throw Exception(e.message ?? 'Request timed out. Please try again.');
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
