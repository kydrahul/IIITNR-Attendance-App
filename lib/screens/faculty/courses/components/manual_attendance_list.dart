import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../providers/live_session_provider.dart';

class ManualAttendanceList extends StatefulWidget {
  const ManualAttendanceList({super.key});

  @override
  State<ManualAttendanceList> createState() => _ManualAttendanceListState();
}

class _ManualAttendanceListState extends State<ManualAttendanceList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    int presentCount = provider.students.where((s) => s['isPresent']).length;
    int absentCount = provider.students.where((s) => !s['isPresent']).length;
    bool isPresentTab = _tabController.index == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: FacultyColors.gray200, height: 32),
        Text('Manual Attendance',
            style: FacultyTextStyles.h3.copyWith(color: FacultyColors.black)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: FacultyColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FacultyColors.gray200),
          ),
          child: TextField(
            onChanged: (value) {
              context.read<LiveSessionProvider>().setSearchQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search by name or roll number...',
              hintStyle: FacultyTextStyles.bodyMedium
                  .copyWith(color: FacultyColors.gray400),
              prefixIcon: const Icon(LucideIcons.search,
                  color: FacultyColors.gray400, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: FacultyTextStyles.bodyMedium
                .copyWith(color: FacultyColors.gray800),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4),
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
                      color: isPresentTab
                          ? FacultyColors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isPresentTab
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text('Present ($presentCount)',
                        style: FacultyTextStyles.bodyLarge.copyWith(
                            color: isPresentTab
                                ? FacultyColors.primary
                                : FacultyColors.gray500,
                            fontWeight: isPresentTab
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
                      color: !isPresentTab
                          ? FacultyColors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !isPresentTab
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text('Absent ($absentCount)',
                        style: FacultyTextStyles.bodyLarge.copyWith(
                            color: !isPresentTab
                                ? FacultyColors.primary
                                : FacultyColors.gray500,
                            fontWeight: !isPresentTab
                                ? FontWeight.bold
                                : FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildStudentList(provider, isPresentTab),
      ],
    );
  }

  Widget _buildStudentList(LiveSessionProvider provider, bool isPresentTab) {
    List<Map<String, dynamic>> tabStudents =
        provider.students.where((s) => s['isPresent'] == isPresentTab).toList();

    if (provider.searchQuery.isNotEmpty) {
      tabStudents = tabStudents
          .where((s) =>
              s['name'].toLowerCase().contains(provider.searchQuery.toLowerCase()) ||
              s['rollNo'].toLowerCase().contains(provider.searchQuery.toLowerCase()))
          .toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: tabStudents.length,
      itemBuilder: (context, index) {
        final student = tabStudents[index];
        final String name = student['name'];
        final String rollNo = student['rollNo'];
        final bool isEdited = student['isEdited'] ?? false;
        final String markedTime = student['markedTime'] ?? '';
        final bool isExpanded = provider.expandedStudentRollNo == rollNo;

        return Column(
          children: [
            InkWell(
              onTap: () {
                provider.toggleExpandedStudent(rollNo);
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
                      flex: 3, // Give more weight to name/roll section
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: FacultyTextStyles.bodyMedium.copyWith(
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
                      flex: 2, // Allow status/time section to be flexible
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
                          onTap: () async {
                            try {
                              await provider.updateAttendance(student, true);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                              }
                            }
                          },
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
                          onTap: () async {
                            try {
                              await provider.updateAttendance(student, false);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                              }
                            }
                          },
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
