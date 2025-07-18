import 'dart:async';
import 'package:flutter/material.dart';
import '../models/goal_template.dart';
import '../models/goal_category.dart';
import '../repositories/goal_template_repository.dart';

class GoalTemplateProvider with ChangeNotifier {
  final GoalTemplateRepository _repository;
  
  // State
  List<GoalTemplate> _templates = [];
  List<GoalTemplate> _activeTemplates = [];
  List<GoalTemplate> _archivedTemplates = [];
  Map<String, int> _stats = {'total': 0, 'active': 0, 'archived': 0};
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  
  // Subscriptions
  StreamSubscription<List<GoalTemplate>>? _templatesSubscription;
  bool _isDisposed = false;

  GoalTemplateProvider({GoalTemplateRepository? repository})
      : _repository = repository ?? GoalTemplateRepository() {
    _initializeStreams();
  }

  // Getters
  List<GoalTemplate> get templates => _templates;
  List<GoalTemplate> get activeTemplates => _activeTemplates;
  List<GoalTemplate> get archivedTemplates => _archivedTemplates;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasTemplates => _templates.isNotEmpty;
  bool get hasActiveTemplates => _activeTemplates.isNotEmpty;
  bool get hasArchivedTemplates => _archivedTemplates.isNotEmpty;

  // Filtered templates based on current category and search
  List<GoalTemplate> get filteredActiveTemplates {
    List<GoalTemplate> filtered = _activeTemplates;
    
    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((template) => template.category == _selectedCategory).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((template) {
        return template.name.toLowerCase().contains(query) ||
               template.description.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }

  List<GoalTemplate> get filteredArchivedTemplates {
    List<GoalTemplate> filtered = _archivedTemplates;
    
    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((template) => template.category == _selectedCategory).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((template) {
        return template.name.toLowerCase().contains(query) ||
               template.description.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }

  // Most used templates for quick access
  List<GoalTemplate> get mostUsedTemplates {
    final sortedTemplates = List<GoalTemplate>.from(_activeTemplates);
    sortedTemplates.sort((a, b) => b.totalChallengesUsed.compareTo(a.totalChallengesUsed));
    return sortedTemplates.take(5).toList();
  }

  // Recently created templates
  List<GoalTemplate> get recentTemplates {
    final sortedTemplates = List<GoalTemplate>.from(_activeTemplates);
    sortedTemplates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedTemplates.take(3).toList();
  }

  // Category distribution for analytics
  Map<String, int> get categoryDistribution {
    final distribution = <String, int>{};
    for (final template in _activeTemplates) {
      distribution[template.category] = (distribution[template.category] ?? 0) + 1;
    }
    return distribution;
  }

  void _initializeStreams() {
    if (_isDisposed) return;

    _setLoading(true);
    
    _templatesSubscription = _repository.streamGoalTemplates().listen(
      (templates) {
        if (_isDisposed) return;
        
        _templates = templates;
        _activeTemplates = templates.where((t) => t.isActive).toList();
        _archivedTemplates = templates.where((t) => t.isArchived).toList();
        
        _updateStats();
        _setLoading(false);
        _clearError();
        
        notifyListeners();
      },
      onError: (error) {
        if (_isDisposed) return;
        _setError('Failed to load goal templates: $error');
        _setLoading(false);
      },
    );
  }

  void _updateStats() {
    _stats = {
      'total': _templates.length,
      'active': _activeTemplates.length,
      'archived': _archivedTemplates.length,
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }

  // CRUD Operations
  Future<bool> createTemplate({
    required String name,
    required String description,
    required GoalType type,
    required int defaultFrequency,
    required String category,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final template = GoalTemplate.create(
        name: name.trim(),
        description: description.trim(),
        type: type,
        defaultFrequency: defaultFrequency,
        category: category,
      );

      final templateId = await _repository.createGoalTemplate(template);
      
      if (templateId != null) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to create goal template');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error creating template: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTemplate(GoalTemplate template) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.updateGoalTemplate(template);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update goal template');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating template: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> archiveTemplate(String templateId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.archiveGoalTemplate(templateId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to archive goal template');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error archiving template: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> reactivateTemplate(String templateId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.reactivateGoalTemplate(templateId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to reactivate goal template');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error reactivating template: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteTemplate(String templateId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.deleteGoalTemplate(templateId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to delete goal template');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error deleting template: $e');
      _setLoading(false);
      return false;
    }
  }

  // Batch operations
  Future<bool> batchArchiveTemplates(List<String> templateIds) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.batchArchiveTemplates(templateIds);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to archive selected templates');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error archiving templates: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> batchReactivateTemplates(List<String> templateIds) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.batchReactivateTemplates(templateIds);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to reactivate selected templates');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error reactivating templates: $e');
      _setLoading(false);
      return false;
    }
  }

  // Usage tracking
  Future<void> markTemplateAsUsed(String templateId) async {
    try {
      await _repository.updateUsageStats(templateId);
    } catch (e) {
      // Don't show error to user for usage tracking
      
    }
  }

  // Filtering and search
  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void clearFilters() {
    _selectedCategory = 'all';
    _searchQuery = '';
    notifyListeners();
  }

  // Utility methods
  GoalTemplate? getTemplateById(String templateId) {
    try {
      return _templates.firstWhere((template) => template.id == templateId);
    } catch (e) {
      return null;
    }
  }

  List<GoalTemplate> getTemplatesByCategory(String category) {
    return _activeTemplates.where((template) => template.category == category).toList();
  }

  bool hasTemplateWithName(String name) {
    final lowercaseName = name.toLowerCase().trim();
    return _templates.any((template) => 
        template.name.toLowerCase().trim() == lowercaseName && template.isActive);
  }

  // Refresh data
  Future<void> refresh() async {
    _initializeStreams();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _templatesSubscription?.cancel();
    super.dispose();
  }
}