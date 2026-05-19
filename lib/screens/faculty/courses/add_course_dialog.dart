import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../models/faculty/faculty_models.dart';
import 'steps/course_wizard_state.dart';
import 'steps/step1_course_info.dart';
import 'steps/step2_branch_selector.dart';
import 'steps/step3_timetable_picker.dart';
import 'steps/step4_review_card.dart';
import 'steps/step5_success.dart';

/// Multi-step dialog for creating or editing a course.
/// Steps: 1 Info → 2 Branches → 3 Timetable → 4 Review → 5 Success
/// Summer courses skip step 2 (branches are auto-set).
class AddCourseDialog extends StatefulWidget {
  final Course? editCourse;
  const AddCourseDialog({super.key, this.editCourse});

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final FacultyApiService _apiService = FacultyApiService();

  // ─── Step navigation ──────────────────────────────────────────────────────
  /// 1=Info, 2=Branches, 3=Timetable, 4=Review, 5=Success
  int _currentStep = 1;
  String _reviewTab = 'summary';
  bool _isCreating = false;

  // ─── Step 1 state ─────────────────────────────────────────────────────────
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  String? _selectedDegree = 'B.Tech';
  String? _selectedCourseYear = '1st';
  String? _selectedSemester = '1';
  String? _selectedCredits = '4';
  String? _selectedSession = 'Autumn';
  DateTime? _summerStartDate;
  DateTime? _summerEndDate;

  // ─── Step 2 state ─────────────────────────────────────────────────────────
  final List<String> _selectedBranches = [];

  // ─── Step 3 state ─────────────────────────────────────────────────────────
  final List<BranchTimeSlot> _selectedSlots = [];
  String _currentTypeMode = 'theory';
  String _selectedDay = 'Monday';
  String? _activeBranchForSlots;
  List<Course> _existingCourses = [];

  // ─── Step 5 state ─────────────────────────────────────────────────────────
  List<dynamic> _results = [];

  // ─── Derived ──────────────────────────────────────────────────────────────
  bool get _isSummerSession => _selectedSession == 'Summer';

  String get _academicYear {
    final now = DateTime.now();
    final year = now.month < 7 ? now.year - 1 : now.year;
    return '$year-${(year + 1).toString().substring(2)}';
  }

  int _nextStep(int s) => (_isSummerSession && s == 1) ? 3 : s + 1;
  int _prevStep(int s) => (_isSummerSession && s == 3) ? 1 : s - 1;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _populateEditFields();
    _loadExistingCourses();
  }

  void _populateEditFields() {
    final c = widget.editCourse;
    if (c == null) return;
    _courseNameController.text = c.name;
    _courseCodeController.text = c.code;
    _selectedDegree = c.degree ?? 'B.Tech';
    _selectedSemester = c.semester ?? '1';
    _selectedCredits = c.credits.toString();
    _selectedSession = c.session ?? 'Autumn';
    if (c.department.isNotEmpty) _selectedBranches.add(c.department);
    for (final slot in c.timetable) {
      _selectedSlots.add(BranchTimeSlot(
        day: slot.day,
        time: slot.time,
        type: slot.type,
        branch: c.department,
      ));
    }
  }

  Future<void> _loadExistingCourses() async {
    try {
      final courses = await _apiService.listCourses();
      if (mounted) setState(() => _existingCourses = courses);
    } catch (e) {
      // Non-critical — existing courses are only used for conflict highlighting in
      // the timetable picker. If the fetch fails the user can still create a course;
      // they just won't see the conflict overlay. Log so it's visible in debug.
      debugPrint('AddCourseDialog: _loadExistingCourses failed (non-critical): $e');
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  // ─── Slot toggle ──────────────────────────────────────────────────────────

  void _handleSlotClick(String day, String time) {
    setState(() {
      final idx = _selectedSlots.indexWhere(
          (s) => s.day == day && s.time == time && s.branch == _activeBranchForSlots);
      if (idx != -1) {
        if (_selectedSlots[idx].type != _currentTypeMode) {
          _selectedSlots[idx] = BranchTimeSlot(
              day: day, time: time, type: _currentTypeMode, branch: _activeBranchForSlots!);
        } else {
          _selectedSlots.removeAt(idx);
        }
      } else {
        _selectedSlots.add(BranchTimeSlot(
            day: day, time: time, type: _currentTypeMode, branch: _activeBranchForSlots!));
      }
    });
  }

  // ─── Submission ───────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one time slot')));
      return;
    }

    setState(() => _isCreating = true);
    final List<dynamic> newResults = [];

    try {
      for (final branch in _selectedBranches) {
        final branchSlots = _selectedSlots
            .where((s) => s.branch == branch)
            .map((s) => {'day': s.day, 'time': s.time, 'type': s.type, 'room': null})
            .toList();
        if (branchSlots.isEmpty) continue;

        final payload = _isSummerSession
            ? {
                'courseName': _courseNameController.text,
                'courseCode':
                    'SUM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                'branch': branch,
                'degree': 'Summer',
                'year': 'N/A',
                'academicYear': _academicYear,
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
                'academicYear': _academicYear,
                'semester': _selectedSemester ?? '1',
                'credits': int.tryParse(_selectedCredits ?? '4') ?? 4,
                'session': _selectedSession ?? 'Autumn',
                'timetable': branchSlots,
              };

        final Map<String, dynamic> res;
        if (widget.editCourse != null) {
          res = await _apiService.updateCourseSchedule(
              courseId: widget.editCourse!.id, payload: payload);
        } else {
          res = await _apiService.createFullClass(payload);
        }

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
          if (widget.editCourse != null) break;
        }
      }

      if (newResults.isNotEmpty) {
        setState(() {
          _results = newResults;
          _currentStep = 5;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No changes were saved. Check branches and timetable.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // ─── Step validation ──────────────────────────────────────────────────────

  bool _validateCurrentStep() {
    if (_currentStep == 1) {
      if (_courseNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a course name')));
        return false;
      }
      if (!_isSummerSession && _courseCodeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a course code')));
        return false;
      }
    } else if (_currentStep == 2 && _selectedBranches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one branch')));
      return false;
    } else if (_currentStep == 3 && _selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please assign at least one slot')));
      return false;
    }
    return true;
  }

  void _onNextPressed() {
    if (_currentStep < 4) {
      if (!_validateCurrentStep()) return;
      // Ensure activeBranch is set when entering step 3
      if (_nextStep(_currentStep) == 3 && _activeBranchForSlots == null && _selectedBranches.isNotEmpty) {
        _activeBranchForSlots = _selectedBranches.first;
      }
      setState(() => _currentStep = _nextStep(_currentStep));
    } else if (_currentStep == 4) {
      _handleSubmit();
    } else {
      Navigator.pop(context);
    }
  }

  // ─── Step label helper ────────────────────────────────────────────────────

  String _stepLabel() {
    if (_isSummerSession) {
      if (_currentStep == 1) return 'STEP 1 OF 3: INFO';
      if (_currentStep == 3) return 'STEP 2 OF 3: SLOTS';
      return 'STEP 3 OF 3: REVIEW';
    }
    const labels = {1: 'INFO', 2: 'BRANCHES', 3: 'SLOTS', 4: 'REVIEW'};
    return 'STEP $_currentStep OF 4: ${labels[_currentStep] ?? ''}';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
            _buildHeader(),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
              Text(
                widget.editCourse != null ? 'Edit Class Schedule' : 'Add New Class',
                style: FacultyTextStyles.h2.copyWith(fontSize: 20),
              ),
              if (_currentStep < 5)
                Text(
                  _stepLabel(),
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
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStep == 1)
            Step1CourseInfo(
              courseNameController: _courseNameController,
              courseCodeController: _courseCodeController,
              selectedDegree: _selectedDegree,
              selectedCourseYear: _selectedCourseYear,
              selectedSemester: _selectedSemester,
              selectedCredits: _selectedCredits,
              selectedSession: _selectedSession,
              summerStartDate: _summerStartDate,
              summerEndDate: _summerEndDate,
              onDegreeChanged: (v) => setState(() {
                _selectedDegree = v;
                if (v == 'M.Tech' &&
                    (_selectedCourseYear == '3rd' || _selectedCourseYear == '4th')) {
                  _selectedCourseYear = '1st';
                  _selectedSemester = '1';
                }
              }),
              onYearChanged: (v) => setState(() {
                _selectedCourseYear = v;
                if (v == '1st') _selectedSemester = '1';
                else if (v == '2nd') _selectedSemester = '3';
                else if (v == '3rd') _selectedSemester = '5';
                else if (v == '4th') _selectedSemester = '7';
              }),
              onSemesterChanged: (v) => setState(() => _selectedSemester = v),
              onCreditsChanged: (v) => setState(() => _selectedCredits = v),
              onSessionChanged: (v) => setState(() {
                _selectedSession = v;
                if (v == 'Summer') {
                  _selectedBranches.clear();
                  _selectedBranches.add('Summer Intern');
                } else {
                  _selectedBranches.remove('Summer Intern');
                }
              }),
              onSummerStartChanged: (d) => setState(() {
                _summerStartDate = d;
                if (d != null &&
                    (_summerEndDate == null || _summerEndDate!.isBefore(d))) {
                  _summerEndDate = d.add(const Duration(days: 30));
                }
              }),
              onSummerEndChanged: (d) => setState(() => _summerEndDate = d),
            ),

          if (_currentStep == 2)
            Step2BranchSelector(
              selectedBranches: _selectedBranches,
              isSummerSession: _isSummerSession,
              onToggleBranch: (branch) => setState(() {
                if (_selectedBranches.contains(branch)) {
                  _selectedBranches.remove(branch);
                } else {
                  _selectedBranches.add(branch);
                }
              }),
            ),

          if (_currentStep == 3)
            Step3TimetablePicker(
              selectedBranches: _selectedBranches,
              selectedSlots: _selectedSlots,
              currentTypeMode: _currentTypeMode,
              selectedDay: _selectedDay,
              activeBranch: _activeBranchForSlots,
              existingCourses: _existingCourses,
              isSummerSession: _isSummerSession,
              onDayChanged: (d) => setState(() => _selectedDay = d),
              onTypeModeChanged: (t) => setState(() => _currentTypeMode = t),
              onActiveBranchChanged: (b) => setState(() => _activeBranchForSlots = b),
              onSlotTap: _handleSlotClick,
            ),

          if (_currentStep == 4)
            Step4ReviewCard(
              courseName: _courseNameController.text,
              courseCode: _courseCodeController.text,
              selectedBranches: _selectedBranches,
              selectedCourseYear: _selectedCourseYear,
              selectedSemester: _selectedSemester,
              selectedSession: _selectedSession,
              academicYear: _academicYear,
              selectedSlots: _selectedSlots,
              isSummerSession: _isSummerSession,
              reviewTab: _reviewTab,
              onTabChanged: (t) => setState(() => _reviewTab = t),
            ),

          if (_currentStep == 5)
            Step5Success(
              results: _results,
              isEditMode: widget.editCourse != null,
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (_currentStep > 1 && _currentStep < 5) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _isCreating
                  ? null
                  : () => setState(() => _currentStep = _prevStep(_currentStep)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: const Text('Back', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isCreating ? null : _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
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
    );
  }
}
