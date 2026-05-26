import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceHistoryPage extends StatelessWidget {
  AttendanceHistoryPage({super.key}); // ❌ NOT const

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .doc(uid)
            .collection('records')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No attendance records yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final time = (data['time'] as Timestamp).toDate();

              return ListTile(
                leading:
                const Icon(Icons.check_circle, color: Colors.green),
                title: Text(data['subject']),
                subtitle: Text(time.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
