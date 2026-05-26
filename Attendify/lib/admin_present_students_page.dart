import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPresentStudentsPage extends StatelessWidget {
  const AdminPresentStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text("Present Today")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = userSnap.data!.docs;

          return ListView(
            children: students.map((student) {
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('attendance')
                    .doc(student.id)
                    .collection('records')
                    .get(),
                builder: (context, recordSnap) {
                  if (!recordSnap.hasData) return const SizedBox();

                  bool presentToday = false;

                  for (var r in recordSnap.data!.docs) {
                    final time = (r['time'] as Timestamp).toDate();

                    if (time.year == today.year &&
                        time.month == today.month &&
                        time.day == today.day) {
                      presentToday = true;
                    }
                  }

                  if (!presentToday) return const SizedBox();

                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(student['email']),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}