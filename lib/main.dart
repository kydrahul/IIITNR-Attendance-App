import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'constants/colors.dart';
import 'screens/common/login_screen.dart';
import 'screens/student/profile_setup_screen.dart';
import 'screens/student/intern_profile_setup_screen.dart';
import 'screens/student/qr_scanner_screen.dart';
import 'screens/student/attendance_history_screen.dart';
import 'screens/student/home_screen.dart';
import 'screens/common/not_found_screen.dart';
import 'services/auth_service.dart';
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

class _StudentAppState extends State<StudentApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: AuthService()),
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
          '/intern-profile-setup': (context) => const InternProfileSetupScreen(),
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
