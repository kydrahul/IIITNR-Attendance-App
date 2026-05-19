
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';

class SessionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final String dateStr;
  final String timeStr;
  final int totalStudents;
  final int presentCount;
  final String? sessionId;
  final String? roomNumber;

  const SessionDetailsScreen({
    super.key,
    required this.course,
    required this.dateStr,
    required this.timeStr,
    required this.totalStudents,
    required this.presentCount,
    this.sessionId,
    this.roomNumber,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final List<Map<String, dynamic>> _students = [];
  String? _expandedStudentRollNo;
  bool _isLoading = false;
  String? _errorMessage;
  final FacultyApiService _apiService = FacultyApiService();

  void _updateAttendance(Map<String, dynamic> student, bool isPresent) {
    if (student['isPresent'] != isPresent) {
      setState(() {
        student['isPresent'] = isPresent;
        student['isEdited'] = true;

        final now = DateTime.now();
        String ampm = now.hour >= 12 ? 'PM' : 'AM';
        int hour =
            now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
        String minute = now.minute.toString().padLeft(2, '0');
        student['markedTime'] = '$hour:$minute $ampm';

        _expandedStudentRollNo = null; // collapse after marking
      });
    } else {
      setState(() {
        _expandedStudentRollNo = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSessionAttendance();
  }

  Future<void> _fetchSessionAttendance() async {
    // A null sessionId means this screen was opened without a valid session.
    // We cannot fetch real data, so show an error instead of fake mock data.
    if (widget.sessionId == null) {
      setState(() {
        _errorMessage =
            'No session ID provided. Cannot load attendance data.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First get all course students to have the full list
      final allStudents = await _apiService.listCourseStudents(
        widget.course['id']?.toString() ?? '',
        sessionId: widget.sessionId
      );

      if (mounted) {
        setState(() {
          _students.clear();
          for (var s in allStudents) {
            _students.add({
              'id': s.id,
              'rollNo': s.rollNo,
              'name': s.name,
              'isPresent': s.status?.toLowerCase() == 'present',
              'isEdited': false,
              'markedTime': s.markedAt ?? '',
            });
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get currentPresentCount =>
      _students.where((s) => s['isPresent'] == true).length;
  int get currentAbsentCount => _students.length - currentPresentCount;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: FacultyColors.background,
        appBar: AppBar(backgroundColor: FacultyColors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: FacultyColors.background,
        appBar: AppBar(backgroundColor: FacultyColors.white, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: FacultyColors.red600, size: 48),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage', style: const TextStyle(color: FacultyColors.red600)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchSessionAttendance, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final totalCount = _students.isEmpty ? widget.totalStudents : _students.length;
    final percent = totalCount > 0 ? (currentPresentCount / totalCount) * 100 : 0.0;

    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: AppBar(
        backgroundColor: FacultyColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FacultyColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Session Details',
          style: FacultyTextStyles.h3.copyWith(
            color: FacultyColors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: FacultyColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dateStr,
                          style: FacultyTextStyles.h3.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lecture • ${widget.timeStr} • Room: ${widget.roomNumber ?? 'N/A'}',
                          style: FacultyTextStyles.bodyMedium.copyWith(
                            color: FacultyColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: percent >= 75
                            ? FacultyColors.green50
                            : FacultyColors.red50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percent.toInt()}%',
                        style: FacultyTextStyles.h4.copyWith(
                          color: percent >= 75
                              ? FacultyColors.green700
                              : FacultyColors.red700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildStatCard('Total', totalCount.toString(),
                        FacultyColors.gray800, FacultyColors.gray100),
                    const SizedBox(width: 16),
                    _buildStatCard('Present', currentPresentCount.toString(),
                        FacultyColors.green600, FacultyColors.green50),
                    const SizedBox(width: 16),
                    _buildStatCard('Absent', currentAbsentCount.toString(),
                        FacultyColors.red600, FacultyColors.red50),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Students...',
                    hintStyle: FacultyTextStyles.bodyMedium
                        .copyWith(color: FacultyColors.gray400),
                    prefixIcon: const Icon(LucideIcons.search,
                        size: 20, color: FacultyColors.gray400),
                    filled: true,
                    fillColor: FacultyColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: FacultyColors.gray200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: FacultyColors.gray200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ColoredBox(
            color: FacultyColors.white,
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: FacultyColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FacultyColors.gray200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.index = 0;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? FacultyColors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _tabController.index == 0
                              ? [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text('Present ($currentPresentCount)',
                            style: FacultyTextStyles.bodyLarge.copyWith(
                                color: _tabController.index == 0
                                    ? FacultyColors.primary
                                    : FacultyColors.gray500,
                                fontWeight: _tabController.index == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.index = 1;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? FacultyColors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _tabController.index == 1
                              ? [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text('Absent ($currentAbsentCount)',
                            style: FacultyTextStyles.bodyLarge.copyWith(
                                color: _tabController.index == 1
                                    ? FacultyColors.primary
                                    : FacultyColors.gray500,
                                fontWeight: _tabController.index == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentList(true),
                _buildStudentList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: FacultyTextStyles.h2.copyWith(
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: FacultyTextStyles.bodySmall.copyWith(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(bool isPresentTab) {
    List<Map<String, dynamic>> tabStudents =
        _students.where((s) => s['isPresent'] == isPresentTab).toList();

    if (tabStudents.isEmpty && _searchQuery.isEmpty) {
      return Center(
        child: Text(
          'No students',
          style: FacultyTextStyles.bodyMedium
              .copyWith(color: FacultyColors.gray500),
        ),
      );
    }

    if (_searchQuery.isNotEmpty) {
      tabStudents = tabStudents.where((student) {
        final query = _searchQuery.toLowerCase();
        return student['name'].toString().toLowerCase().contains(query) ||
            student['rollNo'].toString().toLowerCase().contains(query);
      }).toList();
    }

    if (tabStudents.isEmpty) {
      return Center(
        child: Text(
          'No matching students found',
          style: FacultyTextStyles.bodyMedium
              .copyWith(color: FacultyColors.gray500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: tabStudents.length,
      itemBuilder: (context, index) {
        final student = tabStudents[index];
        final String name = student['name'];
        final String rollNo = student['rollNo'];
        final bool isEdited = student['isEdited'] ?? false;
        final String markedTime = student['markedTime'] ?? '';

        final bool isExpanded = _expandedStudentRollNo == rollNo;

        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedStudentRollNo = isExpanded ? null : rollNo;
                });
              },
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
              child: Container(
                margin: EdgeInsets.only(bottom: isExpanded ? 0 : 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FacultyColors.white,
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(12))
                      : BorderRadius.circular(12),
                  border: Border.all(color: FacultyColors.gray100),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: FacultyColors.gray100,
                      radius: 20,
                      child: Text(
                        name[0],
                        style: FacultyTextStyles.h4.copyWith(
                          color: FacultyColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: FacultyTextStyles.bodyLarge.copyWith(
                              color: FacultyColors.gray800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                rollNo,
                                style: FacultyTextStyles.bodySmall.copyWith(
                                  color: FacultyColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isEdited) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: FacultyColors.yellow50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: FacultyColors.yellow200),
                                  ),
                                  child: Text(
                                    'Modified',
                                    style: FacultyTextStyles.label.copyWith(
                                      color: FacultyColors.yellow800,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPresentTab
                                      ? FacultyColors.green50
                                      : FacultyColors.red50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPresentTab ? 'Present' : 'Absent',
                                  style: FacultyTextStyles.bodySmall.copyWith(
                                    color: isPresentTab
                                        ? FacultyColors.green700
                                        : FacultyColors.red700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            markedTime,
                            style: FacultyTextStyles.label.copyWith(
                              color: FacultyColors.gray400,
                              fontSize: 9,
                              letterSpacing: 0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: FacultyColors.gray50,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(
                    left: BorderSide(color: FacultyColors.gray100),
                    right: BorderSide(color: FacultyColors.gray100),
                    bottom: BorderSide(color: FacultyColors.gray100),
                    top: BorderSide.none,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _updateAttendance(student, true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: student['isPresent']
                                  ? FacultyColors.green50
                                  : FacultyColors.white,
                              border: Border.all(
                                color: student['isPresent']
                                    ? FacultyColors.green600
                                    : FacultyColors.gray200,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Present',
                                style: FacultyTextStyles.bodyMedium.copyWith(
                                  color: student['isPresent']
                                      ? FacultyColors.green700
                                      : FacultyColors.gray600,
                                  fontWeight: student['isPresent']
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _updateAttendance(student, false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !student['isPresent']
                                  ? FacultyColors.red50
                                  : FacultyColors.white,
                              border: Border.all(
                                color: !student['isPresent']
                                    ? FacultyColors.red600
                                    : FacultyColors.gray200,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Absent',
                                style: FacultyTextStyles.bodyMedium.copyWith(
                                  color: !student['isPresent']
                                      ? FacultyColors.red700
                                      : FacultyColors.gray600,
                                  fontWeight: !student['isPresent']
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
