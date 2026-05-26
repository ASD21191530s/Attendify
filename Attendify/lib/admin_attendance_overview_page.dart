import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAttendanceOverviewPage extends StatelessWidget {
  const AdminAttendanceOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Students Attendance")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snap.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, i) {
              final data = students[i];

              int total = data['totalClasses'] ?? 0;
              int attended = data['attendedClasses'] ?? 0;
              int percent =
              total == 0 ? 0 : ((attended / total) * 100).round();

              return ListTile(
                leading: CircleAvatar(child: Text("$percent%")),
                title: Text(data['email']),
                subtitle:
                Text("Attended: $attended / $total"),
              );
            },
          );
        },
      ),
    );
  }
}