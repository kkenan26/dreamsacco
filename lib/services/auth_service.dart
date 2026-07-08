import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
}) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted:  (PhoneAuthCredential credential) async{
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }
  Future<UserModel?> verifyOTP({
    required String verificationId,
    required String otp,
    required String name,
}) async {
    try
    {
      PhoneAuthCredential credential = PhoneAuthProvider().credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user!=null) {
        DocumentSnapshot doc =await _db.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          UserModel newUser = UserModel(
            uid: user.uid,
            name: name,
            phone: user.phoneNumber ?? '',
            createdAt: DateTime.now(),
          );
          await _db.collection('users').doc(user.uid).set(newUser.toMap());
          return newUser;
        } else{
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user ==null) return null;
    DocumentSnapshot doc =await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}