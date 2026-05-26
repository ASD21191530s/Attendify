import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'attendance_history_page.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: (barcodeCapture) async {
          if (_isProcessing) return;
          _isProcessing = true;

          final String? sessionId =
              barcodeCapture.barcodes.first.rawValue;

          if (sessionId == null) {
            _isProcessing = false;
            return;
          }

          final uid = FirebaseAuth.instance.currentUser!.uid;

          final userRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

          final recordRef = FirebaseFirestore.instance
              .collection('attendance')
              .doc(uid)
              .collection('records')
              .doc(sessionId);

          final recordSnap = await recordRef.get();

          if (recordSnap.exists) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Attendance already marked")),
            );
            _isProcessing = false;
            return;
          }

          try {
            await FirebaseFirestore.instance.runTransaction((tx) async {
              final sessionDoc = await tx.get(
                FirebaseFirestore.instance
                    .collection('sessions')
                    .doc(sessionId),
              );

              if (!sessionDoc.exists) {
                throw Exception("Invalid session");
              }

              final data = sessionDoc.data() as Map<String, dynamic>;

              // ⭐ SAFE subject fetch
              final subject =
              data.containsKey('subject') ? data['subject'] : "General";

              tx.set(recordRef, {
                'sessionId': sessionId,
                'subject': subject,
                'time': FieldValue.serverTimestamp(),
              });

              // ONLY increase attendedClasses
              tx.update(userRef, {
                'attendedClasses': FieldValue.increment(1),
              });
            });

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceHistoryPage(),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }

          _isProcessing = false;
        },
      ),
    );
  }
}