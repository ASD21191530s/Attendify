import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceSessionsPage extends StatelessWidget {
  final bool showAbsent;

  const AttendanceSessionsPage({super.key, required this.showAbsent});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(showAbsent ? "Absent Classes" : "All Classes"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadData(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final data = snap.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text("No Data"));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final item = data[i];

              return ListTile(
                leading: Icon(
                  item['attended']
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: item['attended']
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text(item['subject']),
                subtitle: Text(item['time']),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    final sessions = await firestore.collection('sessions').get();

    final records = await firestore
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .get();

    final attendedIds = records.docs.map((e) => e.id).toSet();

    List<Map<String, dynamic>> result = [];

    for (var s in sessions.docs) {
      final data = s.data();

      bool attended = attendedIds.contains(s.id);

      /// Skip attended if showing absent
      if (showAbsent && attended) continue;

      /// SAFE FIELD READING
      final subject =
      data.containsKey('subject') ? data['subject'] : "General";

      String time = "No Date";

      if (data.containsKey('createdAt') && data['createdAt'] != null) {
        final dt = (data['createdAt'] as Timestamp).toDate();
        time = "${dt.day}-${dt.month}-${dt.year}  ${dt.hour}:${dt.minute}";
      }

      result.add({
        "subject": subject,
        "attended": attended,
        "time": time,
      });
    }

    return result;
  }
}