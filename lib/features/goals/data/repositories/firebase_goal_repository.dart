import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/core.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../models/goal_model.dart';
import '../../../auth/models/user_stats.dart';

class FirebaseGoalRepository implements GoalRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'goals';

  FirebaseGoalRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<Goal>>> getGoals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final goals = querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toEntity())
          .toList();

      return Result.success(goals);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<Goal>>> getGoalsByStatus(String userId, GoalStatus status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status.name)
          .orderBy('updatedAt', descending: true)
          .get();

      final goals = querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toEntity())
          .toList();

      return Result.success(goals);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<Goal>>> getGoalsByCategory(String userId, GoalCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.name)
          .orderBy('updatedAt', descending: true)
          .get();

      final goals = querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toEntity())
          .toList();

      return Result.success(goals);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Goal>> getGoal(String goalId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(goalId).get();
      
      if (!doc.exists) {
        return Result.failure(const NotFoundFailure(
          message: 'Goal not found',
        ));
      }

      final goal = GoalModel.fromFirestore(doc).toEntity();
      return Result.success(goal);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Goal>> createGoal(Goal goal) async {
    try {
      logger.debug('FirebaseGoalRepository: Creating goal "${goal.title}" for user ${goal.userId}');
      
      final batch = _firestore.batch();
      
      // Create goal document
      final goalRef = _firestore.collection(_collection).doc();
      final goalWithId = goal.copyWith(
        id: goalRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      logger.debug('FirebaseGoalRepository: Goal will be saved with ID ${goalWithId.id}');
      
      final goalModel = GoalModel.fromEntity(goalWithId);
      final goalData = goalModel.toFirestore();
      
      logger.debug('FirebaseGoalRepository: Goal data: $goalData');
      
      batch.set(goalRef, goalData);

      // Update user stats
      final userRef = _firestore.collection('users').doc(goal.userId);
      await _updateUserStatsOnGoalCreate(batch, userRef, goalWithId);
      
      await batch.commit();
      
      logger.debug('FirebaseGoalRepository: Goal created successfully with ID ${goalWithId.id}');
      return Result.success(goalWithId);
    } catch (e, stackTrace) {
      logger.error('FirebaseGoalRepository: Error creating goal', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Goal>> updateGoal(Goal goal) async {
    try {
      final updatedGoal = goal.copyWith(updatedAt: DateTime.now());
      final goalModel = GoalModel.fromEntity(updatedGoal);
      
      await _firestore
          .collection(_collection)
          .doc(goal.id)
          .update(goalModel.toFirestore());

      return Result.success(updatedGoal);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteGoal(String goalId) async {
    try {
      await _firestore.collection(_collection).doc(goalId).delete();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Goal>> updateProgress(String goalId, int currentCount) async {
    try {
      final goalResult = await getGoal(goalId);
      if (goalResult.isFailure) {
        return Result.failure(goalResult.failureOrNull!);
      }

      final goal = goalResult.valueOrNull!;
      final updatedGoal = goal.copyWith(
        currentCount: currentCount,
        updatedAt: DateTime.now(),
        status: currentCount >= goal.targetFrequency ? GoalStatus.completed : goal.status,
        completedAt: currentCount >= goal.targetFrequency ? DateTime.now() : goal.completedAt,
      );

      return await updateGoal(updatedGoal);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Goal>> completeGoal(String goalId) async {
    try {
      final goalResult = await getGoal(goalId);
      if (goalResult.isFailure) {
        return Result.failure(goalResult.failureOrNull!);
      }

      final goal = goalResult.valueOrNull!;
      final completedGoal = goal.copyWith(
        status: GoalStatus.completed,
        currentCount: goal.targetFrequency,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      
      // Update goal
      final goalRef = _firestore.collection(_collection).doc(goalId);
      final goalModel = GoalModel.fromEntity(completedGoal);
      batch.update(goalRef, goalModel.toFirestore());

      // Update user stats
      final userRef = _firestore.collection('users').doc(goal.userId);
      await _updateUserStatsOnGoalComplete(batch, userRef, completedGoal);
      
      await batch.commit();
      return Result.success(completedGoal);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<Goal>>> watchGoals(String userId) {
    logger.debug('FirebaseGoalRepository: Starting to watch goals for user $userId');
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        logger.debug('FirebaseGoalRepository: Received snapshot with ${snapshot.docs.length} documents');
        
        final goals = snapshot.docs
            .map((doc) {
              logger.debug('FirebaseGoalRepository: Processing document ${doc.id}');
              return GoalModel.fromFirestore(doc).toEntity();
            })
            .toList();
            
        logger.debug('FirebaseGoalRepository: Converted ${goals.length} goals');
        return Result.success(goals);
      } catch (e, stackTrace) {
        logger.error('FirebaseGoalRepository: Error in watchGoals', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<Goal>> watchGoal(String goalId) {
    return _firestore
        .collection(_collection)
        .doc(goalId)
        .snapshots()
        .map((doc) {
      try {
        if (!doc.exists) {
          return Result.failure(const NotFoundFailure(
            message: 'Goal not found',
          ));
        }
        
        final goal = GoalModel.fromFirestore(doc).toEntity();
        return Result.success(goal);
      } catch (e, stackTrace) {
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  /// Gets user stats for dashboard display
  Future<Result<UserStats>> getUserStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return Result.success(UserStats.initial());
      }
      
      final userData = userDoc.data();
      if (userData?['stats'] == null) {
        return Result.success(UserStats.initial());
      }
      
      final stats = UserStats.fromFirestore(userData!['stats'] as Map<String, dynamic>);
      return Result.success(stats);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  /// Watches user stats for real-time updates
  Stream<Result<UserStats>> watchUserStats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      try {
        if (!doc.exists) {
          return Result.success(UserStats.initial());
        }
        
        final userData = doc.data();
        if (userData?['stats'] == null) {
          return Result.success(UserStats.initial());
        }
        
        final stats = UserStats.fromFirestore(userData!['stats'] as Map<String, dynamic>);
        return Result.success(stats);
      } catch (e, stackTrace) {
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  /// Updates user stats when a goal is created
  Future<void> _updateUserStatsOnGoalCreate(WriteBatch batch, DocumentReference userRef, Goal goal) async {
    final userSnapshot = await userRef.get();
    UserStats currentStats;
    
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      currentStats = userData?['stats'] != null 
          ? UserStats.fromFirestore(userData!['stats'] as Map<String, dynamic>)
          : UserStats.initial();
    } else {
      currentStats = UserStats.initial();
    }

    final newActivity = ActivityItem(
      id: goal.id,
      type: ActivityType.goalCreated,
      title: 'Created "${goal.title}"',
      goalId: goal.id,
      timestamp: DateTime.now(),
    );

    final updatedStats = currentStats.copyWith(
      activeGoals: currentStats.activeGoals + 1,
      totalGoals: currentStats.totalGoals + 1,
      lastUpdated: DateTime.now(),
      recentActivity: [newActivity, ...currentStats.recentActivity.take(9)].toList(),
    );

    batch.set(userRef, {
      'stats': updatedStats.toFirestore(),
    }, SetOptions(merge: true));
  }

  /// Updates user stats when a goal is completed
  Future<void> _updateUserStatsOnGoalComplete(WriteBatch batch, DocumentReference userRef, Goal goal) async {
    final userSnapshot = await userRef.get();
    UserStats currentStats;
    
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      currentStats = userData?['stats'] != null 
          ? UserStats.fromFirestore(userData!['stats'] as Map<String, dynamic>)
          : UserStats.initial();
    } else {
      currentStats = UserStats.initial();
    }

    final newActivity = ActivityItem(
      id: '${goal.id}_completed',
      type: ActivityType.goalCompleted,
      title: 'Completed "${goal.title}"',
      goalId: goal.id,
      timestamp: DateTime.now(),
    );

    final updatedStats = currentStats.copyWith(
      activeGoals: currentStats.activeGoals - 1,
      completedGoals: currentStats.completedGoals + 1,
      lastUpdated: DateTime.now(),
      recentActivity: [newActivity, ...currentStats.recentActivity.take(9)].toList(),
    );

    batch.set(userRef, {
      'stats': updatedStats.toFirestore(),
    }, SetOptions(merge: true));
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
            message: 'Goal not found.',
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