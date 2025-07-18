import 'package:cloud_firestore/cloud_firestore.dart';
import 'challenge_state.dart';

class Party {
  final String id;
  final String createdBy;
  final String partyOwner;
  final List<String> members;
  final String partyName;
  final DateTime createdAt;
  final int challengeStartDay; // 0=Sunday, 1=Monday, etc.
  final ChallengeState? activeChallenge;

  const Party({
    required this.id,
    required this.createdBy,
    required this.partyOwner,
    required this.members,
    required this.partyName,
    required this.createdAt,
    this.challengeStartDay = 1, // Default to Monday
    this.activeChallenge,
  });

  Party copyWith({
    String? id,
    String? createdBy,
    String? partyOwner,
    List<String>? members,
    String? partyName,
    DateTime? createdAt,
    int? challengeStartDay,
    ChallengeState? activeChallenge,
  }) {
    return Party(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      partyOwner: partyOwner ?? this.partyOwner,
      members: members ?? this.members,
      partyName: partyName ?? this.partyName,
      createdAt: createdAt ?? this.createdAt,
      challengeStartDay: challengeStartDay ?? this.challengeStartDay,
      activeChallenge: activeChallenge ?? this.activeChallenge,
    );
  }

  // Factory method to easily create new parties
  factory Party.create(String userId, String partyName) {
    return Party(
      id: '', // Will be set by Firestore
      createdBy: userId,
      partyOwner: userId,
      members: [userId],
      partyName: partyName,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'partyOwner': partyOwner,
      'members': members,
      'partyName': partyName,
      'createdAt': Timestamp.fromDate(createdAt),
      'challengeStartDay': challengeStartDay,
      'activeChallenge': activeChallenge?.toMap(),
    };
  }

  factory Party.fromMap(String id, Map<String, dynamic> data) {
    ChallengeState? activeChallenge;
    if (data['activeChallenge'] != null) {
      activeChallenge = ChallengeState.fromMap(data['activeChallenge']);
    }

    return Party(
      id: id,
      createdBy: data['createdBy'],
      partyOwner: data['partyOwner'],
      members: List<String>.from(data['members'] ?? []),
      partyName: data['partyName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      challengeStartDay: data['challengeStartDay'] ?? 1,
      activeChallenge: activeChallenge,
    );
  }

  // Helper methods
  bool get hasActiveChallenge => activeChallenge != null;
  bool get hasPendingChallenge => activeChallenge?.isSetup ?? false;
  bool get hasRunningChallenge => activeChallenge?.isActive ?? false;
  
  bool isOwner(String userId) => partyOwner == userId;
  bool isMember(String userId) => members.contains(userId);
  
  int get memberCount => members.length;
  
  String get challengeStartDayName {
    const dayNames = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday'
    ];
    return dayNames[challengeStartDay];
  }

  // Challenge management
  Party addMember(String userId) {
    if (isMember(userId)) return this;
    
    final updatedMembers = List<String>.from(members)..add(userId);
    return copyWith(members: updatedMembers);
  }

  Party removeMember(String userId) {
    if (!isMember(userId)) return this;
    
    final updatedMembers = List<String>.from(members)..remove(userId);
    return copyWith(members: updatedMembers);
  }

  Party transferOwnership(String newOwnerId) {
    if (!isMember(newOwnerId)) return this;
    return copyWith(partyOwner: newOwnerId);
  }

  Party startChallenge(ChallengeState challenge) {
    final startedChallenge = challenge.copyWith(status: ChallengeStatus.active);
    return copyWith(activeChallenge: startedChallenge);
  }

  Party completeChallenge() {
    if (activeChallenge == null) return this;
    
    final completedChallenge = activeChallenge!.copyWith(
      status: ChallengeStatus.completed,
    );
    return copyWith(activeChallenge: completedChallenge);
  }

  Party updateChallenge(ChallengeState updatedChallenge) {
    return copyWith(activeChallenge: updatedChallenge);
  }

  Party clearChallenge() {
    return copyWith(activeChallenge: null);
  }
}