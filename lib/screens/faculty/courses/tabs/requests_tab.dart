import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';

/// Tab 4 of CourseDetailsScreen (Summer courses only) — pending intern join
/// request approvals with pull-to-refresh support.
class RequestsTab extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final Future<void> Function(String enrollmentId, String action) onReview;
  final Future<void> Function() onRefresh;

  const RequestsTab({
    super.key,
    required this.requests,
    required this.onReview,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: FacultyColors.primary,
      child: requests.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.userCheck,
                          size: 52, color: FacultyColors.gray300),
                      SizedBox(height: 16),
                      Text('No Pending Requests',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: FacultyColors.gray500)),
                      SizedBox(height: 6),
                      Text('Intern join requests will appear here',
                          style: TextStyle(
                              fontSize: 13, color: FacultyColors.gray400)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildRequestCard(requests[index]),
            ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final name = req['studentName'] ?? 'Unknown Intern';
    final college = req['studentCollege'] ?? 'N/A';
    final requestedAt = req['requestedAt'] as String?;
    final timeAgo = _timeAgo(requestedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEDE9FE),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: FacultyColors.black)),
                    const SizedBox(height: 2),
                    Text(college,
                        style: const TextStyle(
                            fontSize: 12, color: FacultyColors.gray500)),
                  ],
                ),
              ),
              if (timeAgo.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: FacultyColors.gray500)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onReview(req['id']?.toString() ?? '', 'deny'),
                  icon: const Icon(LucideIcons.x,
                      size: 15, color: Color(0xFFDC2626)),
                  label: const Text('Deny',
                      style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFFF1F1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onReview(req['id']?.toString() ?? '', 'approve'),
                  icon: const Icon(LucideIcons.check,
                      size: 15, color: Colors.white),
                  label: const Text('Approve',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
