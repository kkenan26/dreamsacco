import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String type;
  final String adminId;
  final String treasurerId;
  final double totalBalance;
  final double goalAmount;
  final String goalDescription;
  final double monthlyContribution;
  final List<String> memberIds;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.adminId,
    required this.treasurerId,
    this.totalBalance = 0.0,
    required this.goalAmount,
    required this.goalDescription,
    required this.monthlyContribution,
    this.memberIds = const[],//empty memer list first
    DateTime? createdAt,
}) : createdAt = createdAt ?? DateTime.now(); //use now if not provided

  factory Group.fromMap(String docId, Map<String, dynamic> data) {
    return Group(
      id: docId,
        name: data['name'] ?? 'Unnamed Group',
        description: data['description'] ?? '',
        type: data['type'] ?? 'public',
        adminId: data['adminId'] ?? '',
        treasurerId: data['treasurerId'] ?? '',
        totalBalance: (data['totalBalance'] ?? 0.0).toDouble(),
        goalAmount: (data['goalAmount'] ?? 0.0).toDouble(),
        goalDescription: data['goalDescription'] ?? '',
        monthlyContribution: (data['monthlyContribution'] ?? 0.0).toDouble(),
        memberIds: List<String>.from(data['memberIds'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'adminId': adminId,
      'treasurerId': treasurerId,
      'totalBalance': totalBalance,
      'goalAmount': goalAmount,
      'goalDescription': goalDescription,
      'monthlyContribution': monthlyContribution,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt), //firestore time
    };
  }
}