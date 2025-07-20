import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/challenge_commitment.dart';

part 'challenge_commitment_model.g.dart';

@JsonSerializable()
class ChallengeCommitmentModel {
  const ChallengeCommitmentModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.goalConfigs = const [],
    this.wagerAmount,
    this.wagerCurrency = 'USD',
    this.commitmentDate,
    this.metadata = const {},
  });

  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String status;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;
  final List<GoalCommitmentModel> goalConfigs;
  final double? wagerAmount;
  final String wagerCurrency;
  @JsonKey(fromJson: _timestampFromJsonNullable, toJson: _timestampToJsonNullable)
  final DateTime? commitmentDate;
  final Map<String, dynamic> metadata;

  factory ChallengeCommitmentModel.fromJson(Map<String, dynamic> json) =>
      _$ChallengeCommitmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeCommitmentModelToJson(this);

  factory ChallengeCommitmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeCommitmentModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  factory ChallengeCommitmentModel.fromEntity(ChallengeCommitment commitment) {
    return ChallengeCommitmentModel(
      id: commitment.id,
      challengeId: commitment.challengeId,
      userId: commitment.userId,
      userName: commitment.userName,
      status: commitment.status.name,
      createdAt: commitment.createdAt,
      updatedAt: commitment.updatedAt,
      goalConfigs: commitment.goalConfigs
          .map((g) => GoalCommitmentModel.fromEntity(g))
          .toList(),
      wagerAmount: commitment.wagerAmount,
      wagerCurrency: commitment.wagerCurrency,
      commitmentDate: commitment.commitmentDate,
      metadata: commitment.metadata,
    );
  }

  ChallengeCommitment toEntity() {
    return ChallengeCommitment(
      id: id,
      challengeId: challengeId,
      userId: userId,
      userName: userName,
      status: CommitmentStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => CommitmentStatus.pending,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      goalConfigs: goalConfigs.map((g) => g.toEntity()).toList(),
      wagerAmount: wagerAmount,
      wagerCurrency: wagerCurrency,
      commitmentDate: commitmentDate,
      metadata: metadata,
    );
  }

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    throw ArgumentError('Invalid timestamp format: $timestamp');
  }

  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  static DateTime? _timestampFromJsonNullable(dynamic timestamp) {
    if (timestamp == null) return null;
    return _timestampFromJson(timestamp);
  }

  static dynamic _timestampToJsonNullable(DateTime? dateTime) {
    if (dateTime == null) return null;
    return _timestampToJson(dateTime);
  }
}

@JsonSerializable()
class GoalCommitmentModel {
  const GoalCommitmentModel({
    required this.goalId,
    required this.goalName,
    required this.weeklyFrequency,
    required this.parameters,
    this.description,
  });

  final String goalId;
  final String goalName;
  final int weeklyFrequency;
  final Map<String, dynamic> parameters;
  final String? description;

  factory GoalCommitmentModel.fromJson(Map<String, dynamic> json) =>
      _$GoalCommitmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$GoalCommitmentModelToJson(this);

  factory GoalCommitmentModel.fromEntity(GoalCommitment goalCommitment) {
    return GoalCommitmentModel(
      goalId: goalCommitment.goalId,
      goalName: goalCommitment.goalName,
      weeklyFrequency: goalCommitment.weeklyFrequency,
      parameters: goalCommitment.parameters,
      description: goalCommitment.description,
    );
  }

  GoalCommitment toEntity() {
    return GoalCommitment(
      goalId: goalId,
      goalName: goalName,
      weeklyFrequency: weeklyFrequency,
      parameters: parameters,
      description: description,
    );
  }
}