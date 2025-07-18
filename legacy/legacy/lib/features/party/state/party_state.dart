class PartyState {
  final String? partyId;
  final String? partyName;
  final String? partyLeaderId;
  final List<String> members;
  final Map<String, Map<String, dynamic>> memberDetails;
  final bool isLoading;
  final int challengeStartDay;
  final Map<String, dynamic>? activeChallenge;
  final List<String> optedOutMembers;

  const PartyState({
    this.partyId,
    this.partyName,
    this.partyLeaderId,
    this.members = const [],
    this.memberDetails = const {},
    this.isLoading = false,
    this.challengeStartDay = 1,
    this.activeChallenge,
    this.optedOutMembers = const [],
  });

  PartyState copyWith({
    String? partyId,
    String? partyName,
    String? partyLeaderId,
    List<String>? members,
    Map<String, Map<String, dynamic>>? memberDetails,
    bool? isLoading,
    int? challengeStartDay,
    Map<String, dynamic>? activeChallenge,
    List<String>? optedOutMembers,
  }) {
    return PartyState(
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      partyLeaderId: partyLeaderId ?? this.partyLeaderId,
      members: members ?? this.members,
      memberDetails: memberDetails ?? this.memberDetails,
      isLoading: isLoading ?? this.isLoading,
      challengeStartDay: challengeStartDay ?? this.challengeStartDay,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      optedOutMembers: optedOutMembers ?? this.optedOutMembers,
    );
  }

  bool get hasParty => partyId != null;
  bool get hasActiveChallenge => activeChallenge != null && activeChallenge?['state'] == 'active';
  bool get hasPendingChallenge => activeChallenge != null && activeChallenge?['state'] == 'preparation';
  bool get hasAnyChallenge => activeChallenge != null;
  
  List<String> get lockedInMembers => hasAnyChallenge
      ? List<String>.from(activeChallenge?['lockedInMembers'] ?? [])
      : [];
  
  Map<String, dynamic> get memberWagers => hasAnyChallenge
      ? (activeChallenge!['wagers'] as Map<String, dynamic>? ?? {})
      : {};

  double getTotalWagerPool() {
    if (!hasAnyChallenge) return 0;
    double total = 0;
    memberWagers.forEach((userId, amount) {
      total += (amount is num) ? amount.toDouble() : 0;
    });
    return total;
  }

  double getMemberWager(String userId) {
    if (!hasAnyChallenge) return 0;
    return memberWagers[userId]?.toDouble() ?? 0;
  }
}