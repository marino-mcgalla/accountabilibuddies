import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/core.dart';
import '../../domain/entities/proof_submission.dart';
import '../../domain/repositories/proof_repository.dart';
import '../models/proof_submission_model.dart';

class FirebaseProofRepository implements ProofRepository {
  final FirebaseFirestore _firestore;
  final String _proofsCollection = 'proofSubmissions';

  FirebaseProofRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<ProofSubmission>> submitProof(ProofSubmission proof) async {
    try {
      logger.debug('FirebaseProofRepository: Submitting proof for user ${proof.userId}');
      
      final docRef = _firestore.collection(_proofsCollection).doc();
      final proofWithId = proof.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final proofModel = ProofSubmissionModel.fromEntity(proofWithId);
      await docRef.set(proofModel.toFirestore());

      logger.debug('FirebaseProofRepository: Proof submitted successfully with ID ${proofWithId.id}');
      return Result.success(proofWithId);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error submitting proof', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ProofSubmission>> getProof(String proofId) async {
    try {
      final doc = await _firestore.collection(_proofsCollection).doc(proofId).get();
      
      if (!doc.exists) {
        return Result.failure(const NotFoundFailure(
          message: 'Proof not found',
        ));
      }

      final proof = ProofSubmissionModel.fromFirestore(doc).toEntity();
      return Result.success(proof);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<ProofSubmission>>> getProofsForChallenge(String challengeId) async {
    try {
      logger.debug('FirebaseProofRepository: Getting proofs for challenge $challengeId');
      
      // Query all proofs and filter by challenge ID in the challengeGoalStates
      final querySnapshot = await _firestore
          .collection(_proofsCollection)
          .orderBy('submissionDate', descending: true)
          .get();

      final proofs = querySnapshot.docs
          .map((doc) => ProofSubmissionModel.fromFirestore(doc).toEntity())
          .where((proof) => proof.challengeIds.contains(challengeId))
          .toList();

      logger.debug('FirebaseProofRepository: Retrieved ${proofs.length} proofs for challenge');
      return Result.success(proofs);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error getting proofs for challenge', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<ProofSubmission>>> getProofsForParticipant(String participationId) async {
    try {
      logger.debug('FirebaseProofRepository: Getting proofs for participant $participationId');
      
      // Query all proofs and filter by participation ID in the challengeGoalStates
      final querySnapshot = await _firestore
          .collection(_proofsCollection)
          .orderBy('submissionDate', descending: true)
          .get();

      final proofs = querySnapshot.docs
          .map((doc) => ProofSubmissionModel.fromFirestore(doc).toEntity())
          .where((proof) => proof.challengeGoalStates.values.any((state) => state.participationId == participationId))
          .toList();

      logger.debug('FirebaseProofRepository: Retrieved ${proofs.length} proofs for participant');
      return Result.success(proofs);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error getting proofs for participant', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<ProofSubmission>>> getProofsForUser(String userId) async {
    try {
      logger.debug('FirebaseProofRepository: Getting proofs for user $userId');
      
      final querySnapshot = await _firestore
          .collection(_proofsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('submissionDate', descending: true)
          .get();

      final proofs = querySnapshot.docs
          .map((doc) => ProofSubmissionModel.fromFirestore(doc).toEntity())
          .toList();

      logger.debug('FirebaseProofRepository: Retrieved ${proofs.length} proofs for user');
      return Result.success(proofs);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error getting proofs for user', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<ProofSubmission>>> getPendingProofs(String challengeId) async {
    try {
      logger.debug('FirebaseProofRepository: Getting pending proofs for challenge $challengeId');
      
      // Query all proofs and filter for those with pending status for this challenge
      final querySnapshot = await _firestore
          .collection(_proofsCollection)
          .orderBy('createdAt', descending: false)
          .get();

      final proofs = querySnapshot.docs
          .map((doc) => ProofSubmissionModel.fromFirestore(doc).toEntity())
          .where((proof) {
            return proof.challengeGoalStates.values.any((state) => 
              state.challengeId == challengeId && state.status == ProofStatus.pending);
          })
          .toList();

      logger.debug('FirebaseProofRepository: Retrieved ${proofs.length} pending proofs');
      return Result.success(proofs);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error getting pending proofs', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Map<String, List<ProofSubmission>>>> getPendingProofsByUser(String challengeId) async {
    try {
      logger.debug('FirebaseProofRepository: Getting pending proofs by user for challenge $challengeId');
      
      final proofResult = await getPendingProofs(challengeId);
      if (proofResult.isFailure) {
        return Result.failure(proofResult.failureOrNull!);
      }

      final proofs = proofResult.valueOrNull!;
      final proofsByUser = <String, List<ProofSubmission>>{};

      for (final proof in proofs) {
        final userId = proof.userId;
        if (!proofsByUser.containsKey(userId)) {
          proofsByUser[userId] = [];
        }
        proofsByUser[userId]!.add(proof);
      }

      logger.debug('FirebaseProofRepository: Retrieved pending proofs for ${proofsByUser.length} users');
      return Result.success(proofsByUser);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error getting pending proofs by user', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ProofSubmission>> updateProofStatusFor(String proofId, String challengeId, String goalTemplateId, ProofStatus status) async {
    try {
      logger.debug('FirebaseProofRepository: Updating proof $proofId status to ${status.name} for challenge $challengeId goal $goalTemplateId');
      
      final proofResult = await getProof(proofId);
      if (proofResult.isFailure) {
        return Result.failure(proofResult.failureOrNull!);
      }

      final proof = proofResult.valueOrNull!;
      final key = '$challengeId:$goalTemplateId';
      final currentState = proof.challengeGoalStates[key];
      
      if (currentState == null) {
        return Result.failure(const ValidationFailure(
          message: 'Proof does not have state for this challenge/goal combination',
        ));
      }

      final updatedState = currentState.copyWith(status: status);
      final updatedStates = Map<String, ChallengeGoalProofState>.from(proof.challengeGoalStates);
      updatedStates[key] = updatedState;
      
      final updatedProof = proof.copyWith(
        challengeGoalStates: updatedStates,
        updatedAt: DateTime.now(),
      );
      
      final updatedModel = ProofSubmissionModel.fromEntity(updatedProof);
      await _firestore.collection(_proofsCollection).doc(proofId).set(updatedModel.toFirestore());

      return Result.success(updatedProof);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error updating proof status', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ProofSubmission>> addProofApprovalFor(String proofId, String challengeId, String goalTemplateId, ProofApproval approval) async {
    try {
      logger.debug('FirebaseProofRepository: Adding approval to proof $proofId for challenge $challengeId goal $goalTemplateId');
      
      final proofResult = await getProof(proofId);
      if (proofResult.isFailure) {
        return Result.failure(proofResult.failureOrNull!);
      }

      final proof = proofResult.valueOrNull!;
      final updatedProof = proof.addApprovalFor(challengeId, goalTemplateId, approval);
      final updatedModel = ProofSubmissionModel.fromEntity(updatedProof);

      await _firestore.collection(_proofsCollection).doc(proofId).set(updatedModel.toFirestore());

      logger.debug('FirebaseProofRepository: Added approval to proof $proofId');
      return Result.success(updatedProof);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error adding proof approval', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ProofSubmission>> markProofAsViewedFor(String proofId, String challengeId, String goalTemplateId, String userId) async {
    try {
      logger.debug('FirebaseProofRepository: Marking proof $proofId as viewed by $userId for challenge $challengeId goal $goalTemplateId');
      
      final proofResult = await getProof(proofId);
      if (proofResult.isFailure) {
        return Result.failure(proofResult.failureOrNull!);
      }

      final proof = proofResult.valueOrNull!;
      final updatedProof = proof.markAsViewedByFor(userId, challengeId, goalTemplateId);
      
      if (updatedProof == proof) {
        // Already viewed, no need to update
        return Result.success(proof);
      }

      final updatedModel = ProofSubmissionModel.fromEntity(updatedProof);
      await _firestore.collection(_proofsCollection).doc(proofId).set(updatedModel.toFirestore());

      logger.debug('FirebaseProofRepository: Marked proof $proofId as viewed by $userId');
      return Result.success(updatedProof);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error marking proof as viewed', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  // Backward compatibility methods
  
  @override
  Future<Result<ProofSubmission>> updateProofStatus(String proofId, ProofStatus status) async {
    try {
      final proofResult = await getProof(proofId);
      if (proofResult.isFailure) {
        return Result.failure(proofResult.failureOrNull!);
      }

      final proof = proofResult.valueOrNull!;
      if (proof.challengeGoalStates.isEmpty) {
        return Result.failure(const ValidationFailure(
          message: 'Proof has no challenge/goal states',
        ));
      }
      
      // Use first challenge/goal for backward compatibility
      final firstKey = proof.challengeGoalStates.keys.first;
      final parts = firstKey.split(':');
      
      return await updateProofStatusFor(proofId, parts[0], parts[1], status);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error updating proof status (backward compatibility)', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ProofSubmission>> addProofApproval(String proofId, ProofApproval approval) async {
    try {
      final proofResult = await getProof(proofId);
      if (proofResult.isFailure) {
        return Result.failure(proofResult.failureOrNull!);
      }

      final proof = proofResult.valueOrNull!;
      if (proof.challengeGoalStates.isEmpty) {
        return Result.failure(const ValidationFailure(
          message: 'Proof has no challenge/goal states',
        ));
      }
      
      // Use first challenge/goal for backward compatibility
      final firstKey = proof.challengeGoalStates.keys.first;
      final parts = firstKey.split(':');
      
      return await addProofApprovalFor(proofId, parts[0], parts[1], approval);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error adding proof approval (backward compatibility)', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ProofSubmission>> markProofAsViewed(String proofId, String userId) async {
    try {
      final proofResult = await getProof(proofId);
      if (proofResult.isFailure) {
        return Result.failure(proofResult.failureOrNull!);
      }

      final proof = proofResult.valueOrNull!;
      if (proof.challengeGoalStates.isEmpty) {
        return Result.failure(const ValidationFailure(
          message: 'Proof has no challenge/goal states',
        ));
      }
      
      // Use first challenge/goal for backward compatibility
      final firstKey = proof.challengeGoalStates.keys.first;
      final parts = firstKey.split(':');
      
      return await markProofAsViewedFor(proofId, parts[0], parts[1], userId);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error marking proof as viewed (backward compatibility)', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteProof(String proofId) async {
    try {
      logger.debug('FirebaseProofRepository: Deleting proof $proofId');
      
      await _firestore.collection(_proofsCollection).doc(proofId).delete();
      
      logger.debug('FirebaseProofRepository: Deleted proof $proofId');
      return Result.success(null);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error deleting proof', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteProofsForChallenge(String challengeId) async {
    try {
      logger.debug('FirebaseProofRepository: Deleting all proofs for challenge $challengeId');
      
      // Get all proofs and filter client-side since challengeId is now stored in challengeGoalStates map
      final querySnapshot = await _firestore
          .collection(_proofsCollection)
          .get();
      
      // Convert to entities and filter for the specific challenge
      final allProofs = querySnapshot.docs
          .map((doc) => ProofSubmissionModel.fromFirestore(doc).toEntity())
          .toList();
      
      final challengeProofsToDelete = allProofs
          .where((proof) => proof.challengeIds.contains(challengeId))
          .toList();
      
      logger.debug('FirebaseProofRepository: Found ${challengeProofsToDelete.length} proofs to delete (out of ${allProofs.length} total proofs)');
      
      if (challengeProofsToDelete.isEmpty) {
        logger.debug('FirebaseProofRepository: No proofs found for challenge $challengeId');
        return Result.success(null);
      }
      
      // Delete all proofs for this challenge in a batch
      final batch = _firestore.batch();
      for (final proof in challengeProofsToDelete) {
        final docRef = _firestore.collection(_proofsCollection).doc(proof.id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      
      logger.debug('FirebaseProofRepository: Successfully deleted ${challengeProofsToDelete.length} proofs for challenge $challengeId');
      return Result.success(null);
    } catch (e, stackTrace) {
      logger.error('FirebaseProofRepository: Error deleting proofs for challenge', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<ProofSubmission>>> watchProofsForChallenge(String challengeId) {
    logger.debug('FirebaseProofRepository: Starting to watch proofs for challenge $challengeId');
    
    // Since challengeId is now stored in challengeGoalStates map, we need to query all proofs
    // and filter client-side. For better performance, we could create a composite index later.
    return _firestore
        .collection(_proofsCollection)
        .orderBy('submissionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        logger.debug('FirebaseProofRepository: Received proofs snapshot with ${snapshot.docs.length} total proofs');
        
        final allProofs = snapshot.docs
            .map((doc) => ProofSubmissionModel.fromFirestore(doc).toEntity())
            .toList();
        
        // Filter by challenge ID using the new structure
        final challengeProofs = allProofs
            .where((proof) => proof.challengeIds.contains(challengeId))
            .toList();
            
        logger.debug('FirebaseProofRepository: Filtered to ${challengeProofs.length} proofs for challenge $challengeId');
        return Result.success(challengeProofs);
      } catch (e, stackTrace) {
        logger.error('FirebaseProofRepository: Error in watchProofsForChallenge', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<List<ProofSubmission>>> watchPendingProofs(String challengeId) {
    logger.debug('FirebaseProofRepository: Starting to watch pending proofs for challenge $challengeId');
    
    // Query all proofs and filter client-side for pending status in specific challenge
    return _firestore
        .collection(_proofsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      try {
        logger.debug('FirebaseProofRepository: Received proofs snapshot with ${snapshot.docs.length} total proofs');
        
        final allProofs = snapshot.docs
            .map((doc) => ProofSubmissionModel.fromFirestore(doc).toEntity())
            .toList();
        
        // Filter for proofs that have pending status for this specific challenge
        final pendingProofs = allProofs.where((proof) {
          return proof.challengeGoalStates.values.any((state) => 
            state.challengeId == challengeId && state.status == ProofStatus.pending
          );
        }).toList();
            
        logger.debug('FirebaseProofRepository: Filtered to ${pendingProofs.length} pending proofs for challenge $challengeId');
        return Result.success(pendingProofs);
      } catch (e, stackTrace) {
        logger.error('FirebaseProofRepository: Error in watchPendingProofs', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<Map<String, List<ProofSubmission>>>> watchPendingProofsByUser(String challengeId) {
    logger.debug('FirebaseProofRepository: Starting to watch pending proofs by user for challenge $challengeId');
    
    return watchPendingProofs(challengeId).map((result) {
      if (result.isFailure) {
        return Result.failure(result.failureOrNull!);
      }

      final proofs = result.valueOrNull!;
      final proofsByUser = <String, List<ProofSubmission>>{};

      for (final proof in proofs) {
        final userId = proof.userId;
        if (!proofsByUser.containsKey(userId)) {
          proofsByUser[userId] = [];
        }
        proofsByUser[userId]!.add(proof);
      }

      return Result.success(proofsByUser);
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
            message: 'Proof not found.',
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