import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'faculty_colors.dart';

class FacultyTextStyles {
  static TextStyle get header => GoogleFonts.montserrat(
        fontWeight: FontWeight.w700,
        color: FacultyColors.gray800,
      );

  static TextStyle get body => GoogleFonts.roboto(
        color: FacultyColors.gray700,
      );

  // Specific styles
  static TextStyle get h1 => header.copyWith(fontSize: 24);
  static TextStyle get h2 => header.copyWith(fontSize: 20);
  static TextStyle get h3 => header.copyWith(fontSize: 18);
  static TextStyle get h4 => header.copyWith(fontSize: 16);

  static TextStyle get bodySmall => body.copyWith(fontSize: 12);
  static TextStyle get bodyMedium => body.copyWith(fontSize: 14);
  static TextStyle get bodyLarge => body.copyWith(fontSize: 16);

  static TextStyle get label => GoogleFonts.roboto(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: FacultyColors.gray400,
        letterSpacing: 0.5,
      );
}
