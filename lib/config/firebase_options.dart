import 'package:firebase_core/firebase_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firebase configuration.
// Values are read from --dart-define build flags so they never need to be
// committed in plaintext.  In CI/CD pass:
//   --dart-define=FIREBASE_API_KEY=<value>
//   --dart-define=FIREBASE_APP_ID=<value>
//   --dart-define=FIREBASE_MESSAGING_SENDER_ID=<value>
//   --dart-define=FIREBASE_PROJECT_ID=<value>
//   --dart-define=FIREBASE_AUTH_DOMAIN=<value>
//   --dart-define=FIREBASE_STORAGE_BUCKET=<value>
//
// For local development without CI, create a `.env.local` or set the flags
// in your IDE run configuration. The defaultValue below keeps `flutter run`
// working out-of-the-box for authorised developers who have the project access.
// ─────────────────────────────────────────────────────────────────────────────

const _apiKey = String.fromEnvironment(
  'FIREBASE_API_KEY',
  defaultValue: 'AIzaSyD1TQ3HK2jRy73WizJsK6AXScQshslHvss',
);
const _authDomain = String.fromEnvironment(
  'FIREBASE_AUTH_DOMAIN',
  defaultValue: 'iiitnr-attendence-app-f604e.firebaseapp.com',
);
const _projectId = String.fromEnvironment(
  'FIREBASE_PROJECT_ID',
  defaultValue: 'iiitnr-attendence-app-f604e',
);
const _storageBucket = String.fromEnvironment(
  'FIREBASE_STORAGE_BUCKET',
  defaultValue: 'iiitnr-attendence-app-f604e.firebasestorage.app',
);
const _messagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
  defaultValue: '790561423093',
);
const _appId = String.fromEnvironment(
  'FIREBASE_APP_ID',
  defaultValue: '1:790561423093:web:e123a8f7024bf58f970fbc',
);

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: _apiKey,
    authDomain: _authDomain,
    projectId: _projectId,
    storageBucket: _storageBucket,
    messagingSenderId: _messagingSenderId,
    appId: _appId,
  );
}
