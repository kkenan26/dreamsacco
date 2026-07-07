import 'package:cloud_firestore/cloud_firestore.dart';

class Member{
  final String userId;
  final String role;
  final String status;
  final String riskFlag;
  final DateTime joinedAt;

  Member({
    required this.userId,
    required this.role,
    this.status = 'active',
    this.riskFlag = 'low',
    DateTime? joinedAt,
}) :joinedAt = joinedAt ?? DateTime.now();

  factory Member.fromMap(String userId, Map<String, dynamic> data) {
    return Member(
      userId: userId,
      role: data['role'] ?? 'member',
      status: data['status'] ?? 'active',
      riskFlag: data['riskFlag'] ?? 'low',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
}
  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'status': status,
      'riskFlag': riskFlag,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
    }
}
