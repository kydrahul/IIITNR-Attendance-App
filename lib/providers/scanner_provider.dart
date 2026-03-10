import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/network/api_client.dart';
import '../core/utils/logger.dart';

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

    _isProcessing = true;
    notifyListeners();

    try {
      Map<String, double> location = {
        'latitude': 0.0,
        'longitude': 0.0,
        'accuracy': 0.0,
      };

      try {
        location = await _getCurrentLocation();
      } catch (e) {
        AppLogger.w('Location fetch failed, using default: $e');
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Location unavailable. Proceeding with attendance...'),
               duration: Duration(seconds: 2),
               backgroundColor: Colors.orange,
             ),
           );
        }
      }

      final response = await _apiClient.post(
        '/attendance/student/scan-qr',
        body: {
            'qrData': qrData,
            'latitude': location['latitude']!,
            'longitude': location['longitude']!,
            'accuracy': location['accuracy'],
        },
      );

      _isProcessing = false;
      notifyListeners();
      return response['message'] ?? 'Attendance marked successfully';
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
