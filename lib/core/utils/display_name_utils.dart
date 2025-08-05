import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/models/user_model.dart';

/// Centralized utility for consistent display name resolution across the app
class DisplayNameUtils {
  /// Get display name for a user ID (async version)
  /// Priority: Firestore displayName → Firebase Auth displayName → email prefix → user ID fallback
  static Future<String> getDisplayName(String userId) async {
    print('🔍 DisplayNameUtils.getDisplayName called for userId: $userId');
    
    try {
      // 1. Check Firestore displayName (most up-to-date)
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      print('📄 Firestore doc exists: ${doc.exists}');
      
      if (doc.exists) {
        final data = doc.data();
        print('📊 Firestore data: $data');
        
        final displayName = data?['displayName'] as String?;
        print('👤 Firestore displayName: "$displayName" (is null: ${displayName == null}, is empty: ${displayName?.isEmpty})');
        
        if (displayName != null && displayName.isNotEmpty) {
          print('✅ Using Firestore displayName: "$displayName"');
          return displayName;
        }
        
        // 2. Fall back to Firebase Auth displayName (for current user only)
        final currentUser = FirebaseAuth.instance.currentUser;
        print('🔑 Current user: ${currentUser?.uid}, Auth displayName: "${currentUser?.displayName}"');
        
        if (currentUser?.uid == userId && currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
          print('✅ Using Firebase Auth displayName: "${currentUser.displayName}"');
          return currentUser.displayName!;
        }
        
        // 3. Fall back to email prefix
        final email = data?['email'] as String?;
        print('📧 Email: "$email"');
        
        if (email != null && email.isNotEmpty) {
          final emailPrefix = email.split('@').first;
          print('✅ Using email prefix: "$emailPrefix"');
          return emailPrefix;
        }
      }
      
      const fallback = 'Anonymous';
      print('⚠️ Using fallback: "$fallback"');
      return fallback;
    } catch (e) {
      const fallback = 'Anonymous';
      print('❌ Error in getDisplayName: $e, using fallback: "$fallback"');
      return fallback;
    }
  }
  
  /// Get display name for a UserModel (sync version)
  /// Priority: UserModel displayName → email prefix
  static String getDisplayNameSync(UserModel user) {
    print('🔍 DisplayNameUtils.getDisplayNameSync called for user: ${user.id}');
    print('👤 UserModel displayName: "${user.displayName}"');
    print('📧 UserModel email: "${user.email}"');
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      print('✅ Using UserModel displayName: "${user.displayName}"');
      return user.displayName!;
    }
    
    final emailPrefix = user.email.split('@').first;
    print('✅ Using email prefix: "$emailPrefix"');
    return emailPrefix;
  }
}