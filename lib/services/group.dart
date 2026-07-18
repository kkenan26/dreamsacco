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
    Group newGroup = group.copyWith(
      id: groupDocRef.id,
      memberIds: [group.adminId],
    );
    await groupDocRef.set(newGroup.toMap());
    await _addMemberToGroup(
      groupId: newGroup.id,
      userId: newGroup.adminId,
      role: 'admin',
    );
    return newGroup.id;
  }

  Stream<List<Group>> getGroupsForUser(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Group.fromMap(doc.id, doc.data()))
        .toList());
  }

  Stream<List<Member>> getGroupMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Member.fromMap(doc.id, doc.data()))
        .toList());
  }

  String _computeRiskFlag(double creditScore) {
    if (creditScore >= 70) {
      return 'low';
    } else if (creditScore >= 40) {
      return 'medium';
    } else {
      return 'high';
    }
  }

  Future<void> submitJoinRequest({
    required String groupId,
    required String userId,
    required String userName,
  }) async {
    double score = await _creditScoreService.getCreditScore(userId);
    String risk = _computeRiskFlag(score);

    CollectionReference requestsRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests');

    DocumentReference requestDocRef = requestsRef.doc();

    JoinRequest newRequest = JoinRequest(
      id: requestDocRef.id,
      userId: userId,
      userName: userName,
      userCreditScore: score,
      riskFlag: risk,
    );

    await requestDocRef.set(newRequest.toMap());
  }

  Stream<List<JoinRequest>> getPendingJoinRequests(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => JoinRequest.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> approveJoinRequest({
    required String groupId,
    required String requestId,
    required String userId,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .doc(requestId)
        .update({'status': 'approved'});

    //add the user to the members
    await _addMemberToGroup(
      groupId: groupId,
      userId: userId,
      role: 'member',
    );

    // 3. Add the userId to the group's memberIds array
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    await _sendNotification(
      targetUserId: userId,
      message: 'Your request to join the group was approved!',
      type: 'join_approved',
    );
  }

  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestId,
    required String userId,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .doc(requestId)
        .update({'status': 'rejected'});

    await _sendNotification(
      targetUserId: userId,
      message: 'Your request to join the group was not approved.',
      type: 'join_rejected',
    );
  }
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String newRole,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .update({'role': newRole});
  }
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    // 1. Delete from the members subcollection
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .delete();

    // 2. Remove the userId from the group's memberIds array
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }
  Future<void> _sendNotification({
    required String targetUserId,
    required String message,
    required String type,
  }) async {
    await _firestore.collection('notifications').add({
      'type': type,
      'message': message,
      'targetUserId': targetUserId,
      'sentAt': Timestamp.now(),
      'read': false,
    });
  }
  Stream<List<Group>> getPublicGroups() {
    return _firestore
        .collection('groups')
        .where('type', isEqualTo: 'public')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Group.fromMap(doc.id, doc.data()))
        .toList());
  }
}
