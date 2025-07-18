import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> createUserInFirestore(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    // Check if user document already exists
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'counter': 0, // Initialize counter for new users
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
