import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> generateAttendanceReport({
    required String courseName,
    required String courseCode,
    required String facultyName,
    required List<dynamic> students,
    required int totalSessions,
    String filterType = 'All', // 'All', 'Below 75%', 'Custom'
    double? customPercentage,
  }) async {
    List<dynamic> filteredStudents = students;

    if (filterType == 'Below 75%') {
      filteredStudents = students.where((s) {
        final perc = s['attendancePercentage'] ?? 0;
        return perc < 75.0;
      }).toList();
    } else if (filterType == 'Custom' && customPercentage != null) {
      filteredStudents = students.where((s) {
        final perc = s['attendancePercentage'] ?? 0;
        return perc < customPercentage;
      }).toList();
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Attendance Report',
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(courseName,
                          style: pw.TextStyle(
                              fontSize: 18, color: PdfColors.grey700)),
                      pw.Text('Course Code: $courseCode',
                          style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text('Filter: $filterType ${customPercentage != null ? '(< $customPercentage%)' : ''}',
                          style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                          style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text('Faculty: $facultyName',
                          style: const pw.TextStyle(color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: ['Roll No', 'Name', 'Attended', 'Total', '%'],
              data: filteredStudents.map((s) {
                final attended = s['attendedCount'] ?? (s['present'] == true ? 1 : 0);
                final perc = s['attendancePercentage'] ?? 0;
                return [
                  s['rollNumber'] ?? s['rollNo'] ?? 'N/A',
                  s['name'] ?? 'Unknown',
                  attended.toString(),
                  totalSessions.toString(),
                  '${perc.toStringAsFixed(1)}%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 24),
            pw.Footer(
              padding: const pw.EdgeInsets.only(top: 16),
              trailing: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
            ),
          ];
        },
      ),
    );

    final String fileName = "${courseName}_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf"
        .replaceAll(' ', '_');
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }
}
