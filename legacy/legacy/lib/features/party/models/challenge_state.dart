import 'package:cloud_firestore/cloud_firestore.dart';
import '../../goals/models/goal_model.dart';

enum ChallengeStatus {
  setup,     // Party leader is setting up, members can adjust goals
  active,    // Challenge is running, proofs can be submitted
  completed, // Week ended, calculating results
  payout,    // Results calculated, payouts determined
}

class ChallengeState {
  final String id;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> lockedInMembers;
  final List<String> optedOutMembers;
  final Map<String, double> wagers; // userId -> wager amount
  final Map<String, bool> goalCompletions; // userId -> completed all goals
  final Map<String, double> payouts; // userId -> amount won/owed
  final Map<String, List<Goal>> memberGoals; // userId -> locked-in goals for this challenge

  const ChallengeState({
    required this.id,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.lockedInMembers = const [],
    this.optedOutMembers = const [],
    this.wagers = const {},
    this.goalCompletions = const {},
    this.payouts = const {},
    this.memberGoals = const {},
  });

  ChallengeState copyWith({
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
  }) {
    return ChallengeState(
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'lockedInMembers': lockedInMembers,
      'optedOutMembers': optedOutMembers,
      'wagers': wagers,
      'goalCompletions': goalCompletions,
      'payouts': payouts,
      'memberGoals': memberGoals.map((userId, goals) => 
          MapEntry(userId, goals.map((goal) => goal.toMap()).toList())),
    };
  }

  factory ChallengeState.fromMap(Map<String, dynamic> data) {
    final memberGoalsData = data['memberGoals'] as Map<String, dynamic>? ?? {};
    final memberGoals = <String, List<Goal>>{};
    
    memberGoalsData.forEach((userId, goalsData) {
      if (goalsData is List) {
        memberGoals[userId] = goalsData
            .map((goalData) => Goal.fromMap(Map<String, dynamic>.from(goalData)))
            .toList();
      }
    });

    return ChallengeState(
      id: data['id'],
      status: ChallengeStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ChallengeStatus.setup,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      lockedInMembers: List<String>.from(data['lockedInMembers'] ?? []),
      optedOutMembers: List<String>.from(data['optedOutMembers'] ?? []),
      wagers: Map<String, double>.from(data['wagers'] ?? {}),
      goalCompletions: Map<String, bool>.from(data['goalCompletions'] ?? {}),
      payouts: Map<String, double>.from(data['payouts'] ?? {}),
      memberGoals: memberGoals,
    );
  }

  // Helper methods
  bool get isSetup => status == ChallengeStatus.setup;
  bool get isActive => status == ChallengeStatus.active;
  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isPayout => status == ChallengeStatus.payout;
  
  // Challenge is active for a specific user if they are locked in
  bool isActiveForUser(String userId) => isUserLockedIn(userId) && (status == ChallengeStatus.setup || status == ChallengeStatus.active);

  bool isUserLockedIn(String userId) => lockedInMembers.contains(userId);
  bool isUserOptedOut(String userId) => optedOutMembers.contains(userId);
  
  double getUserWager(String userId) => wagers[userId] ?? 0.0;
  bool didUserCompleteGoals(String userId) => goalCompletions[userId] ?? false;
  double getUserPayout(String userId) => payouts[userId] ?? 0.0;
  List<Goal> getUserGoals(String userId) => memberGoals[userId] ?? [];

  double get totalWagerPool {
    return wagers.values.fold(0.0, (total, wager) => total + wager);
  }

  List<String> get completedMembers {
    return goalCompletions.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> get failedMembers {
    return goalCompletions.entries
        .where((entry) => entry.value == false)
        .map((entry) => entry.key)
        .toList();
  }

  bool get canStart {
    return status == ChallengeStatus.setup && lockedInMembers.isNotEmpty;
  }

  bool get canComplete {
    return status == ChallengeStatus.active && DateTime.now().isAfter(endDate);
  }

  ChallengeState lockInUser(String userId, double wagerAmount) {
    if (isUserLockedIn(userId)) return this;
    
    final updatedMembers = List<String>.from(lockedInMembers)..add(userId);
    final updatedWagers = Map<String, double>.from(wagers);
    updatedWagers[userId] = wagerAmount;

    return copyWith(
      lockedInMembers: updatedMembers,
      wagers: updatedWagers,
    );
  }

  ChallengeState optOutUser(String userId) {
    if (isUserOptedOut(userId)) return this;
    
    final updatedOptedOut = List<String>.from(optedOutMembers)..add(userId);
    final updatedLockedIn = List<String>.from(lockedInMembers)..remove(userId);
    final updatedWagers = Map<String, double>.from(wagers)..remove(userId);

    return copyWith(
      optedOutMembers: updatedOptedOut,
      lockedInMembers: updatedLockedIn,
      wagers: updatedWagers,
    );
  }
}