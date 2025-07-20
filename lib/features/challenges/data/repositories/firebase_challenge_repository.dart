import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/core.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_commitment.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../models/challenge_model.dart';
import '../models/challenge_commitment_model.dart';

class FirebaseChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;
  final String _challengesCollection = 'challenges';
  final String _commitmentsCollection = 'challengeCommitments';

  FirebaseChallengeRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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
      // Delete all commitments first
      final commitmentsQuery = await _firestore
          .collection(_commitmentsCollection)
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final batch = _firestore.batch();
      
      // Delete all commitments
      for (final doc in commitmentsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the challenge
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
          .where('status', whereIn: [ChallengeStatus.pending.name, ChallengeStatus.active.name])
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
  Future<Result<List<ChallengeCommitment>>> getChallengeCommitments(String challengeId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_commitmentsCollection)
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final commitments = querySnapshot.docs
          .map((doc) => ChallengeCommitmentModel.fromFirestore(doc).toEntity())
          .toList();

      return Result.success(commitments);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ChallengeCommitment?>> getUserCommitment(String challengeId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_commitmentsCollection)
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Result.success(null);
      }

      final commitment = ChallengeCommitmentModel.fromFirestore(querySnapshot.docs.first).toEntity();
      return Result.success(commitment);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ChallengeCommitment>> saveCommitment(ChallengeCommitment commitment) async {
    try {
      final docRef = commitment.id.isEmpty 
          ? _firestore.collection(_commitmentsCollection).doc()
          : _firestore.collection(_commitmentsCollection).doc(commitment.id);
      
      final commitmentWithId = commitment.copyWith(
        id: docRef.id,
        updatedAt: DateTime.now(),
      );
      
      final commitmentModel = ChallengeCommitmentModel.fromEntity(commitmentWithId);
      await docRef.set(commitmentModel.toFirestore());

      return Result.success(commitmentWithId);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteCommitment(String commitmentId) async {
    try {
      await _firestore.collection(_commitmentsCollection).doc(commitmentId).delete();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<ChallengeCommitment>>> watchChallengeCommitments(String challengeId) {
    return _firestore
        .collection(_commitmentsCollection)
        .where('challengeId', isEqualTo: challengeId)
        .snapshots()
        .map((snapshot) {
      try {
        final commitments = snapshot.docs
            .map((doc) => ChallengeCommitmentModel.fromFirestore(doc).toEntity())
            .toList();
            
        return Result.success(commitments);
      } catch (e, stackTrace) {
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<ChallengeCommitment?>> watchUserCommitment(String challengeId, String userId) {
    return _firestore
        .collection(_commitmentsCollection)
        .where('challengeId', isEqualTo: challengeId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          return Result.success(null);
        }
        
        final commitment = ChallengeCommitmentModel.fromFirestore(snapshot.docs.first).toEntity();
        return Result.success(commitment);
      } catch (e, stackTrace) {
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Future<Result<Challenge>> startChallenge(String challengeId) async {
    try {
      final challengeResult = await getChallenge(challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.active,
        updatedAt: DateTime.now(),
      );

      return await updateChallenge(updatedChallenge);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Challenge>> completeChallenge(String challengeId) async {
    try {
      final challengeResult = await getChallenge(challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.settling,
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
      final challengeResult = await getChallenge(challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      return await updateChallenge(updatedChallenge);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Challenge>> settleChallenge(String challengeId) async {
    try {
      final challengeResult = await getChallenge(challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.completed,
        updatedAt: DateTime.now(),
      );

      return await updateChallenge(updatedChallenge);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
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