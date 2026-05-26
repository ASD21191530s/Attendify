import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratePage extends StatefulWidget {
  const QRGeneratePage({super.key});

  @override
  State<QRGeneratePage> createState() => _QRGeneratePageState();
}

class _QRGeneratePageState extends State<QRGeneratePage> {
  bool loading = false;
  String selectedSubject = "DBMS";

  final List<String> subjects = [
    "DBMS",
    "OS",
    "Math",
    "Networks",
    "AI",
  ];

  /// START SESSION
  Future<void> startSession() async {
    setState(() => loading = true);

    final firestore = FirebaseFirestore.instance;

    /// Close previous sessions
    final activeSessions = await firestore
        .collection('sessions')
        .where('active', isEqualTo: true)
        .get();

    for (var doc in activeSessions.docs) {
      await doc.reference.update({'active': false});
    }

    /// Create new session
    final sessionRef = firestore.collection('sessions').doc();

    await sessionRef.set({
      'subject': selectedSubject,
      'timestamp': FieldValue.serverTimestamp(),
      'active': true,
    });

    /// Increment total classes
    final users = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final batch = firestore.batch();

    for (var doc in users.docs) {
      batch.update(doc.reference, {
        'totalClasses': FieldValue.increment(1),
      });
    }

    await batch.commit();

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Session")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          /// NO ACTIVE SESSION
          if (snap.data!.docs.isEmpty) {
            return Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select Subject"),
                  const SizedBox(height: 10),

                  DropdownButton<String>(
                    value: selectedSubject,
                    items: subjects
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedSubject = val!),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label:
                    const Text("Start Attendance Session"),
                    onPressed: startSession,
                  ),
                ],
              ),
            );
          }

          /// ACTIVE SESSION FOUND
          final activeSession = snap.data!.docs.first;
          final sessionId = activeSession.id;
          final subject = activeSession['subject'];

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: sessionId,
                  size: 250,
                ),
                const SizedBox(height: 12),
                Text("Subject: $subject"),
                const SizedBox(height: 6),
                const Text("Students can scan this QR"),
              ],
            ),
          );
        },
      ),
    );
  }
}