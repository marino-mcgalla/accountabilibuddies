import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/party_invite.dart';

class PartyInviteModel extends PartyInvite {
  const PartyInviteModel({
    required super.id,
    required super.partyId,
    required super.partyName,
    required super.inviterUserId,
    required super.inviterName,
    required super.inviteeEmail,
    super.inviteeUserId,
    required super.status,
    required super.createdAt,
    super.respondedAt,
    required super.expiresAt,
    required super.metadata,
  });

  factory PartyInviteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PartyInviteModel(
      id: doc.id,
      partyId: data['partyId'] as String,
      partyName: data['partyName'] as String,
      inviterUserId: data['inviterUserId'] as String,
      inviterName: data['inviterName'] as String,
      inviteeEmail: data['inviteeEmail'] as String,
      inviteeUserId: data['inviteeUserId'] as String?,
      status: PartyInviteStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PartyInviteStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory PartyInviteModel.fromJson(Map<String, dynamic> json) {
    return PartyInviteModel(
      id: json['id'] as String,
      partyId: json['partyId'] as String,
      partyName: json['partyName'] as String,
      inviterUserId: json['inviterUserId'] as String,
      inviterName: json['inviterName'] as String,
      inviteeEmail: json['inviteeEmail'] as String,
      inviteeUserId: json['inviteeUserId'] as String?,
      status: PartyInviteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PartyInviteStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'partyId': partyId,
      'partyName': partyName,
      'inviterUserId': inviterUserId,
      'inviterName': inviterName,
      'inviteeEmail': inviteeEmail,
      'inviteeUserId': inviteeUserId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partyId': partyId,
      'partyName': partyName,
      'inviterUserId': inviterUserId,
      'inviterName': inviterName,
      'inviteeEmail': inviteeEmail,
      'inviteeUserId': inviteeUserId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PartyInviteModel.fromEntity(PartyInvite invite) {
    return PartyInviteModel(
      id: invite.id,
      partyId: invite.partyId,
      partyName: invite.partyName,
      inviterUserId: invite.inviterUserId,
      inviterName: invite.inviterName,
      inviteeEmail: invite.inviteeEmail,
      inviteeUserId: invite.inviteeUserId,
      status: invite.status,
      createdAt: invite.createdAt,
      respondedAt: invite.respondedAt,
      expiresAt: invite.expiresAt,
      metadata: invite.metadata,
    );
  }

  PartyInvite toEntity() {
    return PartyInvite(
      id: id,
      partyId: partyId,
      partyName: partyName,
      inviterUserId: inviterUserId,
      inviterName: inviterName,
      inviteeEmail: inviteeEmail,
      inviteeUserId: inviteeUserId,
      status: status,
      createdAt: createdAt,
      respondedAt: respondedAt,
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }
}