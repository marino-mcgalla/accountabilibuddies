import '../../../features/party/models/challenge_state.dart';
import '../../../features/goals/models/goal_model.dart';

/// Represents a challenge that can span across multiple parties
/// Extends the existing ChallengeState with multi-party capabilities
class MultiPartyChallenge extends ChallengeState {
  final List<String> participatingParties; // List of party IDs
  final Map<String, PartyInviteStatus> partyInviteStatus; // partyId -> status
  final String creatorPartyId; // ID of the party that created the challenge
  final String challengeType; // "single-party" | "multi-party"
  final Map<String, double> partyWagerPools; // partyId -> total wager amount
  final bool allowCrossPartyProofApproval; // Whether members can approve proofs from other parties
  final Map<String, List<String>> partyApprovers; // partyId -> list of userIds who can approve proofs
  
  const MultiPartyChallenge({
    required super.id,
    required super.status,
    required super.startDate,
    required super.endDate,
    super.lockedInMembers = const [],
    super.optedOutMembers = const [],
    super.wagers = const {},
    super.goalCompletions = const {},
    super.payouts = const {},
    super.memberGoals = const {},
    required this.participatingParties,
    this.partyInviteStatus = const {},
    required this.creatorPartyId,
    this.challengeType = 'single-party',
    this.partyWagerPools = const {},
    this.allowCrossPartyProofApproval = false,
    this.partyApprovers = const {},
  });

  @override
  MultiPartyChallenge copyWith({
    String? id,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? lockedInMembers,
    List<String>? optedOutMembers,
    Map<String, double>? wagers,
    Map<String, bool>? goalCompletions,
    Map<String, double>? payouts,
    Map<String, List<Goal>>? memberGoals,
    List<String>? participatingParties,
    Map<String, PartyInviteStatus>? partyInviteStatus,
    String? creatorPartyId,
    String? challengeType,
    Map<String, double>? partyWagerPools,
    bool? allowCrossPartyProofApproval,
    Map<String, List<String>>? partyApprovers,
  }) {
    return MultiPartyChallenge(
      id: id ?? this.id,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lockedInMembers: lockedInMembers ?? this.lockedInMembers,
      optedOutMembers: optedOutMembers ?? this.optedOutMembers,
      wagers: wagers ?? this.wagers,
      goalCompletions: goalCompletions ?? this.goalCompletions,
      payouts: payouts ?? this.payouts,
      memberGoals: memberGoals ?? this.memberGoals,
      participatingParties: participatingParties ?? this.participatingParties,
      partyInviteStatus: partyInviteStatus ?? this.partyInviteStatus,
      creatorPartyId: creatorPartyId ?? this.creatorPartyId,
      challengeType: challengeType ?? this.challengeType,
      partyWagerPools: partyWagerPools ?? this.partyWagerPools,
      allowCrossPartyProofApproval: allowCrossPartyProofApproval ?? this.allowCrossPartyProofApproval,
      partyApprovers: partyApprovers ?? this.partyApprovers,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    baseMap.addAll({
      'participatingParties': participatingParties,
      'partyInviteStatus': partyInviteStatus.map((key, value) => MapEntry(key, value.name)),
      'creatorPartyId': creatorPartyId,
      'challengeType': challengeType,
      'partyWagerPools': partyWagerPools,
      'allowCrossPartyProofApproval': allowCrossPartyProofApproval,
      'partyApprovers': partyApprovers,
    });
    return baseMap;
  }

  factory MultiPartyChallenge.fromMap(Map<String, dynamic> data) {
    final baseChallenge = ChallengeState.fromMap(data);
    
    final partyInviteStatusData = data['partyInviteStatus'] as Map<String, dynamic>? ?? {};
    final partyInviteStatus = <String, PartyInviteStatus>{};
    
    partyInviteStatusData.forEach((partyId, statusString) {
      partyInviteStatus[partyId] = PartyInviteStatus.values.firstWhere(
        (status) => status.name == statusString,
        orElse: () => PartyInviteStatus.pending,
      );
    });

    return MultiPartyChallenge(
      id: baseChallenge.id,
      status: baseChallenge.status,
      startDate: baseChallenge.startDate,
      endDate: baseChallenge.endDate,
      lockedInMembers: baseChallenge.lockedInMembers,
      optedOutMembers: baseChallenge.optedOutMembers,
      wagers: baseChallenge.wagers,
      goalCompletions: baseChallenge.goalCompletions,
      payouts: baseChallenge.payouts,
      memberGoals: baseChallenge.memberGoals,
      participatingParties: List<String>.from(data['participatingParties'] ?? []),
      partyInviteStatus: partyInviteStatus,
      creatorPartyId: data['creatorPartyId'] ?? '',
      challengeType: data['challengeType'] ?? 'single-party',
      partyWagerPools: Map<String, double>.from(data['partyWagerPools'] ?? {}),
      allowCrossPartyProofApproval: data['allowCrossPartyProofApproval'] ?? false,
      partyApprovers: Map<String, List<String>>.from(
        data['partyApprovers']?.map((key, value) => 
          MapEntry(key, List<String>.from(value))) ?? {}),
    );
  }

  /// Create a MultiPartyChallenge from an existing single-party ChallengeState
  factory MultiPartyChallenge.fromSingleParty(ChallengeState challenge, String partyId) {
    return MultiPartyChallenge(
      id: challenge.id,
      status: challenge.status,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      lockedInMembers: challenge.lockedInMembers,
      optedOutMembers: challenge.optedOutMembers,
      wagers: challenge.wagers,
      goalCompletions: challenge.goalCompletions,
      payouts: challenge.payouts,
      memberGoals: challenge.memberGoals,
      participatingParties: [partyId],
      partyInviteStatus: {partyId: PartyInviteStatus.accepted},
      creatorPartyId: partyId,
      challengeType: 'single-party',
      partyWagerPools: {partyId: challenge.totalWagerPool},
      allowCrossPartyProofApproval: false,
      partyApprovers: {partyId: challenge.lockedInMembers},
    );
  }

  // Multi-party specific getters and methods
  bool get isMultiParty => challengeType == 'multi-party';
  bool get isSingleParty => challengeType == 'single-party';
  
  int get totalParticipatingParties => participatingParties.length;
  
  List<String> get acceptedParties => partyInviteStatus.entries
      .where((entry) => entry.value == PartyInviteStatus.accepted)
      .map((entry) => entry.key)
      .toList();
      
  List<String> get pendingParties => partyInviteStatus.entries
      .where((entry) => entry.value == PartyInviteStatus.pending)
      .map((entry) => entry.key)
      .toList();
      
  List<String> get declinedParties => partyInviteStatus.entries
      .where((entry) => entry.value == PartyInviteStatus.declined)
      .map((entry) => entry.key)
      .toList();

  bool isPartyParticipating(String partyId) => participatingParties.contains(partyId);
  
  bool hasPartyAccepted(String partyId) => 
      partyInviteStatus[partyId] == PartyInviteStatus.accepted;
      
  bool canPartyStart(String partyId) => 
      hasPartyAccepted(partyId) && status == ChallengeStatus.setup;

  /// Get all locked-in members from a specific party
  List<String> getPartyLockedInMembers(String partyId) {
    if (!isPartyParticipating(partyId)) return [];
    // This would need to be filtered by actual party membership
    // For now, returning all locked in members - would need party membership data
    return lockedInMembers;
  }

  /// Get total wager pool across all participating parties
  @override
  double get totalWagerPool {
    if (isMultiParty) {
      return partyWagerPools.values.fold(0.0, (total, pool) => total + pool);
    }
    return super.totalWagerPool;
  }

  /// Check if a user from one party can approve proofs from another party
  bool canUserApproveFromOtherParty(String userId, String targetPartyId) {
    if (!allowCrossPartyProofApproval) return false;
    return partyApprovers[targetPartyId]?.contains(userId) ?? false;
  }

  /// Invite a party to join this challenge
  MultiPartyChallenge inviteParty(String partyId) {
    if (isPartyParticipating(partyId)) return this;
    
    final updatedParties = List<String>.from(participatingParties)..add(partyId);
    final updatedInviteStatus = Map<String, PartyInviteStatus>.from(partyInviteStatus);
    updatedInviteStatus[partyId] = PartyInviteStatus.pending;
    
    return copyWith(
      participatingParties: updatedParties,
      partyInviteStatus: updatedInviteStatus,
      challengeType: updatedParties.length > 1 ? 'multi-party' : 'single-party',
    );
  }

  /// Accept a challenge invitation for a party
  MultiPartyChallenge acceptPartyInvite(String partyId) {
    if (!isPartyParticipating(partyId)) return this;
    
    final updatedInviteStatus = Map<String, PartyInviteStatus>.from(partyInviteStatus);
    updatedInviteStatus[partyId] = PartyInviteStatus.accepted;
    
    return copyWith(partyInviteStatus: updatedInviteStatus);
  }

  /// Decline a challenge invitation for a party
  MultiPartyChallenge declinePartyInvite(String partyId) {
    if (!isPartyParticipating(partyId)) return this;
    
    final updatedInviteStatus = Map<String, PartyInviteStatus>.from(partyInviteStatus);
    updatedInviteStatus[partyId] = PartyInviteStatus.declined;
    
    return copyWith(partyInviteStatus: updatedInviteStatus);
  }

  /// Remove a party from the challenge
  MultiPartyChallenge removeParty(String partyId) {
    if (!isPartyParticipating(partyId)) return this;
    
    final updatedParties = List<String>.from(participatingParties)..remove(partyId);
    final updatedInviteStatus = Map<String, PartyInviteStatus>.from(partyInviteStatus)
      ..remove(partyId);
    final updatedWagerPools = Map<String, double>.from(partyWagerPools)..remove(partyId);
    final updatedApprovers = Map<String, List<String>>.from(partyApprovers)..remove(partyId);
    
    return copyWith(
      participatingParties: updatedParties,
      partyInviteStatus: updatedInviteStatus,
      partyWagerPools: updatedWagerPools,
      partyApprovers: updatedApprovers,
      challengeType: updatedParties.length > 1 ? 'multi-party' : 'single-party',
    );
  }

  /// Update the wager pool for a specific party
  MultiPartyChallenge updatePartyWagerPool(String partyId, double amount) {
    final updatedWagerPools = Map<String, double>.from(partyWagerPools);
    updatedWagerPools[partyId] = amount;
    
    return copyWith(partyWagerPools: updatedWagerPools);
  }

  /// Enable or disable cross-party proof approval
  MultiPartyChallenge setCrossPartyApproval(bool enabled) {
    return copyWith(allowCrossPartyProofApproval: enabled);
  }

  /// Update the list of users who can approve proofs for a party
  MultiPartyChallenge updatePartyApprovers(String partyId, List<String> approvers) {
    final updatedApprovers = Map<String, List<String>>.from(partyApprovers);
    updatedApprovers[partyId] = approvers;
    
    return copyWith(partyApprovers: updatedApprovers);
  }
}

/// Status of a party's invitation to join a multi-party challenge
enum PartyInviteStatus {
  pending,    // Invitation sent, awaiting response
  accepted,   // Party has accepted the invitation
  declined,   // Party has declined the invitation
  expired,    // Invitation has expired
}