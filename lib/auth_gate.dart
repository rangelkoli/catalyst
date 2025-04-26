import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main.dart';
import 'know_thyself_wizard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isOnboarded(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists && (doc.data()?['onboarded'] == true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        final user = snapshot.data!;
        return FutureBuilder<bool>(
          future: _isOnboarded(user.uid),
          builder: (context, onboardedSnap) {
            if (!onboardedSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!onboardedSnap.data!) {
              return KnowThyselfWizard(
                onComplete: () {
                  // After onboarding, rebuild to show main app
                  (context as Element).reassemble();
                },
              );
            }
            return MyHomePage(title: 'Flutter Demo Home Page');
          },
        );
      },
    );
  }
}
