import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendify")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "LOGIN",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: loginWithFirebase,
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loginWithFirebase() async {
    try {
      setState(() => loading = true);

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final user = cred.user!;
      final uid = user.uid;
      final email = user.email;

      final userRef =
      FirebaseFirestore.instance.collection('users').doc(uid);

      final snap = await userRef.get();

      if (!snap.exists) {
        // First-time login
        await userRef.set({
          'role': 'student', // change to 'admin' if needed
          'email': email,
          'totalClasses': 0,
          'attendedClasses': 0,
        });
      } else {
        // Ensure required fields exist
        await userRef.update({
          'email': email,
          'totalClasses': snap.data()?['totalClasses'] ?? 0,
          'attendedClasses': snap.data()?['attendedClasses'] ?? 0,
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}
