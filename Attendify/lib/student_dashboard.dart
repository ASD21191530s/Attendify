import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_attendance_page.dart';
import 'attendance_calendar_page.dart';
import 'attendance_history_page.dart';
import 'attendance_sessions_page.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  Widget statusBanner(int percent) {
    Color color;
    String text;
    IconData icon;

    if (percent >= 75) {
      color = Colors.green;
      text = "You are Safe";
      icon = Icons.check_circle;
    } else if (percent >= 60) {
      color = Colors.orange;
      text = "Attendance Warning";
      icon = Icons.warning;
    } else {
      color = Colors.red;
      text = "Defaulter";
      icon = Icons.error;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget card({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final int totalClasses = data['totalClasses'] ?? 0;
          final int attendedClasses = data['attendedClasses'] ?? 0;

          final int absentClasses =
          (totalClasses - attendedClasses).clamp(0, totalClasses);

          final int percent = totalClasses == 0
              ? 0
              : ((attendedClasses / totalClasses) * 100).round();

          return Column(
            children: [
              statusBanner(percent),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("View Attendance Calendar"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceCalendarPage(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    card(
                      context: context,
                      title: "Overall %",
                      value: "$percent%",
                      icon: Icons.percent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceHistoryPage(),
                          ),
                        );
                      },
                    ),
                    card(
                      context: context,
                      title: "Total Classes",
                      value: "$totalClasses",
                      icon: Icons.today,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const AttendanceSessionsPage(showAbsent: false),
                          ),
                        );
                      },
                    ),
                    card(
                      context: context,
                      title: "Absent Classes",
                      value: "$absentClasses",
                      icon: Icons.cancel,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const AttendanceSessionsPage(showAbsent: true),
                          ),
                        );
                      },
                    ),
                    card(
                      context: context,
                      title: "Attended",
                      value: "$attendedClasses",
                      icon: Icons.check_circle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubjectAttendancePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}
