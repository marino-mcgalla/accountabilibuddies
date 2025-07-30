import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_challenge_repository.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/usecases/create_challenge_usecase.dart';
import '../../domain/usecases/participate_in_challenge_usecase.dart';
import '../../domain/usecases/get_current_challenge_usecase.dart';
import '../../domain/usecases/get_party_challenges_usecase.dart';
import '../../domain/usecases/start_challenge_usecase.dart';
import '../../../parties/data/repositories/firebase_party_repository.dart';
import 'proof_providers.dart';

// Repository providers
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final proofRepository = ref.watch(proofRepositoryProvider);
  return FirebaseChallengeRepository(proofRepository: proofRepository);
});

// Use case providers
final createChallengeUseCaseProvider = Provider<CreateChallengeUseCase>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  final partyRepository = FirebasePartyRepository(); // Direct instantiation for now
  return CreateChallengeUseCase(challengeRepository, partyRepository);
});

final participateInChallengeUseCaseProvider = Provider<ParticipateInChallengeUseCase>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  return ParticipateInChallengeUseCase(challengeRepository);
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

final currentChallengeProvider = StreamProvider.family<Challenge?, String>((ref, partyId) {
  final repository = ref.watch(challengeRepositoryProvider);
  
  return repository.watchChallenges(partyId).map((result) {
    return result.fold(
      onSuccess: (challenges) {
        // Find the first active challenge
        final activeChallenges = challenges.where((c) => c.status == ChallengeStatus.active).toList();
        return activeChallenges.isEmpty ? null : activeChallenges.first;
      },
      onFailure: (failure) => null,
    );
  });
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

final challengeParticipationsProvider = StreamProvider.family<List<UserChallengeParticipation>, String>((ref, challengeId) {
  final repository = ref.watch(challengeRepositoryProvider);
  
  return repository.watchChallengeParticipations(challengeId).map((result) {
    return result.fold(
      onSuccess: (participations) => participations,
      onFailure: (failure) => <UserChallengeParticipation>[],
    );
  });
});

final userParticipationProvider = StreamProvider.family<UserChallengeParticipation?, ({String challengeId, String userId})>((ref, params) {
  final repository = ref.watch(challengeRepositoryProvider);
  
  return repository.watchUserParticipation(params.challengeId, params.userId).map((result) {
    return result.fold(
      onSuccess: (participation) => participation,
      onFailure: (failure) => null,
    );
  });
});

