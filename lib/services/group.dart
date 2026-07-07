import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/join_request.dart';
import '../models/member.dart';
import 'credit_score.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CreditScoreService _creditScoreService;

  GroupService({required CreditScoreService creditScoreService})
    : _creditScoreService = creditScoreService;

  Future<void> _addMemberToGroup({
    required String groupId,
    required String userId,
    required String role,
    String riskFlag = 'low',
  }) async {
    CollectionReference membersRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members');

    Member newMember = Member(
      userId: userId,
      role: role,
      riskFlag: riskFlag,
      status: 'active',
    );
    await membersRef.doc(userId).set(newMember.toMap());
  }

  Future<String> createGroup(Group group) async {
    DocumentReference groupDocRef = _firestore.collection('groups').doc();
    Group newGroup = group.copyWith(id: groupDocRef.id);
    await groupDocRef.set(newGroup.toMap());
    await _addMemberToGroup(
      groupId: newGroup.id,
      userId: newGroup.adminId,
      role: 'admin',
    );
    return newGroup.id;
  }
}
