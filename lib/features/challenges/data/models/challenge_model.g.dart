// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeModel _$ChallengeModelFromJson(Map<String, dynamic> json) =>
    ChallengeModel(
      id: json['id'] as String,
      partyId: json['partyId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startDate: ChallengeModel._timestampFromJson(json['startDate']),
      endDate: ChallengeModel._timestampFromJson(json['endDate']),
      status: json['status'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: ChallengeModel._timestampFromJson(json['createdAt']),
      updatedAt: ChallengeModel._timestampFromJson(json['updatedAt']),
      commitmentDeadline:
          ChallengeModel._timestampFromJsonNullable(json['commitmentDeadline']),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ChallengeModelToJson(ChallengeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'partyId': instance.partyId,
      'name': instance.name,
      'description': instance.description,
      'startDate': ChallengeModel._timestampToJson(instance.startDate),
      'endDate': ChallengeModel._timestampToJson(instance.endDate),
      'status': instance.status,
      'createdBy': instance.createdBy,
      'createdAt': ChallengeModel._timestampToJson(instance.createdAt),
      'updatedAt': ChallengeModel._timestampToJson(instance.updatedAt),
      'commitmentDeadline':
          ChallengeModel._timestampToJsonNullable(instance.commitmentDeadline),
      'metadata': instance.metadata,
    };
