import 'package:cloud_firestore/cloud_firestore.dart';

class Member{
  final String userId;
  final String role;
  final String status;
  final String riskFlag;
  final DateTime joinedAt;
  final double shares;

  Member({
    required this.userId,
    required this.role,
    this.status = 'active',
    this.riskFlag = 'low',
    this.shares = 0.0,
    DateTime? joinedAt,
}) :joinedAt = joinedAt ?? DateTime.now();

  factory Member.fromMap(String userId, Map<String, dynamic> data) {
    return Member(
      userId: userId,
      role: data['role'] ?? 'member',
      status: data['status'] ?? 'active',
      riskFlag: data['riskFlag'] ?? 'low',
      shares: (data['shares'] ?? 0.0).toDouble(),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
}
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'status': status,
      'riskFlag': riskFlag,
      'shares': shares,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
