import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacultyProfileTab extends StatefulWidget {
  const FacultyProfileTab({super.key});

  @override
  State<FacultyProfileTab> createState() => _FacultyProfileTabState();
}

class _FacultyProfileTabState extends State<FacultyProfileTab> {
  final FacultyApiService _apiService = FacultyApiService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  int _defaultRadius = 50;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadRadius();
  }

  Future<void> _loadRadius() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultRadius = prefs.getInt('default_scan_radius') ?? 50;
    });
  }

  Future<void> _saveRadius(int radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_scan_radius', radius);
    setState(() {
      _defaultRadius = radius;
    });
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

  void _showRadiusDialog() {
    int currentRadius = _defaultRadius;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FacultyColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Default Scan Radius',
              style: FacultyTextStyles.h3.copyWith(color: FacultyColors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Set the default location radius (in meters) for scanning students.',
                  style: FacultyTextStyles.bodyMedium),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: currentRadius.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Radius (m)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: FacultyColors.primary, width: 2)),
                ),
                onChanged: (val) {
                  currentRadius = int.tryParse(val) ?? 50;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: FacultyTextStyles.bodyMedium
                      .copyWith(color: FacultyColors.gray500)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveRadius(currentRadius);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FacultyColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save',
                  style: TextStyle(color: FacultyColors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Text("Settings",
              style:
                  FacultyTextStyles.h1.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Profile Header Section (Detailed)
          if (!_isLoading) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FacultyColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FacultyColors.gray100),
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
                        colors: [FacultyColors.blue600, FacultyColors.blue500],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: FacultyColors.white,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.network(
                          _authService.currentUser?.photoURL ??
                              "https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(_profileData?['name'] ?? 'Faculty')}",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(LucideIcons.user,
                                  size: 40, color: FacultyColors.gray400),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profileData?['name'] ?? 'Faculty Member',
                    style: FacultyTextStyles.h2
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _profileData?['email'] ??
                        _authService.currentUser?.email ??
                        'faculty@example.com',
                    style: FacultyTextStyles.bodyMedium
                        .copyWith(color: FacultyColors.gray500),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: FacultyColors.gray50, thickness: 1),
                  const SizedBox(height: 16),
                  _buildStatRow(
                      'Employee ID', _profileData?['employeeId'] ?? 'N/A'),
                  _buildStatRow(
                      'Department', _profileData?['department'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          Container(
            decoration: BoxDecoration(
              color: FacultyColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FacultyColors.gray100),
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
                  icon: LucideIcons.mapPin,
                  iconColor: FacultyColors.blue600,
                  iconBg: FacultyColors.blue50,
                  label: "Default Scan Radius",
                  value: "$_defaultRadius m",
                  onTap: () {
                    _showRadiusDialog();
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.fileText,
                  iconColor: FacultyColors.gray600,
                  iconBg: FacultyColors.gray50,
                  label: "Terms & Conditions",
                  onTap: () {
                    // Navigate to Terms screen if available
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.shield,
                  iconColor: FacultyColors.gray600,
                  iconBg: FacultyColors.gray50,
                  label: "Privacy Policy",
                  onTap: () {
                    // Navigate to Privacy screen if available
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.info,
                  iconColor: FacultyColors.gray600,
                  iconBg: FacultyColors.gray50,
                  label: "About",
                  onTap: () {
                    // Navigate to About screen if available
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  icon: LucideIcons.logOut,
                  iconColor: Colors.red,
                  iconBg: Colors.red.withOpacity(0.05),
                  label: "Logout",
                  labelColor: Colors.red,
                  onTap: () async {
                    await _authService.signOut();
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
                  style: FacultyTextStyles.bodySmall
                      .copyWith(color: FacultyColors.gray400))),
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
    String? value,
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
                  style: FacultyTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: labelColor ?? FacultyColors.black,
                  ),
                ),
              ],
            ),
            Row(children: [
              if (value != null) ...[
                Text(value,
                    style: FacultyTextStyles.bodyMedium.copyWith(
                        color: FacultyColors.gray500,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
              ],
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: FacultyColors.gray400),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: FacultyColors.gray50);
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: FacultyTextStyles.bodyMedium
                  .copyWith(color: FacultyColors.gray500)),
          Text(value,
              style: FacultyTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
