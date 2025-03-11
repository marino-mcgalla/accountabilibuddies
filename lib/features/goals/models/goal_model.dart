import 'package:auth_test/features/goals/models/total_goal.dart';
import 'package:auth_test/features/goals/models/weekly_goal.dart';

class Goal {
  final String id;
  final String ownerId;
  String goalName;
  String goalType; // 'weekly' or 'total'
  String goalCriteria;
  int goalFrequency;
  final bool active; // Whether the goal is active for the current week
  Map<String, dynamic> currentWeekCompletions; // Adding this back

  // New challenge property for active challenges
  Map<String, dynamic>? challenge;

  Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.goalType,
    required this.goalCriteria,
    required this.goalFrequency,
    required this.active,
    required this.currentWeekCompletions,
    this.challenge, // Optional in constructor
  });

  factory Goal.fromMap(Map<String, dynamic> data) {
    if (data['goalType'] == 'weekly') {
      return WeeklyGoal.fromMap(data);
    } else if (data['goalType'] == 'total') {
      return TotalGoal.fromMap(data);
    } else {
      throw Exception('Unknown goal type');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalType': goalType,
      'goalCriteria': goalCriteria,
      'goalFrequency': goalFrequency,
      'active': active,
      'currentWeekCompletions': currentWeekCompletions,
      'challenge': challenge, // Include challenge in serialization
    };
  }

  void addProof(String proofText, String? imageUrl, DateTime date) {
    challenge ??= {
      'completions': {},
      'proofs': goalType == 'total' ? [] : {},
    };

    Map<String, dynamic> proofData = {
      'proofText': proofText,
      'imageUrl': imageUrl,
      'status': 'pending',
      'submissionDate': date.toIso8601String(),
    };

    if (goalType == 'weekly') {
      String day = date.toIso8601String().split('T')[0];
      if (challenge!['proofs'] == null) challenge!['proofs'] = {};
      (challenge!['proofs'] as Map)[day] = proofData;

      Map<String, dynamic> completions =
          challenge!['completions'] as Map<String, dynamic>? ?? {};
      if (completions[day] != 'completed') {
        completions[day] = 'pending';
      }
      challenge!['completions'] = completions;
    } else {
      // FIX: Handle case where proofs is a Map instead of List for total goals
      if (challenge!['proofs'] == null) {
        challenge!['proofs'] = [];
      } else if (challenge!['proofs'] is Map) {
        // Convert map to list if incorrectly stored
        challenge!['proofs'] = [];
      }
      (challenge!['proofs'] as List).add(proofData);
    }
  }

  bool get isCompleted {
    int completionsCount = 0;

    if (currentWeekCompletions.isNotEmpty) {
      currentWeekCompletions.forEach((date, value) {
        if (value is int) {
          completionsCount += value;
        } else if (value is bool && value) {
          completionsCount += 1;
        }
      });
    }

    // Goal is completed if the number of completions meets or exceeds the goal frequency
    return completionsCount >= goalFrequency;
  }

  // Map goalName to title for compatibility
  String get title => goalName;
}
