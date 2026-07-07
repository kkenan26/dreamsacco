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

  // Creates a new Group using the same data, but lets you change specific fields.
  // The '?' means the parameter is optional.
  // If you don't provide a new value, it uses the existing one (e.g., id ?? this.id).
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? adminId,
    String? treasurerId,
    double? totalBalance,
    double? goalAmount,
    String? goalDescription,
    double? monthlyContribution,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      adminId: adminId ?? this.adminId,
      treasurerId: treasurerId ?? this.treasurerId,
      totalBalance: totalBalance ?? this.totalBalance,
      goalAmount: goalAmount ?? this.goalAmount,
      goalDescription: goalDescription ?? this.goalDescription,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}