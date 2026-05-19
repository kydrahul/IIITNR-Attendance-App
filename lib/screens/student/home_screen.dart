import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../widgets/common/custom_header.dart';
import '../../widgets/common/profile_popup.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/courses_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _showProfilePopup = false;
  bool _isAuthenticated = false; // blocks UI until biometric passes
  Map<String, dynamic>? _profileData;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  final List<Widget> _tabs = [
    const HomeTab(),
    const CoursesTab(),
    const SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runBiometricGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAuthenticated) {
      // Re-gate on resume only if we previously passed auth
      if (BiometricService.isAuthenticating) return;
      if (BiometricService.lastAuthTime != null) {
        final diff = DateTime.now().difference(BiometricService.lastAuthTime!);
        if (diff.inSeconds < 5) return; // grace period
      }
      setState(() => _isAuthenticated = false);
      _runBiometricGate();
    }
  }

  Future<void> _runBiometricGate() async {
    final canCheck = await _biometricService.checkBiometrics();
    if (!canCheck) {
      // No biometric hardware enrolled — skip gate
      if (mounted) setState(() => _isAuthenticated = true);
      _fetchProfile();
      return;
    }

    // bool? — true: pass, false: user denied (show dialog), null: hw error (skip)
    final result = await _biometricService.authenticate();
    if (!mounted) return;

    if (result == true) {
      setState(() => _isAuthenticated = true);
      _fetchProfile();
    } else if (result == null) {
      // Hardware not available / not enrolled — skip gate silently
      setState(() => _isAuthenticated = true);
      _fetchProfile();
    } else {
      // result == false: user cancelled or failed
      _showAuthFailedDialog();
    }
  }

  void _showAuthFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('Please verify your identity to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _runBiometricGate();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              _authService.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            child: const Text('Logout'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _apiService.getProfile();
      final user = _authService.getCurrentUser();

      if (mounted) {
        setState(() {
          _profileData = profile;
          _profileData!['photoUrl'] = user?.photoURL;
          _profileData!['email'] = user?.email;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  void _toggleProfilePopup() {
    setState(() => _showProfilePopup = !_showProfilePopup);
  }

  @override
  Widget build(BuildContext context) {
    // Show biometric lock screen until authenticated
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, size: 72, color: AppColors.blue600),
              SizedBox(height: 16),
              Text(
                'Verifying identity...',
                style: TextStyle(color: AppColors.gray600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Show header only on Home tab
                if (_selectedIndex == 0)
                  CustomHeader(onProfileClick: _toggleProfilePopup),
                Expanded(child: _tabs[_selectedIndex]),
              ],
            ),
          ),

          // Profile Popup Overlay
          if (_showProfilePopup)
            ProfilePopup(
              onClose: _toggleProfilePopup,
              profileData: _profileData,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, "Home"),
                _buildNavItem(1, LucideIcons.bookOpen, "Courses"),
                _buildNavItem(2, LucideIcons.settings, "Settings"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.black : AppColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.black : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
