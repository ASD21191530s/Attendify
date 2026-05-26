import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> exportAdminAttendancePDF() async {
  final pdf = pw.Document();

  final users = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'student')
      .get();

  List<List<String>> tableData = [];

  /// Table Header
  tableData.add([
    "Student Email",
    "Subject",
    "Date",
    "Time"
  ]);

  for (var user in users.docs) {
    final uid = user.id;
    final email = user['email'];

    final records = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .orderBy('time')
        .get();

    if (records.docs.isEmpty) {
      tableData.add([email, "No records", "-", "-"]);
      continue;
    }

    for (var r in records.docs) {
      final data = r.data();

      final subject = data['subject'] ?? "General";

      final time = (data['time'] as Timestamp?)?.toDate();

      final dateStr =
      time != null ? "${time.day}-${time.month}-${time.year}" : "-";

      final timeStr =
      time != null ? "${time.hour}:${time.minute}" : "-";

      tableData.add([email, subject, dateStr, timeStr]);
    }
  }

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(
          "Attendance Report",
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),

        /// TABLE DESIGN
        pw.Table.fromTextArray(
          headers: tableData.first,
          data: tableData.sublist(1),

          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white),

          headerDecoration:
          const pw.BoxDecoration(color: PdfColors.blue),

          cellAlignment: pw.Alignment.centerLeft,

          cellPadding: const pw.EdgeInsets.all(6),

          border: pw.TableBorder.all(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}