import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<String?> getUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(user.uid).get();
      return snapshot['username'];
    }
    return null;
  }

  Future<void> saveUsername(String username) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(
        {'username': username},
        SetOptions(merge: true),
      );
    }
  }
}
