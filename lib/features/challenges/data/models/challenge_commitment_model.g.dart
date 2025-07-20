// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_commitment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeCommitmentModel _$ChallengeCommitmentModelFromJson(
        Map<String, dynamic> json) =>
    ChallengeCommitmentModel(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      status: json['status'] as String,
      createdAt: ChallengeCommitmentModel._timestampFromJson(json['createdAt']),
      updatedAt: ChallengeCommitmentModel._timestampFromJson(json['updatedAt']),
      goalConfigs: (json['goalConfigs'] as List<dynamic>?)
              ?.map((e) =>
                  GoalCommitmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      wagerAmount: (json['wagerAmount'] as num?)?.toDouble(),
      wagerCurrency: json['wagerCurrency'] as String? ?? 'USD',
      commitmentDate: ChallengeCommitmentModel._timestampFromJsonNullable(
          json['commitmentDate']),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ChallengeCommitmentModelToJson(
        ChallengeCommitmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'challengeId': instance.challengeId,
      'userId': instance.userId,
      'userName': instance.userName,
      'status': instance.status,
      'createdAt':
          ChallengeCommitmentModel._timestampToJson(instance.createdAt),
      'updatedAt':
          ChallengeCommitmentModel._timestampToJson(instance.updatedAt),
      'goalConfigs': instance.goalConfigs,
      'wagerAmount': instance.wagerAmount,
      'wagerCurrency': instance.wagerCurrency,
      'commitmentDate': ChallengeCommitmentModel._timestampToJsonNullable(
          instance.commitmentDate),
      'metadata': instance.metadata,
    };

GoalCommitmentModel _$GoalCommitmentModelFromJson(Map<String, dynamic> json) =>
    GoalCommitmentModel(
      goalId: json['goalId'] as String,
      goalName: json['goalName'] as String,
      weeklyFrequency: (json['weeklyFrequency'] as num).toInt(),
      parameters: json['parameters'] as Map<String, dynamic>,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$GoalCommitmentModelToJson(
        GoalCommitmentModel instance) =>
    <String, dynamic>{
      'goalId': instance.goalId,
      'goalName': instance.goalName,
      'weeklyFrequency': instance.weeklyFrequency,
      'parameters': instance.parameters,
      'description': instance.description,
    };
