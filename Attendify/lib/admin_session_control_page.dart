import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSessionControlPage extends StatefulWidget {
  const AdminSessionControlPage({super.key});

  @override
  State<AdminSessionControlPage> createState() =>
      _AdminSessionControlPageState();
}

class _AdminSessionControlPageState
    extends State<AdminSessionControlPage> {
  bool loading = false;
  String? activeSessionId;

  @override
  void initState() {
    super.initState();
    checkActiveSession();
  }

  Future<void> checkActiveSession() async {
    final snap = await FirebaseFirestore.instance
        .collection('sessions')
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      setState(() {
        activeSessionId = snap.docs.first.id;
      });
    }
  }

  Future<void> startSession() async {
    setState(() => loading = true);

    final sessionRef =
    FirebaseFirestore.instance.collection('sessions').doc();

    await sessionRef.set({
      'subject': "General",
      'active': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // increase total classes for all students
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in users.docs) {
      batch.update(doc.reference, {
        'totalClasses': FieldValue.increment(1),
      });
    }

    await batch.commit();

    setState(() {
      activeSessionId = sessionRef.id;
      loading = false;
    });
  }

  Future<void> endSession() async {
    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(activeSessionId)
        .update({'active': false});

    setState(() {
      activeSessionId = null;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Session Control")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : activeSessionId == null
            ? ElevatedButton(
          onPressed: startSession,
          child: const Text("Start Attendance Session"),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Session Active",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: endSession,
              child: const Text("End Session"),
            ),
          ],
        ),
      ),
    );
  }
}