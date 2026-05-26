import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDefaultersPage extends StatelessWidget {
  const AdminDefaultersPage({super.key});

  int getPercent(int total, int attended) {
    if (total == 0) return 0;
    return ((attended / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Defaulters")),
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

          final defaulters = students.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            int total = data['totalClasses'] ?? 0;
            int attended = data['attendedClasses'] ?? 0;
            return getPercent(total, attended) < 75;
          }).toList();

          if (defaulters.isEmpty) {
            return const Center(child: Text("No defaulters 🎉"));
          }

          return ListView.builder(
            itemCount: defaulters.length,
            itemBuilder: (context, index) {
              final data =
              defaulters[index].data() as Map<String, dynamic>;

              int total = data['totalClasses'] ?? 0;
              int attended = data['attendedClasses'] ?? 0;
              int percent = getPercent(total, attended);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text("$percent%"),
                ),
                title: Text(data['email']),
                subtitle: Text("Attended: $attended / $total"),
              );
            },
          );
        },
      ),
    );
  }
}