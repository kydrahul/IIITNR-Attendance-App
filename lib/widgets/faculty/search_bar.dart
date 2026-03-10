import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';

class FacultySearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  const FacultySearchBar({
    super.key,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
    this.controller,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: FacultyColors.background,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: FacultyColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FacultyColors.gray200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onChanged: onChanged,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: "Search course",
              hintStyle:
                  const TextStyle(color: FacultyColors.gray400, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.search,
                  color: FacultyColors.gray400, size: 20),
              suffixIcon: onClear != null
                  ? IconButton(
                      icon: const Icon(LucideIcons.x,
                          color: FacultyColors.gray400, size: 20),
                      onPressed: onClear,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
