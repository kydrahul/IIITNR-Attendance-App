import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/faculty/faculty_models.dart';
import 'course_wizard_state.dart';

/// Step 3 — Timetable slot picker.
/// Supports multi-branch editing and highlights slots booked by existing courses.
class Step3TimetablePicker extends StatelessWidget {
  final List<String> selectedBranches;
  final List<BranchTimeSlot> selectedSlots;
  final String currentTypeMode; // 'theory' | 'lab'
  final String selectedDay;
  final String? activeBranch;
  final List<Course> existingCourses;
  final bool isSummerSession;

  final ValueChanged<String> onDayChanged;
  final ValueChanged<String> onTypeModeChanged;
  final ValueChanged<String> onActiveBranchChanged;
  final void Function(String day, String time) onSlotTap;

  const Step3TimetablePicker({
    super.key,
    required this.selectedBranches,
    required this.selectedSlots,
    required this.currentTypeMode,
    required this.selectedDay,
    required this.activeBranch,
    required this.existingCourses,
    required this.isSummerSession,
    required this.onDayChanged,
    required this.onTypeModeChanged,
    required this.onActiveBranchChanged,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ASSIGN SLOTS', isFirst: true),

        // Branch selector tabs (only shown when multiple branches)
        if (selectedBranches.length > 1) ...[
          const Text(
            'Select a branch to set its timetable:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: selectedBranches.map((branch) {
                final isActive = activeBranch == branch;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(branch),
                    selected: isActive,
                    showCheckmark: false,
                    onSelected: (_) => onActiveBranchChanged(branch),
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Theory / Lab toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTypeButton('theory', 'Theory')),
              Expanded(child: _buildTypeButton('lab', 'Lab')),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildTimeSlotSelector(),
      ],
    );
  }

  Widget _buildTypeButton(String type, String label) {
    final isSelected = currentTypeMode == type;
    return GestureDetector(
      onTap: () => onTypeModeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildTimeSlotSelector() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Day selector row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kWizardDays.take(5).map((day) {
              final isSelected = selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onDayChanged(day),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.white,
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
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      day.substring(0, 3),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
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
            'Tap a slot to assign ${currentTypeMode == "theory" ? "Theory" : "Lab"} mode',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Time slot grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: kWizardTimeSlots.length,
          itemBuilder: (_, index) {
            final time = kWizardTimeSlots[index];
            return _TimeSlotTile(
              time: time,
              day: selectedDay,
              activeBranch: activeBranch,
              selectedSlots: selectedSlots,
              existingCourses: existingCourses,
              isSummerSession: isSummerSession,
              currentTypeMode: currentTypeMode,
              onTap: () => onSlotTap(selectedDay, time),
            );
          },
        ),
      ],
    );
  }
}

/// Individual time-slot tile within the grid.
class _TimeSlotTile extends StatelessWidget {
  final String time;
  final String day;
  final String? activeBranch;
  final List<BranchTimeSlot> selectedSlots;
  final List<Course> existingCourses;
  final bool isSummerSession;
  final String currentTypeMode;
  final VoidCallback onTap;

  const _TimeSlotTile({
    required this.time,
    required this.day,
    required this.activeBranch,
    required this.selectedSlots,
    required this.existingCourses,
    required this.isSummerSession,
    required this.currentTypeMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Booked by an existing course in the backend
    final coursesToCheck = isSummerSession
        ? existingCourses.where((c) => c.session == 'Summer').toList()
        : existingCourses;
    final bookedCourse = coursesToCheck.cast<Course?>().firstWhere(
          (c) => c!.timetable.any((t) => t.day == day && t.time == time),
          orElse: () => null,
        );
    final isBookedInDB = bookedCourse != null;

    // Assigned to a DIFFERENT branch in this wizard session
    final otherBranches = selectedSlots
        .where((s) => s.day == day && s.time == time && s.branch != activeBranch)
        .map((s) => s.branch)
        .toList();
    final isAssignedToOther = otherBranches.isNotEmpty;

    final exists = selectedSlots.any(
        (s) => s.day == day && s.time == time && s.branch == activeBranch);
    final currentSlot = exists
        ? selectedSlots.firstWhere(
            (s) => s.day == day && s.time == time && s.branch == activeBranch)
        : null;

    final Color borderColor = isBookedInDB
        ? const Color(0xFFE2E8F0)
        : (exists
            ? (currentSlot?.type == 'theory'
                ? const Color(0xFF2563EB)
                : const Color(0xFF7C3AED))
            : (isAssignedToOther
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFE2E8F0)));

    final Color bgColor = isBookedInDB
        ? const Color(0xFFF1F5F9)
        : (exists
            ? (currentSlot?.type == 'theory'
                ? const Color(0xFF2563EB).withOpacity(0.1)
                : const Color(0xFF7C3AED).withOpacity(0.1))
            : (isAssignedToOther ? const Color(0xFFF1F5F9) : Colors.white));

    final IconData icon = isBookedInDB
        ? LucideIcons.lock
        : (exists
            ? LucideIcons.checkCircle2
            : (isAssignedToOther ? LucideIcons.info : LucideIcons.circle));

    final Color iconColor = isBookedInDB
        ? const Color(0xFF94A3B8)
        : (exists
            ? (currentSlot?.type == 'theory'
                ? const Color(0xFF2563EB)
                : const Color(0xFF7C3AED))
            : (isAssignedToOther
                ? const Color(0xFF64748B)
                : const Color(0xFFCBD5E1)));

    return GestureDetector(
      onTap: isBookedInDB ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: exists || isBookedInDB ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
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
                      'ASSIGNED (${otherBranches.join(', ')})',
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
  }
}
