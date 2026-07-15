import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

 //1)Sign up
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try{
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,);
      User? user = result.user;
      if (user!= null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          phone: phone,
          email: email,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        return user.uid;
      }
      return null;
      } catch (e) {
      return null;
      }
    }
  //2) Login
    Future<String?> loginWithEmail({
    required String email,
    required String password,
}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,);
      return result.user?.uid;
    } catch (e) {
      return null;
    }
  }

//3)Enter OTP sent
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
}) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification Failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

//4) Verifying OTP
  Future<bool> verifyOTP({
    required String verificationId,
    required String otp,
}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.currentUser?.linkWithCredential(credential);
      return true;
    } catch (e){
      return false;
    }
  }

//5) Signing out
  Future<void> signOut() async {
    await _auth.signOut();
  }

Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    DocumentSnapshot doc =
        await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
}

  }

