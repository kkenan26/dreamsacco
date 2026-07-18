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
    DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
    String groupName = (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'the group';
    await _sendNotification(
      targetUserId: userId,
      message: 'Your request to join $groupName was approved!',
      type: 'join_approved',
      groupId: groupId,
      groupName: groupName,
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

    DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
    String groupName = (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'the group';

    await _sendNotification(
      targetUserId: userId,
      message: 'Your request to join $groupName was not approved.',
      type: 'join_rejected',
      groupId: groupId,
      groupName: groupName,
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
  Future<void> joinGroupByGroupId({
    required String groupId,
    required String userId,
  }) async {
    DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();

    if (!groupDoc.exists) {
      throw Exception('Group not found. Check the ID and try again.');
    }

    await _addMemberToGroup(
      groupId: groupId,
      userId: userId,
      role: 'member',
    );

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }
  Future<void> requestToLeaveGroup({
    required String groupId,
    required String userId,
    required String userName,
  }) async {
    DocumentSnapshot memberDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .get();

    String role = 'member';
    String joinedAtDisplay = 'Unknown';

    if (memberDoc.exists) {
      Map<String, dynamic> data = memberDoc.data() as Map<String, dynamic>;
      role = data['role'] ?? 'member';
      if (data['joinedAt'] != null) {
        DateTime joinedAt = (data['joinedAt'] as Timestamp).toDate();
        joinedAtDisplay = '${joinedAt.day}/${joinedAt.month}/${joinedAt.year}';
      }
    }

    CollectionReference leaveRequestsRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('leaveRequests');

    await leaveRequestsRef.doc(userId).set({
      'userId': userId,
      'userName': userName,
      'role': role,
      'joinedAtDisplay': joinedAtDisplay,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> getPendingLeaveRequests(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('leaveRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Future<void> approveLeaveRequest({
    required String groupId,
    required String requestId,
    required String userId,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('leaveRequests')
        .doc(requestId)
        .update({'status': 'approved'});

    await removeMember(groupId: groupId, userId: userId);

    DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
    String groupName = (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'the group';

    await _sendNotification(
      targetUserId: userId,
      message: 'You have left $groupName.',
      type: 'leave_approved',
      groupId: groupId,
      groupName: groupName,
    );
  }

  Future<void> rejectLeaveRequest({
    required String groupId,
    required String requestId,
    required String userId,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('leaveRequests')
        .doc(requestId)
        .update({'status': 'rejected'});

    DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
    String groupName = (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'the group';

    await _sendNotification(
      targetUserId: userId,
      message: 'Your request to leave $groupName was declined.',
      type: 'leave_rejected',
      groupId: groupId,
      groupName: groupName,
    );
  }
  Future<void> _sendNotification({
    required String targetUserId,
    required String message,
    required String type,
    String? groupId,
    String? groupName,
  }) async {
    await _firestore.collection('notifications').add({
      'type': type,
      'message': message,
      'targetUserId': targetUserId,
      'groupId': groupId ?? '',
      'groupName': groupName ?? '',
      'sentAt': Timestamp.now(),
      'read': false,
    });
  }
  Stream<List<Map<String, dynamic>>> getNotificationsForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
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
