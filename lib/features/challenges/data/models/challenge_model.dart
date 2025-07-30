import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/challenge.dart';

part 'challenge_model.g.dart';

@JsonSerializable()
class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.partyId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.commitmentDeadline,
    this.totalPool = 0.0,
    this.metadata = const {},
  });

  final String id;
  final String partyId;
  final String name;
  final String description;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime startDate;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime endDate;
  final String status;
  final String createdBy;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;
  @JsonKey(fromJson: _timestampFromJsonNullable, toJson: _timestampToJsonNullable)
  final DateTime? commitmentDeadline;
  final double totalPool;
  final Map<String, dynamic> metadata;

  factory ChallengeModel.fromJson(Map<String, dynamic> json) =>
      _$ChallengeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeModelToJson(this);

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  factory ChallengeModel.fromEntity(Challenge challenge) {
    return ChallengeModel(
      id: challenge.id,
      partyId: challenge.partyId,
      name: challenge.name,
      description: challenge.description,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      status: challenge.status.name,
      createdBy: challenge.createdBy,
      createdAt: challenge.createdAt,
      updatedAt: challenge.updatedAt,
      commitmentDeadline: challenge.commitmentDeadline,
      totalPool: challenge.totalPool,
      metadata: challenge.metadata,
    );
  }

  Challenge toEntity() {
    return Challenge(
      id: id,
      partyId: partyId,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      status: ChallengeStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => ChallengeStatus.pending,
      ),
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      commitmentDeadline: commitmentDeadline,
      totalPool: totalPool,
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