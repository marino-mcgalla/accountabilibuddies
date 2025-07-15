import 'package:cloud_firestore/cloud_firestore.dart';
import 'party_membership.dart';
import 'challenge_state.dart';

class MultiParty {
  final String id;
  final String name;
  final String leaderId;
  final List<String> members;
  final int memberCount;
  final String challengeDuration;
  final String startDay;
  final String? currentChallengeId;
  final ChallengeState? activeChallenge;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final Map<String, dynamic> settings;

  const MultiParty({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.members,
    required this.memberCount,
    required this.challengeDuration,
    required this.startDay,
    this.currentChallengeId,
    this.activeChallenge,
    required this.createdAt,
    required this.lastActivityAt,
    required this.settings,
  });

  factory MultiParty.create({
    required String leaderId,
    required String name,
    String challengeDuration = 'weekly',
    String startDay = 'monday',
  }) {
    return MultiParty(
      id: '', // Will be set by Firestore
      name: name,
      leaderId: leaderId,
      members: [leaderId],
      memberCount: 1,
      challengeDuration: challengeDuration,
      startDay: startDay,
      currentChallengeId: null,
      activeChallenge: null,
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
      settings: {
        'allowMemberInvites': false,
        'autoStartChallenges': false,
        'reminderNotifications': true,
      },
    );
  }

  factory MultiParty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    ChallengeState? activeChallenge;
    if (data['activeChallenge'] != null) {
      try {
        activeChallenge = ChallengeState.fromMap(data['activeChallenge'] as Map<String, dynamic>);
      } catch (e) {
        activeChallenge = null;
      }
    }

    return MultiParty(
      id: doc.id,
      name: data['name'] ?? '',
      leaderId: data['leaderId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      challengeDuration: data['challengeDuration'] ?? 'weekly',
      startDay: data['startDay'] ?? 'monday',
      currentChallengeId: data['currentChallengeId'],
      activeChallenge: activeChallenge,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'name': name,
      'leaderId': leaderId,
      'members': members,
      'memberCount': memberCount,
      'challengeDuration': challengeDuration,
      'startDay': startDay,
      'currentChallengeId': currentChallengeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      'settings': settings,
    };
    
    if (activeChallenge != null) {
      data['activeChallenge'] = activeChallenge!.toMap();
    }
    
    return data;
  }

  MultiParty copyWith({
    String? id,
    String? name,
    String? leaderId,
    List<String>? members,
    int? memberCount,
    String? challengeDuration,
    String? startDay,
    String? currentChallengeId,
    ChallengeState? activeChallenge,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    Map<String, dynamic>? settings,
  }) {
    return MultiParty(
      id: id ?? this.id,
      name: name ?? this.name,
      leaderId: leaderId ?? this.leaderId,
      members: members ?? this.members,
      memberCount: memberCount ?? this.memberCount,
      challengeDuration: challengeDuration ?? this.challengeDuration,
      startDay: startDay ?? this.startDay,
      currentChallengeId: currentChallengeId ?? this.currentChallengeId,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      settings: settings ?? this.settings,
    );
  }

  // Member management methods
  MultiParty addMember(String userId) {
    if (members.contains(userId)) return this;
    
    final newMembers = List<String>.from(members)..add(userId);
    return copyWith(
      members: newMembers,
      memberCount: newMembers.length,
      lastActivityAt: DateTime.now(),
    );
  }

  MultiParty removeMember(String userId) {
    if (!members.contains(userId)) return this;
    
    final newMembers = List<String>.from(members)..remove(userId);
    return copyWith(
      members: newMembers,
      memberCount: newMembers.length,
      lastActivityAt: DateTime.now(),
    );
  }

  MultiParty transferLeadership(String newLeaderId) {
    if (!members.contains(newLeaderId)) {
      throw ArgumentError('New leader must be a party member');
    }
    
    return copyWith(
      leaderId: newLeaderId,
      lastActivityAt: DateTime.now(),
    );
  }

  MultiParty updateActivity() {
    return copyWith(lastActivityAt: DateTime.now());
  }

  // Utility methods
  bool isMember(String userId) => members.contains(userId);
  bool isLeader(String userId) => leaderId == userId;
  bool get hasActiveChallenge => activeChallenge != null;
  bool get canAddMembers => memberCount < 10; // Max 10 members per party
  
  // Challenge utility methods
  bool get hasChallengeInSetup => activeChallenge?.isSetup ?? false;
  bool get hasChallengeActive => activeChallenge?.isActive ?? false;
  bool get hasChallengeCompleted => activeChallenge?.isCompleted ?? false;
  
  bool isUserLockedIn(String userId) => activeChallenge?.isUserLockedIn(userId) ?? false;
  bool isUserOptedOut(String userId) => activeChallenge?.isUserOptedOut(userId) ?? false;
  double getUserWager(String userId) => activeChallenge?.getUserWager(userId) ?? 0.0;
  
  double get totalWagerPool => activeChallenge?.totalWagerPool ?? 0.0;
  List<String> get lockedInMembers => activeChallenge?.lockedInMembers ?? [];
  List<String> get optedOutMembers => activeChallenge?.optedOutMembers ?? [];
  
  bool get canStartChallenge => activeChallenge?.canStart ?? false;
  
  String get startDayDisplayName {
    switch (startDay.toLowerCase()) {
      case 'monday':
        return 'Monday';
      case 'tuesday':
        return 'Tuesday';
      case 'wednesday':
        return 'Wednesday';
      case 'thursday':
        return 'Thursday';
      case 'friday':
        return 'Friday';
      case 'saturday':
        return 'Saturday';
      case 'sunday':
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  String get challengeDurationDisplayName {
    switch (challengeDuration.toLowerCase()) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Weekly';
    }
  }

  // Settings helpers
  bool get allowMemberInvites => settings['allowMemberInvites'] ?? false;
  bool get autoStartChallenges => settings['autoStartChallenges'] ?? false;
  bool get reminderNotifications => settings['reminderNotifications'] ?? true;

  MultiParty updateSettings(Map<String, dynamic> newSettings) {
    final updatedSettings = Map<String, dynamic>.from(settings);
    updatedSettings.addAll(newSettings);
    
    return copyWith(
      settings: updatedSettings,
      lastActivityAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MultiParty &&
        other.id == id &&
        other.name == name &&
        other.leaderId == leaderId &&
        other.memberCount == memberCount &&
        other.challengeDuration == challengeDuration &&
        other.startDay == startDay;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      leaderId,
      memberCount,
      challengeDuration,
      startDay,
    );
  }

  @override
  String toString() {
    return 'MultiParty(id: $id, name: $name, members: $memberCount, leader: $leaderId)';
  }
}