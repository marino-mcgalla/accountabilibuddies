import '../../../../core/error/result.dart';
import '../entities/goal_template.dart';

abstract class GoalTemplateRepository {
  /// Get all templates for a user
  Future<Result<List<GoalTemplate>>> getTemplates(String userId);

  /// Get templates by status
  Future<Result<List<GoalTemplate>>> getTemplatesByStatus(
    String userId, 
    GoalTemplateStatus status,
  );

  /// Get templates by category
  Future<Result<List<GoalTemplate>>> getTemplatesByCategory(
    String userId, 
    GoalCategory category,
  );

  /// Get a specific template
  Future<Result<GoalTemplate>> getTemplate(String templateId);

  /// Create a new template
  Future<Result<GoalTemplate>> createTemplate(GoalTemplate template);

  /// Update an existing template
  Future<Result<GoalTemplate>> updateTemplate(GoalTemplate template);

  /// Delete a template (permanently removes it)
  Future<Result<void>> deleteTemplate(String templateId);

  /// Archive a template (hides it but preserves stats)
  Future<Result<GoalTemplate>> archiveTemplate(String templateId);

  /// Unarchive a template (make it active again)
  Future<Result<GoalTemplate>> unarchiveTemplate(String templateId);

  /// Update template stats when an instance is completed
  Future<Result<GoalTemplate>> updateTemplateStats({
    required String templateId,
    required int targetFrequency,
    required int completionsAchieved,
    required DateTime instanceCreatedAt,
  });

  /// Watch templates for real-time updates
  Stream<Result<List<GoalTemplate>>> watchTemplates(String userId);

  /// Watch a specific template for real-time updates
  Stream<Result<GoalTemplate>> watchTemplate(String templateId);

  /// Search templates by title or description
  Future<Result<List<GoalTemplate>>> searchTemplates(
    String userId, 
    String query,
  );
}