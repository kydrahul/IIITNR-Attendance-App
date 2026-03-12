import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'constants/colors.dart';
import 'screens/common/login_screen.dart';
import 'screens/student/profile_setup_screen.dart';
import 'screens/student/qr_scanner_screen.dart';
import 'screens/student/attendance_history_screen.dart';
import 'screens/student/home_screen.dart';
import 'screens/common/not_found_screen.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'screens/common/splash_screen.dart';
import 'screens/faculty/faculty_main_scaffold.dart';
import 'screens/faculty/profile/profile_completion_screen.dart';
import 'utils/global_error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  GlobalErrorHandler.initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Check for logged in user (Logic moved to SplashScreen)
  // final authService = AuthService();
  // final isLoggedIn = authService.currentUser != null;

  runApp(const StudentApp(initialRoute: '/'));
}

class StudentApp extends StatefulWidget {
  final String initialRoute;

  const StudentApp({super.key, required this.initialRoute});

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ignore if we are currently authenticating (the biometric prompt caused the pause)
      if (BiometricService.isAuthenticating) return;

      // Grace Period: If we JUST authenticated (e.g. < 5 seconds ago),
      // ignore this resume event (it's likely from the biometric dialog closing)
      if (BiometricService.lastAuthTime != null) {
        final diff = DateTime.now().difference(BiometricService.lastAuthTime!);
        if (diff.inSeconds < 5) {
          return;
        }
      }

      // App came to foreground - verify auth again
      final authService = AuthService();
      if (authService.currentUser != null) {
        // Use a local helper to check role and navigate
        () async {
          final role = await authService.getUserRole();
          if (role == 'student') {
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil('/', (route) => false);
          }
        }();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: null), // Placeholder
      ],
      child: MaterialApp(
        title: 'IIITNR Attendance',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.blue600,
            primary: AppColors.blue600,
            surface: AppColors.background,
          ),
          textTheme: GoogleFonts.robotoTextTheme(),
        ),
        initialRoute: widget.initialRoute,
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/profile-setup': (context) => const ProfileSetupScreen(),
          '/qr-scanner': (context) => const QRScannerScreen(),
          '/attendance-history': (context) => const AttendanceHistoryScreen(),
          '/home': (context) => const HomeScreen(),
          '/faculty-home': (context) => const FacultyMainScaffold(),
          '/faculty-profile-completion': (context) =>
              const FacultyProfileCompletionScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const NotFoundScreen(),
          );
        },
      ),
    );
  }
}

// Global navigator key to allow navigation from outside context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
