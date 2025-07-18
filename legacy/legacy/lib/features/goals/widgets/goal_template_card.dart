import 'package:flutter/material.dart';
import '../models/goal_template.dart';
import '../models/goal_category.dart';

class GoalTemplateCard extends StatelessWidget {
  final GoalTemplate template;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onReactivate;
  final VoidCallback? onDelete;
  final bool showArchived;

  const GoalTemplateCard({
    super.key,
    required this.template,
    this.onTap,
    this.onArchive,
    this.onReactivate,
    this.onDelete,
    this.showArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final category = GoalCategory.fromString(template.category);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and actions
              Row(
                children: [
                  // Category icon and label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: category.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.displayName,
                          style: TextStyle(
                            color: category.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Status indicator
                  if (showArchived)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Archived',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  // Actions menu
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value),
                    itemBuilder: (context) => [
                      if (!showArchived && onArchive != null)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined),
                              SizedBox(width: 8),
                              Text('Archive'),
                            ],
                          ),
                        ),
                      if (showArchived && onReactivate != null)
                        const PopupMenuItem(
                          value: 'reactivate',
                          child: Row(
                            children: [
                              Icon(Icons.unarchive_outlined),
                              SizedBox(width: 8),
                              Text('Reactivate'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Goal name
              Text(
                template.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Goal description
              if (template.description.isNotEmpty)
                Text(
                  template.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
              
              // Goal details
              Row(
                children: [
                  // Goal type
                  _buildDetailChip(
                    context,
                    icon: _getGoalTypeIcon(template.type),
                    label: template.displayType,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Frequency
                  _buildDetailChip(
                    context,
                    icon: Icons.repeat,
                    label: template.frequencyText,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats row
              Row(
                children: [
                  // Usage count
                  if (template.totalChallengesUsed > 0) ...[
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Used ${template.totalChallengesUsed} times',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.new_releases_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New template',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Last used or creation date
                  if (template.lastUsedAt != null)
                    Text(
                      'Last used ${_formatRelativeDate(template.lastUsedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else if (showArchived && template.archivedAt != null)
                    Text(
                      'Archived ${_formatRelativeDate(template.archivedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    Text(
                      'Created ${_formatRelativeDate(template.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalTypeIcon(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return Icons.today;
      case GoalType.total:
        return Icons.track_changes;
    }
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  void _handleAction(String action) {
    switch (action) {
      case 'archive':
        onArchive?.call();
        break;
      case 'reactivate':
        onReactivate?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}