# IIITNR Attendance App — Codebase Audit Report
> Generated: May 2026 | Auditor: Antigravity AI  
> Project Root: `d:\projects\minor\Attendance App\`

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Screens & Pages](#2-screens--pages)
3. [Services & Repository Layer](#3-services--repository-layer)
4. [Data Models](#4-data-models)
5. [Providers (State Management)](#5-providers-state-management)
6. [Utilities & Helpers](#6-utilities--helpers)
7. [Widgets & Components](#7-widgets--components)
8. [Routing Setup](#8-routing-setup)
9. [Third-Party Packages](#9-third-party-packages)
10. [God Files (>300 lines)](#10-god-files-300-lines)
11. [Missing Error Handling](#11-missing-error-handling)
12. [dart:io / Platform Calls](#12-dartio--platform-calls)
13. [Summary & Recommendations](#13-summary--recommendations)

---

## 1. Project Overview

| Property | Value |
|---|---|
| Framework | Flutter (Dart) |
| State Management | `Provider` + `ChangeNotifier` |
| Navigation | `MaterialApp` named routes (defined in `main.dart`) |
| Backend | REST API (Render cloud) via HTTP — no direct Firestore reads from app |
| Auth | Firebase Auth (Google Sign-In) + `flutter_secure_storage` |
| Security | Device binding via `DeviceService`, Biometric via `local_auth` |
| User Roles | **Student**, **Faculty**, **Summer Intern** |

---

## 2. Screens & Pages

### 2.1 Common Screens

| File | Lines | Purpose |
|---|---|---|
| `lib/screens/common/login_screen.dart` | **485** | Google OAuth login; handles student vs. faculty auth flow, email domain check, device binding, profile verification. Routes to `/home`, `/profile-setup`, `/faculty-home`, etc. |
| `lib/screens/common/splash_screen.dart` | ~120 | App launch screen; checks auth state and redirects to appropriate route. |
| `lib/screens/common/device_mismatch_screen.dart` | 112 | Shown when the device ID doesn't match the bound device. Provides sign-out only. |
| `lib/screens/common/not_found_screen.dart` | 109 | 404 fallback screen with `assets/404error.jpg`. |

### 2.2 Student Screens

| File | Lines | Purpose |
|---|---|---|
| `lib/screens/student/home_screen.dart` | 143 | Shell screen with bottom nav (Home, Courses, Settings tabs). Fetches profile on init. |
| `lib/screens/student/profile_setup_screen.dart` | **409** | One-time profile setup (name, roll no, dept, year). Includes device-binding confirmation dialog. |
| `lib/screens/student/intern_profile_setup_screen.dart` | **548** | Intern-specific profile setup (name, college, faculty, internship dates). |
| `lib/screens/student/course_detail_screen.dart` | **458** | Per-course detail: attendance %, schedule, class history with filter/sort. |
| `lib/screens/student/qr_scanner_screen.dart` | ~200 | Camera QR scanner using `mobile_scanner`. Uses `ScannerProvider`. |
| `lib/screens/student/attendance_history_screen.dart` | ~180 | Full attendance history list with grouping/filtering. |
| `lib/screens/student/search_screen.dart` | ~150 | Course/session search screen. |
| `lib/screens/student/account_screen.dart` | ~120 | Student account settings and sign-out. |
| `lib/screens/student/weekly_timetable_screen.dart` | ~250 | Weekly timetable grid for students. |

#### Student Tabs
| File | Purpose |
|---|---|
| `lib/screens/student/tabs/home_tab.dart` | Dashboard: today's schedule, attendance summary cards |
| `lib/screens/student/tabs/courses_tab.dart` | Lists enrolled courses with attendance % |
| `lib/screens/student/tabs/settings_tab.dart` | App settings, biometric toggle |

### 2.3 Faculty Screens

| File | Lines | Purpose |
|---|---|---|
| `lib/screens/faculty/faculty_home_screen.dart` | ~180 | Faculty shell with bottom nav (Home, Attendance, Courses, Profile). |
| `lib/screens/faculty/faculty_weekly_timetable_screen.dart` | **507** | System-generated timetable grid + image import feature (uses `dart:io`). |
| `lib/screens/faculty/courses/courses_tab.dart` | **766** | Lists all courses with search, filter (by year/session), archive toggle. |
| `lib/screens/faculty/courses/course_details_screen.dart` | **1289** | Per-course detail with tabs: Overview, Attendance, Students, Requests (summer). Exports PDF. |
| `lib/screens/faculty/courses/add_course_dialog.dart` | **1605** | Multi-step wizard (5 steps) to create/edit a course: info → branches → timetable → review → success. |
| `lib/screens/faculty/courses/session_details_screen.dart` | **747** | Shows session attendance; supports manual mark present/absent per student. |
| `lib/screens/faculty/courses/student_stats_screen.dart` | ~300 | Per-student attendance statistics over course lifetime. |
| `lib/screens/faculty/courses/start_session_screen.dart` | ~200 | Pre-session setup before launching a live QR session. |
| `lib/screens/faculty/attendance/attendance_tab.dart` | **1012** | Attendance hub: course search/autocomplete, quick-picks, session history tab, student list tab. |
| `lib/screens/faculty/profile/faculty_profile_tab.dart` | ~200 | Faculty profile display. |
| `lib/screens/faculty/profile/faculty_account_screen.dart` | ~150 | Faculty account settings, sign-out. |
| `lib/screens/faculty/profile/profile_completion_screen.dart` | ~180 | One-time faculty profile setup. |
| `lib/screens/faculty/home/faculty_home_tab.dart` | ~200 | Faculty dashboard with today's classes and quick actions. |

#### Faculty Components
| File | Lines | Purpose |
|---|---|---|
| `lib/screens/faculty/courses/components/session_setup_form.dart` | ~200 | Room number, class type picker form before starting a session. |
| `lib/screens/faculty/courses/components/manual_attendance_list.dart` | ~180 | Manual attendance marking list during a live session. |
| `lib/screens/faculty/courses/widgets/join_code_dialog.dart` | ~80 | Dialog showing QR join code for a course. |

---

## 3. Services & Repository Layer

### 3.1 `lib/services/api_service.dart` (~266 lines)
**Role:** All student-facing REST API calls.

| Method | Endpoint | Cache? |
|---|---|---|
| `getProfile()` | `GET /api/profile` | Yes (SharedPreferences, 1hr) |
| `createProfile(...)` | `POST /api/profile` | Clears cache |
| `createInternProfile(...)` | `POST /api/profile/intern` | Clears cache |
| `getCourses()` | `GET /api/courses` | Yes |
| `getAttendanceSummary()` | `GET /api/attendance/summary` | Yes |
| `getAttendanceHistory(courseId)` | `GET /api/attendance/history?courseId=` | No |
| `scanQr(token, courseId)` | `POST /api/attendance/scan` | No |
| `getSchedule()` | `GET /api/schedule` | Yes |

**Firebase Collections touched:** None — all calls go to REST backend.

---

### 3.2 `lib/services/faculty/faculty_api_service.dart` (~322 lines)
**Role:** All faculty-facing REST API calls.

| Method | Endpoint | Notes |
|---|---|---|
| `listCourses({forceRefresh})` | `GET /api/faculty/courses` | Cached in SharedPreferences |
| `createFullClass(payload)` | `POST /api/faculty/courses` | Creates course + timetable |
| `updateCourseSchedule(...)` | `PUT /api/faculty/courses/:id` | Edit existing course |
| `archiveCourse(id, archive)` | `PATCH /api/faculty/courses/:id/archive` | Archive/unarchive |
| `getCourseAttendanceGrid(...)` | `GET /api/faculty/courses/:id/grid` | Attendance matrix |
| `listCourseStudents(id, sessionId)` | `GET /api/faculty/courses/:id/students` | With session filter |
| `getJoinRequests(courseId)` | `GET /api/faculty/courses/:id/requests` | Intern requests |
| `reviewJoinRequest(...)` | `POST /api/faculty/courses/:id/requests/:eid` | approve/deny |
| `startSession(courseId, payload)` | `POST /api/faculty/sessions/start` | Live session |
| `endSession(sessionId)` | `POST /api/faculty/sessions/:id/end` | End live session |

**Firebase Collections touched:** None — REST-only.

---

### 3.3 `lib/services/auth_service.dart` (~200 lines)
- Firebase Auth (Google Sign-In via `google_sign_in`)
- Reads/writes user token to `flutter_secure_storage`
- Checks `@nitrkl.ac.in` email domain for faculty validation
- `signOut()` clears secure storage

**Firebase:** Uses `FirebaseAuth.instance` — Auth only, no Firestore reads.

---

### 3.4 `lib/services/biometric_service.dart` (76 lines)
- Wraps `local_auth` for fingerprint/face ID
- `checkBiometrics()` → returns `bool` (enrolled biometrics available)
- `authenticate()` → performs biometric prompt with 10s timeout safety
- Uses `BiometricType.fingerprint` and `BiometricType.strong`

---

### 3.5 `lib/services/device_service.dart` (83 lines)
- Generates unique device ID using `device_info_plus`
- Stores ID via `flutter_secure_storage` with `encryptedSharedPreferences: true`
- Uses `Platform.isAndroid` / `Platform.isIOS` (**only file with direct `Platform` calls**)
- Sends device ID to backend for binding verification

---

### 3.6 `lib/services/report_service.dart`
- Generates and shares attendance reports
- Used by `FacultyAttendanceTab`'s export menu

---

### 3.7 `lib/core/network/api_client.dart`
- Base HTTP client wrapper using `http` package
- Attaches Firebase Auth token to every request (`Authorization: Bearer <token>`)
- Central place for base URL config (`AppConfig.baseUrl`)
- Has `try/catch` on all request methods

---

## 4. Data Models

### 4.1 `lib/models/data_models.dart` (184 lines) — Student-side

| Class | Key Fields |
|---|---|
| `ScheduleItem` | `courseId`, `courseName`, `day`, `time`, `room`, `type` |
| `Course` | `id`, `name`, `faculty`, `attendance` (%), `totalClasses`, `attended`, `missed`, `schedule[]`, `contact` |
| `ContactInfo` | `phone`, `email` |
| `ScheduleSlot` | `day`, `time`, `room` |
| `AttendanceRecord` | `date`, `day`, `time`, `room`, `status` ("Present"/"Absent"), `type` |

All models have `fromJson(Map)` factory constructors.

---

### 4.2 `lib/models/faculty/faculty_models.dart` (358 lines) — Faculty-side

| Class | Key Fields |
|---|---|
| `Course` | `id`, `code`, `name`, `section`, `department`, `academicYear`, `credits`, `semester`, `session`, `joinCode`, `enrolledCount`, `timetable[]`, `isArchived`, `degree`, `startDate`, `endDate` |
| `TimetableSlot` | `day`, `time`, `type` (theory/lab), `room?` |
| `AttendanceSession` | `id`, `date`, `startTime`, `endTime`, `type`, `presentCount`, `totalStudents`, `room` |
| `StudentAttendance` | `id`, `rollNo`, `name`, `status`, `markedAt` |
| `FacultyProfile` | `id`, `name`, `email`, `department`, `photoUrl` |

All models have `fromJson` and `toJson` methods.

---

## 5. Providers (State Management)

### 5.1 `lib/providers/live_session_provider.dart` (**451 lines** — ⚠️ God File)
**Manages entire live session lifecycle for faculty.**

Key state:
- `sessionId`, `qrData`, `timerSeconds`, `isSessionActive`
- `presentStudents[]`, `recentScans[]`
- Proximity detection (`geolocator`)
- Timer management (auto-expire after duration)
- QR token rotation

Key methods:
- `startSession(courseId, config)` — calls API, starts QR rotation timer
- `endSession()` — stops timer, calls API end endpoint
- `updateManualAttendance(studentId, isPresent)` — real-time update

---

### 5.2 `lib/providers/scanner_provider.dart`
**Manages QR scan state for students.**

Key state:
- `isScanning`, `lastScanResult`, `error`
- Debounce logic to prevent duplicate scans

---

## 6. Utilities & Helpers

| File | Purpose |
|---|---|
| `lib/utils/responsive.dart` | `Responsive` class — `horizontalPadding(context)`, `sp(context, size)`, `hp(context, ratio)`. Based on 375×812 design reference. |
| `lib/utils/faculty/pdf_generator.dart` | `AttendancePdfGenerator.generateAndShare(...)` — builds a PDF from attendance data and shares via platform share sheet using `pdf` + `printing` packages. |
| `lib/core/error/global_error_handler.dart` | Sets `FlutterError.onError` and `PlatformDispatcher.instance.onError`. Logs to console; shows SnackBar for unhandled exceptions. |
| `lib/constants/colors.dart` | `AppColors` — all student-side color constants |
| `lib/constants/text_styles.dart` | `AppTextStyles` — student-side typography |
| `lib/constants/faculty/faculty_colors.dart` | `FacultyColors` — faculty-side color constants |
| `lib/constants/faculty/faculty_text_styles.dart` | `FacultyTextStyles` — faculty-side typography |
| `lib/config/app_config.dart` | `AppConfig.baseUrl` — production Render URL |

---

## 7. Widgets & Components

| File | Purpose |
|---|---|
| `lib/widgets/common/custom_header.dart` | Top header bar with greeting + profile avatar button |
| `lib/widgets/common/profile_popup.dart` | Overlay popup showing profile info (photo, name, email, roll no) |
| `lib/widgets/overlays/weekly_timetable_overlay.dart` | Slide-up overlay timetable view used in student home tab |

---

## 8. Routing Setup

**Router type:** `MaterialApp` with `initialRoute` + `onGenerateRoute` (named routes).  
**Defined in:** `lib/main.dart`

| Route | Widget | Notes |
|---|---|---|
| `/` (initial) | `SplashScreen` | Auto-redirects based on auth state |
| `/login` | `LoginScreen` | Google OAuth entry point |
| `/profile-setup` | `ProfileSetupScreen` | Student first-time setup |
| `/intern-profile-setup` | `InternProfileSetupScreen` | Summer intern setup |
| `/home` | `HomeScreen` | Student main shell |
| `/faculty-home` | `FacultyHomeScreen` | Faculty main shell |
| `/faculty-profile-setup` | `ProfileCompletionScreen` | Faculty first-time setup |
| `/device-mismatch` | `DeviceMismatchScreen` | Device binding error |
| `*` (unknown) | `NotFoundScreen` | 404 fallback |

Named routes are registered in `routes: {}` map. `Navigator.pushReplacementNamed` is used for post-auth redirects.

---

## 9. Third-Party Packages

From `pubspec.yaml`:

| Package | Version | Used For |
|---|---|---|
| `firebase_core` | ^3.13.0 | Firebase SDK initialization |
| `firebase_auth` | ^5.5.2 | Google Sign-In authentication |
| `google_sign_in` | ^6.2.2 | Google OAuth flow |
| `flutter_secure_storage` | ^9.2.4 | Encrypted token/device ID storage; uses `encryptedSharedPreferences` on Android |
| `shared_preferences` | ^2.5.3 | API response caching (non-sensitive) |
| `http` | ^1.4.0 | REST API HTTP calls |
| `local_auth` | ^2.3.0 | Biometric authentication (fingerprint/face) |
| `device_info_plus` | ^11.4.0 | Unique device ID retrieval (Android ID, iOS identifierForVendor) |
| `geolocator` | ^13.0.4 | Location for proximity detection during live sessions |
| `mobile_scanner` | ^7.0.1 | QR code scanning (student-side) |
| `qr_flutter` | ^4.1.0 | QR code generation (faculty live session display) |
| `pdf` | ^3.11.3 | PDF generation for attendance reports |
| `printing` | ^5.14.2 | Share/print the generated PDF |
| `image_picker` | ^1.1.2 | Pick timetable image from gallery (faculty) |
| `google_fonts` | ^6.2.1 | Custom typography (Montserrat, Roboto, Outfit) |
| `lucide_icons` | ^0.0.7 | Icon set (Lucide) |
| `provider` | ^6.1.2 | State management (`ChangeNotifierProvider`) |
| `path_provider` | ^2.1.5 | File system paths (PDF temp file, etc.) |

---

## 10. God Files (>300 lines)

Files that are excessively large and should be refactored:

| File | Lines | Issue |
|---|---|---|
| `screens/faculty/courses/add_course_dialog.dart` | **1605** | 🔴 CRITICAL — 5-step course creation wizard with all logic, all step UIs, all subwidgets in a single file. Should be split into `Step1InfoForm`, `Step2BranchSelector`, `Step3TimetablePicker`, `Step4ReviewCard`, each in their own widget files. |
| `screens/faculty/courses/course_details_screen.dart` | **1289** | 🔴 CRITICAL — Contains 4 tab classes (`_OverviewTab`, `_AttendanceTab`, `_StudentsTab`, `_RequestsTab`) inline plus the main screen. Each tab is a candidate for extraction. |
| `screens/faculty/attendance/attendance_tab.dart` | **1012** | 🔴 CRITICAL — Single file managing course selector, session history, student list tab, export dialog. Should extract `_CourseSelector`, `_SessionHistoryList`, `_EnrolledStudentsList`. |
| `screens/faculty/courses/courses_tab.dart` | **766** | 🟠 HIGH — Mixes `FacultyCoursesTab` (list/filter) and `_CourseCard` (individual course card). Extract `CourseCard` to `widgets/faculty/course_card.dart`. |
| `screens/faculty/courses/session_details_screen.dart` | **747** | 🟠 HIGH — Session header, stat cards, custom tab bar, student list with expand-to-mark all in one file. |
| `providers/live_session_provider.dart` | **451** | 🟠 HIGH — God Provider. Manages timers, QR rotation, geo-proximity, and API calls. Split into `LiveSessionTimerService`, `QrRotationService`. |
| `screens/faculty/faculty_weekly_timetable_screen.dart` | **507** | 🟡 MEDIUM — Timetable grid builder + image import feature. `_buildCell` switch block is complex. |
| `screens/student/intern_profile_setup_screen.dart` | **548** | 🟡 MEDIUM — Large form; hardcoded `facultyList` (24 entries) bloats the file. Extract list to a constants file. |
| `screens/student/profile_setup_screen.dart` | **409** | 🟡 MEDIUM — Form + confirmation dialog in one file. Acceptable but could extract dialog. |
| `screens/student/course_detail_screen.dart` | **458** | 🟡 MEDIUM — Stats card, schedule list, history list all in one screen widget. |
| `models/faculty/faculty_models.dart` | **358** | 🟡 MEDIUM — All faculty models in one file. Consider splitting `Course`, `Session`, `Student` to separate files. |
| `screens/common/login_screen.dart` | **485** | 🟡 MEDIUM — Handles both student and faculty login flows with device binding logic embedded. |

---

## 11. Missing Error Handling

Files confirmed to have `try/catch` blocks: ✅ (all major screens and services do).

### Files with NO `try/catch` anywhere:

| File | Risk | Notes |
|---|---|---|
| `lib/models/data_models.dart` | 🟡 LOW | JSON parsing in `fromJson` can throw `TypeError` on malformed API response. No null-safe guards on all fields. |
| `lib/models/faculty/faculty_models.dart` | 🟡 LOW | Same — `fromJson` methods do raw casts (`as List`, `as String`) that can throw on unexpected API changes. |
| `lib/constants/colors.dart` | ✅ N/A | No runtime logic. |
| `lib/constants/text_styles.dart` | ✅ N/A | No runtime logic. |
| `lib/utils/responsive.dart` | ✅ N/A | Pure math, no IO. |
| `lib/screens/common/not_found_screen.dart` | ✅ N/A | Static UI only. |
| `lib/screens/common/device_mismatch_screen.dart` | 🟡 LOW | Calls `AuthService().signOut()` in a button handler with no `try/catch`. A sign-out failure would silently fail and leave the user stuck. |
| `lib/screens/student/home_screen.dart` | ✅ Has catch | `_fetchProfile` wraps in try/catch. |

### Specific Async Gaps (try/catch present but incomplete):

| Location | Gap |
|---|---|
| `AddCourseDialog._loadExistingCourses()` | Has `catch (e)` but silently ignores the error with a comment `// Fail silently`. No user feedback. |
| `SessionDetailsScreen._initializeStudents()` | Uses **hardcoded mock student names** as fallback when `sessionId` is null. This is a development artifact that should be removed or gated behind a debug flag. |
| `FacultyWeeklyTimetableScreen._removeImage()` | No `try/catch` around `SharedPreferences.remove()`. Low risk but inconsistent. |

---

## 12. dart:io / Platform Calls

Files importing `dart:io`:

| File | Usage | Risk |
|---|---|---|
| `lib/services/device_service.dart` | `Platform.isAndroid`, `Platform.isIOS` guards. **Fully wrapped in try/catch.** | ✅ Safe |
| `lib/screens/faculty/faculty_weekly_timetable_screen.dart` | `File(imagePath)` for the imported timetable image. Uses `await file.exists()` before accessing. Also `Image.file(_importedTimetableImage!)` — the `!` force-unwrap is safe because it's inside a null-check branch. | ✅ Safe |

### Platform Call Details

**`device_service.dart`:**
```dart
// Platform checks are guarded before use:
if (Platform.isAndroid) { ... }
else if (Platform.isIOS) { ... }
// Wrapped in try/catch — safe
```

**`faculty_weekly_timetable_screen.dart`:**
```dart
// File existence check before use:
if (await file.exists()) {
  setState(() => _importedTimetableImage = file);
}
// Image.file() called only when _importedTimetableImage != null
```

**Verdict:** No unsafe bare `Platform` calls or unguarded `File` access found. Risk is low.

---

## 13. Summary & Recommendations

### 🔴 Critical (Fix Before Next Milestone)

1. **Refactor `add_course_dialog.dart` (1605 lines)** — Extract each step into its own widget file under `lib/screens/faculty/courses/steps/`. This is the single biggest maintenance liability.

2. **Refactor `course_details_screen.dart` (1289 lines)** — Move `_OverviewTab`, `_AttendanceTab`, `_StudentsTab`, `_RequestsTab` to `lib/screens/faculty/courses/tabs/`.

3. **Refactor `attendance_tab.dart` (1012 lines)** — Extract `CourseSelector`, `SessionHistoryList`, and `EnrolledStudentsList` as standalone widgets.

4. **Remove mock data from `SessionDetailsScreen._initializeStudents()`** — The hardcoded 50-name student list is a development leftover that should be removed. When `sessionId` is null, show an error state instead.

### 🟠 High Priority

5. **Split `LiveSessionProvider` (451 lines)** — Extract timer logic and QR rotation into a dedicated `LiveSessionTimerService`. The provider should only hold UI state.

6. **Add error handling to `DeviceMismatchScreen` sign-out button** — Currently an uncaught exception during `AuthService().signOut()` leaves the user with no escape.

7. **Move hardcoded `facultyList` out of `InternProfileSetupScreen`** — Put it in `lib/constants/faculty_list.dart` or fetch it from the API.

### 🟡 Medium Priority

8. **Add null-safe JSON parsing to models** — Replace raw casts in `fromJson` factories with null-aware operators and fallbacks. Example: `json['credits'] as int` → `int.tryParse(json['credits']?.toString() ?? '3') ?? 3`.

9. **Audit `AppConfig.baseUrl`** — Currently hardcoded to production Render URL. Add a `.env`-backed or build-flavor-based config for dev vs. prod environments.

10. **Consolidate duplicate ordinal/date helpers** — `_getOrdinal()` and month/date formatting logic appear independently in at least 4 files (`courses_tab.dart`, `course_details_screen.dart`, `add_course_dialog.dart`, `intern_profile_setup_screen.dart`). Extract to `lib/utils/date_utils.dart`.

11. **Standardize `_isSummerSession` check** — This boolean getter is duplicated in both `add_course_dialog.dart` and `course_details_screen.dart`. Move to `Course` model.

### ✅ Already Done Well

- All major API calls (`ApiService`, `FacultyApiService`, `AuthService`) are wrapped in `try/catch`.
- `FlutterSecureStorage` correctly uses `encryptedSharedPreferences: true` on Android to avoid Keystore biometric hang.
- `BiometricService` has a timeout safety mechanism.
- `GlobalErrorHandler` catches uncaught Flutter and platform errors globally.
- `dart:io` and `Platform` calls are minimal and properly guarded.
- Mounted checks (`if (mounted)`) are consistently applied before `setState` in async callbacks.
- Device binding is enforced before profile creation (confirmed in both `profile_setup_screen.dart` and `intern_profile_setup_screen.dart`).
