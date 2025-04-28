import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/reward.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User
  Future<void> setUser(AppUser user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!, doc.id);
    return null;
  }

  // Goals
  Future<void> addGoal(Goal goal) async {
    await _db.collection('goals').doc(goal.id).set(goal.toMap());
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.collection('goals').doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteGoal(String goalId) async {
    await _db.collection('goals').doc(goalId).delete();
  }

  Stream<List<Goal>> goalsStream(String userId) => _db
      .collection('goals')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => Goal.fromMap(d.data(), d.id)).toList(),
      );

  // Habits
  Future<void> addHabit(Habit habit) async {
    await _db.collection('habits').doc(habit.id).set(habit.toMap());
  }

  Future<void> updateHabit(Habit habit) async {
    await _db.collection('habits').doc(habit.id).update(habit.toMap());
  }

  Future<void> deleteHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).delete();
  }

  Future<void> setHabitSharedWithFriends(String habitId, bool shared) async {
    await _db.collection('habits').doc(habitId).update({
      'sharedWithFriends': shared,
    });
  }

  Stream<List<Habit>> habitsStream(String userId) => _db
      .collection('habits')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => Habit.fromMap(d.data(), d.id)).toList(),
      );

  Stream<List<Habit>> sharedHabitsStream(String userId) => _db
      .collection('habits')
      .where('userId', isEqualTo: userId)
      .where('sharedWithFriends', isEqualTo: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => Habit.fromMap(d.data(), d.id)).toList(),
      );

  // Habit Completions
  Future<void> completeHabit({
    required String userId,
    required String habitId,
    required DateTime date,
  }) async {
    final dateStr = _dateToYMD(date);
    final docId = '${userId}_$habitId",$dateStr';
    await _db.collection('habit_completions').doc(docId).set({
      'userId': userId,
      'habitId': habitId,
      'date': dateStr,
    });
  }

  Stream<List<String>> habitCompletionsStream({
    required String userId,
    required String habitId,
  }) {
    return _db
        .collection('habit_completions')
        .where('userId', isEqualTo: userId)
        .where('habitId', isEqualTo: habitId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d['date'] as String).toList());
  }

  /// Adjusts habit points based on recent consistency (Effort Decay & Struggle Boost)
  Future<void> autoAdjustHabitPoints(String userId) async {
    final habitsSnap =
        await _db.collection('habits').where('userId', isEqualTo: userId).get();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 28)); // last 4 weeks
    for (final doc in habitsSnap.docs) {
      final habit = Habit.fromMap(doc.data(), doc.id);
      // Get completions for last 28 days
      final completionsSnap =
          await _db
              .collection('habit_completions')
              .where('userId', isEqualTo: userId)
              .where('habitId', isEqualTo: habit.id)
              .where('date', isGreaterThanOrEqualTo: _dateToYMD(start))
              .get();
      final completions =
          completionsSnap.docs.map((d) => d['date'] as String).toSet();
      int totalDays = now.difference(start).inDays + 1;
      int completedDays = 0;
      for (int i = 0; i < totalDays; i++) {
        final day = start.add(Duration(days: i));
        final ymd = _dateToYMD(day);
        if (completions.contains(ymd)) completedDays++;
      }
      final rate = completedDays / totalDays;
      int newDifficulty = habit.difficulty;
      if (rate > 0.85 && habit.difficulty > 1) {
        newDifficulty = habit.difficulty - 1; // Effort Decay
      } else if (rate < 0.4) {
        newDifficulty = habit.difficulty + 1; // Struggle Boost
      }
      if (newDifficulty != habit.difficulty) {
        await _db.collection('habits').doc(habit.id).update({
          'difficulty': newDifficulty,
        });
      }
    }
  }

  // Rewards
  Future<void> addReward(Reward reward) async {
    await _db.collection('rewards').doc(reward.id).set(reward.toMap());
  }

  Future<void> updateReward(Reward reward) async {
    await _db.collection('rewards').doc(reward.id).update(reward.toMap());
  }

  Future<void> deleteReward(String rewardId) async {
    await _db.collection('rewards').doc(rewardId).delete();
  }

  Stream<List<Reward>> rewardsStream(String userId) => _db
      .collection('rewards')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Reward.fromMap(d.data())).toList());

  Future<void> redeemReward(String rewardId) async {
    final doc = _db.collection('rewards').doc(rewardId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final current = snapshot.data();
      final currentCount = (current?['redeemedCount'] ?? 0) as int;
      transaction.update(doc, {'redeemedCount': currentCount + 1});
    });
  }

  // FRIENDS & FRIEND REQUESTS
  Future<void> sendFriendRequest({
    required String fromUid,
    required String toEmail,
  }) async {
    // Find user by email
    final userQuery =
        await _db.collection('users').where('email', isEqualTo: toEmail).get();
    if (userQuery.docs.isEmpty) throw Exception('User not found');
    final toUid = userQuery.docs.first.id;
    // Add a friend request document
    await _db.collection('friend_requests').add({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> incomingFriendRequests(String myUid) {
    return _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final reqDoc = _db.collection('friend_requests').doc(requestId);
    final reqSnap = await reqDoc.get();
    final data = reqSnap.data()!;
    final fromUid = data['fromUid'];
    final toUid = data['toUid'];
    // Add each other as friends
    await _db
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(toUid)
        .set({'since': FieldValue.serverTimestamp()});
    await _db
        .collection('users')
        .doc(toUid)
        .collection('friends')
        .doc(fromUid)
        .set({'since': FieldValue.serverTimestamp()});
    // Mark request as accepted
    await reqDoc.update({'status': 'accepted'});
  }

  Stream<List<Map<String, dynamic>>> friendsStream(String myUid) {
    return _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList(),
        );
  }

  String _dateToYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
