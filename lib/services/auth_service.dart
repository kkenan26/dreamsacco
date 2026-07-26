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
      print('SignUp Error: $e');
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
      print('Login Error: $e');
      return null;
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

