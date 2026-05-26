import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_dashboard.dart';
import 'admin_dashboard.dart';
import 'qr_scan_page.dart';
import 'qr_generate_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final role = snap.data!['role'];

        final pages = role == "student"
            ? [ StudentDashboard(),  QRScanPage(),  SettingsPage()]
            : [
           AdminDashboard(),
           QRGeneratePage(),
           SettingsPage()
        ];

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            body: IndexedStack(index: index, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: index,
              onTap: (i) => setState(() => index = i),
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard), label: "Dashboard"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code), label: "QR"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: "Settings"),
              ],
            ),
          ),
        );
      },
    );
  }
}
