import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../../domain/entities/challenge_goal.dart';
import 'challenge_goal_model.dart';
class UserChallengeParticipationModel {
  const UserChallengeParticipationModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.goals = const {},
    this.wagerAmount,
    this.wagerCurrency = 'USD',
    this.lockedInDate,
    this.metadata = const {},
  });

  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, ChallengeGoalModel> goals;
  final double? wagerAmount;
  final String wagerCurrency;
  final DateTime? lockedInDate;
  final Map<String, dynamic> metadata;

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    final goalsMap = <String, dynamic>{};
    goals.forEach((key, value) {
      goalsMap[key] = value.toFirestore();
    });
    
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'userName': userName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'goals': goalsMap,
      'wagerAmount': wagerAmount,
      'wagerCurrency': wagerCurrency,
      'lockedInDate': lockedInDate != null ? Timestamp.fromDate(lockedInDate!) : null,
      'metadata': metadata,
    };
  }

  factory UserChallengeParticipationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final goalsMap = <String, ChallengeGoalModel>{};
    final goalsData = data['goals'] as Map<String, dynamic>? ?? {};
    goalsData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        goalsMap[key] = ChallengeGoalModel.fromFirestore(value);
      }
    });
    
    return UserChallengeParticipationModel(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      goals: goalsMap,
      wagerAmount: data['wagerAmount']?.toDouble(),
      wagerCurrency: data['wagerCurrency'] ?? 'USD',
      lockedInDate: data['lockedInDate'] != null 
          ? (data['lockedInDate'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory UserChallengeParticipationModel.fromEntity(UserChallengeParticipation participation) {
    final goalsMap = <String, ChallengeGoalModel>{};
    participation.goals.forEach((key, value) {
      goalsMap[key] = ChallengeGoalModel.fromEntity(value);
    });
    
    return UserChallengeParticipationModel(
      id: participation.id,
      challengeId: participation.challengeId,
      userId: participation.userId,
      userName: participation.userName,
      status: participation.status.name,
      createdAt: participation.createdAt,
      updatedAt: participation.updatedAt,
      goals: goalsMap,
      wagerAmount: participation.wagerAmount,
      wagerCurrency: participation.wagerCurrency,
      lockedInDate: participation.lockedInDate,
      metadata: participation.metadata,
    );
  }

  UserChallengeParticipation toEntity() {
    final goalsMap = <String, ChallengeGoal>{};
    goals.forEach((key, value) {
      goalsMap[key] = value.toEntity();
    });
    
    return UserChallengeParticipation(
      id: id,
      challengeId: challengeId,
      userId: userId,
      userName: userName,
      status: ParticipationStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => ParticipationStatus.notLockedIn,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      goals: goalsMap,
      wagerAmount: wagerAmount,
      wagerCurrency: wagerCurrency,
      lockedInDate: lockedInDate,
      metadata: metadata,
    );
  }

}