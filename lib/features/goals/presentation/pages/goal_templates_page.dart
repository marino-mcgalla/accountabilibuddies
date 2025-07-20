import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/goal_template.dart';
import '../providers/goal_template_providers.dart';

class GoalTemplatesPage extends ConsumerStatefulWidget {
  const GoalTemplatesPage({super.key});

  @override
  ConsumerState<GoalTemplatesPage> createState() => _GoalTemplatesPageState();
}

class _GoalTemplatesPageState extends ConsumerState<GoalTemplatesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  GoalCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(goalTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search goal templates...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white60),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              )
            : const Text('Goal Templates'),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.flag)),
            Tab(text: 'Archived', icon: Icon(Icons.archive)),
          ],
        ),
      ),
      body: templatesAsync.when(
        data: (templates) => Column(
          children: [
            // Category Filter
            _buildCategoryFilter(context),
            
            // Stats Bar
            _buildStatsBar(context, templates),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveTemplatesTab(context, templates),
                  _buildArchivedTemplatesTab(context, templates),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your goal templates...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading templates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(goalTemplatesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/goals/templates/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip('All', null),
            const SizedBox(width: 8),
            ...GoalCategory.values.map((category) => 
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(category.name.toUpperCase(), category),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, GoalCategory? category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
    );
  }

  Widget _buildStatsBar(BuildContext context, List<GoalTemplate> templates) {
    final activeCount = templates.where((t) => t.isActive).length;
    final archivedCount = templates.where((t) => t.isArchived).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            'Total',
            templates.length.toString(),
            Icons.flag,
          ),
          _buildStatItem(
            context,
            'Active',
            activeCount.toString(),
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildStatItem(
            context,
            'Archived',
            archivedCount.toString(),
            Icons.archive,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTemplatesTab(BuildContext context, List<GoalTemplate> allTemplates) {
    final templates = _filterTemplates(allTemplates.where((t) => t.isActive).toList());

    if (templates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.flag_outlined,
        title: _searchQuery.isNotEmpty || _selectedCategory != null
            ? 'No matching templates'
            : 'No active goal templates',
        subtitle: _searchQuery.isNotEmpty || _selectedCategory != null
            ? 'Try adjusting your search or filters'
            : 'Create your first goal template to get started!',
        actionLabel: 'Create Template',
        onAction: () => context.go('/goals/templates/create'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(goalTemplatesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTemplateCard(context, template),
          );
        },
      ),
    );
  }

  Widget _buildArchivedTemplatesTab(BuildContext context, List<GoalTemplate> allTemplates) {
    final templates = _filterTemplates(allTemplates.where((t) => t.isArchived).toList());

    if (templates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.archive_outlined,
        title: 'No archived templates',
        subtitle: 'Archived templates will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(goalTemplatesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTemplateCard(context, template, showArchived: true),
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, GoalTemplate template, {bool showArchived = false}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/goals/templates/${template.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleTemplateAction(context, template, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (!showArchived)
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
              const SizedBox(height: 8),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.goalTypeDisplay,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.categoryDisplay,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (template.totalInstances > 0) ...[
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${template.totalInstances} uses • ${(template.averageCompletionRate * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<GoalTemplate> _filterTemplates(List<GoalTemplate> templates) {
    var filtered = templates;

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((t) => t.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query) ||
          t.tags.any((tag) => tag.toLowerCase().contains(query))).toList();
    }

    return filtered;
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'clear_filters':
        setState(() {
          _selectedCategory = null;
          _searchQuery = '';
          _isSearchVisible = false;
        });
        _searchController.clear();
        break;
      case 'refresh':
        ref.refresh(goalTemplatesProvider);
        break;
    }
  }

  void _handleTemplateAction(BuildContext context, GoalTemplate template, String action) {
    final controller = ref.read(goalTemplateControllerProvider);
    
    switch (action) {
      case 'edit':
        context.go('/goals/templates/${template.id}/edit');
        break;
      case 'archive':
        _archiveTemplate(context, controller, template);
        break;
      case 'unarchive':
        _unarchiveTemplate(context, controller, template);
        break;
      case 'delete':
        _deleteTemplate(context, controller, template);
        break;
    }
  }

  Future<void> _archiveTemplate(
    BuildContext context,
    GoalTemplateController controller,
    GoalTemplate template,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Archive Template',
      content: 'Are you sure you want to archive "${template.title}"? You can reactivate it later.',
      confirmLabel: 'Archive',
    );

    if (confirmed) {
      final success = await controller.archiveTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Template archived successfully' 
                : 'Failed to archive template'),
            backgroundColor: success 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.error,
          ),
        );
        if (success) {
          ref.refresh(goalTemplatesProvider);
        }
      }
    }
  }

  Future<void> _unarchiveTemplate(
    BuildContext context,
    GoalTemplateController controller,
    GoalTemplate template,
  ) async {
    final success = await controller.unarchiveTemplate(template.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Template reactivated successfully' 
              : 'Failed to reactivate template'),
          backgroundColor: success 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.error,
        ),
      );
      if (success) {
        ref.refresh(goalTemplatesProvider);
      }
    }
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    GoalTemplateController controller,
    GoalTemplate template,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Delete Template',
      content: 'Are you sure you want to permanently delete "${template.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      final success = await controller.deleteTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Template deleted successfully' 
                : 'Failed to delete template'),
            backgroundColor: success 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.error,
          ),
        );
        if (success) {
          ref.refresh(goalTemplatesProvider);
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}