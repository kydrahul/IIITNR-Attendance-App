import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';

class AddCourseDialog extends StatefulWidget {
  const AddCourseDialog({super.key});

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final FacultyApiService _apiService = FacultyApiService();
  int _currentStep = 1; // 1: Info & Config, 2: Timetable, 3: Review, 4: Success
  String _reviewTab = 'summary'; // 'summary' or 'table'
  bool _isCreating = false;

  // Step 1 & 2 Data
  // Step 1: Basic Info
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();

  // Step 2: Course Configuration
  String? _selectedBranch;
  String? _selectedCourseYear;
  String? _selectedAcademicYear = '2023-24';
  String? _selectedSemester = '1';
  String? _selectedCredits = '4';
  String? _selectedSession = 'Autumn';

  // Step 3: Timetable Data
  final List<_BranchTimeSlot> _selectedSlots = [];
  String _currentTypeMode = 'theory'; // 'theory' or 'lab'
  String _selectedDay = 'Monday';

  // Step 4: Results
  List<dynamic> _results = [];

  final List<String> _branchesList = ['CSE', 'DSAI', 'ECE'];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
    '05:00 PM - 06:00 PM'
  ];

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _handleSlotClick(String day, String time) {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a branch first')));
      return;
    }

    setState(() {
      final existingSlotIdx = _selectedSlots.indexWhere(
          (s) => s.day == day && s.time == time && s.branch == _selectedBranch);

      if (existingSlotIdx != -1) {
        if (_selectedSlots[existingSlotIdx].type != _currentTypeMode) {
          // Update type
          _selectedSlots[existingSlotIdx] = _BranchTimeSlot(
              day: day,
              time: time,
              type: _currentTypeMode,
              branch: _selectedBranch!);
        } else {
          // Remove slot
          _selectedSlots.removeAt(existingSlotIdx);
        }
      } else {
        // Add slot
        _selectedSlots.add(_BranchTimeSlot(
            day: day,
            time: time,
            type: _currentTypeMode,
            branch: _selectedBranch!));
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select at least one time slot')));
      return;
    }

    setState(() => _isCreating = true);
    final List<dynamic> newResults = [];

    try {
      final res = await _apiService.createFullClass({
        'name': _courseNameController.text,
        'code': _courseCodeController.text,
        'branch': _selectedBranch ?? 'CSE',
        'year': _selectedCourseYear ?? '1st',
        'academicYear': _selectedAcademicYear ?? '2023-24',
        'semester': _selectedSemester ?? '1',
        'credits': int.tryParse(_selectedCredits ?? '4') ?? 4,
        'session': _selectedSession ?? 'Autumn',
        'slots': _selectedSlots.map((s) => s.toJson()).toList(),
      });

      if (res['course'] != null) {
        newResults.add({
          'branch': _selectedBranch,
          'joinCode': res['course']['joinCode'],
          'courseName': _courseNameController.text,
          'courseCode': _courseCodeController.text,
        });
      }

      if (newResults.isNotEmpty) {
        setState(() {
          _results = newResults;
          _currentStep = 4;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No classes were created. Check branches and timetable.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isCreating = false);
    }
  }

  // --- UI Components ---

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: FacultyTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
          children: required
              ? [
                  const TextSpan(
                      text: ' *', style: TextStyle(color: Colors.red))
                ]
              : [],
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

  Widget _buildTextFieldWithIcon(TextEditingController controller, String label,
      String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextFieldPlain(TextEditingController controller, String hintText,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hintText.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: FacultyTextStyles.bodyLarge
                .copyWith(color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: FacultyTextStyles.bodyLarge
                  .copyWith(color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? currentValue,
      List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8))),
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
                  style: FacultyTextStyles.bodyLarge
                      .copyWith(color: const Color(0xFF94A3B8))),
              icon:
                  const Icon(LucideIcons.chevronDown, color: Color(0xFF64748B)),
              isExpanded: true,
              style: FacultyTextStyles.bodyLarge
                  .copyWith(color: const Color(0xFF1E293B)),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggleButton(String type, String text) {
    final isSelected = _currentTypeMode == type;
    return GestureDetector(
      onTap: () => setState(() => _currentTypeMode = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          '${_selectedBranch ?? 'Branch'} $text',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BASIC INFORMATION', isFirst: true),
        _buildTextFieldPlain(_courseNameController, 'Course Name'),
        const SizedBox(height: 16),
        _buildTextFieldPlain(_courseCodeController, 'Course Code'),
        const SizedBox(height: 24),
        _buildSectionHeader('ACADEMIC DETAILS'),
        _buildDropdownField('Select Branch', _selectedBranch, _branchesList,
            (val) => setState(() => _selectedBranch = val)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                  'Select Year',
                  _selectedCourseYear,
                  ['1st', '2nd', '3rd', '4th'],
                  (val) => setState(() => _selectedCourseYear = val)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownField(
                  'Academic Year',
                  _selectedAcademicYear,
                  ['2023-24', '2024-25', '2025-26', '2026-27'],
                  (val) => setState(() => _selectedAcademicYear = val)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CLASS CONFIGURATION', isFirst: true),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                  'Semester',
                  _selectedSemester,
                  ['1', '2', '3', '4', '5', '6', '7', '8'],
                  (val) => setState(() => _selectedSemester = val)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownField(
                  'Credits',
                  _selectedCredits,
                  ['1', '2', '3', '4'],
                  (val) => setState(() => _selectedCredits = val)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdownField('Session', _selectedSession, ['Autumn', 'Spring'],
            (val) => setState(() => _selectedSession = val)),
        const SizedBox(height: 24),
        _buildSectionHeader('ASSIGN SLOTS'),
        // Timetable UI...
        // Mode Toggle (Pill shape)
        if (_selectedBranch != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTypeMode = 'theory'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTypeMode == 'theory'
                            ? const Color(0xFF0F172A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Theory',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _currentTypeMode == 'theory'
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTypeMode = 'lab'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTypeMode == 'lab'
                            ? const Color(0xFF0F172A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Lab',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _currentTypeMode == 'lab'
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (_selectedBranch != null) _buildTimeSlotSelector(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FINAL REVIEW', isFirst: true),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reviewTab = 'summary'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _reviewTab == 'summary'
                          ? const Color(0xFF0F172A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      'Summary',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _reviewTab == 'summary'
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reviewTab = 'table'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _reviewTab == 'table'
                          ? const Color(0xFF0F172A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      'Table View',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _reviewTab == 'table'
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _reviewTab == 'summary' ? _buildReviewSummary() : _buildReviewTable(),
      ],
    );
  }

  Widget _buildReviewSummary() {
    return Column(
      children: [
        _buildSummaryRow(LucideIcons.book, 'Course',
            '${_courseNameController.text} (${_courseCodeController.text})'),
        _buildSummaryRow(LucideIcons.graduationCap, 'Academic',
            '$_selectedBranch - Year $_selectedCourseYear'),
        _buildSummaryRow(LucideIcons.calendar, 'Term',
            'Sem $_selectedSemester, $_selectedSession $_selectedAcademicYear'),
        _buildSummaryRow(LucideIcons.clock, 'Slots',
            '${_selectedSlots.length} Slots Selected'),
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
                _selectedSlots.where((s) => s.type == 'theory').length,
                const Color(0xFF2563EB)),
            const SizedBox(width: 16),
            _buildCountBadge(
                'LAB',
                _selectedSlots.where((s) => s.type == 'lab').length,
                const Color(0xFF7C3AED)),
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
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8))),
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

  Widget _buildReviewTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2), // Space for time
          },
          defaultColumnWidth: const FlexColumnWidth(1.0),
          border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 0.5),
          children: [
            // Header Row (Days)
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const _TableCell('Time', isHeader: true),
                ..._days
                    .take(5)
                    .map((day) => _TableCell(day[0], isHeader: true)),
              ],
            ),
            // Data Rows (Time Slots x Days)
            ..._timeSlots.map((time) {
              return TableRow(
                children: [
                  _TableCell(time.split(' - ')[0],
                      isSmall: true), // Start time only
                  ..._days.take(5).map((day) {
                    final matches = _selectedSlots
                        .where((s) => s.day == day && s.time == time);
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

  Widget _buildTimeSlotSelector() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Day Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.take(5).map((day) {
              final isSelected = _selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      day.substring(0, 3),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Text(
            'Tap a slot to assign ${(_currentTypeMode == "theory" ? "Theory" : "Lab")} mode',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),

        // Time Slots Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final time = _timeSlots[index];
            final exists = _selectedSlots.any((s) =>
                s.day == _selectedDay &&
                s.time == time &&
                s.branch == _selectedBranch);

            final currentSlot = exists
                ? _selectedSlots.firstWhere((s) =>
                    s.day == _selectedDay &&
                    s.time == time &&
                    s.branch == _selectedBranch)
                : null;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (exists) {
                    _selectedSlots.removeWhere((s) =>
                        s.day == _selectedDay &&
                        s.time == time &&
                        s.branch == _selectedBranch);
                  } else {
                    _selectedSlots.add(_BranchTimeSlot(
                      day: _selectedDay,
                      time: time,
                      type: _currentTypeMode,
                      branch: _selectedBranch!,
                    ));
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: exists
                      ? (currentSlot?.type == 'theory'
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : const Color(0xFF7C3AED).withOpacity(0.1))
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: exists
                        ? (currentSlot?.type == 'theory'
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF7C3AED))
                        : const Color(0xFFE2E8F0),
                    width: exists ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      exists ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      size: 16,
                      color: exists
                          ? (currentSlot?.type == 'theory'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF7C3AED))
                          : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time.split(' - ')[0],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  exists ? FontWeight.bold : FontWeight.normal,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (exists)
                            Text(
                              currentSlot?.type.toUpperCase() ?? '',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: currentSlot?.type == 'theory'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF7C3AED),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.checkCircle,
              color: Colors.green, size: 48),
        ),
        const SizedBox(height: 24),
        const Text('Class Created!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        const Text('The class has been successfully added to your list.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        const SizedBox(height: 32),
        ..._results.map((res) => Container(
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
                    )
                  ]),
              child: Column(
                children: [
                  Text('${res['branch']} - ${res['courseName']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('JOIN CODE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(res['joinCode'],
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB),
                            letterSpacing: 4,
                            fontFamily: 'monospace')),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_currentStep > 1 && _currentStep < 4)
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft),
                    onPressed: _isCreating
                        ? null
                        : () => setState(() => _currentStep--),
                  )
                else
                  const SizedBox(
                      width: 48), // Match IconButton size for symmetry
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Add New Class',
                          style: FacultyTextStyles.h2.copyWith(fontSize: 20)),
                      if (_currentStep < 4)
                        Text(
                          'STEP $_currentStep OF 3: ${_currentStep == 1 ? "BASIC INFO" : (_currentStep == 2 ? "TIMETABLE" : "REVIEW")}',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const ClampingScrollPhysics(), // Prevent elastic scrolling if not needed
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _currentStep == 1
                        ? _buildStep1()
                        : (_currentStep == 2
                            ? _buildStep2()
                            : (_currentStep == 3
                                ? _buildStep3()
                                : _buildStep4())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_currentStep > 1 && _currentStep < 4)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _isCreating
                          ? null
                          : () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text('Back',
                          style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  ),
                if (_currentStep > 1 && _currentStep < 4)
                  const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isCreating
                        ? null
                        : () {
                            if (_currentStep < 3) {
                              if (_currentStep == 1) {
                                if (_courseNameController.text.isEmpty ||
                                    _courseCodeController.text.isEmpty ||
                                    _selectedBranch == null ||
                                    _selectedCourseYear == null ||
                                    _selectedAcademicYear == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please fill all required fields')));
                                  return;
                                }
                              } else if (_currentStep == 2) {
                                if (_selectedSemester == null ||
                                    _selectedCredits == null ||
                                    _selectedSession == null ||
                                    _selectedSlots.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please configure class and select at least one slot')));
                                  return;
                                }
                              }
                              setState(() => _currentStep++);
                            } else if (_currentStep == 3) {
                              _handleSubmit();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(_currentStep < 3
                            ? 'Next'
                            : (_currentStep == 3 ? 'Create Class' : 'Done')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchTimeSlot {
  final String day;
  final String time;
  final String type;
  final String branch;

  _BranchTimeSlot(
      {required this.day,
      required this.time,
      required this.type,
      required this.branch});

  Map<String, dynamic> toJson() => {
        'day': day,
        'time': time,
        'type': type,
        'branch': branch,
      };
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isType;
  final bool isSmall;

  const _TableCell(this.text,
      {this.isHeader = false, this.isType = false, this.isSmall = false});

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
          fontSize: isSmall ? 9 : (isHeader ? 10 : 11), // Granular font sizes
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
