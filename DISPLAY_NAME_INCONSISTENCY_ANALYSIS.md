# Display Name Inconsistency Analysis

**Date:** January 30, 2025  
**Issue:** Display name updates from profile page don't work, and different parts of the app show different display names

## Current Problem

User "reno@qa.com" sees "Reno" as display name in some places, but updating display name from profile page doesn't change it. The app has inconsistent display name resolution logic across different components.

## Root Cause Analysis

### Current Display Name Resolution (Inconsistent)

1. **Auth Repository** (`auth_repository.dart:393`):
   ```dart
   displayName: user.displayName ?? firestoreData?['displayName']
   ```
   - Priority: Firebase Auth displayName → Firestore displayName

2. **userDisplayNameProvider** (`party_detail_page.dart`):
   ```dart
   final displayName = data?['displayName'] as String?;
   if (displayName != null && displayName.isNotEmpty) {
     return displayName;
   }
   final email = data?['email'] as String?;
   if (email != null && email.isNotEmpty) {
     return email.split('@').first; // "reno" from "reno@qa.com"
   }
   ```
   - Priority: Firestore displayName → email prefix extraction

3. **Most Widgets** (proof submissions, challenges, etc.):
   ```dart
   userName: user.displayName ?? user.email
   ```
   - Priority: Firebase Auth displayName → full email

### Why "Reno" Appears

The `userDisplayNameProvider` extracts "reno" from "reno@qa.com" using `email.split('@').first` when no displayName exists in Firestore. This only affects the party detail page where this provider is used.

### Why Profile Updates Don't Work

When updating display name from profile page:
1. Updates Firebase Auth displayName ✓
2. Updates Firestore displayName ✓  
3. **But** `userDisplayNameProvider` still finds no displayName in Firestore (caching issue?)
4. Falls back to email extraction logic, showing "Reno" instead of updated name

## Files Affected (7+ files)

### Files That Use displayName Logic:
1. **`lib/features/auth/repositories/auth_repository.dart`**
   - Line 393: User model creation logic
   - Line 221: Profile update logic
   - Line 85: User registration logic

2. **`lib/features/parties/presentation/pages/party_detail_page.dart`**
   - Lines 11-43: `userDisplayNameProvider` definition
   - Line 154: Usage in member list

3. **`lib/features/dashboard/presentation/pages/dashboard_page.dart`**
   - Line 1326: Proof submission userName logic

4. **`lib/features/challenges/presentation/pages/proof_story_viewer.dart`**
   - Lines 542, 596: Approval userName logic

5. **`lib/features/challenges/presentation/widgets/multi_goal_proof_submission_widget.dart`**
   - Lines 445, 467: Proof userName logic

6. **`lib/features/challenges/presentation/widgets/quick_proof_submission_widget.dart`**
   - Line 89: Proof userName logic

7. **`lib/features/challenges/presentation/widgets/proof_submission_widget.dart`**
   - Line 220: Proof userName logic

8. **`lib/features/challenges/presentation/pages/challenge_commitment_page.dart`**
   - Line 339: Participation userName logic

## Recommended Solution

### Create Centralized Display Name Resolution

1. **Create Utility Function** (`lib/core/utils/display_name_utils.dart`):
   ```dart
   class DisplayNameUtils {
     static Future<String> getDisplayName(String userId) async {
       try {
         // 1. Check Firestore displayName (most up-to-date)
         final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
         if (doc.exists) {
           final data = doc.data();
           final displayName = data?['displayName'] as String?;
           if (displayName != null && displayName.isNotEmpty) {
             return displayName;
           }
           
           // 2. Fall back to Firebase Auth displayName
           final currentUser = FirebaseAuth.instance.currentUser;
           if (currentUser?.uid == userId && currentUser?.displayName != null) {
             return currentUser!.displayName!;
           }
           
           // 3. Fall back to email prefix
           final email = data?['email'] as String?;
           if (email != null && email.isNotEmpty) {
             return email.split('@').first;
           }
         }
         
         return 'User ${userId.substring(0, 8)}...';
       } catch (e) {
         return 'User ${userId.substring(0, 8)}...';
       }
     }
     
     static String getDisplayNameSync(UserModel user) {
       // For synchronous cases where we have UserModel
       return user.displayName ?? user.email.split('@').first;
     }
   }
   ```

2. **Create Riverpod Provider**:
   ```dart
   final displayNameProvider = FutureProvider.family<String, String>((ref, userId) async {
     return DisplayNameUtils.getDisplayName(userId);
   });
   ```

3. **Update All Files** to use centralized logic:
   - Replace `user.displayName ?? user.email` with `DisplayNameUtils.getDisplayNameSync(user)`
   - Replace `userDisplayNameProvider` with new `displayNameProvider`
   - Update auth repository to use consistent priority

### Priority Order (Recommended)
1. **Firestore displayName** (most up-to-date, user can update)
2. **Firebase Auth displayName** (fallback for existing users)
3. **Email prefix extraction** (e.g., "reno" from "reno@qa.com")
4. **User ID substring** (final fallback)

## Impact Assessment

### Scope: **Moderate**
- **7-8 files** need updates
- **1 new utility file** to create
- **Multiple widgets** need refactoring

### Risk: **Low-Medium**
- Changes display logic only
- No database schema changes
- Backward compatible

### Benefits: **High**
- Consistent display names across app
- Profile updates work properly
- Single source of truth for display name logic
- Easier to maintain and debug

## Testing Requirements

1. **Test display name updates from profile page**
2. **Test display name consistency across:**
   - Party member lists
   - Proof submissions
   - Challenge participations
   - Story circles
3. **Test fallback logic** for users without displayName
4. **Test caching behavior** of Riverpod providers

## Implementation Notes

- Consider invalidating relevant providers after profile updates
- May need to add provider refresh logic in profile update success callback
- Test with users who have no displayName, only Firebase Auth displayName, and only Firestore displayName

---

**Status:** Analysis Complete - Ready for Implementation  
**Estimated Effort:** 2-3 hours  
**Priority:** Medium (UX consistency issue)