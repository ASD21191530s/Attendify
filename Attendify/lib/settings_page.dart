import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'utils/admin_pdf_export.dart';
import 'utils/pdf_export.dart';
import 'theme_provider.dart';
import 'login_page.dart';
import 'attendance_history_page.dart';
import 'admin_students_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final role = data['role'];

          return ListView(
            children: [

              /// PROFILE HEADER
              Container(
                padding: const EdgeInsets.all(20),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email ?? "",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(role.toString().toUpperCase(),
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// DARK MODE
              SwitchListTile(
                title: const Text("Dark Mode"),
                value: theme.isDark,
                onChanged: (_) => theme.toggleTheme(),
              ),

              /// HISTORY BUTTON
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(role == "admin"
                    ? "View Students Attendance"
                    : "View My Attendance History"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => role == "admin"
                          ? const AdminStudentsPage()
                          :  AttendanceHistoryPage(),
                    ),
                  );
                },
              ),

              /// EXPORT BUTTON
              ListTile(
                leading: const Icon(Icons.print),
                title: Text(role == "admin"
                    ? "Export Full Attendance Report"
                    : "Export My Attendance"),
                onTap: () async {
                  if (role == "admin") {
                    await exportAdminAttendancePDF();
                  } else {
                    await exportAttendancePDF();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("PDF Downloaded")),
                    );
                  }
                },
              ),

              const Divider(),

              /// LOGOUT
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginPage()),
                          (_) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}