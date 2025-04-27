class AppUser {
  final String uid;
  final String email;
  final int points;
  final Map<String, dynamic> records;
  final bool onboarded;

  AppUser({
    required this.uid,
    required this.email,
    this.points = 0,
    this.records = const {},
    this.onboarded = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) => AppUser(
    uid: uid,
    email: data['email'] ?? '',
    points: data['points'] ?? 0,
    records: data['records'] ?? {},
    onboarded: data['onboarded'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'points': points,
    'records': records,
    'onboarded': onboarded,
  };
}
