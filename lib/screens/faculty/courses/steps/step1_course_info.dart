import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../utils/date_utils.dart' as du;

/// Step 1 — Basic course info: name, code, degree, year, semester,
/// credits, session, and (for Summer) date-range pickers.
class Step1CourseInfo extends StatelessWidget {
  // Controllers
  final TextEditingController courseNameController;
  final TextEditingController courseCodeController;

  // Drop-down selections
  final String? selectedDegree;
  final String? selectedCourseYear;
  final String? selectedSemester;
  final String? selectedCredits;
  final String? selectedSession;
  final DateTime? summerStartDate;
  final DateTime? summerEndDate;

  // Callbacks
  final ValueChanged<String?> onDegreeChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onSemesterChanged;
  final ValueChanged<String?> onCreditsChanged;
  final ValueChanged<String?> onSessionChanged;
  final ValueChanged<DateTime?> onSummerStartChanged;
  final ValueChanged<DateTime?> onSummerEndChanged;

  const Step1CourseInfo({
    super.key,
    required this.courseNameController,
    required this.courseCodeController,
    required this.selectedDegree,
    required this.selectedCourseYear,
    required this.selectedSemester,
    required this.selectedCredits,
    required this.selectedSession,
    required this.summerStartDate,
    required this.summerEndDate,
    required this.onDegreeChanged,
    required this.onYearChanged,
    required this.onSemesterChanged,
    required this.onCreditsChanged,
    required this.onSessionChanged,
    required this.onSummerStartChanged,
    required this.onSummerEndChanged,
  });

  bool get _isSummer => selectedSession == 'Summer';

  @override
  Widget build(BuildContext context) {
    List<String> years = ['1st', '2nd'];
    if (selectedDegree == 'B.Tech') years.addAll(['3rd', '4th']);

    List<String> semesters = [];
    if (selectedCourseYear == '1st') { semesters = ['1', '2']; }
    else if (selectedCourseYear == '2nd') { semesters = ['3', '4']; }
    else if (selectedCourseYear == '3rd') { semesters = ['5', '6']; }
    else if (selectedCourseYear == '4th') { semesters = ['7', '8']; }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('COURSE INFORMATION', isFirst: true),
        _buildTextFieldPlain(courseNameController, 'Course Name'),
        const SizedBox(height: 16),

        if (!_isSummer) ...[
          _buildTextFieldPlain(courseCodeController, 'Course Code'),
          const SizedBox(height: 16),
        ],

        // Session selector
        if (_isSummer) ...[
          _buildDropdownField(
            'Session',
            selectedSession,
            ['Autumn', 'Spring', 'Summer'],
            onSessionChanged,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('COURSE DURATION'),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  context,
                  'Start Date',
                  summerStartDate,
                  (picked) => onSummerStartChanged(picked),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerField(
                  context,
                  'End Date',
                  summerEndDate,
                  (picked) => onSummerEndChanged(picked),
                  firstDate: summerStartDate,
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  'Credits',
                  selectedCredits,
                  ['1', '2', '3', '4'],
                  onCreditsChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  'Session',
                  selectedSession,
                  ['Autumn', 'Spring', 'Summer'],
                  onSessionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            'Degree',
            selectedDegree,
            ['B.Tech', 'M.Tech'],
            onDegreeChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  'Year',
                  years.contains(selectedCourseYear) ? selectedCourseYear : years.first,
                  years,
                  onYearChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  'Semester',
                  semesters.contains(selectedSemester) ? selectedSemester : (semesters.isEmpty ? null : semesters.first),
                  semesters,
                  onSemesterChanged,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Shared widget builders ───────────────────────────────────────────────

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

  Widget _buildTextFieldPlain(TextEditingController controller, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hintText.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            style: FacultyTextStyles.bodyLarge.copyWith(color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: FacultyTextStyles.bodyLarge.copyWith(color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? currentValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(currentValue) ? currentValue : null,
              hint: Text(label,
                  style: FacultyTextStyles.bodyLarge.copyWith(color: const Color(0xFF94A3B8))),
              icon: const Icon(LucideIcons.chevronDown, color: Color(0xFF64748B)),
              isExpanded: true,
              style: FacultyTextStyles.bodyLarge.copyWith(color: const Color(0xFF1E293B)),
              onChanged: onChanged,
              items: items
                  .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(
    BuildContext context,
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onPicked, {
    DateTime? firstDate,
  }) {
    final displayText = du.formatDateDMY(date) == 'Select date' ? 'Select' : du.formatDateDMY(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(2025),
              lastDate: DateTime(2027, 12, 31),
            );
            onPicked(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
