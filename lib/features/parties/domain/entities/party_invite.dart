import 'package:equatable/equatable.dart';

enum PartyInviteStatus {
  pending,
  accepted,
  declined,
  expired,
}

class PartyInvite extends Equatable {
  final String id;
  final String partyId;
  final String partyName;
  final String inviterUserId;
  final String inviterName;
  final String inviteeEmail;
  final String? inviteeUserId; // null if user hasn't registered yet
  final PartyInviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;

  const PartyInvite({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.inviterUserId,
    required this.inviterName,
    required this.inviteeEmail,
    this.inviteeUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
    required this.metadata,
  });

  /// Check if invite is still valid (not expired)
  bool get isValid => DateTime.now().isBefore(expiresAt) && status == PartyInviteStatus.pending;

  /// Check if invite is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt) || status == PartyInviteStatus.expired;

  /// Check if invite has been responded to
  bool get hasResponded => status == PartyInviteStatus.accepted || status == PartyInviteStatus.declined;

  /// Days until expiration
  int get daysUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }

  PartyInvite copyWith({
    String? id,
    String? partyId,
    String? partyName,
    String? inviterUserId,
    String? inviterName,
    String? inviteeEmail,
    String? inviteeUserId,
    PartyInviteStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return PartyInvite(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      inviterName: inviterName ?? this.inviterName,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      inviteeUserId: inviteeUserId ?? this.inviteeUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partyId,
        partyName,
        inviterUserId,
        inviterName,
        inviteeEmail,
        inviteeUserId,
        status,
        createdAt,
        respondedAt,
        expiresAt,
        metadata,
      ];
}