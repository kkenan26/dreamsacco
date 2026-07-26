import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/credit_score_model.dart';
import 'credit_score.dart';

class RealCreditScoreAdapter implements CreditScoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<double> getCreditScore(String userId) async {
    try {
      QuerySnapshot contributions = await _db
          .collectionGroup('contributions')
          .where('userId', isEqualTo: userId)
          .get();

      int totalContributions = 0;
      int missedContributions = 0;
      for (var doc in contributions.docs) {
        String status = (doc.data() as Map<String, dynamic>)['status'] ?? 'missed';
        if (status == 'paid') {
          totalContributions++;
        } else {
          missedContributions++;
        }
      }

      QuerySnapshot loans = await _db
          .collectionGroup('loans')
          .where('requesterId', isEqualTo: userId)
          .get();

      int loansRepaid = 0;
      int activeLoanCount = 0;
      for (var doc in loans.docs) {
        String status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
        if (status == 'cleared') loansRepaid++;
        if (status == 'repaying') activeLoanCount++;
      }

      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
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

      return score.score.toDouble();
    } catch (e) {
      return 50.0; // safe fallback, matches her own fallback default
    }
  }
}