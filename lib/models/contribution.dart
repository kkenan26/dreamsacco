import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single contribution record.
/// Maps directly to a document in the top-level `contributions` collection.
class Contribution {
  final String id;
  final String userId;
  final String groupId;
  final double amount;
  final String month; // format: "yyyy-MM", e.g. "2026-07"
  final DateTime? paidAt;
  final String status; // "paid", "missed", "late"

  Contribution({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.amount,
    required this.month,
    required this.paidAt,
    required this.status,
  });

  factory Contribution.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contribution(
      id: doc.id,
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      month: data['month'] ?? '',
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'missed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'groupId': groupId,
      'amount': amount,
      'month': month,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'status': status,
    };
  }
}

/// Helper to represent "did this member pay this month" for the
/// group-wide status screen (who has paid / who hasn't).
class MemberMonthStatus {
  final String userId;
  final String userName;
  final bool hasPaid;
  final String status; // "paid", "late", "missed", "pending"

  MemberMonthStatus({
    required this.userId,
    required this.userName,
    required this.hasPaid,
    required this.status,
  });
}