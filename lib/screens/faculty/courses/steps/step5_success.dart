import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Step 5 — Success screen.
/// Displayed after the course is created, showing the join code(s).
class Step5Success extends StatelessWidget {
  /// Each element contains: 'branch', 'courseName', 'courseCode', 'joinCode'.
  final List<dynamic> results;
  final bool isEditMode;

  const Step5Success({
    super.key,
    required this.results,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.checkCircle, color: Colors.green, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          isEditMode ? 'Class Updated!' : 'Class Created!',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          isEditMode
              ? 'The class schedule has been updated successfully.'
              : 'The class(es) have been successfully created.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 32),
        ...results.map((res) => _buildResultCard(res)),
      ],
    );
  }

  Widget _buildResultCard(dynamic res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${res['branch']} - ${res['courseName']}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'JOIN CODE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              res['joinCode'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB),
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
