import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/contribution.dart';

/// Handles everything to do with recording and reading contributions.
/// Streak + loan limit math is intentionally NOT done here — that lives
/// in the Cloud Function (functions/index.js) so it can't be tampered
/// with client-side and stays consistent across every device.
class ContributionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get currentMonthKey => DateFormat('yyyy-MM').format(DateTime.now());

  /// Records a contribution payment made by [userId] in [groupId].
  /// This single write is what fires the Cloud Function trigger that
  /// recalculates streak + loan limit.
  Future<void> recordPayment({
    required String userId,
    required String groupId,
    required double amount,
    String? monthOverride,
  }) async {
    final month = monthOverride ?? currentMonthKey;

    // Determine on-time vs late based on the group's due day.
    final groupSnap = await _db.collection('groups').doc(groupId).get();
    final dueDay = (groupSnap.data()?['contributionDueDay'] ?? 5) as int;
    final now = DateTime.now();
    final status = now.day <= dueDay ? 'paid' : 'late';

    // Use a deterministic doc ID (userId_month) so a member can only
    // have ONE contribution record per month per group — this also
    // makes "did they pay this month" a simple doc lookup instead of
    // a query, and prevents duplicate payments for the same month.
    final docId = '${groupId}_${userId}_$month';

    await _db.collection('contributions').doc(docId).set({
      'userId': userId,
      'groupId': groupId,
      'amount': amount,
      'month': month,
      'paidAt': Timestamp.fromDate(now),
      'status': status,
    });
  }

  /// Returns every contribution record for a group in a given month.
  Stream<List<Contribution>> watchGroupContributionsForMonth(
    String groupId,
    String month,
  ) {
    return _db
        .collection('contributions')
        .where('groupId', isEqualTo: groupId)
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Contribution.fromDoc(d)).toList());
  }

  /// Builds the "who has paid / who hasn't" list for the current month
  /// by cross-referencing active group members against contribution docs.
  Future<List<MemberMonthStatus>> getMonthlyStatus(
    String groupId, {
    String? month,
  }) async {
    final targetMonth = month ?? currentMonthKey;

    final membersSnap = await _db
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .get();

    final contributionsSnap = await _db
        .collection('contributions')
        .where('groupId', isEqualTo: groupId)
        .where('month', isEqualTo: targetMonth)
        .get();

    final paidByUserId = <String, Contribution>{
      for (final doc in contributionsSnap.docs)
        Contribution.fromDoc(doc).userId: Contribution.fromDoc(doc)
    };

    final results = <MemberMonthStatus>[];
    for (final memberDoc in membersSnap.docs) {
      final userId = memberDoc.id;
      final userSnap = await _db.collection('users').doc(userId).get();
      final userName = userSnap.data()?['name'] ?? 'Unknown';

      final contribution = paidByUserId[userId];
      results.add(MemberMonthStatus(
        userId: userId,
        userName: userName,
        hasPaid: contribution != null,
        status: contribution?.status ?? 'pending',
      ));
    }

    return results;
  }

  /// A member's full contribution history, most recent month first.
  /// Useful for showing a personal payment timeline in the UI.
  Future<List<Contribution>> getUserHistory(String userId, {int limit = 12}) async {
    final snap = await _db
        .collection('contributions')
        .where('userId', isEqualTo: userId)
        .orderBy('month', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => Contribution.fromDoc(d)).toList();
  }
}
