import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class CustomHeader extends StatefulWidget {
  final VoidCallback onProfileClick;

  const CustomHeader({super.key, required this.onProfileClick});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (_profileData != null) return;

    setState(() => _isLoading = true);

    try {
      final profile = await _apiService.getProfile();
      final user = _authService.getCurrentUser();

      if (mounted) {
        setState(() {
          _profileData = profile;
          _profileData!['photoUrl'] = user?.photoURL;
          _profileData!['email'] = user?.email;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? getProfileData() => _profileData;

  @override
  Widget build(BuildContext context) {
    final userName = _profileData?['name'] ?? 'User';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Image.asset(
            'assets/logo.png',
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 40,
              width: 100,
              color: AppColors.gray200,
              alignment: Alignment.center,
              child: const Text("LOGO",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),

          // Profile Button
          GestureDetector(
            onTap: widget.onProfileClick,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gray100,
                border: Border.all(color: AppColors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ClipOval(
                      child: Image.network(
                        _profileData?['photoUrl'] ??
                            "https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(userName)}",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: AppColors.gray400),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
