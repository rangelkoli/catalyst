import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/user_points_widget.dart';
import 'friends_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [UserPointsWidget()],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80),
            const SizedBox(height: 16),
            Text('Profile', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            if (user != null) ...[
              Text('Email: \\${user.email}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FriendsScreen(),
                    ),
                  );
                },
                child: const Text('Friends'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
