import 'package:equatable/equatable.dart';

enum PartyStatus {
  active,
  inactive,
}

class Party extends Equatable {
  final String id;
  final String name;
  final String description;
  final String ownerId;  // User who created the party
  final List<String> memberIds;  // All members including owner
  final String inviteCode;  // Unique code for joining
  final PartyStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const Party({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.memberIds,
    required this.inviteCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
  });

  /// Check if a user is the owner/leader
  bool isOwner(String userId) => ownerId == userId;
  
  /// Check if a user is the party leader (alias for isOwner)
  bool isLeader(String userId) => isOwner(userId);

  /// Check if a user is a member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Get member count
  int get memberCount => memberIds.length;
  
  /// Get the party leader's ID
  String get leaderId => ownerId;
  
  /// Check if the party can start challenges (has leader and members)
  bool get canStartChallenges => memberIds.length >= 2; // At least leader + 1 member

  Party copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<String>? memberIds,
    String? inviteCode,
    PartyStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        ownerId,
        memberIds,
        inviteCode,
        status,
        createdAt,
        updatedAt,
        metadata,
      ];
}