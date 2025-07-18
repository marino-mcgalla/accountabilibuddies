import 'package:cloud_firestore/cloud_firestore.dart';
import '../../party/models/party_membership.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? username;
  final Map<String, PartyMembership> parties;
  final int activePartyCount;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.username,
    required this.parties,
    required this.activePartyCount,
    required this.createdAt,
    required this.lastActiveAt,
    required this.preferences,
  });

  factory UserModel.create({
    required String uid,
    required String email,
    String? displayName,
    String? username,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      username: username,
      parties: {},
      activePartyCount: 0,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      preferences: {
        'notifications': true,
        'timezone': 'America/New_York',
      },
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse parties map
    final partiesData = data['parties'] as Map<String, dynamic>? ?? {};
    final parties = <String, PartyMembership>{};
    
    partiesData.forEach((partyId, membershipData) {
      parties[partyId] = PartyMembership.fromMap(
        partyId, 
        membershipData as Map<String, dynamic>
      );
    });

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      username: data['username'],
      parties: parties,
      activePartyCount: data['activePartyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {
        'notifications': true,
        'timezone': 'America/New_York',
      }),
    );
  }

  Map<String, dynamic> toFirestore() {
    final partiesMap = <String, dynamic>{};
    parties.forEach((partyId, membership) {
      partiesMap[partyId] = membership.toMap();
    });

    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'parties': partiesMap,
      'activePartyCount': activePartyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    Map<String, PartyMembership>? parties,
    int? activePartyCount,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      parties: parties ?? this.parties,
      activePartyCount: activePartyCount ?? this.activePartyCount,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // Convenience getters
  List<PartyMembership> get activeParties {
    return parties.values.where((membership) => membership.isActive).toList();
  }

  List<PartyMembership> get inactiveParties {
    return parties.values.where((membership) => !membership.isActive).toList();
  }

  List<PartyMembership> get leaderParties {
    return parties.values.where((membership) => membership.isLeader && membership.isActive).toList();
  }

  List<PartyMembership> get memberParties {
    return parties.values.where((membership) => membership.isMember && membership.isActive).toList();
  }

  bool get hasActiveParties => activePartyCount > 0;
  bool get hasMultipleParties => activePartyCount > 1;

  // Party-specific methods
  PartyMembership? getPartyMembership(String partyId) {
    return parties[partyId];
  }

  bool isPartyMember(String partyId) {
    final membership = parties[partyId];
    return membership != null && membership.isActive;
  }

  bool isPartyLeader(String partyId) {
    final membership = parties[partyId];
    return membership != null && membership.isActive && membership.isLeader;
  }

  UserModel addPartyMembership(String partyId, PartyMembership membership) {
    final newParties = Map<String, PartyMembership>.from(parties);
    newParties[partyId] = membership;
    
    return copyWith(
      parties: newParties,
      activePartyCount: newParties.values.where((m) => m.isActive).length,
    );
  }

  UserModel removePartyMembership(String partyId) {
    final newParties = Map<String, PartyMembership>.from(parties);
    newParties.remove(partyId);
    
    return copyWith(
      parties: newParties,
      activePartyCount: newParties.values.where((m) => m.isActive).length,
    );
  }

  UserModel updatePartyMembership(String partyId, PartyMembership membership) {
    final newParties = Map<String, PartyMembership>.from(parties);
    newParties[partyId] = membership;
    
    return copyWith(
      parties: newParties,
      activePartyCount: newParties.values.where((m) => m.isActive).length,
    );
  }

  // Display methods
  String get displayNameOrEmail => displayName ?? email;
  String get displayNameOrUsername => displayName ?? username ?? email;
  String get usernameOrEmail => username ?? email;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.username == username &&
        other.activePartyCount == activePartyCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      email,
      displayName,
      username,
      activePartyCount,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, activeParties: $activePartyCount)';
  }
}