# IIITNR Attendance App

> **A QR-code + Geofence based Smart Attendance System** for DSPM IIIT Naya Raipur — built as a Minor Project.

A production-grade, cross-platform Flutter application that serves both **Faculty** (session management) and **Students** (attendance marking) through a single unified codebase.

---

## 📸 App Overview

The app enforces a multi-layered attendance verification pipeline:

```
Faculty starts session → Signs QR code (HMAC) → Student scans QR
→ Server verifies signature + geofence + device ID → Attendance marked
```

---

## ✨ Features

### 👨‍🏫 Faculty Portal
| Feature | Description |
|---|---|
| Course Management | View assigned courses, enrolled students, and credit details |
| Live Session | Start a timed attendance session that auto-stops after 15 minutes |
| Signed QR Generation | Dynamic QR codes signed with HMAC — resistant to replay attacks |
| Attendance Analytics | Per-course statistics, session history, and manual override |
| Weekly Timetable | Visual teaching schedule |
| Intern Approval | Approve/deny summer intern enrollment requests |

### 👨‍🎓 Student Portal
| Feature | Description |
|---|---|
| QR Scanner | Secure mobile_scanner integration with overlay UI |
| Geofence Check | GPS location verified server-side against classroom coordinates |
| Attendance Dashboard | Colour-coded percentage cards (🟢 ≥75% / 🔴 <75%) |
| Course Detail | Per-subject history, session breakdown, and faculty info |
| Weekly Timetable | Daily schedule from 9 AM – 6 PM |
| PDF Export | Download attendance report as a formatted PDF |
| Search | Search courses and sessions |
| Biometric / PIN login | `local_auth` for secure re-authentication |
| Settings | About, Terms, Privacy, account management |

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3.5+) |
| State Management | Provider |
| Authentication | Firebase Auth (Email/Password + Google Sign-In) |
| Backend | Node.js + Express (hosted on **Render**) |
| Database | Firebase Firestore |
| QR Generation | `qr_flutter` |
| QR Scanning | `mobile_scanner` |
| Location | `geolocator` + server-side geofencing |
| PDF Reports | `pdf` + `printing` |
| Biometrics | `local_auth` |
| Secure Storage | `flutter_secure_storage` |
| Fonts | `google_fonts` (Roboto) |

---

## 📂 Project Structure

```
lib/
├── config/
│   ├── app_config.dart          # API base URL config (prod / local)
│   └── firebase_options.dart    # Firebase initialisation options
├── constants/
│   ├── colors.dart              # Design system colour tokens
│   └── text_styles.dart         # Typography scale
├── core/                        # Core utilities and error handling
├── models/                      # Data models (User, Course, Session, Attendance)
├── providers/                   # Provider state classes
├── screens/
│   ├── common/
│   │   ├── splash_screen.dart   # Auth gate + role routing
│   │   ├── login_screen.dart    # Firebase Auth (email + Google)
│   │   ├── device_mismatch_screen.dart
│   │   └── not_found_screen.dart
│   ├── student/
│   │   ├── home_screen.dart
│   │   ├── course_detail_screen.dart
│   │   ├── qr_scanner_screen.dart
│   │   ├── attendance_history_screen.dart
│   │   ├── profile_setup_screen.dart
│   │   ├── intern_profile_setup_screen.dart
│   │   ├── weekly_timetable_screen.dart
│   │   ├── account_screen.dart
│   │   ├── search_screen.dart
│   │   ├── tabs/               # Bottom nav tabs
│   │   └── settings/           # About, Terms, Privacy screens
│   └── faculty/
│       ├── faculty_main_scaffold.dart
│       ├── faculty_weekly_timetable_screen.dart
│       ├── home/               # Faculty dashboard
│       ├── courses/            # Course + session management
│       ├── attendance/         # Attendance review screens
│       └── profile/            # Profile completion
├── services/
│   ├── api_service.dart         # HTTP client for backend REST API
│   ├── auth_service.dart        # Firebase Auth wrapper
│   ├── biometric_service.dart   # local_auth integration
│   ├── device_service.dart      # Device ID fingerprinting
│   └── report_service.dart      # PDF generation
├── utils/
│   └── global_error_handler.dart
└── widgets/                     # Reusable UI components
```

---

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK ≥ 3.5.3
- Android Studio with NDK **27.0.12077973**
- A Firebase project with Firestore + Authentication enabled
- The [iiitnrattendance-backend](https://github.com/kydrahul/iiitnrattendance-backend) running locally or deployed to Render

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/kydrahul/IIITNR-Attendance-App.git
   cd IIITNR-Attendance-App
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Email/Password** and **Google Sign-In** in Authentication
   - Enable **Firestore** database
   - Download `google-services.json` → place in `android/app/`
   - Update `lib/config/firebase_options.dart` with your project credentials

4. **Configure Backend URL**
   - Edit `lib/config/app_config.dart`
   - Set `_prodBaseUrl` to your Render deployment URL, or uncomment `_localBaseUrl` for local dev

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔒 Security Model

| Mechanism | Detail |
|---|---|
| **Signed QR Codes** | HMAC-SHA256 signed payloads; server rejects any tampered/replayed codes |
| **Device Binding** | First login fingerprints the device; subsequent logins from different devices are blocked |
| **Geofencing** | GPS coordinates verified server-side against a configurable classroom radius |
| **Biometric Gate** | `local_auth` (fingerprint / face / PIN fallback) for re-authentication |
| **Secure Storage** | Tokens stored in `flutter_secure_storage`, never in plain `SharedPreferences` |
| **Role-based Routing** | Firebase custom claims (`role: faculty/student`) gate every API endpoint |
| **Session Timeout** | Faculty sessions auto-expire after **15 minutes** |

---

## 🌐 Backend API

The Flutter app communicates with a REST API at `https://iiitnrattendence-backend.onrender.com/api`.

Key endpoint groups:
- `POST /auth/login` — verify credentials, return JWT
- `GET /student/courses` — enrolled courses for the authenticated student
- `POST /student/mark-attendance` — mark attendance (verifies QR + location)
- `GET /faculty/courses` — faculty's assigned courses
- `POST /faculty/sessions/start` — start a live QR session
- `GET /faculty/attendance/:sessionId` — view session attendance

See the [backend repository](https://github.com/kydrahul/iiitnrattendance-backend) for full API documentation.

---

## 🧑‍💻 Team

| Name | Role |
|---|---|
| Rahul Barma | Lead Developer — Full Stack |
| Himanshu Deshmukh | Developer |
| Abhinav Bhagat | Developer |

**Contact**: rahul24102@iiitnr.edu.in

---

> ⚠️ This is an **independent academic minor project** at DSPM IIIT Naya Raipur. It is **not** an official product of the institution.

---

*Version 1.0.1 · Built with Flutter · © 2025 Rahul Barma*
