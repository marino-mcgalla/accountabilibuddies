import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/core.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<Result<UserModel>> signInWithEmail(String email, String password);
  Future<Result<UserModel>> signUpWithEmail(String email, String password, String? displayName);
  Future<Result<void>> sendPasswordResetEmail(String email);
  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccount();
  Future<Result<UserModel>> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<Result<void>> updateProfile({String? displayName, String? photoUrl});
  Future<Result<void>> updateEmail(String newEmail);
  Future<Result<void>> updatePassword(String newPassword);
  Future<Result<void>> reauthenticateWithEmail(String email, String password);
  Future<Result<void>> sendEmailVerification();
  Future<Result<void>> reloadUser();
  Future<Result<void>> updateUser(UserModel user);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<UserModel>> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return Result.failure(const AuthFailure(
          message: 'Sign in failed. Please try again.',
          code: 'SIGNIN_FAILED',
        ));
      }

      final user = await _mapFirebaseUserToUserModel(credential.user!);
      return Result.success(user);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred during sign in.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<UserModel>> signUpWithEmail(String email, String password, String? displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return Result.failure(const AuthFailure(
          message: 'Account creation failed. Please try again.',
          code: 'SIGNUP_FAILED',
        ));
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      final userDoc = {
        'id': credential.user!.uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': null,
        'isEmailVerified': credential.user!.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignInAt': FieldValue.serverTimestamp(),
        'metadata': {
          'onboarded': false,
          'agreedToTerms': true,
          'agreedToPrivacy': true,
        },
      };

      await _firestore.collection('users').doc(credential.user!.uid).set(userDoc);
      // logger.debug('FirebaseAuthRepository: Firestore user document created successfully');

      // Send email verification
      // logger.debug('FirebaseAuthRepository: Sending email verification');
      await credential.user!.sendEmailVerification();

      // logger.debug('FirebaseAuthRepository: Creating UserModel from Firebase user');
      final user = await _mapFirebaseUserToUserModel(credential.user!);
      // logger.debug('FirebaseAuthRepository: Sign up completed successfully');
      return Result.success(user);
    } on FirebaseAuthException catch (e, stackTrace) {
      logger.error('FirebaseAuthRepository: Firebase Auth error during sign up', error: e, stackTrace: stackTrace);
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      logger.error('FirebaseAuthRepository: Unexpected error during sign up', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred during sign up.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while sending password reset email.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred during sign out.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth user
      await user.delete();

      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while deleting account.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<UserModel>> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      final userModel = await _mapFirebaseUserToUserModel(user);
      return Result.success(userModel);
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while getting current user.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      return await _mapFirebaseUserToUserModel(user);
    });
  }

  @override
  Future<Result<void>> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while updating profile.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> updateEmail(String newEmail) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      await user.verifyBeforeUpdateEmail(newEmail);

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'isEmailVerified': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send verification email for new email
      await user.sendEmailVerification();

      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while updating email.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      await user.updatePassword(newPassword);
      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while updating password.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> reauthenticateWithEmail(String email, String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred during reauthentication.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      await user.sendEmailVerification();
      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while sending email verification.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      await user.reload();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while reloading user.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  // Helper methods
  Future<UserModel> _mapFirebaseUserToUserModel(User user) async {
    // print('🔍 AuthRepository._mapFirebaseUserToUserModel called for user: ${user.uid}');
    // print('🔑 Firebase Auth displayName: "${user.displayName}"');
    
    // Get additional user data from Firestore
    Map<String, dynamic>? firestoreData;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        firestoreData = doc.data();
        // print('📊 Firestore data in auth repo: $firestoreData');
      } else {
        // print('📄 No Firestore document found for user');
      }
    } catch (e) {
      // print('❌ Error fetching Firestore data in auth repo: $e');
      // If Firestore data retrieval fails, we'll use Firebase Auth data only
    }

    final firestoreDisplayName = firestoreData?['displayName'] as String?;
    // print('🔄 Firestore displayName: "$firestoreDisplayName" (is null: ${firestoreDisplayName == null}, is empty: ${firestoreDisplayName?.isEmpty}');
    
    final finalDisplayName = (firestoreDisplayName != null && firestoreDisplayName.isNotEmpty) 
        ? firestoreDisplayName 
        : user.displayName;
    // print('✅ Final displayName for UserModel: "$finalDisplayName"');

    return UserModel(
      id: user.uid,
      email: user.email!,
      displayName: finalDisplayName,
      photoUrl: user.photoURL ?? firestoreData?['photoUrl'],
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSignInAt: user.metadata.lastSignInTime,
      metadata: firestoreData?['metadata'] ?? {},
    );
  }

  Failure _mapFirebaseAuthException(FirebaseAuthException e, StackTrace stackTrace) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure(
          message: 'No account found with this email address.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'wrong-password':
        return AuthFailure(
          message: 'Incorrect password. Please try again.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'invalid-email':
        return ValidationFailure(
          message: 'Please enter a valid email address.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'user-disabled':
        return AuthFailure(
          message: 'This account has been disabled.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'email-already-in-use':
        return ValidationFailure(
          message: 'An account with this email already exists.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'weak-password':
        return ValidationFailure(
          message: 'Password is too weak. Please choose a stronger password.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'requires-recent-login':
        return AuthFailure(
          message: 'Please sign in again to perform this action.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'too-many-requests':
        return NetworkFailure(
          message: 'Too many failed attempts. Please try again later.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'network-request-failed':
        return NetworkFailure(
          message: 'Network error. Please check your internet connection.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      default:
        return AuthFailure(
          message: e.message ?? 'An authentication error occurred.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
    }
  }

  @override
  Future<Result<void>> updateUser(UserModel user) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return Result.failure(const AuthFailure(
          message: 'No user is currently signed in.',
          code: 'NO_USER',
        ));
      }

      // Update user data in Firestore
      await _firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'isEmailVerified': user.isEmailVerified,
        'metadata': user.metadata,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return Result.success(null);
    } catch (e, stackTrace) {
      if (e is FirebaseException) {
        return Result.failure(_mapFirebaseAuthException(e as FirebaseAuthException, stackTrace));
      }
      
      return Result.failure(UnknownFailure(
        message: 'An unexpected error occurred while updating user.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}