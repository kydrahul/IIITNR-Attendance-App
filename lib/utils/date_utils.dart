/// Shared date/ordinal formatting utilities.
///
/// Centralises logic that was previously duplicated across:
/// - `courses_tab.dart` (_CourseCard._getOrdinal)
/// - `overview_tab.dart` (static _ordinal, static _month)
/// - `attendance_tab.dart` (static _month)
/// - `student_stats_screen.dart` (_formatDate)
/// - `intern_profile_setup_screen.dart` (_formatDate)
library date_utils;

/// Returns the abbreviated month name for a 1-based month index (1 = Jan).
///
/// ```dart
/// monthAbbr(3) // 'Mar'
/// ```
String monthAbbr(int month) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][month - 1];

/// Formats a [DateTime] as `'DD Mon YYYY'` (e.g. `'05 Jun 2025'`).
///
/// Returns `'Select date'` when [date] is null.
String formatDateDMY(DateTime? date) {
  if (date == null) return 'Select date';
  return '${date.day.toString().padLeft(2, '0')} ${monthAbbr(date.month)} ${date.year}';
}

/// Formats a [DateTime] as `'D Mon, YYYY'` (e.g. `'5 Jun, 2025'`).
///
/// Used in session history lists.
String formatDateShort(DateTime date) =>
    '${date.day} ${monthAbbr(date.month)}, ${date.year}';

/// Converts a 12/24-h [DateTime] to a human-readable `'H:MM AM/PM'` string.
String formatTime(DateTime dt) {
  final h = dt.hour > 12
      ? dt.hour - 12
      : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
}

/// Returns the ordinal string for a semester number string.
///
/// ```dart
/// semesterOrdinal('3') // '3rd'
/// semesterOrdinal('N/A') // 'N/A'
/// ```
String semesterOrdinal(String? n) {
  if (n == null || n == 'N/A' || n.isEmpty) return n ?? 'N/A';
  final i = int.tryParse(n);
  if (i == null) return n;
  if (i % 100 >= 11 && i % 100 <= 13) return '${i}th';
  switch (i % 10) {
    case 1: return '${i}st';
    case 2: return '${i}nd';
    case 3: return '${i}rd';
    default: return '${i}th';
  }
}
