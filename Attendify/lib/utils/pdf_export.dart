import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> exportAttendancePDF() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final email = FirebaseAuth.instance.currentUser!.email ?? "";

  final snapshot = await FirebaseFirestore.instance
      .collection('attendance')
      .doc(uid)
      .collection('records')
      .orderBy('time', descending: true)
      .get();

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Attendance Report",
                style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Text("Student: $email"),
            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: ["Subject", "Date", "Time"],
              data: snapshot.docs.map((doc) {
                final data = doc.data();

                final subject = data['subject'] ?? "Unknown";

                final timestamp = data['time'] as Timestamp?;
                final date = timestamp?.toDate();

                return [
                  subject,
                  date?.toString().split(' ')[0] ?? "",
                  date?.toString().split(' ')[1].substring(0, 5) ?? "",
                ];
              }).toList(),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}