import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../services/auth_service.dart';

class FacultyAccountScreen extends StatefulWidget {
  const FacultyAccountScreen({super.key});

  @override
  State<FacultyAccountScreen> createState() => _FacultyAccountScreenState();
}

class _FacultyAccountScreenState extends State<FacultyAccountScreen> {
  final FacultyApiService _apiService = FacultyApiService();
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
      backgroundColor: FacultyColors.background,
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
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: FacultyTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _isLoading = true);
                              _fetchProfile();
                            },
                            child: const Text('Retry'),
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
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: FacultyColors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: FacultyColors.gray100),
                                    ),
                                    child: const Icon(LucideIcons.chevronLeft,
                                        size: 20, color: FacultyColors.black),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text("My Account",
                                    style: FacultyTextStyles.h2
                                        .copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Profile Info
                          Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      FacultyColors.blue600,
                                      FacultyColors.blue500
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: FacultyColors.white,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: ClipOval(
                                    child: Image.network(
                                      _authService.currentUser?.photoURL ??
                                          "https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(_profileData?['name'] ?? 'Faculty')}",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(LucideIcons.user,
                                                  size: 48,
                                                  color: FacultyColors.gray400),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _profileData?['name'] ?? 'N/A',
                                style: FacultyTextStyles.h1
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _profileData?['department'] ?? 'N/A',
                                style: FacultyTextStyles.bodyMedium.copyWith(
                                    color: FacultyColors.gray500,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Details List
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: FacultyColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: FacultyColors.gray100),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                      "Faculty ID",
                                      _profileData?['facultyId']?.toString() ??
                                          'N/A'),
                                  _buildDivider(),
                                  _buildDetailRow("Department",
                                      _profileData?['department'] ?? 'N/A'),
                                  _buildDivider(),
                                  _buildDetailRow("Designation",
                                      _profileData?['designation'] ?? 'N/A'),
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
              style: FacultyTextStyles.bodyMedium.copyWith(
                  color: FacultyColors.gray500, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: FacultyTextStyles.bodyMedium.copyWith(
                  color: FacultyColors.black, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: FacultyColors.gray100);
  }
}
