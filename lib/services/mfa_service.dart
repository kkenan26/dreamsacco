import 'package:cloud_firestore/cloud_firestore.dart';

enum SensitiveAction {
  loanApproval,
  withdrawal,
  roleChange,
  highValueTransaction,
}

class MFAService {
  final FirebaseFirestore _db =FirebaseFirestore.instance;

  bool requiresMFA(SensitiveAction action, {double amount = 0}) {
    switch(action) {
      case SensitiveAction.loanApproval:
        return true;
      case SensitiveAction.withdrawal:
        return amount >=  500000;
      case SensitiveAction.roleChange:
        return true;
      case SensitiveAction.highValueTransaction:
        return amount >= 500000;
    }
  }

  Future<void> logMFAEvent({
    required String userId,
    required SensitiveAction action,
    required bool verified,
}) async {
    await _db.collection('mfaLogs').add({
      'userId': userId,
      'action': action,
      'verified': verified,
      'triggeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> validateAction({
    required String userId,
    required SensitiveAction action,
    double amount = 0,
    required Future<bool> Function() onMFARequired,
}) async {
    if (!requiresMFA(action, amount: amount)) {
      return true;
    }


  bool verified = await onMFARequired();

  await logMFAEvent(
      userId: userId,
      action: action,
      verified: verified,
      );

      return verified;}

}