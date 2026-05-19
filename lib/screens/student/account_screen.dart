import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

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
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle,
                              size: 48, color: AppColors.red500),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!.contains('Profile not found')
                                ? 'Your profile setup is incomplete.'
                                : _errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_errorMessage!
                                  .contains('Profile not found')) {
                                Navigator.pushNamed(context, '/profile-setup');
                              } else {
                                setState(() => _isLoading = true);
                                _fetchProfile();
                              }
                            },
                            child: Text(
                                _errorMessage!.contains('Profile not found')
                                    ? 'Complete Setup'
                                    : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: EdgeInsets.all(
                                Responsive.horizontalPadding(context)),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: AppColors.gray200),
                                    ),
                                    child: const Icon(LucideIcons.chevronLeft,
                                        size: 20, color: AppColors.gray600),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text("My Account",
                                    style: AppTextStyles.h2
                                        .copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Profile Info
                          Column(
                            children: [
                              Container(
                                width: Responsive.w(88, context).clamp(72.0, 104.0),
                                height: Responsive.w(88, context).clamp(72.0, 104.0),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF60A5FA),
                                      Color(0xFFC084FC)
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: ClipOval(
                                    child: Image.network(
                                      _authService.currentUser?.photoURL ??
                                          "https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(_profileData?['name'] ?? 'User')}",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.person,
                                                  size: 48,
                                                  color: AppColors.gray400),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _profileData?['name'] ?? 'N/A',
                                style: AppTextStyles.h1
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _profileData?['department'] ?? 'N/A',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.gray500,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Details List
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    Responsive.horizontalPadding(context)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.gray100),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                      "Roll Number",
                                      _profileData?['rollNo']?.toString() ??
                                          _profileData?['rollNumber']
                                              ?.toString() ??
                                          'N/A'),
                                  _buildDivider(),
                                  _buildDetailRow(
                                      "Department",
                                      _profileData?['department'] ??
                                          _profileData?['branch'] ??
                                          'N/A'),
                                  _buildDivider(),
                                  _buildDetailRow(
                                      "Passing Year",
                                      _profileData?['passingYear']
                                              ?.toString() ??
                                          _profileData?['passingOutYear']
                                              ?.toString() ??
                                          'N/A'),
                                  _buildDivider(),
                                  _buildDetailRow(
                                      "Email",
                                      _authService.currentUser?.email ??
                                          _profileData?['email'] ??
                                          'N/A'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray500, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray800, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.gray50);
  }
}
