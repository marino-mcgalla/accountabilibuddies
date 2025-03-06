// In a separate file: /lib/features/party/models/party_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Party {
  final String id;
  final String createdBy;
  final String partyOwner;
  final List<String> members;
  final String partyName;
  final DateTime? createdAt;
  final int challengeStartDay;
  final Map<String, dynamic>? activeChallenge;

  Party({
    this.id = '',
    required this.createdBy,
    required this.partyOwner,
    required this.members,
    required this.partyName,
    this.createdAt,
    this.challengeStartDay = 1,
    this.activeChallenge,
  });

  // Factory method to easily create new parties
  factory Party.create(String userId, String partyName) {
    return Party(
      createdBy: userId,
      partyOwner: userId,
      members: [userId],
      partyName: partyName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'partyOwner': partyOwner,
      'members': members,
      'partyName': partyName,
      'createdAt': FieldValue.serverTimestamp(),
      'challengeStartDay': challengeStartDay,
      'activeChallenge': activeChallenge,
    };
  }
}
