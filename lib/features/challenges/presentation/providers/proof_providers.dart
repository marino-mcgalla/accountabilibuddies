import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_proof_repository.dart';
import '../../domain/entities/proof_submission.dart';
import '../../domain/repositories/proof_repository.dart';
import '../../domain/services/proof_approval_service.dart';
import '../providers/challenge_providers.dart';

// Repository provider
final proofRepositoryProvider = Provider<ProofRepository>((ref) {
  return FirebaseProofRepository();
});

// Stream providers for proofs
final challengeProofsProvider = StreamProvider.family<List<ProofSubmission>, String>((ref, challengeId) {
  final repository = ref.watch(proofRepositoryProvider);
  
  return repository.watchProofsForChallenge(challengeId).map((result) {
    return result.fold(
      onSuccess: (proofs) => proofs,
      onFailure: (failure) => <ProofSubmission>[],
    );
  });
});

final pendingProofsProvider = StreamProvider.family<List<ProofSubmission>, String>((ref, challengeId) {
  final repository = ref.watch(proofRepositoryProvider);
  
  return repository.watchPendingProofs(challengeId).map((result) {
    return result.fold(
      onSuccess: (proofs) => proofs,
      onFailure: (failure) => <ProofSubmission>[],
    );
  });
});

final pendingProofsByUserProvider = StreamProvider.family<Map<String, List<ProofSubmission>>, String>((ref, challengeId) {
  final repository = ref.watch(proofRepositoryProvider);
  
  return repository.watchPendingProofsByUser(challengeId).map((result) {
    return result.fold(
      onSuccess: (proofsByUser) => proofsByUser,
      onFailure: (failure) => <String, List<ProofSubmission>>{},
    );
  });
});

final participantProofsProvider = StreamProvider.family<List<ProofSubmission>, String>((ref, participationId) {
  final repository = ref.watch(proofRepositoryProvider);
  
  // For now, we'll need to get this via a future provider since we don't have a stream method
  // This could be optimized later with a proper stream method
  return Stream.fromFuture(
    repository.getProofsForParticipant(participationId).then((result) {
      return result.fold(
        onSuccess: (proofs) => proofs,
        onFailure: (failure) => <ProofSubmission>[],
      );
    }),
  );
});

// Proof approval service provider
final proofApprovalServiceProvider = Provider<ProofApprovalService>((ref) {
  final proofRepository = ref.watch(proofRepositoryProvider);
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  
  return ProofApprovalService(
    proofRepository: proofRepository,
    challengeRepository: challengeRepository,
  );
});