import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/progress_log.dart';

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

  Stream<List<Habit>> habitsStream(String userId) => _db
      .collection('habits')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => Habit.fromMap(d.data(), d.id)).toList(),
      );

  // Achievements
  Future<void> addAchievement(Achievement achievement) async {
    await _db
        .collection('achievements')
        .doc(achievement.id)
        .set(achievement.toMap());
  }

  Future<void> updateAchievement(Achievement achievement) async {
    await _db
        .collection('achievements')
        .doc(achievement.id)
        .update(achievement.toMap());
  }

  Future<void> deleteAchievement(String achievementId) async {
    await _db.collection('achievements').doc(achievementId).delete();
  }

  Stream<List<Achievement>> achievementsStream(String userId) => _db
      .collection('achievements')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => Achievement.fromMap(d.data(), d.id)).toList(),
      );

  // Challenges
  Future<void> addChallenge(Challenge challenge) async {
    await _db.collection('challenges').doc(challenge.id).set(challenge.toMap());
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _db
        .collection('challenges')
        .doc(challenge.id)
        .update(challenge.toMap());
  }

  Future<void> deleteChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).delete();
  }

  Stream<List<Challenge>> challengesStream(String userId) => _db
      .collection('challenges')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => Challenge.fromMap(d.data(), d.id)).toList(),
      );

  // Progress Logs
  Future<void> addProgressLog(ProgressLog log) async {
    await _db.collection('progress_logs').doc(log.id).set(log.toMap());
  }

  Stream<List<ProgressLog>> progressLogsStream(String userId) => _db
      .collection('progress_logs')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => ProgressLog.fromMap(d.data(), d.id)).toList(),
      );
}
