import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/faculty/faculty_colors.dart';
import '../../constants/faculty/faculty_text_styles.dart';

class ProfilePopup extends StatelessWidget {
  final VoidCallback onClose;
  final Map<String, dynamic>? profileData;
  final String? photoUrl;

  const ProfilePopup({
    super.key,
    required this.onClose,
    this.profileData,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final name = profileData?['name'] ?? 'Loading...';
    final designation = profileData?['designation'] ?? 'Faculty Member';
    final department = profileData?['department'] ?? 'N/A';
    final facultyId = profileData?['facultyId'] ?? profileData?['_id'] ?? 'N/A';
    final email = profileData?['email'] ?? 'N/A';
    final effectivePhotoUrl = photoUrl ?? profileData?['photoUrl'];

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        // Popup
        Positioned(
          top: 80,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FacultyColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: FacultyColors.gray100),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: onClose,
                      child: const Icon(LucideIcons.xCircle,
                          size: 20, color: FacultyColors.gray400),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Profile Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [FacultyColors.blue600, FacultyColors.blue500],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FacultyColors.blue600.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: FacultyColors.white,
                      ),
                      child: ClipOval(
                        child: effectivePhotoUrl != null && effectivePhotoUrl.isNotEmpty
                            ? Image.network(
                                effectivePhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitialAvatar(name),
                              )
                            : _buildInitialAvatar(name),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name & Designation
                  Text(
                    name,
                    style: FacultyTextStyles.h3.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    designation,
                    style: FacultyTextStyles.bodyMedium.copyWith(
                      color: FacultyColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FacultyColors.gray50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("ID", facultyId),
                        const SizedBox(height: 12),
                        _buildDetailRow("DEPT", department),
                        const SizedBox(height: 12),
                        _buildDetailRow("EMAIL", email),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: FacultyColors.blue600,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FacultyTextStyles.bodySmall.copyWith(
            color: FacultyColors.gray400,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: FacultyTextStyles.bodySmall.copyWith(
              color: FacultyColors.gray700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
