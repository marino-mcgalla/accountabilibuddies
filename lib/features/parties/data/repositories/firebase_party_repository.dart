import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/core.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_invite.dart';
import '../../domain/repositories/party_repository.dart';
import '../models/party_model.dart';
import '../models/party_invite_model.dart';

class FirebasePartyRepository implements PartyRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'parties';
  final String _invitesCollection = 'partyInvites';

  FirebasePartyRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<Party>>> getParties(String userId) async {
    try {
      logger.debug('FirebasePartyRepository: Getting parties for user $userId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('memberIds', arrayContains: userId)
          .where('status', isEqualTo: PartyStatus.active.name)
          .get();

      final parties = querySnapshot.docs
          .map((doc) => PartyModel.fromFirestore(doc).toEntity())
          .toList();

      logger.debug('FirebasePartyRepository: Retrieved ${parties.length} parties');
      return Result.success(parties);
    } catch (e, stackTrace) {
      logger.error('FirebasePartyRepository: Error getting parties', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Party>> getParty(String partyId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(partyId).get();
      
      if (!doc.exists) {
        return Result.failure(const NotFoundFailure(
          message: 'Party not found',
        ));
      }

      final party = PartyModel.fromFirestore(doc).toEntity();
      return Result.success(party);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Party>> createParty(Party party) async {
    try {
      logger.debug('FirebasePartyRepository: Creating party "${party.name}" for user ${party.ownerId}');
      
      final docRef = _firestore.collection(_collection).doc();
      final partyWithId = party.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final partyModel = PartyModel.fromEntity(partyWithId);
      await docRef.set(partyModel.toFirestore());

      logger.debug('FirebasePartyRepository: Party created successfully with ID ${partyWithId.id}');
      return Result.success(partyWithId);
    } catch (e, stackTrace) {
      logger.error('FirebasePartyRepository: Error creating party', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Party>> updateParty(Party party) async {
    try {
      final updatedParty = party.copyWith(updatedAt: DateTime.now());
      final partyModel = PartyModel.fromEntity(updatedParty);
      
      await _firestore
          .collection(_collection)
          .doc(party.id)
          .update(partyModel.toFirestore());

      return Result.success(updatedParty);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteParty(String partyId) async {
    try {
      await _firestore.collection(_collection).doc(partyId).delete();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Party>> joinParty(String userId, String inviteCode) async {
    try {
      logger.debug('FirebasePartyRepository: User $userId joining party with code $inviteCode');
      
      // Find party by invite code
      final partyResult = await getPartyByInviteCode(inviteCode);
      if (partyResult.isFailure) {
        return Result.failure(partyResult.failureOrNull!);
      }

      final party = partyResult.valueOrNull!;
      
      // Check if user is already a member
      if (party.isMember(userId)) {
        logger.debug('FirebasePartyRepository: User $userId already a member of party ${party.id}');
        return Result.success(party);
      }

      // Add user to member list
      final updatedMemberIds = [...party.memberIds, userId];
      final updatedParty = party.copyWith(
        memberIds: updatedMemberIds,
        updatedAt: DateTime.now(),
      );

      final updateResult = await updateParty(updatedParty);
      if (updateResult.isFailure) {
        return Result.failure(updateResult.failureOrNull!);
      }

      logger.debug('FirebasePartyRepository: User $userId successfully joined party ${party.id}');
      return Result.success(updatedParty);
    } catch (e, stackTrace) {
      logger.error('FirebasePartyRepository: Error joining party', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> leaveParty(String userId, String partyId) async {
    try {
      final partyResult = await getParty(partyId);
      if (partyResult.isFailure) {
        return Result.failure(partyResult.failureOrNull!);
      }

      final party = partyResult.valueOrNull!;
      
      // Don't allow owner to leave (they must delete the party)
      if (party.isOwner(userId)) {
        return Result.failure(const ValidationFailure(
          message: 'Party owner cannot leave. Delete the party instead.',
        ));
      }

      // Remove user from member list
      final updatedMemberIds = party.memberIds.where((id) => id != userId).toList();
      final updatedParty = party.copyWith(
        memberIds: updatedMemberIds,
        updatedAt: DateTime.now(),
      );

      final updateResult = await updateParty(updatedParty);
      if (updateResult.isFailure) {
        return Result.failure(updateResult.failureOrNull!);
      }

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Party>> removeMember(String partyId, String memberToRemove) async {
    try {
      final partyResult = await getParty(partyId);
      if (partyResult.isFailure) {
        return Result.failure(partyResult.failureOrNull!);
      }

      final party = partyResult.valueOrNull!;
      
      // Don't allow removing the owner
      if (party.isOwner(memberToRemove)) {
        return Result.failure(const ValidationFailure(
          message: 'Cannot remove party owner.',
        ));
      }

      // Remove member from list
      final updatedMemberIds = party.memberIds.where((id) => id != memberToRemove).toList();
      final updatedParty = party.copyWith(
        memberIds: updatedMemberIds,
        updatedAt: DateTime.now(),
      );

      final updateResult = await updateParty(updatedParty);
      if (updateResult.isFailure) {
        return Result.failure(updateResult.failureOrNull!);
      }

      return Result.success(updatedParty);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Party>> getPartyByInviteCode(String inviteCode) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('inviteCode', isEqualTo: inviteCode)
          .where('status', isEqualTo: PartyStatus.active.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Result.failure(const NotFoundFailure(
          message: 'Invalid invite code',
        ));
      }

      final party = PartyModel.fromFirestore(querySnapshot.docs.first).toEntity();
      return Result.success(party);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<Party>>> watchParties(String userId) {
    logger.debug('FirebasePartyRepository: Starting to watch parties for user $userId');
    
    return _firestore
        .collection(_collection)
        .where('memberIds', arrayContains: userId)
        .where('status', isEqualTo: PartyStatus.active.name)
        .snapshots()
        .map((snapshot) {
      try {
        logger.debug('FirebasePartyRepository: Received snapshot with ${snapshot.docs.length} parties');
        
        final parties = snapshot.docs
            .map((doc) {
              logger.debug('FirebasePartyRepository: Processing party ${doc.id}');
              return PartyModel.fromFirestore(doc).toEntity();
            })
            .toList();
            
        logger.debug('FirebasePartyRepository: Converted ${parties.length} parties');
        return Result.success(parties);
      } catch (e, stackTrace) {
        logger.error('FirebasePartyRepository: Error in watchParties', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<Party>> watchParty(String partyId) {
    return _firestore
        .collection(_collection)
        .doc(partyId)
        .snapshots()
        .map((doc) {
      try {
        if (!doc.exists) {
          return Result.failure(const NotFoundFailure(
            message: 'Party not found',
          ));
        }
        
        final party = PartyModel.fromFirestore(doc).toEntity();
        return Result.success(party);
      } catch (e, stackTrace) {
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Future<String> generateInviteCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    while (true) {
      // Generate 6-character code
      final code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))
      ));
      
      // Check if code already exists
      final existingParty = await getPartyByInviteCode(code);
      if (existingParty.isFailure) {
        // Code doesn't exist, we can use it
        return code;
      }
    }
  }

  @override
  Future<Result<PartyInvite>> sendInvite({
    required String partyId,
    required String inviterUserId,
    required String inviterName,
    required String inviteeEmail,
  }) async {
    try {
      logger.debug('FirebasePartyRepository: Sending invite from $inviterUserId to $inviteeEmail for party $partyId');
      
      // Get party details
      final partyResult = await getParty(partyId);
      if (partyResult.isFailure) {
        return Result.failure(partyResult.failureOrNull!);
      }
      
      final party = partyResult.valueOrNull!;
      
      // Check if user is already a member (by email - we'll need to implement user lookup by email)
      // For now, just check if there's already a pending invite
      final existingInviteQuery = await _firestore
          .collection(_invitesCollection)
          .where('partyId', isEqualTo: partyId)
          .where('inviteeEmail', isEqualTo: inviteeEmail.toLowerCase())
          .where('status', isEqualTo: PartyInviteStatus.pending.name)
          .limit(1)
          .get();
          
      if (existingInviteQuery.docs.isNotEmpty) {
        return Result.failure(const ValidationFailure(
          message: 'User already has a pending invite to this party',
        ));
      }
      
      // Create invite
      final docRef = _firestore.collection(_invitesCollection).doc();
      final invite = PartyInvite(
        id: docRef.id,
        partyId: partyId,
        partyName: party.name,
        inviterUserId: inviterUserId,
        inviterName: inviterName,
        inviteeEmail: inviteeEmail.toLowerCase(),
        inviteeUserId: null, // Will be set when user accepts
        status: PartyInviteStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)), // 7-day expiration
        metadata: {},
      );
      
      final inviteModel = PartyInviteModel.fromEntity(invite);
      await docRef.set(inviteModel.toFirestore());
      
      logger.debug('FirebasePartyRepository: Invite sent successfully with ID ${invite.id}');
      return Result.success(invite);
    } catch (e, stackTrace) {
      logger.error('FirebasePartyRepository: Error sending invite', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<PartyInvite>>> getPendingInvites(String userEmail) async {
    try {
      final normalizedEmail = userEmail.toLowerCase();
      
      final querySnapshot = await _firestore
          .collection(_invitesCollection)
          .where('inviteeEmail', isEqualTo: normalizedEmail)
          .where('status', isEqualTo: PartyInviteStatus.pending.name)
          .get();

      final invites = querySnapshot.docs
          .map((doc) => PartyInviteModel.fromFirestore(doc).toEntity())
          .where((invite) => invite.isValid)
          .toList();

      // Sort by createdAt descending (newest first) since we can't do it in the query
      invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Result.success(invites);
    } catch (e, stackTrace) {
      logger.error('FirebasePartyRepository: Error getting pending invites', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Party>> acceptInvite(String inviteId, String userId) async {
    try {
      // Get the invite
      final inviteDoc = await _firestore.collection(_invitesCollection).doc(inviteId).get();
      if (!inviteDoc.exists) {
        return Result.failure(const NotFoundFailure(
          message: 'Invite not found',
        ));
      }
      
      final invite = PartyInviteModel.fromFirestore(inviteDoc).toEntity();
      
      // Check if invite is still valid
      if (!invite.isValid) {
        return Result.failure(const ValidationFailure(
          message: 'Invite has expired or is no longer valid',
        ));
      }
      
      // Update invite status
      final updatedInvite = invite.copyWith(
        status: PartyInviteStatus.accepted,
        inviteeUserId: userId,
        respondedAt: DateTime.now(),
      );
      
      final updatedInviteModel = PartyInviteModel.fromEntity(updatedInvite);
      await _firestore.collection(_invitesCollection).doc(inviteId).update(updatedInviteModel.toFirestore());
      
      // Get the party to add user to
      final partyResult = await getParty(invite.partyId);
      if (partyResult.isFailure) {
        return Result.failure(partyResult.failureOrNull!);
      }
      
      final party = partyResult.valueOrNull!;
      
      // Check if user is already a member
      if (party.isMember(userId)) {
        return Result.success(party);
      }
      
      // Add user to member list
      final updatedMemberIds = [...party.memberIds, userId];
      final updatedParty = party.copyWith(
        memberIds: updatedMemberIds,
        updatedAt: DateTime.now(),
      );
      
      final updateResult = await updateParty(updatedParty);
      if (updateResult.isFailure) {
        return Result.failure(updateResult.failureOrNull!);
      }
      
      // Delete the invitation since it's been successfully accepted
      try {
        await _firestore.collection(_invitesCollection).doc(inviteId).delete();
        logger.debug('FirebasePartyRepository: Deleted accepted invitation $inviteId');
      } catch (e) {
        // Log but don't fail the operation since the user was successfully added to the party
        logger.warning('FirebasePartyRepository: Failed to delete accepted invitation $inviteId: $e');
      }
      
      return Result.success(updatedParty);
    } catch (e, stackTrace) {
      logger.error('FirebasePartyRepository: Error accepting invite', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> declineInvite(String inviteId) async {
    try {
      // Get the invite
      final inviteDoc = await _firestore.collection(_invitesCollection).doc(inviteId).get();
      if (!inviteDoc.exists) {
        return Result.failure(const NotFoundFailure(
          message: 'Invite not found',
        ));
      }
      
      final invite = PartyInviteModel.fromFirestore(inviteDoc).toEntity();
      
      // Update invite status
      final updatedInvite = invite.copyWith(
        status: PartyInviteStatus.declined,
        respondedAt: DateTime.now(),
      );
      
      // Delete the invitation instead of updating it since declined invites don't need to be kept
      await _firestore.collection(_invitesCollection).doc(inviteId).delete();
      logger.debug('FirebasePartyRepository: Deleted declined invitation $inviteId');
      
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  /// Cleanup expired invitations
  /// This method should be called periodically to remove expired invitations from the database
  Future<Result<int>> cleanupExpiredInvites() async {
    try {
      final now = DateTime.now();
      
      // Query for expired invitations
      final expiredInvitesQuery = await _firestore
          .collection(_invitesCollection)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .where('status', isEqualTo: PartyInviteStatus.pending.name)
          .get();
      
      // Delete all expired invitations in a batch
      final batch = _firestore.batch();
      for (final doc in expiredInvitesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      if (expiredInvitesQuery.docs.isNotEmpty) {
        await batch.commit();
        logger.debug('FirebasePartyRepository: Cleaned up ${expiredInvitesQuery.docs.length} expired invitations');
      }
      
      return Result.success(expiredInvitesQuery.docs.length);
    } catch (e, stackTrace) {
      logger.error('FirebasePartyRepository: Error cleaning up expired invites', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<PartyInvite>>> watchPendingInvites(String userEmail) {
    final normalizedEmail = userEmail.toLowerCase();
    
    return _firestore
        .collection(_invitesCollection)
        .where('inviteeEmail', isEqualTo: normalizedEmail)
        .where('status', isEqualTo: PartyInviteStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      try {
        final invites = snapshot.docs
            .map((doc) => PartyInviteModel.fromFirestore(doc).toEntity())
            .where((invite) => invite.isValid)
            .toList();
            
        // Sort by createdAt descending (newest first) since we can't do it in the query
        invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
        return Result.success(invites);
      } catch (e, stackTrace) {
        logger.error('FirebasePartyRepository: Error in watchPendingInvites', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  Failure _mapException(dynamic e, StackTrace stackTrace) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return AuthFailure(
            message: 'Permission denied. Please check your authentication.',
            code: e.code,
            originalError: e,
            stackTrace: stackTrace,
          );
        case 'unavailable':
          return NetworkFailure(
            message: 'Service unavailable. Please try again later.',
            code: e.code,
            originalError: e,
            stackTrace: stackTrace,
          );
        case 'not-found':
          return NotFoundFailure(
            message: 'Party not found.',
            code: e.code,
            originalError: e,
            stackTrace: stackTrace,
          );
        default:
          return UnknownFailure(
            message: e.message ?? 'An unknown error occurred.',
            originalError: e,
            stackTrace: stackTrace,
          );
      }
    }

    return UnknownFailure(
      message: 'An unexpected error occurred.',
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}