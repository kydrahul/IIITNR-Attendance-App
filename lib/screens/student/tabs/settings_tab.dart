import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import '../account_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../settings/terms_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/about_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _profileData = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Text("Settings",
              style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Profile Header Section (Detailed)
          if (!_isLoading) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gray100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.blue600, AppColors.blue500],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.network(
                          _authService.currentUser?.photoURL ??
                              "https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(_profileData?['name'] ?? 'Student')}",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(LucideIcons.user,
                                  size: 40, color: AppColors.gray400),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profileData?['name'] ?? 'Student Name',
                    style:
                        AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _profileData?['email'] ??
                        _authService.currentUser?.email ??
                        'student@example.com',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.gray50, thickness: 1),
                  const SizedBox(height: 16),
                  _buildStatRow(
                      'Roll No', _profileData?['rollNo']?.toString() ?? 'N/A'),
                  _buildStatRow(
                      'Department', _profileData?['department'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  icon: LucideIcons.user,
                  iconColor: AppColors.blue600,
                  iconBg: AppColors.blue50,
                  label: "Account",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AccountScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.fileText,
                  iconColor: AppColors.gray600,
                  iconBg: AppColors.gray50,
                  label: "Terms & Conditions",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const TermsAndConditionsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.shield,
                  iconColor: AppColors.gray600,
                  iconBg: AppColors.gray50,
                  label: "Privacy Policy",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.info,
                  iconColor: AppColors.gray600,
                  iconBg: AppColors.gray50,
                  label: "About",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.logOut,
                  iconColor: AppColors.red500,
                  iconBg: AppColors.red50,
                  label: "Logout",
                  labelColor: AppColors.red500,
                  onTap: () async {
                    await _apiService.clearCache();
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
              child: Text("Version 1.0.0",
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gray400))),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: labelColor ?? AppColors.gray700,
                  ),
                ),
              ],
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.gray50);
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500)),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
