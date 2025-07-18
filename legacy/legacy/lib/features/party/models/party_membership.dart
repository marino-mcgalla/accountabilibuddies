import 'package:cloud_firestore/cloud_firestore.dart';

enum PartyRole {
  leader('leader'),
  member('member');

  const PartyRole(this.value);
  final String value;

  static PartyRole fromString(String value) {
    return PartyRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => PartyRole.member,
    );
  }
}

enum MembershipStatus {
  active('active'),
  inactive('inactive');

  const MembershipStatus(this.value);
  final String value;

  static MembershipStatus fromString(String value) {
    return MembershipStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MembershipStatus.active,
    );
  }
}

class PartyMembership {
  final String partyId;
  final String partyName;
  final PartyRole role;
  final DateTime joinedAt;
  final MembershipStatus status;
  final int memberCount;
  final DateTime? lastActivityAt;

  const PartyMembership({
    required this.partyId,
    required this.partyName,
    required this.role,
    required this.joinedAt,
    required this.status,
    required this.memberCount,
    this.lastActivityAt,
  });

  factory PartyMembership.fromMap(String partyId, Map<String, dynamic> data) {
    return PartyMembership(
      partyId: partyId,
      partyName: data['partyName'] ?? '',
      role: PartyRole.fromString(data['role'] ?? 'member'),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MembershipStatus.fromString(data['status'] ?? 'active'),
      memberCount: data['memberCount'] ?? 0,
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partyName': partyName,
      'role': role.value,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status.value,
      'memberCount': memberCount,
      'lastActivityAt': lastActivityAt != null 
          ? Timestamp.fromDate(lastActivityAt!) 
          : null,
    };
  }

  PartyMembership copyWith({
    String? partyId,
    String? partyName,
    PartyRole? role,
    DateTime? joinedAt,
    MembershipStatus? status,
    int? memberCount,
    DateTime? lastActivityAt,
  }) {
    return PartyMembership(
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
      memberCount: memberCount ?? this.memberCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  bool get isActive => status == MembershipStatus.active;
  bool get isLeader => role == PartyRole.leader;
  bool get isMember => role == PartyRole.member;

  String get roleDisplayName {
    switch (role) {
      case PartyRole.leader:
        return 'Leader';
      case PartyRole.member:
        return 'Member';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case MembershipStatus.active:
        return 'Active';
      case MembershipStatus.inactive:
        return 'Inactive';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartyMembership &&
        other.partyId == partyId &&
        other.partyName == partyName &&
        other.role == role &&
        other.joinedAt == joinedAt &&
        other.status == status &&
        other.memberCount == memberCount &&
        other.lastActivityAt == lastActivityAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      partyId,
      partyName,
      role,
      joinedAt,
      status,
      memberCount,
      lastActivityAt,
    );
  }

  @override
  String toString() {
    return 'PartyMembership(partyId: $partyId, partyName: $partyName, role: ${role.value}, status: ${status.value})';
  }
}