import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_challenge_repository.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_commitment.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/usecases/create_challenge_usecase.dart';
import '../../domain/usecases/commit_to_challenge_usecase.dart';
import '../../domain/usecases/get_current_challenge_usecase.dart';
import '../../domain/usecases/get_party_challenges_usecase.dart';
import '../../domain/usecases/start_challenge_usecase.dart';
import '../../../parties/data/repositories/firebase_party_repository.dart';

// Repository provider
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return FirebaseChallengeRepository();
});

// Use case providers
final createChallengeUseCaseProvider = Provider<CreateChallengeUseCase>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  final partyRepository = FirebasePartyRepository(); // Direct instantiation for now
  return CreateChallengeUseCase(challengeRepository, partyRepository);
});

final commitToChallengeUseCaseProvider = Provider<CommitToChallengeUseCase>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  return CommitToChallengeUseCase(challengeRepository);
});

final getCurrentChallengeUseCaseProvider = Provider<GetCurrentChallengeUseCase>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  return GetCurrentChallengeUseCase(challengeRepository);
});

final getPartyChallengesUseCaseProvider = Provider<GetPartyChallengesUseCase>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  return GetPartyChallengesUseCase(challengeRepository);
});

final startChallengeUseCaseProvider = Provider<StartChallengeUseCase>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  final partyRepository = FirebasePartyRepository(); // Direct instantiation for now
  return StartChallengeUseCase(challengeRepository, partyRepository);
});

// Stream providers for challenges
final partyChallengesProvider = StreamProvider.family<List<Challenge>, String>((ref, partyId) {
  final repository = ref.watch(challengeRepositoryProvider);
  
  return repository.watchChallenges(partyId).map((result) {
    return result.fold(
      onSuccess: (challenges) => challenges,
      onFailure: (failure) => <Challenge>[],
    );
  });
});

final currentChallengeProvider = FutureProvider.family<Challenge?, String>((ref, partyId) async {
  final useCase = ref.watch(getCurrentChallengeUseCaseProvider);
  final result = await useCase.call(partyId);
  
  return result.fold(
    onSuccess: (challenge) => challenge,
    onFailure: (failure) => null,
  );
});

final challengeProvider = StreamProvider.family<Challenge?, String>((ref, challengeId) {
  final repository = ref.watch(challengeRepositoryProvider);
  
  return repository.watchChallenge(challengeId).map((result) {
    return result.fold(
      onSuccess: (challenge) => challenge,
      onFailure: (failure) => null,
    );
  });
});

final challengeCommitmentsProvider = StreamProvider.family<List<ChallengeCommitment>, String>((ref, challengeId) {
  final repository = ref.watch(challengeRepositoryProvider);
  
  return repository.watchChallengeCommitments(challengeId).map((result) {
    return result.fold(
      onSuccess: (commitments) => commitments,
      onFailure: (failure) => <ChallengeCommitment>[],
    );
  });
});

final userCommitmentProvider = StreamProvider.family<ChallengeCommitment?, ({String challengeId, String userId})>((ref, params) {
  final repository = ref.watch(challengeRepositoryProvider);
  
  return repository.watchUserCommitment(params.challengeId, params.userId).map((result) {
    return result.fold(
      onSuccess: (commitment) => commitment,
      onFailure: (failure) => null,
    );
  });
});