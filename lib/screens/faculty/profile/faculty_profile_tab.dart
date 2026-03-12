import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/faculty/faculty_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacultyProfileTab extends StatefulWidget {
  const FacultyProfileTab({super.key});

  @override
  State<FacultyProfileTab> createState() => _FacultyProfileTabState();
}

class _FacultyProfileTabState extends State<FacultyProfileTab> {
  final FacultyApiService _apiService = FacultyApiService();
  final AuthService _authService = AuthService();
  FacultyProfile? _facultyProfile;
  bool _isLoading = true;

  int _defaultRadius = 50;
  int _defaultRefreshInterval = 10;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultRadius = prefs.getInt('default_scan_radius') ?? 50;
      _defaultRefreshInterval = prefs.getInt('default_qr_refresh_interval') ?? 10;
    });
  }

  Future<void> _saveRadius(int radius) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = radius.clamp(10, 150);
    await prefs.setInt('default_scan_radius', clamped);
    setState(() {
      _defaultRadius = clamped;
    });
  }

  Future<void> _saveRefreshInterval(int interval) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = interval.clamp(5, 60);
    await prefs.setInt('default_qr_refresh_interval', clamped);
    setState(() {
      _defaultRefreshInterval = clamped;
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _facultyProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings(String key, dynamic value) async {
    if (_facultyProfile == null) return;

    final updatedSettings = Map<String, dynamic>.from(_facultyProfile!.settings);
    updatedSettings[key] = value;

    try {
      final updatedProfile = await _apiService.updateProfile(
        FacultyProfile(
          id: _facultyProfile!.id,
          facultyId: _facultyProfile!.facultyId,
          employeeId: _facultyProfile!.employeeId,
          name: _facultyProfile!.name,
          email: _facultyProfile!.email,
          department: _facultyProfile!.department,
          position: _facultyProfile!.position,
          designation: _facultyProfile!.designation,
          photoUrl: _facultyProfile!.photoUrl,
          settings: updatedSettings,
        ).toJson(),
      );
      if (mounted) {
        setState(() {
          _facultyProfile = updatedProfile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Default Scan Radius', style: FacultyTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set the default location radius (10m - 150m) for scanning.', style: FacultyTextStyles.bodyMedium),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: currentRadius.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Radius (m)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  currentRadius = int.tryParse(val) ?? 50;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _saveRadius(currentRadius);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary),
              child: const Text('Save', style: TextStyle(color: FacultyColors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRefreshIntervalDialog() {
    int currentInterval = _defaultRefreshInterval;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FacultyColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('QR Refresh Interval', style: FacultyTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set the default interval (seconds) for dynamic QR codes.', style: FacultyTextStyles.bodyMedium),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: currentInterval.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Interval (sec)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  currentInterval = int.tryParse(val) ?? 10;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _saveRefreshInterval(currentInterval);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary),
              child: const Text('Save', style: TextStyle(color: FacultyColors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            "Settings",
            style: FacultyTextStyles.h1.copyWith(fontWeight: FontWeight.normal),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchProfile,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
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
                            child: Builder(builder: (context) {
                              final photoUrl = _authService.currentUser?.photoURL ?? _facultyProfile?.photoUrl;
                              if (photoUrl != null && photoUrl.isNotEmpty) {
                                return Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(LucideIcons.user,
                                          size: 40, color: FacultyColors.gray400),
                                );
                              }
                              return const Icon(LucideIcons.user,
                                  size: 40, color: FacultyColors.gray400);
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _facultyProfile?.name ?? _authService.currentUser?.displayName ?? 'Faculty Member',
                        style: FacultyTextStyles.h2
                            .copyWith(fontWeight: FontWeight.normal),
                      ),
                      Text(
                        _facultyProfile?.email ??
                            _authService.currentUser?.email ??
                            'faculty@example.com',
                        style: FacultyTextStyles.bodyMedium
                            .copyWith(color: FacultyColors.gray500),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: FacultyColors.gray50, thickness: 1),
                      const SizedBox(height: 16),
                      _buildStatRow(
                          'Employee ID', _isLoading ? 'Loading...' : (_facultyProfile?.employeeId ?? 'N/A')),
                      _buildStatRow(
                          'Department', _isLoading ? 'Loading...' : (_facultyProfile?.department ?? 'N/A')),
                      _buildStatRow(
                          'Position', _isLoading ? 'Loading...' : (_facultyProfile?.position ?? 'N/A')),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
                        iconColor: FacultyColors.black,
                        iconBg: FacultyColors.gray50,
                        label: "Default Scan Radius",
                        value: "$_defaultRadius m",
                        onTap: _showRadiusDialog,
                      ),
                      _buildDivider(),
                      _buildSettingItemWithSwitch(
                        icon: LucideIcons.mapPin,
                        iconColor: FacultyColors.black,
                        iconBg: FacultyColors.gray50,
                        label: "Always Require Location",
                        value: _facultyProfile?.settings['defaultIsLocationRequired'] ?? true,
                        onChanged: (val) => _updateSettings('defaultIsLocationRequired', val),
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        context,
                        icon: LucideIcons.refreshCw,
                        iconColor: FacultyColors.black,
                        iconBg: FacultyColors.gray50,
                        label: "Default QR Refresh",
                        value: "$_defaultRefreshInterval s",
                        onTap: _showRefreshIntervalDialog,
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        context,
                        icon: LucideIcons.fileText,
                        iconColor: FacultyColors.black,
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
                        iconColor: FacultyColors.black,
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
                        iconColor: FacultyColors.black,
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
                        iconColor: FacultyColors.black,
                        iconBg: FacultyColors.gray50,
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
                  child: Text(
                    "Version 1.0.0",
                    style: FacultyTextStyles.bodySmall.copyWith(color: FacultyColors.gray400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                    fontWeight: FontWeight.normal,
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
                        fontWeight: FontWeight.normal)),
                const SizedBox(width: 8),
              ],
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: FacultyColors.black),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: FacultyColors.gray50);
  }

  Widget _buildSettingItemWithSwitch({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  fontWeight: FontWeight.normal,
                  color: FacultyColors.black,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: FacultyColors.black,
          ),
        ],
      ),
    );
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
                  .copyWith(fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }
}
