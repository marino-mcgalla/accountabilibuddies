import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_party_repository.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_invite.dart';
import '../../domain/repositories/party_repository.dart';
import '../../../auth/auth.dart';
import '../../../../core/logging/logger_service.dart';

// Repository provider
final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return FirebasePartyRepository();
});

// Parties list provider
final partiesProvider = StreamProvider<List<Party>>((ref) {
  final repository = ref.watch(partyRepositoryProvider);
  final user = ref.watch(userProvider);
  
  logger.debug('PartiesProvider: user = ${user?.id}');
  
  if (user == null) {
    logger.debug('PartiesProvider: No user, returning empty list');
    return Stream.value(<Party>[]);
  }
  
  logger.debug('PartiesProvider: Watching parties for user ${user.id}');
  
  return repository.watchParties(user.id).map((result) {
    return result.fold(
      onSuccess: (parties) {
        logger.debug('PartiesProvider: Received ${parties.length} parties');
        return parties;
      },
      onFailure: (failure) {
        logger.error('PartiesProvider: Error loading parties', error: failure);
        return <Party>[];
      },
    );
  });
});

// Individual party provider
final partyProvider = StreamProvider.family<Party?, String>((ref, partyId) {
  final repository = ref.watch(partyRepositoryProvider);
  
  return repository.watchParty(partyId).map((result) {
    return result.fold(
      onSuccess: (party) => party,
      onFailure: (failure) => null,
    );
  });
});

// Pending invites provider (invites received by the user)
final pendingInvitesProvider = StreamProvider<List<PartyInvite>>((ref) {
  final repository = ref.watch(partyRepositoryProvider);
  final user = ref.watch(userProvider);
  
  if (user == null) {
    logger.debug('PendingInvitesProvider: No user found');
    return Stream.value(<PartyInvite>[]);
  }
  
  return repository.watchPendingInvites(user.email).map((result) {
    return result.fold(
      onSuccess: (invites) => invites,
      onFailure: (failure) {
        logger.error('PendingInvitesProvider: Error loading invites', error: failure);
        return <PartyInvite>[];
      },
    );
  });
});

// Sent invites provider (invites sent by the user)
final sentInvitesProvider = StreamProvider<List<PartyInvite>>((ref) {
  final repository = ref.watch(partyRepositoryProvider);
  final user = ref.watch(userProvider);
  
  if (user == null) {
    logger.debug('SentInvitesProvider: No user found');
    return Stream.value(<PartyInvite>[]);
  }
  
  return repository.watchSentInvites(user.id).map((result) {
    return result.fold(
      onSuccess: (invites) => invites,
      onFailure: (failure) {
        logger.error('SentInvitesProvider: Error loading sent invites', error: failure);
        return <PartyInvite>[];
      },
    );
  });
});

// Combined invites provider (both sent and received)
final allInvitesProvider = StreamProvider<List<PartyInvite>>((ref) {
  final receivedInvitesAsync = ref.watch(pendingInvitesProvider);
  final sentInvitesAsync = ref.watch(sentInvitesProvider);
  
  // Combine both lists
  final receivedInvites = receivedInvitesAsync.valueOrNull ?? [];
  final sentInvites = sentInvitesAsync.valueOrNull ?? [];
  
  // Return combined list
  return Stream.value([...receivedInvites, ...sentInvites]);
});

// Party controller for actions
final partyControllerProvider = Provider<PartyController>((ref) {
  final repository = ref.watch(partyRepositoryProvider);
  final user = ref.watch(userProvider);
  return PartyController(
    repository: repository,
    user: user,
  );
});

class PartyController {
  final PartyRepository repository;
  final UserModel? user;

  PartyController({
    required this.repository,
    required this.user,
  });

  String get userId => user?.id ?? '';

  Future<bool> createParty({
    required String name,
    required String description,
  }) async {
    final inviteCode = await repository.generateInviteCode();
    
    final party = Party(
      id: '', // Will be set by repository
      name: name,
      description: description,
      ownerId: userId,
      memberIds: [userId], // Owner is automatically a member
      inviteCode: inviteCode,
      status: PartyStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {},
    );

    final result = await repository.createParty(party);
    return result.isSuccess;
  }

  Future<String?> createPartyAndGetId({
    required String name,
    required String description,
  }) async {
    final inviteCode = await repository.generateInviteCode();
    
    final party = Party(
      id: '', // Will be set by repository
      name: name,
      description: description,
      ownerId: userId,
      memberIds: [userId], // Owner is automatically a member
      inviteCode: inviteCode,
      status: PartyStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {},
    );

    final result = await repository.createParty(party);
    return result.fold(
      onSuccess: (createdParty) => createdParty.id,
      onFailure: (_) => null,
    );
  }

  Future<bool> joinParty(String inviteCode) async {
    final result = await repository.joinParty(userId, inviteCode);
    return result.isSuccess;
  }

  Future<bool> leaveParty(String partyId) async {
    final result = await repository.leaveParty(userId, partyId);
    return result.isSuccess;
  }

  Future<bool> deleteParty(String partyId) async {
    final result = await repository.deleteParty(partyId);
    return result.isSuccess;
  }

  Future<bool> removeMember(String partyId, String memberToRemove) async {
    final result = await repository.removeMember(partyId, memberToRemove);
    return result.isSuccess;
  }

  Future<bool> updateParty(Party party) async {
    final result = await repository.updateParty(party);
    return result.isSuccess;
  }

  Future<bool> transferOwnership(String partyId, String newOwnerId) async {
    final party = await getParty(partyId);
    if (party == null) return false;

    // Only current owner can transfer ownership
    if (party.ownerId != userId) return false;

    // New owner must be a party member
    if (!party.memberIds.contains(newOwnerId)) return false;

    // Update party with new owner
    final updatedParty = party.copyWith(
      ownerId: newOwnerId,
      updatedAt: DateTime.now(),
    );

    final result = await repository.updateParty(updatedParty);
    return result.isSuccess;
  }

  Future<Party?> getParty(String partyId) async {
    final result = await repository.getParty(partyId);
    return result.fold(
      onSuccess: (party) => party,
      onFailure: (failure) => null,
    );
  }

  Future<Party?> getPartyByInviteCode(String inviteCode) async {
    final result = await repository.getPartyByInviteCode(inviteCode);
    return result.fold(
      onSuccess: (party) => party,
      onFailure: (failure) => null,
    );
  }

  Future<bool> sendInvite({
    required String partyId,
    required String inviteeEmail,
  }) async {
    if (user == null) return false;
    
    final result = await repository.sendInvite(
      partyId: partyId,
      inviterUserId: user!.id,
      inviterName: user!.displayName ?? user!.email,
      inviteeEmail: inviteeEmail,
    );
    return result.isSuccess;
  }

  Future<bool> acceptInvite(String inviteId) async {
    if (user == null) return false;
    
    final result = await repository.acceptInvite(inviteId, user!.id);
    return result.isSuccess;
  }

  Future<bool> declineInvite(String inviteId) async {
    final result = await repository.declineInvite(inviteId);
    return result.isSuccess;
  }
}