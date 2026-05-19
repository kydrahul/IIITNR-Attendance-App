import 'dart:math';

/// Result of a geofence check.
enum GeofenceStatus {
  /// Student is within the allowed radius.
  pass,

  /// Student is outside the allowed radius.
  fail,

  /// Location was unavailable (GPS failed, returned default, or permission denied).
  locationUnavailable,

  /// GPS fix was obtained but the reported accuracy is too poor to trust.
  accuracyTooLow,
}

class GeofenceResult {
  final GeofenceStatus status;

  /// Computed distance from the classroom centre, in metres.
  /// Null when status is [GeofenceStatus.locationUnavailable].
  final double? distanceMeters;

  /// Human-readable explanation suitable for display to the student.
  final String message;

  const GeofenceResult({
    required this.status,
    required this.message,
    this.distanceMeters,
  });

  bool get isPassed => status == GeofenceStatus.pass;
}

/// All geofencing logic lives here. Pure functions — no Flutter dependencies,
/// making them trivially unit-testable.
class GeofenceUtils {
  // -------------------------------------------------------------------------
  // IIIT Naya Raipur campus centre (verified from Google Maps / campus docs)
  // Lat: 21.1288, Lon: 81.7664  — roughly LT / Lab block cluster centroid
  // -------------------------------------------------------------------------
  static const double campusCenterLat = 21.1288;
  static const double campusCenterLon = 81.7664;

  /// Conservative GPS accuracy threshold.  If the device reports a horizontal
  /// accuracy circle larger than this, the reading is too coarse to rely on.
  static const double maxAcceptableAccuracyMeters = 50.0;

  /// Earth radius in metres (WGS-84 mean radius).
  static const double _earthRadiusMeters = 6371000.0;

  // ---------------------------------------------------------------------------
  // Bug fix #1: GPS default coordinates guard
  // When GPS fails, Android and many Flutter geolocator implementations return
  // (0.0, 0.0) — the "Null Island" in the Gulf of Guinea.  We must detect this
  // BEFORE running the Haversine check; otherwise it produces a geofence failure
  // with a confusing "X metres away" message instead of "location unavailable".
  // ---------------------------------------------------------------------------
  /// Returns true when [lat] and [lon] are both exactly 0.0.
  ///
  /// This is the "Null Island" sentinel value that many GPS stacks return when
  /// no fix is available.  Must be checked **before** the Haversine formula to
  /// avoid misreporting a geofence failure instead of "location unavailable".
  static bool isNullIsland(double lat, double lon) {
    return lat == 0.0 && lon == 0.0;
  }

  // ---------------------------------------------------------------------------
  // Bug fix #2: Haversine formula — correct spherical-Earth distance.
  // Simple Euclidean distance on raw (lat, lon) values is WRONG for GPS because:
  //   • 1° of latitude ≈ 111 km everywhere, but
  //   • 1° of longitude varies from ~111 km at the equator to 0 at the poles.
  // At IIIT NR (lat ≈ 21°) a naïve Euclidean formula under-estimates east-west
  // distances by ~cos(21°) ≈ 7%, causing false passes near the campus perimeter.
  // ---------------------------------------------------------------------------
  static double haversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = lat1 * pi / 180.0;
    final phi2 = lat2 * pi / 180.0;
    final dPhi = (lat2 - lat1) * pi / 180.0;
    final dLambda = (lon2 - lon1) * pi / 180.0;

    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Performs a full geofence check against a given classroom location.
  ///
  /// [studentLat], [studentLon]: coordinates reported by the device.
  /// [classroomLat], [classroomLon]: the target room's coordinates.
  /// [radiusMeters]: maximum allowed distance from the classroom centre.
  /// [accuracyMeters]: horizontal accuracy circle reported by the GPS fix.
  ///   Pass `null` when the accuracy is unknown (treated as unacceptably low).
  ///
  /// Returns a [GeofenceResult] with a [GeofenceStatus] and a human-readable
  /// [message].
  static GeofenceResult checkGeofence({
    required double studentLat,
    required double studentLon,
    required double classroomLat,
    required double classroomLon,
    required double radiusMeters,
    double? accuracyMeters,
  }) {
    // --- Guard 1: Null Island / GPS default -----------------------------------
    // Fix for scenario 4: (0, 0) must never reach the distance calculation.
    if (isNullIsland(studentLat, studentLon)) {
      return const GeofenceResult(
        status: GeofenceStatus.locationUnavailable,
        message:
            'Location unavailable. Could not obtain a valid GPS fix. '
            'Please enable GPS and try again inside the classroom.',
      );
    }

    // --- Guard 2: GPS accuracy -----------------------------------------------
    // Fix for scenario 6: poor accuracy → "uncertain", not auto-approved.
    if (accuracyMeters == null || accuracyMeters > maxAcceptableAccuracyMeters) {
      final accuracyStr = accuracyMeters != null
          ? '${accuracyMeters.toStringAsFixed(0)} m'
          : 'unknown';
      return GeofenceResult(
        status: GeofenceStatus.accuracyTooLow,
        message:
            'GPS accuracy is too low ($accuracyStr; max allowed: '
            '${maxAcceptableAccuracyMeters.toStringAsFixed(0)} m). '
            'Move to an open area and try again.',
        distanceMeters: haversineDistanceMeters(
          studentLat, studentLon, classroomLat, classroomLon,
        ),
      );
    }

    // --- Guard 3: Radius validation ------------------------------------------
    if (radiusMeters <= 0) {
      throw ArgumentError('radiusMeters must be positive, got $radiusMeters');
    }

    // --- Haversine distance --------------------------------------------------
    final distance = haversineDistanceMeters(
      studentLat, studentLon, classroomLat, classroomLon,
    );

    if (distance <= radiusMeters) {
      return GeofenceResult(
        status: GeofenceStatus.pass,
        message:
            'Location verified. You are ${distance.toStringAsFixed(0)} m '
            'from the classroom.',
        distanceMeters: distance,
      );
    } else {
      return GeofenceResult(
        status: GeofenceStatus.fail,
        message:
            'You are too far from the classroom '
            '(${distance.toStringAsFixed(0)} m away; '
            'max ${radiusMeters.toStringAsFixed(0)} m allowed).',
        distanceMeters: distance,
      );
    }
  }

  /// Convenience overload that checks against the IIIT NR campus centre.
  /// Kept for backward-compat with any campus-wide (non-room-specific) checks.
  static GeofenceResult checkAgainstCampus({
    required double studentLat,
    required double studentLon,
    double radiusMeters = 300.0,
    double? accuracyMeters,
  }) {
    return checkGeofence(
      studentLat: studentLat,
      studentLon: studentLon,
      classroomLat: campusCenterLat,
      classroomLon: campusCenterLon,
      radiusMeters: radiusMeters,
      accuracyMeters: accuracyMeters,
    );
  }
}
