import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/core.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/repositories/proof_repository.dart';
import '../models/challenge_model.dart';
import '../models/user_challenge_participation_model.dart';

class FirebaseChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;
  final ProofRepository _proofRepository;
  final String _challengesCollection = 'challenges';
  final String _participantsSubcollection = 'participants';

  FirebaseChallengeRepository({
    FirebaseFirestore? firestore,
    required ProofRepository proofRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _proofRepository = proofRepository;

  @override
  Future<Result<List<Challenge>>> getChallenges(String partyId) async {
    try {
      logger.debug('FirebaseChallengeRepository: Getting challenges for party $partyId');
      
      final querySnapshot = await _firestore
          .collection(_challengesCollection)
          .where('partyId', isEqualTo: partyId)
          .get();

      final challenges = querySnapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc).toEntity())
          .toList();

      // Sort by creation date descending (newest first)
      challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      logger.debug('FirebaseChallengeRepository: Retrieved ${challenges.length} challenges');
      return Result.success(challenges);
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error getting challenges', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Challenge>> getChallenge(String challengeId) async {
    try {
      final doc = await _firestore.collection(_challengesCollection).doc(challengeId).get();
      
      if (!doc.exists) {
        return Result.failure(const NotFoundFailure(
          message: 'Challenge not found',
        ));
      }

      final challenge = ChallengeModel.fromFirestore(doc).toEntity();
      return Result.success(challenge);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Challenge>> createChallenge(Challenge challenge) async {
    try {
      logger.debug('FirebaseChallengeRepository: Creating challenge "${challenge.name}" for party ${challenge.partyId}');
      
      final docRef = _firestore.collection(_challengesCollection).doc();
      final challengeWithId = challenge.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final challengeModel = ChallengeModel.fromEntity(challengeWithId);
      await docRef.set(challengeModel.toFirestore());

      logger.debug('FirebaseChallengeRepository: Challenge created successfully with ID ${challengeWithId.id}');
      return Result.success(challengeWithId);
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error creating challenge', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Challenge>> updateChallenge(Challenge challenge) async {
    try {
      final updatedChallenge = challenge.copyWith(updatedAt: DateTime.now());
      final challengeModel = ChallengeModel.fromEntity(updatedChallenge);
      
      await _firestore
          .collection(_challengesCollection)
          .doc(challenge.id)
          .update(challengeModel.toFirestore());

      return Result.success(updatedChallenge);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteChallenge(String challengeId) async {
    try {
      // Delete all participants in the subcollection first
      final participantsQuery = await _firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_participantsSubcollection)
          .get();

      final batch = _firestore.batch();
      
      // Delete all participants from the subcollection
      for (final doc in participantsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the challenge document itself
      batch.delete(_firestore.collection(_challengesCollection).doc(challengeId));
      
      await batch.commit();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Challenge?>> getCurrentChallenge(String partyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_challengesCollection)
          .where('partyId', isEqualTo: partyId)
          .where('status', isEqualTo: ChallengeStatus.active.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Result.success(null);
      }

      final challenge = ChallengeModel.fromFirestore(querySnapshot.docs.first).toEntity();
      return Result.success(challenge);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<Challenge>>> watchChallenges(String partyId) {
    logger.debug('FirebaseChallengeRepository: Starting to watch challenges for party $partyId');
    
    return _firestore
        .collection(_challengesCollection)
        .where('partyId', isEqualTo: partyId)
        .snapshots()
        .map((snapshot) {
      try {
        logger.debug('FirebaseChallengeRepository: Received snapshot with ${snapshot.docs.length} challenges');
        
        final challenges = snapshot.docs
            .map((doc) => ChallengeModel.fromFirestore(doc).toEntity())
            .toList();
            
        // Sort by creation date descending (newest first)
        challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
        logger.debug('FirebaseChallengeRepository: Converted ${challenges.length} challenges');
        return Result.success(challenges);
      } catch (e, stackTrace) {
        logger.error('FirebaseChallengeRepository: Error in watchChallenges', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<Challenge>> watchChallenge(String challengeId) {
    return _firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .snapshots()
        .map((doc) {
      try {
        if (!doc.exists) {
          return Result.failure(const NotFoundFailure(
            message: 'Challenge not found',
          ));
        }
        
        final challenge = ChallengeModel.fromFirestore(doc).toEntity();
        return Result.success(challenge);
      } catch (e, stackTrace) {
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Future<Result<List<UserChallengeParticipation>>> getChallengeParticipations(String challengeId) async {
    try {
      logger.debug('FirebaseChallengeRepository: Getting all participations for challenge $challengeId');
      
      final querySnapshot = await _firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_participantsSubcollection)
          .get();

      final participations = querySnapshot.docs
          .map((doc) => UserChallengeParticipationModel.fromFirestore(doc).toEntity())
          .toList();

      logger.debug('FirebaseChallengeRepository: Retrieved ${participations.length} participations');
      return Result.success(participations);
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error getting challenge participations', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<UserChallengeParticipation?>> getUserParticipation(String challengeId, String userId) async {
    try {
      logger.debug('FirebaseChallengeRepository: Getting user participation for user $userId in challenge $challengeId');
      
      final doc = await _firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_participantsSubcollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        logger.debug('FirebaseChallengeRepository: No participation found for user $userId in challenge $challengeId');
        return Result.success(null);
      }

      final participation = UserChallengeParticipationModel.fromFirestore(doc).toEntity();
      logger.debug('FirebaseChallengeRepository: Found participation for user $userId with status ${participation.status}');
      return Result.success(participation);
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error getting user participation', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<UserChallengeParticipation>> saveParticipation(UserChallengeParticipation participation) async {
    try {
      // Use userId as document ID in the participants subcollection
      final docRef = _firestore
          .collection(_challengesCollection)
          .doc(participation.challengeId)
          .collection(_participantsSubcollection)
          .doc(participation.userId);
      
      final participationWithId = participation.copyWith(
        id: participation.userId, // Use userId as the ID
        updatedAt: DateTime.now(),
      );
      
      final participationModel = UserChallengeParticipationModel.fromEntity(participationWithId);
      await docRef.set(participationModel.toFirestore());

      // Update challenge total pool after saving participation
      await _updateChallengePool(participation.challengeId);

      logger.debug('FirebaseChallengeRepository: Saved participation for user ${participation.userId} in challenge ${participation.challengeId}');
      return Result.success(participationWithId);
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error saving participation', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteParticipation(String challengeId, String userId) async {
    try {
      logger.debug('FirebaseChallengeRepository: Deleting participation for user $userId in challenge $challengeId');
      
      await _firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_participantsSubcollection)
          .doc(userId)
          .delete();
      
      // Update challenge total pool after deleting participation
      await _updateChallengePool(challengeId);
      
      logger.debug('FirebaseChallengeRepository: Deleted participation for user $userId');
      return Result.success(null);
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error deleting participation', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<UserChallengeParticipation>>> watchChallengeParticipations(String challengeId) {
    logger.debug('FirebaseChallengeRepository: Starting to watch participations for challenge $challengeId');
    
    return _firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .collection(_participantsSubcollection)
        .snapshots()
        .map((snapshot) {
      try {
        logger.debug('FirebaseChallengeRepository: Received participations snapshot with ${snapshot.docs.length} participants');
        
        final participations = snapshot.docs
            .map((doc) => UserChallengeParticipationModel.fromFirestore(doc).toEntity())
            .toList();
            
        logger.debug('FirebaseChallengeRepository: Converted ${participations.length} participations');
        return Result.success(participations);
      } catch (e, stackTrace) {
        logger.error('FirebaseChallengeRepository: Error in watchChallengeParticipations', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<UserChallengeParticipation?>> watchUserParticipation(String challengeId, String userId) {
    logger.debug('FirebaseChallengeRepository: Starting to watch user participation for user $userId in challenge $challengeId');
    
    return _firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .collection(_participantsSubcollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      try {
        if (!doc.exists) {
          logger.debug('FirebaseChallengeRepository: No participation document exists for user $userId');
          return Result.success(null);
        }
        
        final participation = UserChallengeParticipationModel.fromFirestore(doc).toEntity();
        logger.debug('FirebaseChallengeRepository: Received participation update for user $userId with status ${participation.status}');
        return Result.success(participation);
      } catch (e, stackTrace) {
        logger.error('FirebaseChallengeRepository: Error in watchUserParticipation', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Future<Result<Challenge>> moveToSummary(String challengeId) async {
    try {
      final challengeResult = await getChallenge(challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.summary,
        updatedAt: DateTime.now(),
      );

      return await updateChallenge(updatedChallenge);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Challenge>> cancelChallenge(String challengeId) async {
    try {
      logger.debug('FirebaseChallengeRepository: Cancelling challenge $challengeId');
      
      final challengeResult = await getChallenge(challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;
      
      // Delete all proof submissions for this challenge
      logger.debug('FirebaseChallengeRepository: Deleting proofs for cancelled challenge $challengeId');
      final deleteProofsResult = await _proofRepository.deleteProofsForChallenge(challengeId);
      if (deleteProofsResult.isFailure) {
        logger.error('FirebaseChallengeRepository: Failed to delete proofs for challenge $challengeId');
        // Log the error but continue with challenge cancellation
        // This ensures the challenge is still cancelled even if proof deletion fails
      } else {
        logger.debug('FirebaseChallengeRepository: Successfully deleted proofs for challenge $challengeId');
      }
      
      // Update challenge status to cancelled
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      final updateResult = await updateChallenge(updatedChallenge);
      if (updateResult.isSuccess) {
        logger.debug('FirebaseChallengeRepository: Successfully cancelled challenge $challengeId');
      }
      
      return updateResult;
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error cancelling challenge', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  /// Updates the challenge's total pool by calculating sum of all participant wagers
  Future<void> _updateChallengePool(String challengeId) async {
    try {
      logger.debug('FirebaseChallengeRepository: Updating total pool for challenge $challengeId');
      
      // Get all participants for this challenge
      final participantsSnapshot = await _firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_participantsSubcollection)
          .get();

      // Calculate total pool from all participant wagers
      double totalPool = 0.0;
      for (final doc in participantsSnapshot.docs) {
        final participation = UserChallengeParticipationModel.fromFirestore(doc);
        if (participation.wagerAmount != null) {
          totalPool += participation.wagerAmount!;
        }
      }

      // Update the challenge document with the new total pool
      await _firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .update({
            'totalPool': totalPool,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      logger.debug('FirebaseChallengeRepository: Updated total pool to \$${totalPool.toStringAsFixed(2)} for challenge $challengeId');
    } catch (e, stackTrace) {
      logger.error('FirebaseChallengeRepository: Error updating challenge pool', error: e, stackTrace: stackTrace);
      // Don't throw - this is a background operation that shouldn't fail the main operation
    }
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
            message: 'Challenge not found.',
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