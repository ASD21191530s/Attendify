import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_present_students_page.dart';
import 'admin_students_page.dart';
import 'admin_defaulters_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  /// END SESSION FUNCTION
  Future<void> endSession() async {
    final firestore = FirebaseFirestore.instance;

    final activeSessions = await firestore
        .collection('sessions')
        .where('active', isEqualTo: true)
        .get();

    for (var doc in activeSessions.docs) {
      await doc.reference.update({'active': false});
    }
  }

  Widget card(String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = userSnap.data!.docs
              .where((u) => u['role'] == 'student')
              .toList();

          int totalStudents = students.length;
          int presentToday = 0;
          int defaulters = 0;

          for (var u in students) {
            int total = u['totalClasses'] ?? 0;
            int attended = u['attendedClasses'] ?? 0;

            int percent =
            total == 0 ? 0 : ((attended / total) * 100).round();

            if (percent < 75) defaulters++;
            if (attended > 0) presentToday++;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sessions')
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (context, sessionSnap) {
              bool sessionActive =
                  sessionSnap.hasData && sessionSnap.data!.docs.isNotEmpty;

              return GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                children: [
                  card("Students", "$totalStudents", Icons.people, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminStudentsPage()),
                    );
                  }),

                  card("Present Today", "$presentToday",
                      Icons.check_circle, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const AdminPresentStudentsPage()),
                        );
                      }),

                  card("Defaulters", "$defaulters", Icons.warning, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const AdminDefaultersPage()),
                    );
                  }),

                  /// ACTIVE SESSION CONTROL
                  card("Active Session", sessionActive ? "YES" : "NO",
                      Icons.wifi, () async {
                        if (!sessionActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No active session")),
                          );
                          return;
                        }

                        await endSession();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Session Closed")),
                        );
                      }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}