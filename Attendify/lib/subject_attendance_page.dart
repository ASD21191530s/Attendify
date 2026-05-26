import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectAttendancePage extends StatelessWidget {
  const SubjectAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Subject Attendance")),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('attendance')
            .doc(uid)
            .collection('records')
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          Map<String, int> subjectCount = {};

          for (var doc in docs) {
            final subject = doc['subject'];
            subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
          }

          if (subjectCount.isEmpty) {
            return const Center(child: Text("No attendance yet"));
          }

          return ListView(
            children: subjectCount.entries.map((entry) {
              final subject = entry.key;
              final attended = entry.value;

              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(subject),
                trailing: Text("$attended classes"),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}