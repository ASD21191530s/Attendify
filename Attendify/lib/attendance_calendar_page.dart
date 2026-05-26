import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceCalendarPage extends StatefulWidget {
  AttendanceCalendarPage({super.key});

  @override
  State<AttendanceCalendarPage> createState() =>
      _AttendanceCalendarPageState();
}

class _AttendanceCalendarPageState extends State<AttendanceCalendarPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final Set<DateTime> presentDays = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    final snap = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .get();

    for (var doc in snap.docs) {
      final date = (doc['time'] as Timestamp).toDate();
      presentDays.add(DateTime(date.year, date.month, date.day));
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Calendar")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: DateTime(2022),
        lastDay: DateTime(2030),
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.horizontalSwipe,
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final d = DateTime(date.year, date.month, date.day);
            if (presentDays.contains(d)) {
              return const Positioned(
                bottom: 1,
                child: Icon(
                  Icons.circle,
                  color: Colors.green,
                  size: 8,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
