import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStudentsPage extends StatelessWidget {
  const AdminStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Students")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index];

              final total = data['totalClasses'] ?? 0;
              final attended = data['attendedClasses'] ?? 0;

              final percent = total == 0
                  ? 0
                  : ((attended / total) * 100).round();

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['email']),
                subtitle: Text("Attendance: $percent%"),
              );
            },
          );
        },
      ),
    );
  }
}