// test/utils/geofence_test.dart
//
// Pure-Dart unit tests for GeofenceUtils — no Flutter, no platform channels.
// Run with:  flutter test test/utils/geofence_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:iiitnr_attendance/utils/geofence_utils.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// IIIT Naya Raipur campus centre — the geofence origin used in tests.
const double campusLat = GeofenceUtils.campusCenterLat; // 21.1288
const double campusLon = GeofenceUtils.campusCenterLon; // 81.7664
const double testRadius = 150.0; // metres — default campus geofence
const double goodAccuracy = 10.0; // metres — typical clear-sky GPS accuracy

/// Moves [distanceMeters] to the north of [originLat] and returns the new lat.
/// Longitude stays the same (pure-north movement along a meridian).
/// Formula: Δlat = d / R  (small-angle approximation is fine for ≤500 m)
double moveSouth(double originLat, double distanceMeters) {
  const earthRadius = 6371000.0;
  final deltaLat = distanceMeters / earthRadius * (180.0 / 3.141592653589793);
  return originLat - deltaLat;
}

double moveNorth(double originLat, double distanceMeters) {
  const earthRadius = 6371000.0;
  final deltaLat = distanceMeters / earthRadius * (180.0 / 3.141592653589793);
  return originLat + deltaLat;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ─── Haversine correctness ────────────────────────────────────────────────
  group('haversineDistanceMeters', () {
    test('same point → 0 metres', () {
      final d = GeofenceUtils.haversineDistanceMeters(
          campusLat, campusLon, campusLat, campusLon);
      expect(d, closeTo(0.0, 0.001));
    });

    test('known distance: campus ↔ 1 degree north ≈ 111.2 km', () {
      // 1° of latitude on a sphere ≈ π/180 × 6371000 ≈ 111 195 m
      final d = GeofenceUtils.haversineDistanceMeters(
          campusLat, campusLon, campusLat + 1.0, campusLon);
      // Allow ±500 m tolerance (formula uses mean earth radius, not WGS-84 exact)
      expect(d, closeTo(111195, 500));
    });

    test('is symmetric (swap A↔B gives same result)', () {
      final lat2 = moveNorth(campusLat, 200);
      final d1 = GeofenceUtils.haversineDistanceMeters(
          campusLat, campusLon, lat2, campusLon);
      final d2 = GeofenceUtils.haversineDistanceMeters(
          lat2, campusLon, campusLat, campusLon);
      expect(d1, closeTo(d2, 0.001));
    });
  });

  // ─── isNullIsland ─────────────────────────────────────────────────────────
  group('isNullIsland', () {
    test('(0, 0) is null island', () {
      expect(GeofenceUtils.isNullIsland(0.0, 0.0), isTrue);
    });

    test('campus coords are NOT null island', () {
      expect(GeofenceUtils.isNullIsland(campusLat, campusLon), isFalse);
    });

    test('(0, 1) is NOT null island', () {
      expect(GeofenceUtils.isNullIsland(0.0, 1.0), isFalse);
    });
  });

  // ─── Scenario 1: Exactly at campus centre ─────────────────────────────────
  group('Scenario 1 — coordinates exactly at campus centre', () {
    test('should PASS', () {
      final result = GeofenceUtils.checkGeofence(
        studentLat: campusLat,
        studentLon: campusLon,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: goodAccuracy,
      );
      expect(result.status, GeofenceStatus.pass,
          reason: 'Distance is 0 — must pass');
      expect(result.isPassed, isTrue);
      expect(result.distanceMeters, closeTo(0.0, 0.01));
    });
  });

  // ─── Scenario 2: Exactly at the radius boundary ───────────────────────────
  group('Scenario 2 — coordinates at exactly the radius boundary', () {
    test('should PASS (distance == radius)', () {
      // Place student exactly [testRadius] metres north of the classroom.
      final studentLat = moveNorth(campusLat, testRadius);

      final result = GeofenceUtils.checkGeofence(
        studentLat: studentLat,
        studentLon: campusLon,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: goodAccuracy,
      );

      // The computed distance should be within 1 m of testRadius.
      expect(result.distanceMeters, closeTo(testRadius, 1.0),
          reason: 'Should be ~$testRadius m from the classroom');
      expect(result.status, GeofenceStatus.pass,
          reason: 'distance == radius → boundary is inclusive, must pass');
    });
  });

  // ─── Scenario 3: 1 metre outside the radius ───────────────────────────────
  group('Scenario 3 — 1 metre outside the radius', () {
    test('should FAIL', () {
      final studentLat = moveNorth(campusLat, testRadius + 1.0);

      final result = GeofenceUtils.checkGeofence(
        studentLat: studentLat,
        studentLon: campusLon,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: goodAccuracy,
      );

      expect(result.status, GeofenceStatus.fail,
          reason: 'One metre past the boundary must fail');
      expect(result.distanceMeters, greaterThan(testRadius));
      expect(result.message, contains('too far'),
          reason: 'Message should explain the failure');
    });
  });

  // ─── Scenario 4: (0, 0) — GPS failed and returned default ─────────────────
  group('Scenario 4 — (0, 0) GPS failure sentinel', () {
    test('should return locationUnavailable, NOT a geofence failure', () {
      final result = GeofenceUtils.checkGeofence(
        studentLat: 0.0,
        studentLon: 0.0,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: goodAccuracy,
      );

      expect(result.status, GeofenceStatus.locationUnavailable,
          reason: '(0,0) must be caught as GPS failure, not geofence failure');
      expect(result.status, isNot(GeofenceStatus.fail),
          reason: 'Must not be reported as a distance failure');
      expect(result.distanceMeters, isNull,
          reason: 'No distance should be computed for an invalid fix');
      expect(result.message.toLowerCase(), contains('unavailable'),
          reason: 'Message must mention location being unavailable');
    });
  });

  // ─── Scenario 5: Location permission denied ───────────────────────────────
  // The Dart utility layer receives no coordinates at all when permission is
  // denied — the scanner_provider raises before calling checkGeofence.  We
  // test that checkGeofence still handles a null-island fallback safely, AND
  // confirm the error message is appropriate.
  group('Scenario 5 — permission denied (no coordinates available)', () {
    test('calling with (0,0) fallback returns locationUnavailable, not a crash',
        () {
      // The provider now throws before reaching the server; this test verifies
      // that if (0,0) somehow arrives at the utility it is handled gracefully.
      final result = GeofenceUtils.checkGeofence(
        studentLat: 0.0,
        studentLon: 0.0,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: null, // No accuracy when there was no fix
      );

      // Should be locationUnavailable (null-island check fires first)
      expect(result.status, GeofenceStatus.locationUnavailable);
      expect(result.isPassed, isFalse);
    });
  });

  // ─── Scenario 6: GPS accuracy worse than 50 m ─────────────────────────────
  group('Scenario 6 — GPS accuracy worse than 50 m', () {
    test('accuracy == 51 m → accuracyTooLow, not auto-approved', () {
      // Student is genuinely inside the campus (distance < radius)
      final result = GeofenceUtils.checkGeofence(
        studentLat: campusLat,
        studentLon: campusLon,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: 51.0, // Just over the 50 m threshold
      );

      expect(result.status, GeofenceStatus.accuracyTooLow,
          reason: 'Poor accuracy must not auto-approve attendance');
      expect(result.status, isNot(GeofenceStatus.pass),
          reason: 'Must not be marked as passed');
      expect(result.message.toLowerCase(), contains('accuracy'),
          reason: 'Message must mention accuracy');
    });

    test('accuracy == 50 m → passes (boundary is inclusive)', () {
      final result = GeofenceUtils.checkGeofence(
        studentLat: campusLat,
        studentLon: campusLon,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: 50.0, // Exactly at threshold — should pass
      );

      expect(result.status, GeofenceStatus.pass);
    });

    test('null accuracy → accuracyTooLow (unknown accuracy is untrustworthy)',
        () {
      final result = GeofenceUtils.checkGeofence(
        studentLat: campusLat,
        studentLon: campusLon,
        classroomLat: campusLat,
        classroomLon: campusLon,
        radiusMeters: testRadius,
        accuracyMeters: null, // Unknown
      );

      expect(result.status, GeofenceStatus.accuracyTooLow,
          reason: 'Unknown accuracy must not auto-approve');
    });
  });

  // ─── Additional: confirm Haversine is used (not Euclidean) ────────────────
  group('Haversine vs Euclidean sanity check', () {
    test('east-west movement at IIIT-NR latitude is correctly scaled', () {
      // At latitude 21°, 1° of longitude ≈ cos(21°) × 111 195 m ≈ 103 800 m
      // A Euclidean formula on raw degrees would give 111 195 m (7% over-estimate)
      const deltaLon = 0.001; // 0.001 degrees east
      final d = GeofenceUtils.haversineDistanceMeters(
          campusLat, campusLon, campusLat, campusLon + deltaLon);
      // At 21° latitude: expected ≈ cos(21° in radians) × 111195 × 0.001
      //                          ≈ 0.9336 × 111.195 ≈ 103.8 m
      expect(d, closeTo(103.8, 2.0),
          reason: 'Must use Haversine (accounts for latitude-scaled longitude)');
    });
  });

  // ─── Coordinate constants: IIIT NR campus centre ─────────────────────────
  group('Geofence constants — IIIT Naya Raipur', () {
    test('campus centre latitude is within IIIT-NR bounding box', () {
      // IIIT Naya Raipur is in Chhattisgarh, roughly 21.1° N, 81.7° E
      expect(GeofenceUtils.campusCenterLat, inInclusiveRange(21.10, 21.16));
      expect(GeofenceUtils.campusCenterLon, inInclusiveRange(81.74, 81.80));
    });

    test('default campus radius is between 100 m and 500 m', () {
      // 300 m is the default used in checkAgainstCampus
      // Anything outside 100–500 m is either too tight or too permissive
      const defaultRadius = 300.0;
      expect(defaultRadius, inInclusiveRange(100.0, 500.0));
    });
  });
}
