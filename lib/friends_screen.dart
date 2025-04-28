import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'friend_habits_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirestoreService _firestore = FirestoreService();

  void _showAddFriendDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Friend'),
            content: TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Friend\'s Email'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  try {
                    await _firestore.sendFriendRequest(
                      fromUid: user.uid,
                      toEmail: emailController.text.trim(),
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Friend request sent!')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: \\${e.toString()}')),
                    );
                  }
                },
                child: const Text('Send Request'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Friend',
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Friend Requests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestore.incomingFriendRequests(user.uid),
              builder: (context, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final requests = snap.data!;
                if (requests.isEmpty) return const Text('No pending requests.');
                return Column(
                  children:
                      requests
                          .map(
                            (req) => ListTile(
                              title: Text('From: ' + req['fromUid']),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  await _firestore.acceptFriendRequest(
                                    req['id'],
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Friend request accepted!'),
                                    ),
                                  );
                                },
                                child: const Text('Accept'),
                              ),
                            ),
                          )
                          .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Friends',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestore.friendsStream(user.uid),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  final friends = snap.data!;
                  if (friends.isEmpty) return const Text('No friends yet.');
                  return ListView(
                    children:
                        friends
                            .map(
                              (f) => ListTile(
                                title: Text(f['uid']),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => FriendHabitsScreen(
                                            friendUid: f['uid'],
                                          ),
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
