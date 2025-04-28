// Reward model for personalized reward management
class Reward {
  final String id;
  final String userId;
  final String desc;
  final int cost;
  final int redeemedCount;
  final String? rationale;

  Reward({
    required this.id,
    required this.userId,
    required this.desc,
    required this.cost,
    this.redeemedCount = 0,
    this.rationale,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      desc: map['desc'] ?? '',
      cost: map['cost'] ?? 0,
      redeemedCount: map['redeemedCount'] ?? 0,
      rationale: map['rationale'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'desc': desc,
      'cost': cost,
      'redeemedCount': redeemedCount,
      if (rationale != null) 'rationale': rationale,
    };
  }
}
