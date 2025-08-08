import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../main.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndNavigate();
  }

  Future<void> _initializeFirebaseAndNavigate() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      await Future.delayed(const Duration(seconds: 2));

      final user = FirebaseAuth.instance.currentUser;
      log('User: ${user?.email ?? "No user logged in"}');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => user != null ? const HomeScreen() : const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      log('Error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE9E1FB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app-logo',
              child: Image.asset(
                'assets/images/icon.png',
                height: 130,
                width: 130,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chattify',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect. Chat. Repeat.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.deepPurpleAccent,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
