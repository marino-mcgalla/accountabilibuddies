import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/providers/auth_provider.dart';

/// Provider for managing dismissed challenge summaries per user
final dismissedChallengesProvider = StateNotifierProvider<DismissedChallengesNotifier, Set<String>>((ref) {
  final user = ref.watch(userProvider);
  return DismissedChallengesNotifier(user?.id);
});

/// Notifier for managing dismissed challenge summaries
class DismissedChallengesNotifier extends StateNotifier<Set<String>> {
  DismissedChallengesNotifier(this._userId) : super(<String>{}) {
    _loadDismissedChallenges();
  }

  final String? _userId;
  static const String _keyPrefix = 'dismissed_challenges_';
  static const String _timestampPrefix = 'dismissed_timestamp_';
  static const Duration _retentionPeriod = Duration(days: 7);

  /// Load dismissed challenges from SharedPreferences and clean up old ones
  Future<void> _loadDismissedChallenges() async {
    if (_userId == null) return;
    
    try {
      final prefs = sl<SharedPreferences>();
      final key = '$_keyPrefix$_userId';
      final dismissedIds = prefs.getStringList(key) ?? <String>[];
      
      // Clean up old dismissals
      final cleanedIds = await _cleanupOldDismissals(dismissedIds);
      
      // Update state with cleaned list
      state = cleanedIds.toSet();
      
      // Save cleaned list back if it changed
      if (cleanedIds.length != dismissedIds.length) {
        await prefs.setStringList(key, cleanedIds);
      }
    } catch (e) {
      // Ignore errors, use empty set
      state = <String>{};
    }
  }
  
  /// Clean up dismissals older than retention period
  Future<List<String>> _cleanupOldDismissals(List<String> challengeIds) async {
    if (challengeIds.isEmpty) return challengeIds;
    
    final prefs = sl<SharedPreferences>();
    final now = DateTime.now();
    final validIds = <String>[];
    
    for (final challengeId in challengeIds) {
      final timestampKey = '$_timestampPrefix$challengeId';
      final timestamp = prefs.getInt(timestampKey);
      
      if (timestamp != null) {
        final dismissedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (now.difference(dismissedDate) < _retentionPeriod) {
          // Keep this dismissal, it's still within retention period
          validIds.add(challengeId);
        } else {
          // Remove old timestamp
          await prefs.remove(timestampKey);
        }
      } else {
        // No timestamp found (old dismissal), remove it
        // Don't add to validIds
      }
    }
    
    return validIds;
  }

  /// Dismiss a challenge summary for the current user
  Future<void> dismissChallenge(String challengeId) async {
    if (_userId == null) return;
    
    try {
      final newState = {...state, challengeId};
      state = newState;
      
      // Save to SharedPreferences with timestamp
      final prefs = sl<SharedPreferences>();
      final key = '$_keyPrefix$_userId';
      final timestampKey = '$_timestampPrefix$challengeId';
      
      await prefs.setStringList(key, newState.toList());
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Check if a challenge is dismissed
  bool isChallengeDismissed(String challengeId) {
    return state.contains(challengeId);
  }

  /// Clear all dismissed challenges (for testing or user preference)
  Future<void> clearDismissedChallenges() async {
    if (_userId == null) return;
    
    try {
      state = <String>{};
      final prefs = sl<SharedPreferences>();
      final key = '$_keyPrefix$_userId';
      await prefs.remove(key);
    } catch (e) {
      // Ignore errors
    }
  }
}