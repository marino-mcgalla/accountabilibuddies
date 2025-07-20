import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/goal_template.dart';
import '../providers/goal_template_providers.dart';
import '../../../../core/utils/date_formatter.dart';

class GoalTemplateDetailPage extends ConsumerWidget {
  final String templateId;

  const GoalTemplateDetailPage({
    super.key,
    required this.templateId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(goalTemplateProvider(templateId));

    return templateAsync.when(
      data: (template) {
        if (template == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Template Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Template not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/goals/templates'),
                    child: const Text('Back to Templates'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Template Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/goals/templates/$templateId/edit'),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, ref, template, value),
                itemBuilder: (context) => [
                  if (template.isActive)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive),
                          SizedBox(width: 8),
                          Text('Archive'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'unarchive',
                      child: Row(
                        children: [
                          Icon(Icons.unarchive),
                          SizedBox(width: 8),
                          Text('Reactivate'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                _buildStatusBadge(context, template),
                const SizedBox(height: 24),

                // Title and Description
                _buildBasicInfo(context, template),
                const SizedBox(height: 24),

                // Type and Category
                _buildTypeAndCategory(context, template),
                const SizedBox(height: 24),

                // Frequency Configuration
                _buildFrequencyInfo(context, template),
                const SizedBox(height: 24),

                // Statistics
                _buildStatistics(context, template),
                const SizedBox(height: 24),

                // Tags
                if (template.tags.isNotEmpty) ...[
                  _buildTags(context, template),
                  const SizedBox(height: 24),
                ],

                // Metadata
                _buildMetadata(context, template),
                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(context, ref, template),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading template: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(goalTemplateProvider(templateId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, GoalTemplate template) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: template.isActive
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: template.isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            template.isActive ? Icons.check_circle : Icons.archive,
            size: 16,
            color: template.isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            template.statusDisplay,
            style: TextStyle(
              color: template.isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, GoalTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          template.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (template.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            template.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeAndCategory(BuildContext context, GoalTemplate template) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.track_changes,
            label: 'Type',
            value: template.goalTypeDisplay,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.category,
            label: 'Category',
            value: template.categoryDisplay,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyInfo(BuildContext context, GoalTemplate template) {
    String frequencyLabel;
    String frequencyDescription;

    switch (template.goalType) {
      case GoalType.daily:
        frequencyLabel = 'Default Days Per Week';
        frequencyDescription = 'Suggested number of days per week to complete this goal';
        break;
      case GoalType.total:
        frequencyLabel = 'Default Target';
        frequencyDescription = 'Suggested total completions for this goal';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  frequencyLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              frequencyDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    template.plannedFrequency?.toString() ?? 'Not set',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    template.goalType == GoalType.daily ? 'days/week' : 'total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, GoalTemplate template) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Times Used',
                    value: template.totalInstances.toString(),
                    icon: Icons.history,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Completions',
                    value: template.totalCompletions.toString(),
                    icon: Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Success Rate',
                    value: '${(template.averageCompletionRate * 100).toInt()}%',
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
            if (template.lastUsedAt != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last used ${DateFormatter.formatRelative(template.lastUsedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context, GoalTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: template.tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context, GoalTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildMetadataRow(
          context,
          label: 'Created',
          value: DateFormatter.formatFull(template.createdAt),
        ),
        const SizedBox(height: 8),
        _buildMetadataRow(
          context,
          label: 'Last Updated',
          value: DateFormatter.formatFull(template.updatedAt),
        ),
        if (template.metadata.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...template.metadata.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMetadataRow(
                  context,
                  label: entry.key,
                  value: entry.value.toString(),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, GoalTemplate template) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/goals/templates/$templateId/edit'),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Template'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleCreateGoal(context, template),
            icon: const Icon(Icons.add),
            label: const Text('Use This Template'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, GoalTemplate template, String action) {
    final controller = ref.read(goalTemplateControllerProvider);

    switch (action) {
      case 'archive':
        _archiveTemplate(context, ref, controller, template);
        break;
      case 'unarchive':
        _unarchiveTemplate(context, ref, controller, template);
        break;
      case 'delete':
        _deleteTemplate(context, ref, controller, template);
        break;
    }
  }

  Future<void> _archiveTemplate(
    BuildContext context,
    WidgetRef ref,
    GoalTemplateController controller,
    GoalTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Template'),
        content: Text('Are you sure you want to archive "${template.title}"? You can reactivate it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.archiveTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Template archived successfully' : 'Failed to archive template'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          context.go('/goals/templates');
        }
      }
    }
  }

  Future<void> _unarchiveTemplate(
    BuildContext context,
    WidgetRef ref,
    GoalTemplateController controller,
    GoalTemplate template,
  ) async {
    final success = await controller.unarchiveTemplate(template.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Template reactivated successfully' : 'Failed to reactivate template'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        ref.refresh(goalTemplateProvider(templateId));
      }
    }
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    GoalTemplateController controller,
    GoalTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to permanently delete "${template.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.deleteTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Template deleted successfully' : 'Failed to delete template'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          context.go('/goals/templates');
        }
      }
    }
  }

  void _handleCreateGoal(BuildContext context, GoalTemplate template) {
    // Navigate to goal creation with this template
    context.go('/goals/create?templateId=${template.id}');
  }
}