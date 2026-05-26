import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> markAttendanceFromQR(String qr) async {
  final parts = qr.split('|');
  if (parts.length != 4) throw "Invalid QR";

  final classId = parts[0];
  final subject = parts[1];
  final timestamp = int.parse(parts[2]);
  final sessionId = parts[3];

  final now = DateTime.now().millisecondsSinceEpoch;
  if (now - timestamp > 2 * 60 * 1000) throw "QR expired";

  final sessionDoc = await FirebaseFirestore.instance
      .collection('sessions')
      .doc(sessionId)
      .get();

  if (!sessionDoc.exists || sessionDoc['active'] != true) {
    throw "Session inactive";
  }

  final uid = FirebaseAuth.instance.currentUser!.uid;

  final recordRef = FirebaseFirestore.instance
      .collection('attendance')
      .doc(uid)
      .collection('records')
      .doc(sessionId);

  if ((await recordRef.get()).exists) throw "Already marked";

  await recordRef.set({
    'classId': classId,
    'subject': subject,
    'time': FieldValue.serverTimestamp(),
  });

  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(userRef);

    final total = (snap['totalClasses'] ?? 0) + 1;
    final attended = (snap['attendedClasses'] ?? 0) + 1;

    tx.update(userRef, {
      'totalClasses': total,
      'attendedClasses': attended,
    });
  });

  final subjectRef = FirebaseFirestore.instance
      .collection('attendance')
      .doc(uid)
      .collection('subjects')
      .doc(subject);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(subjectRef);

    final total = (snap.exists ? snap['total'] : 0) + 1;
    final attended = (snap.exists ? snap['attended'] : 0) + 1;

    tx.set(subjectRef, {'total': total, 'attended': attended});
  });
}
