import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_goal_repository.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../../auth/auth.dart';
import '../../../auth/models/user_stats.dart';
import '../../../../core/logging/logger_service.dart';

// Repository provider
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return FirebaseGoalRepository();
});

// Goals list provider
final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  final user = ref.watch(userProvider);
  
  // logger.debug('GoalsProvider: user = ${user?.id}');
  
  if (user == null) {
    // logger.debug('GoalsProvider: No user, returning empty list');
    return Stream.value(<Goal>[]);
  }
  
  // logger.debug('GoalsProvider: Watching goals for user ${user.id}');
  
  return repository.watchGoals(user.id).map((result) {
    return result.fold(
      onSuccess: (goals) {
        // logger.debug('GoalsProvider: Received ${goals.length} goals');
        return goals;
      },
      onFailure: (failure) {
        logger.error('GoalsProvider: Error loading goals', error: failure);
        return <Goal>[];
      },
    );
  });
});

// Active goals provider
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.when(
    data: (goalList) => goalList.where((goal) => goal.status == GoalStatus.active).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Completed goals provider
final completedGoalsProvider = Provider<List<Goal>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.when(
    data: (goalList) => goalList.where((goal) => goal.status == GoalStatus.completed).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Goals by category provider
final goalsByCategoryProvider = Provider.family<List<Goal>, GoalCategory>((ref, category) {
  final goals = ref.watch(goalsProvider);
  return goals.when(
    data: (goalList) => goalList.where((goal) => goal.category == category).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Individual goal provider
final goalProvider = StreamProvider.family<Goal?, String>((ref, goalId) {
  final repository = ref.watch(goalRepositoryProvider);
  
  return repository.watchGoal(goalId).map((result) {
    return result.fold(
      onSuccess: (goal) => goal,
      onFailure: (failure) => null,
    );
  });
});

// User statistics provider (from denormalized data)
final userStatsProvider = StreamProvider<UserStats>((ref) {
  final repository = ref.watch(goalRepositoryProvider) as FirebaseGoalRepository;
  final user = ref.watch(userProvider);
  
  if (user == null) {
    return Stream.value(UserStats.initial());
  }
  
  return repository.watchUserStats(user.id).map((result) {
    return result.fold(
      onSuccess: (stats) => stats,
      onFailure: (failure) {
        // Log error and return initial stats
        return UserStats.initial();
      },
    );
  });
});

// Goal controller for actions
final goalControllerProvider = Provider<GoalController>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  final user = ref.watch(userProvider);
  return GoalController(repository: repository, userId: user?.id ?? '');
});

class GoalController {
  final GoalRepository repository;
  final String userId;

  GoalController({
    required this.repository,
    required this.userId,
  });

  Future<bool> createGoal({
    required String title,
    required String description,
    required GoalCategory category,
    required GoalType goalType,
    required int targetFrequency,
    DateTime? dueDate,
    List<String> tags = const [],
    List<String> partyIds = const [],
  }) async {
    final goal = Goal(
      id: '', // Will be set by repository
      userId: userId,
      title: title,
      description: description,
      category: category,
      goalType: goalType,
      status: GoalStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueDate: dueDate,
      targetFrequency: targetFrequency,
      currentCount: 0,
      tags: tags,
      partyIds: partyIds,
      metadata: {},
    );

    final result = await repository.createGoal(goal);
    return result.isSuccess;
  }

  Future<bool> updateGoal(Goal goal) async {
    final result = await repository.updateGoal(goal);
    return result.isSuccess;
  }

  Future<bool> deleteGoal(String goalId) async {
    final result = await repository.deleteGoal(goalId);
    return result.isSuccess;
  }

  Future<bool> updateProgress(String goalId, int currentCount) async {
    final result = await repository.updateProgress(goalId, currentCount);
    return result.isSuccess;
  }

  Future<bool> completeGoal(String goalId) async {
    final result = await repository.completeGoal(goalId);
    return result.isSuccess;
  }
}

