import 'package:flutter/material.dart';
import 'course_wizard_state.dart';

/// Step 2 — Branch selection.
/// For Summer courses the branch is auto-locked to "Summer Intern"
/// and an informational card is shown instead of the picker.
class Step2BranchSelector extends StatelessWidget {
  final List<String> selectedBranches;
  final bool isSummerSession;
  final ValueChanged<String> onToggleBranch;

  const Step2BranchSelector({
    super.key,
    required this.selectedBranches,
    required this.isSummerSession,
    required this.onToggleBranch,
  });

  @override
  Widget build(BuildContext context) {
    if (isSummerSession) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('TARGET AUDIENCE', isFirst: true),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny, size: 24, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summer Intern Course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This course will be available for summer interns to join using the join code.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SELECT BRANCHES', isFirst: true),
        const Text(
          'Choose one or more branches for this course.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kWizardBranches.map((branch) {
            final isSelected = selectedBranches.contains(branch);
            return FilterChip(
              label: Text(branch),
              selected: isSelected,
              onSelected: (_) => onToggleBranch(branch),
              backgroundColor: Colors.white,
              showCheckmark: false,
              selectedColor: const Color(0xFF0F172A),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool isFirst = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, top: isFirst ? 0 : 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
