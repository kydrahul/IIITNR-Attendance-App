# IIITNR Attendance — Release Checklist
> Audit date: 2026-05-19 | Auditor: Antigravity pre-deployment audit
> App version at time of audit: 1.0.1+2

---

## ✅ Fixed in This Audit

### Code Cleanup

| # | Item | Result |
|---|------|--------|
| 1 | `print()` statements in `lib/` | ✅ None found — all logging already uses `debugPrint` / `AppLogger` |
| 2 | TODO in `login_screen.dart` (faculty email restriction) | ✅ **Fixed** — uncommented and activated production email validation for `@iiitnr.edu.in` |
| 2 | TODO in `build.gradle` (applicationId) | ✅ **Fixed** — already production (`in.ac.iiitnr.student_app`); misleading TODO removed |
| 2 | Commented signing TODO in `build.gradle` | ✅ Updated comment to a clear `IMPORTANT` note |
| 3 | Hardcoded strings audit | ✅ No Firestore collection names or route names found as bare strings — routes are defined centrally in `main.dart` and service endpoints in each service class |
| 4 | Test/dummy credentials | ✅ None found — clean |

### Flutter Specific

| # | Item | Result |
|---|------|--------|
| 5 | `flutter analyze` errors | ✅ **Fixed**: 2 errors → 0 errors; 3 warnings → 0 warnings |
| 5a | `uri_does_not_exist` in `overview_tab.dart` | ✅ Fixed — corrected relative import path for `FacultyWeeklyTimetableScreen` |
| 5b | `undefined_method` in `overview_tab.dart` | ✅ Fixed — consequence of broken import, resolved with above |
| 5c | `unused_import` in 3 files | ✅ Removed — `faculty_text_styles.dart`, `faculty_models.dart`, `course_wizard_state.dart`, `flutter/services.dart` |
| 5d | `unused_element` warnings | ✅ Fixed — removed dead code: `_month`, `_ordinal`, `_getStatusColor`, `_getStatusBg`, `_buildStat` |
| 5e | `curly_braces_in_flow_control_structures` | ✅ Fixed in `step1_course_info.dart` |
| 7 | `resizeToAvoidBottomInset` on form screens | ✅ Added to `profile_setup_screen.dart` and `intern_profile_setup_screen.dart` |
| 8 | Semantic labels for images | ⚠️ See **Manual Attention** below |

### Firebase

| # | Item | Result |
|---|------|--------|
| 9 | Firebase Crashlytics | ✅ **Added** — `firebase_crashlytics: ^4.1.3` in pubspec; `FlutterError.onError` and `PlatformDispatcher.instance.onError` wired in `main.dart` |
| 10 | Firebase Analytics | ✅ **Added** — `firebase_analytics: ^11.3.3` in pubspec; `AnalyticsService` created at `lib/services/analytics_service.dart`; observer added to `MaterialApp` |
| 10a | `login_success` event | ✅ Implemented — `AnalyticsService.logLoginSuccess(role:)` |
| 10b | `attendance_marked` event | ✅ Implemented — `AnalyticsService.logAttendanceMarked(sessionId:)` with `method: qr_scan` |
| 10c | `qr_generated` event | ✅ Implemented — `AnalyticsService.logQrGenerated(sessionId:)` |
| 10d | `login_failure` event | ✅ Implemented — `AnalyticsService.logLoginFailure(errorCode:)` |

### Android

| # | Item | Status |
|---|------|--------|
| 11 | `minSdkVersion` | ✅ **23** (above required 21) |
| 11 | `targetSdkVersion` | ✅ **34** |
| 11 | `applicationId` | ✅ **`in.ac.iiitnr.student_app`** (production) |
| 12 | `CAMERA` permission | ✅ Present in `AndroidManifest.xml` |
| 12 | `INTERNET` permission | ✅ Present |
| 12 | `ACCESS_FINE_LOCATION` | ✅ Present |
| 12 | `ACCESS_COARSE_LOCATION` | ✅ Present |

### iOS

| # | Item | Status |
|---|------|--------|
| 13 | `NSCameraUsageDescription` | ✅ **Added** — meaningful message about QR scanning |
| 13 | `NSLocationWhenInUseUsageDescription` | ✅ **Added** — campus presence verification message |
| 13 | `NSLocationAlwaysUsageDescription` | ✅ **Added** — background verification message |
| 13 | `NSFaceIDUsageDescription` | ✅ **Added** — biometric auth message |
| 13 | `CFBundleDisplayName` | ✅ **Fixed** — was `"Student App"`, now `"IIITNR Attendance"` |

---

## ⚠️ Requires Manual Attention

### 🔴 High Priority — Must Fix Before Release

| Item | Details |
|------|---------|
| **Call `AnalyticsService` at event sites** | The service is ready but events must be called from: `login_screen.dart` `_handleGoogleSignIn/Faculty/Intern` (login_success / login_failure), `scanner_provider.dart` on QR success (attendance_marked), and `live_session_provider.dart` on QR generation (qr_generated). |
| **Release signing key** | `build.gradle` still uses `signingConfigs.debug` for release. Create a production keystore and configure `signingConfigs.release` before Play Store submission. |
| **Firebase Crashlytics enablement** | Ensure `google-services.json` exists in `android/app/` and Crashlytics is **enabled** in the Firebase Console. Run `flutter build apk --release` and verify a test crash appears in the Crashlytics dashboard. |
| **`use_build_context_synchronously` in `api_client.dart:153`** | A `BuildContext` is used across an `async` gap — potential crash if the widget is unmounted. Add a `mounted` guard or restructure the call. |

### 🟡 Medium Priority — Strongly Recommended

| Item | Details |
|------|---------|
| **Semantic labels on all images** | No `semanticLabel` set on `Image.asset` / `Image.network` anywhere. Required for accessibility. Add labels to: app logo, profile photo widgets (17 image sites identified). |
| **Public API doc comments** | Most service classes lack `///` doc comments. Priority: `ApiService`, `FacultyApiService`, `AuthService`, `ScannerProvider`, `LiveSessionProvider`. |
| **iOS bundle name** | `CFBundleName` is still `student_app` — update to `iiitnr_attendance`. Verify `PRODUCT_BUNDLE_IDENTIFIER` in Xcode matches App Store Connect registration. |
| **Firebase App Check** | Not integrated. Without it, anyone with a valid Firebase token can query Firestore directly. Add `firebase_app_check` and enforce in backend Cloud Functions. |

### 🟢 Low Priority — Pre-Release Polish

| Item | Details |
|------|---------|
| **43 `prefer_const` infos** | Performance hints only. Run `dart fix --apply` to auto-resolve most of them. |
| **`curly_braces_in_flow_control_structures` in `add_course_dialog.dart:377-380`** | Four single-statement `if` bodies without braces. |
| **App version bump** | Version is `1.0.1+2`. Increment `versionCode` for Play Store. |
| **`flutter pub outdated`** | 106 packages have newer versions. Review major bumps before upgrading. |

---

## 🎯 Risk Assessment: MEDIUM

### Why Not HIGH
- ✅ No hardcoded credentials found
- ✅ Firebase Auth with `@iiitnr.edu.in` domain restriction now active for all roles
- ✅ Device-binding enforced for attendance marking
- ✅ HMAC-signed, time-bounded QR codes
- ✅ All Android permissions declared; all iOS `NS*UsageDescription` keys present
- ✅ Crashlytics + Analytics integrated
- ✅ Zero `flutter analyze` errors/warnings

### Why Not LOW
- 🔴 Release signing key is still debug — **cannot ship to Play Store**
- 🔴 Analytics events are defined but not yet called at trigger sites
- 🔴 `BuildContext` async gap in `api_client.dart` is a live crash vector
- 🟡 No semantic labels — accessibility compliance gap
- 🟡 No Firebase App Check — backend reachable by any valid Firebase token

### Path to LOW Risk (3 steps)
1. Wire `AnalyticsService` call sites + configure production signing keystore
2. Fix `use_build_context_synchronously` in `api_client.dart:153`
3. Add semantic labels to images

---

*Generated by Antigravity pre-deployment audit — 2026-05-19*
