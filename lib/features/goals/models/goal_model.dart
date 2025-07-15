import 'challenge_data.dart';
import 'proof_model.dart';

/// Unified Goal Model
/// This replaces both goal_model.dart and goal_model_new.dart
/// 
/// Key improvements:
/// 1. Consistent string-based completion tracking
/// 2. Single ChallengeData structure for all challenge-related data
/// 3. Clear separation between template-created and challenge-specific data
/// 4. Immutable design with copyWith methods
/// 5. Type safety with proper enum usage

abstract class Goal {
  final String id;
  final String ownerId;
  final String goalName;
  final GoalType goalType;
  final String goalCriteria;
  final int goalFrequency;
  final bool active;
  final ChallengeData? challengeData;
  final String? templateId; // Template this goal was created from
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.goalType,
    required this.goalCriteria,
    required this.goalFrequency,
    required this.active,
    this.challengeData,
    this.templateId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor that creates the appropriate goal type from map data
  factory Goal.fromMap(Map<String, dynamic> data) {
    final typeString = data['goalType'] as String?;
    final goalType = GoalType.fromString(typeString ?? 'daily');
    
    switch (goalType) {
      case GoalType.daily:
        return WeeklyGoal.fromMap(data);
      case GoalType.total:
        return TotalGoal.fromMap(data);
    }
  }

  /// Convert goal to map for Firestore storage
  Map<String, dynamic> toMap();

  /// Check if goal is completed based on current challenge data
  bool get isCompleted;

  /// Get current completion percentage (0.0 to 1.0)
  double get completionPercentage;

  /// Get number of completions achieved
  int get completionsCount;

  /// Create a copy with updated values
  Goal copyWith({
    String? goalName,
    String? goalCriteria,
    int? goalFrequency,
    bool? active,
    ChallengeData? challengeData,
    DateTime? updatedAt,
  });

  /// Add proof submission to this goal
  Goal addProof(String proofText, String? imageUrl, DateTime date);

  /// Overwrite proof - replaces existing proof and resets completion status to pending
  Goal overwriteProof(String proofText, String? imageUrl, DateTime date);

  /// Approve a proof for this goal
  Goal approveProof(String proofId, String date);

  /// Deny a proof for this goal
  Goal denyProof(String proofId, String date);

  /// Get all pending proofs for this goal
  List<Proof> get pendingProofs {
    return challengeData?.pendingProofs ?? [];
  }

  /// Convenience getter for backward compatibility
  String get title => goalName;

  /// Get goal type as string for storage
  String get goalTypeString => goalType.name;
}

/// Weekly Goal Implementation
class WeeklyGoal extends Goal {
  const WeeklyGoal({
    required super.id,
    required super.ownerId,
    required super.goalName,
    required super.goalCriteria,
    required super.goalFrequency,
    required super.active,
    super.challengeData,
    super.templateId,
    required super.createdAt,
    required super.updatedAt,
  }) : super(goalType: GoalType.daily);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalType': goalType.name,
      'goalCriteria': goalCriteria,
      'goalFrequency': goalFrequency,
      'active': active,
      'challengeData': challengeData?.toMap(),
      'templateId': templateId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeeklyGoal.fromMap(Map<String, dynamic> data) {
    ChallengeData? challengeData;
    
    // Handle new format
    if (data['challengeData'] != null) {
      challengeData = ChallengeData.fromMap(data['challengeData']);
    } 
    // Handle legacy format from old goal_model.dart
    else if (data['challenge'] != null) {
      challengeData = ChallengeData.fromLegacyMap(data['challenge']);
    }
    // Handle legacy currentWeekCompletions from old goal_model.dart
    else if (data['currentWeekCompletions'] != null) {
      challengeData = ChallengeData.fromLegacyCompletions(data['currentWeekCompletions']);
    }

    return WeeklyGoal(
      id: data['id'] ?? '',
      ownerId: data['ownerId'] ?? '',
      goalName: data['goalName'] ?? data['name'] ?? '', // Support both field names
      goalCriteria: data['goalCriteria'] ?? data['description'] ?? '', // Support both field names
      goalFrequency: data['goalFrequency'] ?? data['frequency'] ?? 1, // Support both field names
      active: data['active'] ?? true,
      challengeData: challengeData,
      templateId: data['templateId'],
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  @override
  bool get isCompleted {
    if (challengeData == null) return false;
    return challengeData!.totalCompletions >= goalFrequency;
  }

  @override
  double get completionPercentage {
    if (goalFrequency == 0) return 0.0;
    return (completionsCount / goalFrequency).clamp(0.0, 1.0);
  }

  @override
  int get completionsCount {
    return challengeData?.totalCompletions ?? 0;
  }

  @override
  WeeklyGoal copyWith({
    String? goalName,
    String? goalCriteria,
    int? goalFrequency,
    bool? active,
    ChallengeData? challengeData,
    DateTime? updatedAt,
  }) {
    return WeeklyGoal(
      id: id,
      ownerId: ownerId,
      goalName: goalName ?? this.goalName,
      goalCriteria: goalCriteria ?? this.goalCriteria,
      goalFrequency: goalFrequency ?? this.goalFrequency,
      active: active ?? this.active,
      challengeData: challengeData ?? this.challengeData,
      templateId: templateId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  WeeklyGoal addProof(String proofText, String? imageUrl, DateTime date) {
    final dateKey = date.toIso8601String().split('T')[0];
    
    final proof = Proof(
      id: '${id}_${dateKey}_${DateTime.now().millisecondsSinceEpoch}',
      proofText: proofText,
      imageUrl: imageUrl,
      submissionDate: date,
      status: ProofStatus.pending,
    );

    final currentData = challengeData ?? const ChallengeData();
    final updatedDailyProofs = Map<String, Proof>.from(currentData.dailyProofs);
    final updatedCompletions = Map<String, String>.from(currentData.completions);
    
    updatedDailyProofs[dateKey] = proof;
    
    // Don't override if already completed
    if (updatedCompletions[dateKey] != 'completed') {
      updatedCompletions[dateKey] = 'pending';
    }

    return copyWith(
      challengeData: currentData.copyWith(
        dailyProofs: updatedDailyProofs,
        completions: updatedCompletions,
      ),
    );
  }

  /// Overwrite proof - replaces existing proof and resets completion status to pending
  @override
  WeeklyGoal overwriteProof(String proofText, String? imageUrl, DateTime date) {
    final dateKey = date.toIso8601String().split('T')[0];
    
    final proof = Proof(
      id: '${id}_${dateKey}_${DateTime.now().millisecondsSinceEpoch}',
      proofText: proofText,
      imageUrl: imageUrl,
      submissionDate: date,
      status: ProofStatus.pending,
    );

    final currentData = challengeData ?? const ChallengeData();
    final updatedDailyProofs = Map<String, Proof>.from(currentData.dailyProofs);
    final updatedCompletions = Map<String, String>.from(currentData.completions);
    
    // Replace the proof and reset completion to pending
    updatedDailyProofs[dateKey] = proof;
    updatedCompletions[dateKey] = 'pending';

    return copyWith(
      challengeData: currentData.copyWith(
        dailyProofs: updatedDailyProofs,
        completions: updatedCompletions,
      ),
    );
  }

  @override
  WeeklyGoal approveProof(String proofId, String date) {
    final currentData = challengeData ?? const ChallengeData();
    final updatedCompletions = Map<String, String>.from(currentData.completions);
    final updatedDailyProofs = Map<String, Proof>.from(currentData.dailyProofs);
    
    updatedCompletions[date] = 'completed';
    
    // Update proof status
    if (updatedDailyProofs[date] != null) {
      updatedDailyProofs[date] = updatedDailyProofs[date]!.copyWith(
        status: ProofStatus.approved
      );
    }

    return copyWith(
      challengeData: currentData.copyWith(
        completions: updatedCompletions,
        dailyProofs: updatedDailyProofs,
      ),
    );
  }

  @override
  WeeklyGoal denyProof(String proofId, String date) {
    final currentData = challengeData ?? const ChallengeData();
    final updatedCompletions = Map<String, String>.from(currentData.completions);
    final updatedDailyProofs = Map<String, Proof>.from(currentData.dailyProofs);
    
    updatedCompletions[date] = 'denied';
    
    // Update proof status
    if (updatedDailyProofs[date] != null) {
      updatedDailyProofs[date] = updatedDailyProofs[date]!.copyWith(
        status: ProofStatus.denied
      );
    }

    return copyWith(
      challengeData: currentData.copyWith(
        completions: updatedCompletions,
        dailyProofs: updatedDailyProofs,
      ),
    );
  }
}

/// Total Goal Implementation
class TotalGoal extends Goal {
  const TotalGoal({
    required super.id,
    required super.ownerId,
    required super.goalName,
    required super.goalCriteria,
    required super.goalFrequency,
    required super.active,
    super.challengeData,
    super.templateId,
    required super.createdAt,
    required super.updatedAt,
  }) : super(goalType: GoalType.total);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalType': goalType.name,
      'goalCriteria': goalCriteria,
      'goalFrequency': goalFrequency,
      'active': active,
      'challengeData': challengeData?.toMap(),
      'templateId': templateId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TotalGoal.fromMap(Map<String, dynamic> data) {
    ChallengeData? challengeData;
    
    // Handle new format
    if (data['challengeData'] != null) {
      challengeData = ChallengeData.fromMap(data['challengeData']);
    } 
    // Handle legacy format from old goal_model.dart
    else if (data['challenge'] != null) {
      challengeData = ChallengeData.fromLegacyMap(data['challenge']);
    }

    return TotalGoal(
      id: data['id'] ?? '',
      ownerId: data['ownerId'] ?? '',
      goalName: data['goalName'] ?? data['name'] ?? '', // Support both field names
      goalCriteria: data['goalCriteria'] ?? data['description'] ?? '', // Support both field names
      goalFrequency: data['goalFrequency'] ?? data['frequency'] ?? 1, // Support both field names
      active: data['active'] ?? true,
      challengeData: challengeData,
      templateId: data['templateId'],
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  @override
  bool get isCompleted {
    if (challengeData == null) return false;
    return challengeData!.proofs.where((p) => p.status == ProofStatus.approved).length >= goalFrequency;
  }

  @override
  double get completionPercentage {
    if (goalFrequency == 0) return 0.0;
    return (completionsCount / goalFrequency).clamp(0.0, 1.0);
  }

  @override
  int get completionsCount {
    return challengeData?.proofs.where((p) => p.status == ProofStatus.approved).length ?? 0;
  }

  @override
  TotalGoal copyWith({
    String? goalName,
    String? goalCriteria,
    int? goalFrequency,
    bool? active,
    ChallengeData? challengeData,
    DateTime? updatedAt,
  }) {
    return TotalGoal(
      id: id,
      ownerId: ownerId,
      goalName: goalName ?? this.goalName,
      goalCriteria: goalCriteria ?? this.goalCriteria,
      goalFrequency: goalFrequency ?? this.goalFrequency,
      active: active ?? this.active,
      challengeData: challengeData ?? this.challengeData,
      templateId: templateId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  TotalGoal addProof(String proofText, String? imageUrl, DateTime date) {
    final proof = Proof(
      id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
      proofText: proofText,
      imageUrl: imageUrl,
      submissionDate: date,
      status: ProofStatus.pending,
    );

    final currentData = challengeData ?? const ChallengeData();
    final updatedProofs = List<Proof>.from(currentData.proofs)..add(proof);

    return copyWith(
      challengeData: currentData.copyWith(proofs: updatedProofs),
    );
  }

  /// Overwrite proof - for total goals, this is the same as adding a proof since they don't track daily completions
  @override
  TotalGoal overwriteProof(String proofText, String? imageUrl, DateTime date) {
    // For total goals, overwriting is the same as adding since there's no daily completion tracking
    return addProof(proofText, imageUrl, date);
  }

  @override
  TotalGoal approveProof(String proofId, String date) {
    final currentData = challengeData ?? const ChallengeData();
    final updatedProofs = currentData.proofs.map((proof) {
      if (proof.id == proofId) {
        return proof.copyWith(status: ProofStatus.approved);
      }
      return proof;
    }).toList();

    return copyWith(
      challengeData: currentData.copyWith(proofs: updatedProofs),
    );
  }

  @override
  TotalGoal denyProof(String proofId, String date) {
    final currentData = challengeData ?? const ChallengeData();
    final updatedProofs = currentData.proofs.map((proof) {
      if (proof.id == proofId) {
        return proof.copyWith(status: ProofStatus.denied);
      }
      return proof;
    }).toList();

    return copyWith(
      challengeData: currentData.copyWith(proofs: updatedProofs),
    );
  }
}

/// Goal Type Enum
enum GoalType {
  daily,
  total;

  static GoalType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return GoalType.daily;
      case 'weekly': // Support legacy data
        return GoalType.daily;
      case 'total':
        return GoalType.total;
      default:
        return GoalType.daily; // Default fallback
    }
  }

  String get name {
    switch (this) {
      case GoalType.daily:
        return 'daily';
      case GoalType.total:
        return 'total';
    }
  }
}