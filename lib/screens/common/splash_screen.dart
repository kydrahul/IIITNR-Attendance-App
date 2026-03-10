import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // User is authenticated, check if profile exists
    try {
      // Pass true to bypass cache and verify real DB existence
      await _apiService.getProfile(checkProfileExists: true);

      // Profile exists, now check Biometrics
      if (mounted) {
        setState(() {
          // Update UI to show "Authenticating..."? Or just let the system dialog show
        });

        final biometricService = BiometricService();
        final canCheck = await biometricService.checkBiometrics();

        if (canCheck) {
          final authenticated = await biometricService.authenticate();
          if (authenticated) {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Biometric failed
            if (mounted) {
              _showAuthFailedDialog();
            }
          }
        } else {
          // No hardware support, proceed to home safely
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('Profile check failed: $e');

      if (e.toString().contains('Profile not found')) {
        if (mounted) Navigator.pushReplacementNamed(context, '/profile-setup');
      } else {
        // Show error dialog for other errors (e.g. 500, Network)
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Connection Error'),
              content: Text(
                  'Could not verify profile. Error: ${e.toString().replaceAll("Exception:", "")}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _checkAuthAndNavigate(); // Retry
                  },
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () {
                    _authService.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showAuthFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('Please authenticate to access the app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAuthAndNavigate(); // Retry sequence
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(), // Exit app
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school,
                    size: 100, color: AppColors.blue600);
              },
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Verifying Profile...',
              style: TextStyle(
                color: AppColors.gray600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
