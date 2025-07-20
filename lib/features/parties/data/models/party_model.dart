import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/party.dart';

class PartyModel extends Party {
  const PartyModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.memberIds,
    required super.inviteCode,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.metadata,
  });

  factory PartyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PartyModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      ownerId: data['ownerId'] as String,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      inviteCode: data['inviteCode'] as String,
      status: PartyStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PartyStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      ownerId: json['ownerId'] as String,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      inviteCode: json['inviteCode'] as String,
      status: PartyStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PartyStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PartyModel.fromEntity(Party party) {
    return PartyModel(
      id: party.id,
      name: party.name,
      description: party.description,
      ownerId: party.ownerId,
      memberIds: party.memberIds,
      inviteCode: party.inviteCode,
      status: party.status,
      createdAt: party.createdAt,
      updatedAt: party.updatedAt,
      metadata: party.metadata,
    );
  }

  Party toEntity() {
    return Party(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      memberIds: memberIds,
      inviteCode: inviteCode,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }
}