# IIITNR Unified Attendance App (Faculty & Student)

A comprehensive, cross-platform Flutter application for the IIITNR QR-based Attendance System. This unified app serves both **Faculty** for session management and **Students** for attendance marking.

## 📱 Features

### For Faculty
- **Course Management**: View and manage assigned courses and student enrollments.
- **Session Tracking**: Start attendance sessions with dynamic, signed QR codes.
- **Attendance Analytics**: View real-time attendance stats and student lists per course.
- **Weekly Timetable**: View teaching schedule.

### For Students
- **Smart QR Scanner**: Secure scanning of faculty-generated QR codes.
- **Location Verification**: Automatic GPS/Geofencing check to ensure classroom presence.
- **Dashboard**: Track overall attendance percentage and daily schedule.
- **History**: Detailed record of attendance across all enrolled subjects.

## 🛠 Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider / setState
- **Authentication**: Firebase Auth (with Custom Roles)
- **Backend**: Render-hosted Node.js Express server
- **Database**: Firebase Firestore

## 🚀 Setup & Installation
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/kydrahul/IIITNR-Attendance-App.git
    cd IIITNR-Attendance-App
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Firebase Configuration**:
    - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase Project.
    - Place them in `android/app/` and `ios/Runner/` respectively.
    - (Optional) Update `lib/config/firebase_options.dart` if using FlutterFire CLI.
4.  **Run the App**:
    ```bash
    flutter run
    ```

## 🔒 Security
- **Signed QR Payloads**: Prevents students from sharing attendance "links."
- **Device Binding**: Locks student accounts to a specific device ID.
- **Biometric Support**: Uses `local_auth` for secure login verification.

---
© 2024 IIITNR Attendance Project Team
