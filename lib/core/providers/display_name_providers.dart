import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/display_name_utils.dart';

/// Provider for fetching display names by user ID
/// Uses centralized display name resolution logic
final displayNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  print('🔮 displayNameProvider called for userId: $userId');
  try {
    final result = await DisplayNameUtils.getDisplayName(userId);
    print('🔮 displayNameProvider returning: "$result"');
    return result;
  } catch (e) {
    print('🔮 displayNameProvider error: $e');
    rethrow;
  }
});