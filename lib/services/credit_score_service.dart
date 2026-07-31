import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/credit_score_model.dart';

class CreditScoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CreditScoreModel> fetchUserCreditScore(String groupId) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';

      QuerySnapshot contributions = await _db
          .collectionGroup('contributions')
          .where('userId', isEqualTo: uid)
          .get();

      int totalContributions = 0;
      int missedContributions = 0;

      for (var doc in contributions.docs) {
        String status = doc['status'] ?? 'missed';
        if (status == 'paid') {
          totalContributions++;
        } else {
          missedContributions++;
        }
      }

      QuerySnapshot loans = await _db
          .collectionGroup('loans')
          .where('requesterId', isEqualTo: uid)
          .get();

      int loansRepaid = 0;
      int activeLoanCount = 0;

      for (var doc in loans.docs) {
        String status = doc['status'] ?? '';
        if (status == 'cleared') loansRepaid++;
        if (status == 'repaying') activeLoanCount++;
      }

      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      int streak = 0;
      if (userDoc.exists) {
        streak = (userDoc['contributionStreak'] as num?)?.toInt() ?? 0;
      }

      CreditScoreModel score = CreditScoreModel.compute(
        totalContributions: totalContributions,
        missedContributions: missedContributions,
        loansRepaid: loansRepaid,
        activeLoanCount: activeLoanCount,
        contributionStreak: streak,
      );

      await _db.collection('users').doc(uid).update({
        'creditScore': score.score,
        'loanLimit': score.loanLimit,
      });

      return score;
    } catch (e) {
      print('Credit score error: $e');
      return CreditScoreModel(
        score: 50,
        rating: "Unrated",
        remark: "Not enough activity to compute score yet.",
        loanLimit: 0,
        interestRate: 0.15,
      );
    }
  }
}