import 'dart:developer';

import 'package:chattify/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../api/Apis.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    // Start animation after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _handleGoogleBtnClick() {
    _signInWithGoogle().then((user) async {
      log('\nUser: ${user.user}');
      log('\nUser Additional Information: ${user.additionalUserInfo}');

      if ((await APIs.userExists())) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }else{
        await APIs.createUser().then((value){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const HomeScreen()));
        });
      }
    });
  }

  Future<UserCredential> _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
      serverClientId:
          '96219241237-8e4c7lt5prdopd8iosirivfjjb358j2u.apps.googleusercontent.com', // 🔐 Paste Web Client ID here
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Sign-in cancelled');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Welcome to Chattify',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height: mq.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: mq.height * 0.05),

              // Animated Logo
              SlideTransition(
                position: _offsetAnimation,
                child: Hero(
                  tag: 'app-logo',
                  child: Image.asset(
                    'assets/images/login.png',
                    height: mq.height * 0.26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: mq.height * 0.03),
              const Text(
                'Let\'s get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
              SizedBox(height: mq.height * 0.02),

              const Text(
                'Connect with friends and family with secure, real-time messaging',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: mq.height * 0.09),

              // Google Login Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _handleGoogleBtnClick();
                  // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                },
                icon: Image.asset(
                  'assets/images/google.png',
                  height: mq.height * 0.03,
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(height: mq.height * 0.03),

              // Divider with "or" text
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),
              SizedBox(height: mq.height * 0.03),

              // Email Login Option
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.blue.shade400),
                ),
                onPressed: () {},
                child: const Text(
                  'Continue with Email',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Text(
          'By continuing, you agree to our Terms and Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }
}
