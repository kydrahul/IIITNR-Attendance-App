import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../providers/live_session_provider.dart';
import 'components/session_setup_form.dart';
import 'components/active_session_card.dart';
import 'components/session_statistics.dart';
import 'components/manual_attendance_list.dart';

class StartSessionScreen extends StatelessWidget {
  final Map<String, dynamic> course;

  const StartSessionScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LiveSessionProvider(course: course),
      child: const _StartSessionScreenContent(),
    );
  }
}

class _StartSessionScreenContent extends StatelessWidget {
  const _StartSessionScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    final course = provider.course;

    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Attendance',
              style: FacultyTextStyles.h3.copyWith(color: FacultyColors.black),
            ),
            Text(
              '${course['code']} - ${(course['name'] ?? '')}',
              style: FacultyTextStyles.bodySmall.copyWith(
                color: FacultyColors.gray500,
              ),
            ),
          ],
        ),
        backgroundColor: FacultyColors.white,
        foregroundColor: FacultyColors.gray800,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FacultyColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!provider.qrActive && !provider.sessionEnded) const SessionSetupForm(),
            if (provider.qrActive) const ActiveSessionCard(),
            if (provider.sessionEnded) const SessionStatistics(),
            if (provider.qrActive || provider.sessionEnded) ...[
              const SizedBox(height: 32),
              const ManualAttendanceList(),
            ]
          ],
        ),
      ),
    );
  }
}
