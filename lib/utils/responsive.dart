import 'package:flutter/material.dart';

/// A lightweight responsive-sizing utility.
///
/// Reference design is 375 × 812 (iPhone 13 logical pixels).
/// Call [Responsive.init] once in [build] (or use the static helpers that
/// read from [MediaQuery] directly).
///
/// Usage:
///   Text('Hello', style: TextStyle(fontSize: Responsive.sp(16)))
///   SizedBox(height: Responsive.h(24))
///   Padding(padding: EdgeInsets.all(Responsive.w(16)))
class Responsive {
  Responsive._();

  static const double _refWidth = 375.0;
  static const double _refHeight = 812.0;

  // ── Width-based scalar (horizontal spacing, padding, widths) ──
  static double w(double size, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / _refWidth);
  }

  // ── Height-based scalar (vertical spacing, heights) ──
  static double h(double size, BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return size * (screenHeight / _refHeight);
  }

  // ── Font scalar (uses width axis, clamped to avoid extremes) ──
  static double sp(double size, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / _refWidth;
    // Clamp between 0.85× and 1.2× to keep text readable on all screens.
    return size * scale.clamp(0.85, 1.2);
  }

  // ── Responsive padding helpers ──
  static EdgeInsets symPadding(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: w(horizontal, context),
      vertical: h(vertical, context),
    );
  }

  static EdgeInsets allPadding(BuildContext context, double value) {
    return EdgeInsets.symmetric(
      horizontal: w(value, context),
      vertical: h(value, context),
    );
  }

  // ── Convenience: is this a small screen? (< 360 dp wide) ──
  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  // ── Convenience: safe horizontal padding (shrinks on small screens) ──
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 16.0;
    if (width < 400) return 20.0;
    return 24.0;
  }

  // ── Screen fractions ──
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
}
