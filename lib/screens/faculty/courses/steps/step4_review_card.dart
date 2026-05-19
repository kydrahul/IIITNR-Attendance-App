import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'course_wizard_state.dart';

/// Step 4 — Final review before submitting.
/// Shows either a human-readable Summary or a timetable Table view.
class Step4ReviewCard extends StatelessWidget {
  final String courseName;
  final String courseCode;
  final List<String> selectedBranches;
  final String? selectedCourseYear;
  final String? selectedSemester;
  final String? selectedSession;
  final String academicYear;
  final List<BranchTimeSlot> selectedSlots;
  final bool isSummerSession;

  // Toggle between 'summary' and 'table'
  final String reviewTab;
  final ValueChanged<String> onTabChanged;

  const Step4ReviewCard({
    super.key,
    required this.courseName,
    required this.courseCode,
    required this.selectedBranches,
    required this.selectedCourseYear,
    required this.selectedSemester,
    required this.selectedSession,
    required this.academicYear,
    required this.selectedSlots,
    required this.isSummerSession,
    required this.reviewTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FINAL REVIEW', isFirst: true),

        // Summary / Table toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTabButton('summary', 'Summary')),
              Expanded(child: _buildTabButton('table', 'Table View')),
            ],
          ),
        ),

        const SizedBox(height: 24),
        reviewTab == 'summary' ? _buildSummary() : _buildTable(),
      ],
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isSelected = reviewTab == tab;
    return GestureDetector(
      onTap: () => onTabChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        if (isSummerSession) ...[
          _buildSummaryRow(LucideIcons.book, 'Course', courseName),
          _buildSummaryRow(LucideIcons.calendar, 'Term', 'Summer 2026'),
          _buildSummaryRow(
              LucideIcons.clock, 'Slots', '${selectedSlots.length} Slots Selected'),
        ] else ...[
          _buildSummaryRow(
              LucideIcons.book, 'Course', '$courseName ($courseCode)'),
          _buildSummaryRow(LucideIcons.graduationCap, 'Branches',
              '${selectedBranches.join(', ')} - Year $selectedCourseYear'),
          _buildSummaryRow(LucideIcons.calendar, 'Term',
              'Sem $selectedSemester, $selectedSession $academicYear'),
          _buildSummaryRow(
              LucideIcons.clock, 'Slots', '${selectedSlots.length} Slots Selected'),
        ],
        const Divider(height: 32),
        const Text(
          'Total sessions per week',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCountBadge(
              'THEORY',
              selectedSlots.where((s) => s.type == 'theory').length,
              const Color(0xFF2563EB),
            ),
            const SizedBox(width: 16),
            _buildCountBadge(
              'LAB',
              selectedSlots.where((s) => s.type == 'lab').length,
              const Color(0xFF7C3AED),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    const fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(1.2)},
          defaultColumnWidth: const FlexColumnWidth(1.0),
          border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 0.5),
          children: [
            // Header row
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const _TableCell('Time', isHeader: true),
                ...days.map((d) => _TableCell(d, isHeader: true)),
              ],
            ),
            // Time rows
            ...kWizardTimeSlots.map((time) {
              return TableRow(
                children: [
                  _TableCell(time.split(' - ')[0], isSmall: true),
                  ...fullDays.map((day) {
                    final matches =
                        selectedSlots.where((s) => s.day == day && s.time == time);
                    final slot = matches.isNotEmpty ? matches.first : null;
                    if (slot == null) return const _TableCell('');
                    return _TableCell(
                      slot.type == 'theory' ? 'TH' : 'LAB',
                      isType: true,
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
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

/// Compact table cell used in the review table.
class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isType;
  final bool isSmall;

  const _TableCell(
    this.text, {
    this.isHeader = false,
    this.isType = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: TextStyle(
          fontSize: isSmall ? 9 : (isHeader ? 10 : 11),
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader
              ? const Color(0xFF64748B)
              : (isType
                  ? (text == 'THEORY' || text == 'TH'
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF7C3AED))
                  : const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}
