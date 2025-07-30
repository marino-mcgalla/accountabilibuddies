import '../../../../core/error/result.dart';
import '../entities/party.dart';
import '../entities/party_invite.dart';

abstract class PartyRepository {
  /// Get all parties for a user (where user is a member)
  Future<Result<List<Party>>> getParties(String userId);

  /// Get a specific party by ID
  Future<Result<Party>> getParty(String partyId);

  /// Create a new party
  Future<Result<Party>> createParty(Party party);

  /// Update an existing party
  Future<Result<Party>> updateParty(Party party);

  /// Delete a party (only owner can delete)
  Future<Result<void>> deleteParty(String partyId);

  /// Join a party using invite code
  Future<Result<Party>> joinParty(String userId, String inviteCode);

  /// Leave a party
  Future<Result<void>> leaveParty(String userId, String partyId);

  /// Remove a member from party (only owner can remove)
  Future<Result<Party>> removeMember(String partyId, String memberToRemove);

  /// Find party by invite code
  Future<Result<Party>> getPartyByInviteCode(String inviteCode);

  /// Watch parties for real-time updates
  Stream<Result<List<Party>>> watchParties(String userId);

  /// Watch a specific party for real-time updates
  Stream<Result<Party>> watchParty(String partyId);

  /// Generate a unique invite code
  Future<String> generateInviteCode();

  /// Send an invite to someone via email
  Future<Result<PartyInvite>> sendInvite({
    required String partyId,
    required String inviterUserId,
    required String inviterName,
    required String inviteeEmail,
  });

  /// Get pending invites for a user (by their email or userId)
  Future<Result<List<PartyInvite>>> getPendingInvites(String userEmail);

  /// Accept a party invite
  Future<Result<Party>> acceptInvite(String inviteId, String userId);

  /// Decline a party invite
  Future<Result<void>> declineInvite(String inviteId);

  /// Watch pending invites for real-time updates
  Stream<Result<List<PartyInvite>>> watchPendingInvites(String userEmail);

  /// Watch sent invites for real-time updates
  Stream<Result<List<PartyInvite>>> watchSentInvites(String userId);

  /// Cleanup expired invitations
  Future<Result<int>> cleanupExpiredInvites();
}