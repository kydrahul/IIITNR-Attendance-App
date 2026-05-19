import 'package:flutter/material.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../models/faculty/faculty_models.dart';

/// An Autocomplete-based search field that lets faculty pick a course from their
/// list. Shows department, semester, and name in both the field and the dropdown.
class CourseSelector extends StatelessWidget {
  final Course? selectedCourse;
  final List<Course> courses;
  final ValueChanged<Course?> onCourseChanged;
  final VoidCallback onClear;

  const CourseSelector({
    super.key,
    required this.selectedCourse,
    required this.courses,
    required this.onCourseChanged,
    required this.onClear,
  });

  static String _displayText(Course c) => [
        if (c.department.isNotEmpty) c.department,
        if (c.semester != null && c.semester!.isNotEmpty) 'Sem ${c.semester}',
        c.name,
      ].join(' - ');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Course>(
          key: ValueKey(selectedCourse?.id),
          initialValue: selectedCourse != null
              ? TextEditingValue(text: _displayText(selectedCourse!))
              : TextEditingValue.empty,
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return courses;
            final q = value.text.toLowerCase();
            return courses.where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.code.toLowerCase().contains(q));
          },
          displayStringForOption: _displayText,
          onSelected: onCourseChanged,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            // Sync controller text with external selection state
            if (selectedCourse == null &&
                controller.text.isNotEmpty &&
                !focusNode.hasFocus) {
              controller.text = '';
            } else if (selectedCourse != null && !focusNode.hasFocus) {
              final expected = _displayText(selectedCourse!);
              if (controller.text != expected) controller.text = expected;
            }

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onFieldSubmitted: (_) => onSubmitted(),
              decoration: InputDecoration(
                hintText: 'Search for a course...',
                hintStyle: FacultyTextStyles.bodyMedium
                    .copyWith(color: FacultyColors.gray400),
                prefixIcon: const Icon(Icons.search,
                    color: FacultyColors.gray400, size: 20),
                suffixIcon: (selectedCourse != null ||
                        controller.text.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: FacultyColors.gray500,
                        onPressed: () {
                          controller.clear();
                          onClear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: FacultyColors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FacultyColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FacultyColors.primary),
                ),
              ),
              style: FacultyTextStyles.bodyMedium
                  .copyWith(color: FacultyColors.gray900, fontSize: 16),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  color: FacultyColors.white,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: 300,
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: FacultyColors.gray100),
                      itemBuilder: (context, index) {
                        final Course option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dept + Semester (bold header)
                                Text(
                                  [
                                    if (option.department.isNotEmpty)
                                      option.department,
                                    if (option.semester != null &&
                                        option.semester!.isNotEmpty)
                                      'Semester ${option.semester}'
                                  ].join(' - '),
                                  style: FacultyTextStyles.bodyMedium.copyWith(
                                      color: FacultyColors.gray900,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                // Academic year + session
                                Text(
                                  [
                                    if (option.academicYear.isNotEmpty)
                                      option.academicYear,
                                    if (option.session != null &&
                                        option.session!.isNotEmpty)
                                      option.session!
                                  ].join(' - '),
                                  style: FacultyTextStyles.bodySmall
                                      .copyWith(color: FacultyColors.gray500),
                                ),
                                const SizedBox(height: 2),
                                // Course name
                                Text(
                                  option.name,
                                  style: FacultyTextStyles.bodySmall
                                      .copyWith(color: FacultyColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
