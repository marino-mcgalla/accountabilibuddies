import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/core.dart';
import '../../domain/entities/goal_template.dart';
import '../../domain/repositories/goal_template_repository.dart';
import '../models/goal_template_model.dart';

class FirebaseGoalTemplateRepository implements GoalTemplateRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'goalTemplates';

  FirebaseGoalTemplateRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<GoalTemplate>>> getTemplates(String userId) async {
    try {
      // logger.debug('FirebaseGoalTemplateRepository: Getting templates for user $userId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .first;

      final templates = querySnapshot.docs
          .map((doc) => GoalTemplateModel.fromFirestore(doc).toEntity())
          .toList();

      // logger.debug('FirebaseGoalTemplateRepository: Retrieved ${templates.length} templates');
      return Result.success(templates);
    } catch (e, stackTrace) {
      logger.error('FirebaseGoalTemplateRepository: Error getting templates', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<GoalTemplate>>> getTemplatesByStatus(
    String userId, 
    GoalTemplateStatus status,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status.name)
          .snapshots()
          .first;

      final templates = querySnapshot.docs
          .map((doc) => GoalTemplateModel.fromFirestore(doc).toEntity())
          .toList();

      return Result.success(templates);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<GoalTemplate>>> getTemplatesByCategory(
    String userId, 
    GoalCategory category,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.name)
          .where('status', isEqualTo: GoalTemplateStatus.active.name)
          .snapshots()
          .first;

      final templates = querySnapshot.docs
          .map((doc) => GoalTemplateModel.fromFirestore(doc).toEntity())
          .toList();

      return Result.success(templates);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<GoalTemplate>> getTemplate(String templateId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(templateId).get();
      
      if (!doc.exists) {
        return Result.failure(const NotFoundFailure(
          message: 'Goal template not found',
        ));
      }

      final template = GoalTemplateModel.fromFirestore(doc).toEntity();
      return Result.success(template);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<GoalTemplate>> createTemplate(GoalTemplate template) async {
    try {
      // logger.debug('FirebaseGoalTemplateRepository: Creating template "${template.title}" for user ${template.userId}');
      
      final docRef = _firestore.collection(_collection).doc();
      final templateWithId = template.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final templateModel = GoalTemplateModel.fromEntity(templateWithId);
      await docRef.set(templateModel.toFirestore());

      // logger.debug('FirebaseGoalTemplateRepository: Template created successfully with ID ${templateWithId.id}');
      return Result.success(templateWithId);
    } catch (e, stackTrace) {
      logger.error('FirebaseGoalTemplateRepository: Error creating template', error: e, stackTrace: stackTrace);
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<GoalTemplate>> updateTemplate(GoalTemplate template) async {
    try {
      final updatedTemplate = template.copyWith(updatedAt: DateTime.now());
      final templateModel = GoalTemplateModel.fromEntity(updatedTemplate);
      
      await _firestore
          .collection(_collection)
          .doc(template.id)
          .update(templateModel.toFirestore());

      return Result.success(updatedTemplate);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteTemplate(String templateId) async {
    try {
      await _firestore.collection(_collection).doc(templateId).delete();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<GoalTemplate>> archiveTemplate(String templateId) async {
    try {
      final templateResult = await getTemplate(templateId);
      if (templateResult.isFailure) {
        return Result.failure(templateResult.failureOrNull!);
      }

      final template = templateResult.valueOrNull!;
      final archivedTemplate = template.copyWith(
        status: GoalTemplateStatus.archived,
        updatedAt: DateTime.now(),
      );

      return await updateTemplate(archivedTemplate);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<GoalTemplate>> unarchiveTemplate(String templateId) async {
    try {
      final templateResult = await getTemplate(templateId);
      if (templateResult.isFailure) {
        return Result.failure(templateResult.failureOrNull!);
      }

      final template = templateResult.valueOrNull!;
      final activeTemplate = template.copyWith(
        status: GoalTemplateStatus.active,
        updatedAt: DateTime.now(),
      );

      return await updateTemplate(activeTemplate);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<GoalTemplate>> updateTemplateStats({
    required String templateId,
    required int targetFrequency,
    required int completionsAchieved,
    required DateTime instanceCreatedAt,
  }) async {
    try {
      final templateResult = await getTemplate(templateId);
      if (templateResult.isFailure) {
        return Result.failure(templateResult.failureOrNull!);
      }

      final template = templateResult.valueOrNull!;
      final updatedTemplate = template.updateStatsFromInstance(
        targetFrequency: targetFrequency,
        completionsAchieved: completionsAchieved,
        instanceCreatedAt: instanceCreatedAt,
      );

      return await updateTemplate(updatedTemplate);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }

  @override
  Stream<Result<List<GoalTemplate>>> watchTemplates(String userId) {
    // logger.debug('FirebaseGoalTemplateRepository: Starting to watch templates for user $userId');
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        // logger.debug('FirebaseGoalTemplateRepository: Received snapshot with ${snapshot.docs.length} templates');
        
        final templates = snapshot.docs
            .map((doc) {
              // logger.debug('FirebaseGoalTemplateRepository: Processing template ${doc.id}');
              return GoalTemplateModel.fromFirestore(doc).toEntity();
            })
            .toList();
            
        // logger.debug('FirebaseGoalTemplateRepository: Converted ${templates.length} templates');
        return Result.success(templates);
      } catch (e, stackTrace) {
        logger.error('FirebaseGoalTemplateRepository: Error in watchTemplates', error: e, stackTrace: stackTrace);
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Stream<Result<GoalTemplate>> watchTemplate(String templateId) {
    return _firestore
        .collection(_collection)
        .doc(templateId)
        .snapshots()
        .map((doc) {
      try {
        if (!doc.exists) {
          return Result.failure(const NotFoundFailure(
            message: 'Goal template not found',
          ));
        }
        
        final template = GoalTemplateModel.fromFirestore(doc).toEntity();
        return Result.success(template);
      } catch (e, stackTrace) {
        return Result.failure(_mapException(e, stackTrace));
      }
    });
  }

  @override
  Future<Result<List<GoalTemplate>>> searchTemplates(
    String userId, 
    String query,
  ) async {
    try {
      // Basic text search - in production you might want to use Algolia or similar
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: GoalTemplateStatus.active.name)
          .snapshots()
          .first;

      final templates = querySnapshot.docs
          .map((doc) => GoalTemplateModel.fromFirestore(doc).toEntity())
          .where((template) {
            final searchText = query.toLowerCase();
            return template.title.toLowerCase().contains(searchText) ||
                   template.description.toLowerCase().contains(searchText) ||
                   template.tags.any((tag) => tag.toLowerCase().contains(searchText));
          })
          .toList();

      return Result.success(templates);
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
            message: 'Goal template not found.',
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