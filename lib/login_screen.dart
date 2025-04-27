import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'models/app_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
              },
              child: const Text('Don\'t have an account? Sign up'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: () async {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                try {
                  final GoogleSignInAccount? googleUser =
                      await GoogleSignIn().signIn();
                  if (googleUser == null) return;
                  final GoogleSignInAuthentication googleAuth =
                      await googleUser.authentication;
                  final credential = GoogleAuthProvider.credential(
                    accessToken: googleAuth.accessToken,
                    idToken: googleAuth.idToken,
                  );
                  final userCred = await FirebaseAuth.instance
                      .signInWithCredential(credential);
                  final user = userCred.user;
                  if (user != null) {
                    final firestore = FirestoreService();
                    final doc =
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                    if (!doc.exists) {
                      await firestore.setUser(
                        AppUser(
                          uid: user.uid,
                          email: user.email ?? '',
                          points: 0,
                          records: const {},
                          onboarded: false,
                        ),
                      );
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  setState(() {
                    _error = e.message;
                  });
                } finally {
                  setState(() {
                    _loading = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
