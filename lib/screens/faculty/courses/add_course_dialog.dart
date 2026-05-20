import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../models/faculty/faculty_models.dart';

class AddCourseDialog extends StatefulWidget {
  final Course? editCourse;
  const AddCourseDialog({super.key, this.editCourse});

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final FacultyApiService _apiService = FacultyApiService();
  int _currentStep =
      1; // 1: Info, 2: Branches, 3: Timetable, 4: Review, 5: Success
  String _reviewTab = 'summary'; // 'summary' or 'table'
  bool _isCreating = false;
  List<Course> _existingCourses = [];

  // Step 1: Basic Info & Class Configuration
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  String? _selectedDegree = 'B.Tech';
  String? _selectedCourseYear = '1st';
  String? _selectedSemester = '1';
  String? _selectedCredits = '4';
  String? _selectedSession = 'Autumn';
  DateTime? _summerStartDate;
  DateTime? _summerEndDate;
  String get _selectedAcademicYear {
    final now = DateTime.now();
    final year = now.month < 7 ? now.year - 1 : now.year;
    return '$year-${(year + 1).toString().substring(2)}';
  }

  // Step 2: Branch selection
  final List<String> _selectedBranches = [];

  // Step 3: Timetable Data
  final List<_BranchTimeSlot> _selectedSlots = [];
  String _currentTypeMode = 'theory'; // 'theory' or 'lab'
  String _selectedDay = 'Monday';
  String? _activeBranchForSlots; // Branch currently being edited in timetable

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
  void initState() {
    super.initState();
    if (widget.editCourse != null) {
      final c = widget.editCourse!;
      _courseNameController.text = c.name;
      _courseCodeController.text = c.code;
      _selectedDegree = c.degree ?? 'B.Tech';
      _selectedSemester = c.semester ?? '1';
      _selectedCredits = c.credits.toString();
      _selectedSession = c.session ?? 'Autumn';

      _selectedBranches.clear();
      if (c.department.isNotEmpty) {
        _selectedBranches.add(c.department);
      }

      _selectedSlots.clear();
      for (var slot in c.timetable) {
        _selectedSlots.add(_BranchTimeSlot(
          day: slot.day,
          time: slot.time,
          type: slot.type,
          branch: c.department,
        ));
      }
    }
    _loadExistingCourses();
  }

  Future<void> _loadExistingCourses() async {
    try {
      final courses = await _apiService.listCourses();
      setState(() {
        _existingCourses = courses;
      });
    } catch (e) {
      // Fail silently
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _handleSlotClick(String day, String time) {
    if (_activeBranchForSlots == null) return;

    setState(() {
      final existingSlotIdx = _selectedSlots.indexWhere((s) =>
          s.day == day && s.time == time && s.branch == _activeBranchForSlots);

      if (existingSlotIdx != -1) {
        if (_selectedSlots[existingSlotIdx].type != _currentTypeMode) {
          _selectedSlots[existingSlotIdx] = _BranchTimeSlot(
              day: day,
              time: time,
              type: _currentTypeMode,
              branch: _activeBranchForSlots!);
        } else {
          _selectedSlots.removeAt(existingSlotIdx);
        }
      } else {
        _selectedSlots.add(_BranchTimeSlot(
            day: day,
            time: time,
            type: _currentTypeMode,
            branch: _activeBranchForSlots!));
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
      for (String branch in _selectedBranches) {
        final branchSlots = _selectedSlots
            .where((s) => s.branch == branch)
            .map((s) => {
                  'day': s.day,
                  'time': s.time,
                  'type': s.type,
                  'room': null, // Optional
                })
            .toList();

        if (branchSlots.isEmpty) continue;

        final payload = _isSummerSession
            ? {
                'courseName': _courseNameController.text,
                'courseCode': 'SUM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                'branch': branch,
                'degree': 'Summer',
                'year': 'N/A',
                'academicYear': _selectedAcademicYear,
                'semester': 'N/A',
                'credits': 0,
                'session': 'Summer',
                'startDate': _summerStartDate?.toIso8601String(),
                'endDate': _summerEndDate?.toIso8601String(),
                'timetable': branchSlots,
              }
            : {
                'courseName': _courseNameController.text,
                'courseCode': _courseCodeController.text,
                'branch': branch,
                'degree': _selectedDegree,
                'year': _selectedCourseYear ?? '1st',
                'academicYear': _selectedAcademicYear,
                'semester': _selectedSemester ?? '1',
                'credits': int.tryParse(_selectedCredits ?? '4') ?? 4,
                'session': _selectedSession ?? 'Autumn',
                'timetable': branchSlots,
              };

        final Map<String, dynamic> res;
        if (kDebugMode) debugPrint('Creating class with payload: $payload');
        if (widget.editCourse != null) {
          res = await _apiService.updateCourseSchedule(
            courseId: widget.editCourse!.id,
            payload: payload,
          );
        } else {
          res = await _apiService.createFullClass(payload);
        }
        if (kDebugMode) debugPrint('Create class response: $res');

        if (res['success'] == true) {
          newResults.add({
            'branch': branch,
            'joinCode': (res['course'] != null
                    ? res['course']['joinCode']
                    : widget.editCourse?.joinCode) ??
                'N/A',
            'courseName': _courseNameController.text,
            'courseCode': payload['courseCode'] ?? _courseCodeController.text,
          });
          // If we are editing, we only update one course
          if (widget.editCourse != null) break;
        }
      }

      if (newResults.isNotEmpty) {
        setState(() {
          _results = newResults;
          _currentStep = 5;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('No changes were saved. Check branches and timetable.')));
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
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime? date, VoidCallback onTap) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final displayText = date != null
        ? '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}'
        : 'Select';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
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

  bool get _isSummerSession => _selectedSession == 'Summer';

  // For summer: skip step 2 (1 → 3 → 4 → 5)
  int _nextStep(int current) {
    if (_isSummerSession && current == 1) return 3;
    return current + 1;
  }
  int _prevStep(int current) {
    if (_isSummerSession && current == 3) return 1;
    return current - 1;
  }

  Widget _buildStep1() {
    List<String> years = ['1st', '2nd'];
    if (_selectedDegree == 'B.Tech') {
      years.addAll(['3rd', '4th']);
    }

    List<String> semesters = [];
    if (_selectedCourseYear == '1st')
      semesters = ['1', '2'];
    else if (_selectedCourseYear == '2nd')
      semesters = ['3', '4'];
    else if (_selectedCourseYear == '3rd')
      semesters = ['5', '6'];
    else if (_selectedCourseYear == '4th') semesters = ['7', '8'];

    // Validation: if current selection is invalid, reset it
    if (!years.contains(_selectedCourseYear)) {
      _selectedCourseYear = years.first;
    }
    if (!semesters.contains(_selectedSemester)) {
      _selectedSemester = semesters.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('COURSE INFORMATION', isFirst: true),
        _buildTextFieldPlain(_courseNameController, 'Course Name'),
        const SizedBox(height: 16),
        if (!_isSummerSession) ...[
          _buildTextFieldPlain(_courseCodeController, 'Course Code'),
          const SizedBox(height: 16),
        ],

        // Session selector (moved up so Summer can hide other fields)
        if (_isSummerSession) ...[
          _buildDropdownField(
              'Session',
              _selectedSession,
              ['Autumn', 'Spring', 'Summer'],
              (val) => setState(() {
                    _selectedSession = val;
                    if (val == 'Summer') {
                      _selectedBranches.clear();
                      _selectedBranches.add('Summer Intern');
                    } else {
                      _selectedBranches.remove('Summer Intern');
                    }
                  })),
          const SizedBox(height: 20),
          // Date range picker for summer courses
          _buildSectionHeader('COURSE DURATION'),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  'Start Date',
                  _summerStartDate,
                  () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _summerStartDate ?? DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027, 12, 31),
                    );
                    if (picked != null) {
                      setState(() {
                        _summerStartDate = picked;
                        if (_summerEndDate == null || _summerEndDate!.isBefore(picked)) {
                          _summerEndDate = picked.add(const Duration(days: 30));
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerField(
                  'End Date',
                  _summerEndDate,
                  () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _summerEndDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: _summerStartDate ?? DateTime(2025),
                      lastDate: DateTime(2027, 12, 31),
                    );
                    if (picked != null) {
                      setState(() => _summerEndDate = picked);
                    }
                  },
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
                    _selectedCredits,
                    ['1', '2', '3', '4'],
                    (val) => setState(() => _selectedCredits = val)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                    'Session',
                    _selectedSession,
                    ['Autumn', 'Spring', 'Summer'],
                    (val) => setState(() {
                          _selectedSession = val;
                          if (val == 'Summer') {
                            _selectedBranches.clear();
                            _selectedBranches.add('Summer Intern');
                          } else {
                            _selectedBranches.remove('Summer Intern');
                          }
                        })),
              ),
            ],
          ),
        ],

        // Hide Degree/Year/Semester for Summer session
        if (!_isSummerSession) ...[
          const SizedBox(height: 16),
          _buildDropdownField(
              'Degree',
              _selectedDegree,
              ['B.Tech', 'M.Tech'],
              (val) => setState(() {
                    _selectedDegree = val;
                    if (val == 'M.Tech' &&
                        (_selectedCourseYear == '3rd' ||
                            _selectedCourseYear == '4th')) {
                      _selectedCourseYear = '1st';
                      _selectedSemester = '1';
                    }
                  })),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                    'Year',
                    _selectedCourseYear,
                    years,
                    (val) => setState(() {
                          _selectedCourseYear = val;
                          if (val == '1st')
                            _selectedSemester = '1';
                          else if (val == '2nd')
                            _selectedSemester = '3';
                          else if (val == '3rd')
                            _selectedSemester = '5';
                          else if (val == '4th') _selectedSemester = '7';
                        })),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField('Semester', _selectedSemester,
                    semesters, (val) => setState(() => _selectedSemester = val)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    // For summer session, branch is auto-set to 'Summer Intern'
    if (_isSummerSession) {
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                        ),
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
          children: _branchesList.map((branch) {
            final isSelected = _selectedBranches.contains(branch);
            return FilterChip(
              label: Text(branch),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedBranches.add(branch);
                  } else {
                    _selectedBranches.remove(branch);
                  }
                });
              },
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
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    if (_activeBranchForSlots == null && _selectedBranches.isNotEmpty) {
      _activeBranchForSlots = _selectedBranches.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ASSIGN SLOTS', isFirst: true),
        if (_selectedBranches.length > 1) ...[
          const Text(
            'Select a branch to set its timetable:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _selectedBranches.map((branch) {
                final isSelected = _activeBranchForSlots == branch;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(branch),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected)
                        setState(() => _activeBranchForSlots = branch);
                    },
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
        _buildTimeSlotSelector(),
      ],
    );
  }

  Widget _buildStep4() {
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
        if (_isSummerSession) ...[
          _buildSummaryRow(LucideIcons.book, 'Course',
              _courseNameController.text),
          _buildSummaryRow(LucideIcons.calendar, 'Term', 'Summer 2026'),
          _buildSummaryRow(LucideIcons.clock, 'Slots',
              '${_selectedSlots.length} Slots Selected'),
        ] else ...[
          _buildSummaryRow(LucideIcons.book, 'Course',
              '${_courseNameController.text} (${_courseCodeController.text})'),
          _buildSummaryRow(LucideIcons.graduationCap, 'Branches',
              '${_selectedBranches.join(', ')} - Year $_selectedCourseYear'),
          _buildSummaryRow(LucideIcons.calendar, 'Term',
              'Sem $_selectedSemester, $_selectedSession $_selectedAcademicYear'),
          _buildSummaryRow(LucideIcons.clock, 'Slots',
              '${_selectedSlots.length} Slots Selected'),
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

            // 1. Check if booked in existing courses (from backend)
            // For summer courses, only check against other summer courses
            final coursesToCheck = _isSummerSession
                ? _existingCourses.where((c) => c.session == 'Summer').toList()
                : _existingCourses;
            final bookedCourse = coursesToCheck.cast<Course?>().firstWhere(
                  (c) => c!.timetable
                      .any((t) => t.day == _selectedDay && t.time == time),
                  orElse: () => null,
                );
            final isBookedInDB = bookedCourse != null;

            // 2. Check if assigned to another branch in THIS subject creation
            final otherBranchesWithThisSlot = _selectedSlots
                .where((s) =>
                    s.day == _selectedDay &&
                    s.time == time &&
                    s.branch != _activeBranchForSlots)
                .map((s) => s.branch)
                .toList();
            final isAssignedToOther = otherBranchesWithThisSlot.isNotEmpty;

            final exists = _selectedSlots.any((s) =>
                s.day == _selectedDay &&
                s.time == time &&
                s.branch == _activeBranchForSlots);

            final currentSlot = exists
                ? _selectedSlots.firstWhere((s) =>
                    s.day == _selectedDay &&
                    s.time == time &&
                    s.branch == _activeBranchForSlots)
                : null;

            return GestureDetector(
              onTap: isBookedInDB
                  ? null // Disable tap if already booked by another course
                  : () => _handleSlotClick(_selectedDay, time),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isBookedInDB
                      ? const Color(0xFFF1F5F9)
                      : (exists
                          ? (currentSlot?.type == 'theory'
                              ? const Color(0xFF2563EB).withOpacity(0.1)
                              : const Color(0xFF7C3AED).withOpacity(0.1))
                          : (isAssignedToOther
                              ? const Color(0xFFF1F5F9)
                              : Colors.white)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isBookedInDB
                        ? const Color(0xFFE2E8F0)
                        : (exists
                            ? (currentSlot?.type == 'theory'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF7C3AED))
                            : (isAssignedToOther
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFE2E8F0))),
                    width: exists || isBookedInDB ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBookedInDB
                          ? LucideIcons.lock
                          : (exists
                              ? LucideIcons.checkCircle2
                              : (isAssignedToOther
                                  ? LucideIcons.info
                                  : LucideIcons.circle)),
                      size: 16,
                      color: isBookedInDB
                          ? const Color(0xFF94A3B8)
                          : (exists
                              ? (currentSlot?.type == 'theory'
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF7C3AED))
                              : (isAssignedToOther
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFFCBD5E1))),
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
                              fontWeight: (exists || isBookedInDB)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isBookedInDB
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (isBookedInDB)
                            Text(
                              'BOOKED (${bookedCourse.code})',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          else if (exists)
                            Text(
                              currentSlot?.type.toUpperCase() ?? '',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: currentSlot?.type == 'theory'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF7C3AED),
                              ),
                            )
                          else if (isAssignedToOther)
                            Text(
                              'ASSIGNED (${otherBranchesWithThisSlot.join(', ')})',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
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

  Widget _buildStep5() {
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
        const Text('The class(es) have been successfully created.',
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
                if (_currentStep > 1 && _currentStep < 5)
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft),
                    onPressed: _isCreating
                        ? null
                        : () => setState(() => _currentStep = _prevStep(_currentStep)),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Add New Class',
                          style: FacultyTextStyles.h2.copyWith(fontSize: 20)),
                      if (_currentStep < 5)
                        Builder(builder: (context) {
                          String stepLabel;
                          int stepNum;
                          int totalSteps;
                          if (_isSummerSession) {
                            totalSteps = 3;
                            if (_currentStep == 1) { stepNum = 1; stepLabel = 'INFO'; }
                            else if (_currentStep == 3) { stepNum = 2; stepLabel = 'SLOTS'; }
                            else { stepNum = 3; stepLabel = 'REVIEW'; }
                          } else {
                            totalSteps = 4;
                            stepNum = _currentStep;
                            stepLabel = _currentStep == 1 ? 'INFO' : (_currentStep == 2 ? 'BRANCHES' : (_currentStep == 3 ? 'SLOTS' : 'REVIEW'));
                          }
                          return Text(
                            'STEP $stepNum OF $totalSteps: $stepLabel',
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        }),
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
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentStep == 1) _buildStep1(),
                    if (_currentStep == 2) _buildStep2(),
                    if (_currentStep == 3) _buildStep3(),
                    if (_currentStep == 4) _buildStep4(),
                    if (_currentStep == 5) _buildStep5(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_currentStep > 1 && _currentStep < 5)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _isCreating
                          ? null
                          : () => setState(() => _currentStep = _prevStep(_currentStep)),
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
                if (_currentStep > 1 && _currentStep < 5)
                  const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isCreating
                        ? null
                        : () {
                            if (_currentStep < 4) {
                              if (_currentStep == 1) {
                                if (_courseNameController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter a course name')));
                                  return;
                                }
                                if (!_isSummerSession &&
                                    _courseCodeController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter a course code')));
                                  return;
                                }
                              } else if (_currentStep == 2) {
                                if (_selectedBranches.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please select at least one branch')));
                                  return;
                                }
                              } else if (_currentStep == 3) {
                                if (_selectedSlots.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please assign at least one slot')));
                                  return;
                                }
                              }
                              setState(() => _currentStep = _nextStep(_currentStep));
                            } else if (_currentStep == 4) {
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
                        : Text(_currentStep < 4
                            ? 'Next'
                            : (_currentStep == 4 ? 'Create Class' : 'Done')),
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
