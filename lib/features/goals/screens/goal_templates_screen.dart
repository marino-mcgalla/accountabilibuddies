import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_template_provider.dart';
import '../models/goal_template.dart';
import '../models/goal_category.dart';
import '../widgets/goal_template_card.dart';
import '../widgets/goal_category_selector.dart';
import 'create_goal_template_screen.dart';
import 'edit_goal_template_screen.dart';

class GoalTemplatesScreen extends StatefulWidget {
  const GoalTemplatesScreen({super.key});

  @override
  State<GoalTemplatesScreen> createState() => _GoalTemplatesScreenState();
}

class _GoalTemplatesScreenState extends State<GoalTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;

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
                  context.read<GoalTemplateProvider>().setSearchQuery(query);
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
                  context.read<GoalTemplateProvider>().setSearchQuery('');
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
      body: Consumer<GoalTemplateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasTemplates) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your goal templates...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
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
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Category Filter
              _buildCategoryFilter(context, provider),
              
              // Stats Bar
              _buildStatsBar(context, provider),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTemplatesTab(context, provider),
                    _buildArchivedTemplatesTab(context, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTemplate(context),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, GoalTemplateProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GoalCategorySelector(
        selectedCategory: provider.selectedCategory,
        onCategorySelected: (category) {
          provider.setSelectedCategory(category);
        },
        showAllOption: true,
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, GoalTemplateProvider provider) {
    final stats = provider.stats;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            'Total',
            stats['total'].toString(),
            Icons.flag,
          ),
          _buildStatItem(
            context,
            'Active',
            stats['active'].toString(),
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildStatItem(
            context,
            'Archived',
            stats['archived'].toString(),
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
            color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTemplatesTab(BuildContext context, GoalTemplateProvider provider) {
    final templates = provider.filteredActiveTemplates;

    if (templates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.flag_outlined,
        title: provider.searchQuery.isNotEmpty || provider.selectedCategory != 'all'
            ? 'No matching templates'
            : 'No active goal templates',
        subtitle: provider.searchQuery.isNotEmpty || provider.selectedCategory != 'all'
            ? 'Try adjusting your search or filters'
            : 'Create your first goal template to get started!',
        actionLabel: 'Create Template',
        onAction: () => _navigateToCreateTemplate(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GoalTemplateCard(
              template: template,
              onTap: () => _navigateToEditTemplate(context, template),
              onArchive: () => _archiveTemplate(context, provider, template),
              onDelete: () => _deleteTemplate(context, provider, template),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArchivedTemplatesTab(BuildContext context, GoalTemplateProvider provider) {
    final templates = provider.filteredArchivedTemplates;

    if (templates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.archive_outlined,
        title: 'No archived templates',
        subtitle: 'Archived templates will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GoalTemplateCard(
              template: template,
              onTap: () => _navigateToEditTemplate(context, template),
              onReactivate: () => _reactivateTemplate(context, provider, template),
              onDelete: () => _deleteTemplate(context, provider, template),
              showArchived: true,
            ),
          );
        },
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

  // Navigation methods
  void _navigateToCreateTemplate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateGoalTemplateScreen(),
      ),
    );
  }

  void _navigateToEditTemplate(BuildContext context, GoalTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditGoalTemplateScreen(template: template),
      ),
    );
  }

  // Action methods
  void _handleMenuAction(BuildContext context, String action) {
    final provider = context.read<GoalTemplateProvider>();
    
    switch (action) {
      case 'clear_filters':
        provider.clearFilters();
        _searchController.clear();
        setState(() {
          _isSearchVisible = false;
        });
        break;
      case 'refresh':
        provider.refresh();
        break;
    }
  }

  Future<void> _archiveTemplate(
    BuildContext context,
    GoalTemplateProvider provider,
    GoalTemplate template,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Archive Template',
      content: 'Are you sure you want to archive "${template.name}"? You can reactivate it later.',
      confirmLabel: 'Archive',
    );

    if (confirmed) {
      final success = await provider.archiveTemplate(template.id);
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
      }
    }
  }

  Future<void> _reactivateTemplate(
    BuildContext context,
    GoalTemplateProvider provider,
    GoalTemplate template,
  ) async {
    final success = await provider.reactivateTemplate(template.id);
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
    }
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    GoalTemplateProvider provider,
    GoalTemplate template,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Delete Template',
      content: 'Are you sure you want to permanently delete "${template.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      final success = await provider.deleteTemplate(template.id);
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