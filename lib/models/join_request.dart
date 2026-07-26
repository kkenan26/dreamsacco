import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String id;
  final String userId;
  final String userName;
  final double userCreditScore;
  final String riskFlag; //computed from  credit score
  final String status;
  final String reason;
  final DateTime requestedAt;
  final double sharesRequested; // 0 if not a share-based group

  JoinRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userCreditScore,
    required this.riskFlag,
    this.status = 'pending',
    this.reason = '',
    this.sharesRequested = 0.0,
    DateTime? requestedAt,
}) : requestedAt = requestedAt ?? DateTime.now();

  factory JoinRequest.fromMap(String id, Map<String, dynamic> data) {
    return JoinRequest(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userCreditScore: (data['userCreditScore'] ?? 0.0).toDouble(),
      riskFlag: data['riskFlag'] ?? 'medium',
      status: data['status'] ?? 'pending',
      reason: data['reason'] ?? '',
      sharesRequested: (data['sharesRequested'] ?? 0.0).toDouble(),
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userCreditScore': userCreditScore,
      'riskFlag': riskFlag,
      'status': status,
      'reason': reason,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'sharesRequested': sharesRequested,
    };
  }
}