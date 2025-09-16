import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_goal_template_repository.dart';
import '../../domain/entities/goal_template.dart';
import '../../domain/repositories/goal_template_repository.dart';
import '../../../auth/auth.dart';
import '../../../../core/logging/logger_service.dart';

// Repository provider
final goalTemplateRepositoryProvider = Provider<GoalTemplateRepository>((ref) {
  return FirebaseGoalTemplateRepository();
});

// Templates list provider
final goalTemplatesProvider = StreamProvider<List<GoalTemplate>>((ref) {
  final repository = ref.watch(goalTemplateRepositoryProvider);
  final user = ref.watch(userProvider);
  
  // logger.debug('GoalTemplatesProvider: user = ${user?.id}');
  
  if (user == null) {
    // logger.debug('GoalTemplatesProvider: No user, returning empty list');
    return Stream.value(<GoalTemplate>[]);
  }
  
  // logger.debug('GoalTemplatesProvider: Watching templates for user ${user.id}');
  
  return repository.watchTemplates(user.id).map((result) {
    return result.fold(
      onSuccess: (templates) {
        // logger.debug('GoalTemplatesProvider: Received ${templates.length} templates');
        return templates;
      },
      onFailure: (failure) {
        logger.error('GoalTemplatesProvider: Error loading templates', error: failure);
        return <GoalTemplate>[];
      },
    );
  });
});

// Active templates provider
final activeGoalTemplatesProvider = Provider<List<GoalTemplate>>((ref) {
  final templates = ref.watch(goalTemplatesProvider);
  return templates.when(
    data: (templateList) => templateList.where((template) => template.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Archived templates provider
final archivedGoalTemplatesProvider = Provider<List<GoalTemplate>>((ref) {
  final templates = ref.watch(goalTemplatesProvider);
  return templates.when(
    data: (templateList) => templateList.where((template) => template.isArchived).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Templates by category provider
final goalTemplatesByCategoryProvider = Provider.family<List<GoalTemplate>, GoalCategory>((ref, category) {
  final templates = ref.watch(goalTemplatesProvider);
  return templates.when(
    data: (templateList) => templateList.where((template) => template.category == category && template.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Individual template provider
final goalTemplateProvider = StreamProvider.family<GoalTemplate?, String>((ref, templateId) {
  final repository = ref.watch(goalTemplateRepositoryProvider);
  
  return repository.watchTemplate(templateId).map((result) {
    return result.fold(
      onSuccess: (template) => template,
      onFailure: (failure) => null,
    );
  });
});

// Template controller for actions
final goalTemplateControllerProvider = Provider<GoalTemplateController>((ref) {
  final repository = ref.watch(goalTemplateRepositoryProvider);
  final user = ref.watch(userProvider);
  return GoalTemplateController(repository: repository, userId: user?.id ?? '');
});

class GoalTemplateController {
  final GoalTemplateRepository repository;
  final String userId;

  GoalTemplateController({
    required this.repository,
    required this.userId,
  });

  Future<bool> createTemplate({
    required String title,
    required String description,
    required GoalCategory category,
    required GoalType goalType,
    int? plannedFrequency,
    List<String> tags = const [],
  }) async {
    final template = GoalTemplate(
      id: '', // Will be set by repository
      userId: userId,
      title: title,
      description: description,
      category: category,
      goalType: goalType,
      plannedFrequency: plannedFrequency,
      tags: tags,
      status: GoalTemplateStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {},
    );

    final result = await repository.createTemplate(template);
    return result.isSuccess;
  }

  Future<bool> updateTemplate(GoalTemplate template) async {
    final result = await repository.updateTemplate(template);
    return result.isSuccess;
  }

  Future<bool> deleteTemplate(String templateId) async {
    final result = await repository.deleteTemplate(templateId);
    return result.isSuccess;
  }

  Future<bool> archiveTemplate(String templateId) async {
    final result = await repository.archiveTemplate(templateId);
    return result.isSuccess;
  }

  Future<bool> unarchiveTemplate(String templateId) async {
    final result = await repository.unarchiveTemplate(templateId);
    return result.isSuccess;
  }

  Future<GoalTemplate?> getTemplate(String templateId) async {
    final result = await repository.getTemplate(templateId);
    return result.fold(
      onSuccess: (template) => template,
      onFailure: (failure) => null,
    );
  }

  Future<List<GoalTemplate>> searchTemplates(String query) async {
    final result = await repository.searchTemplates(userId, query);
    return result.fold(
      onSuccess: (templates) => templates,
      onFailure: (failure) => [],
    );
  }

  Future<bool> updateTemplateStats({
    required String templateId,
    required int targetFrequency,
    required int completionsAchieved,
    required DateTime instanceCreatedAt,
  }) async {
    final result = await repository.updateTemplateStats(
      templateId: templateId,
      targetFrequency: targetFrequency,
      completionsAchieved: completionsAchieved,
      instanceCreatedAt: instanceCreatedAt,
    );
    return result.isSuccess;
  }
}