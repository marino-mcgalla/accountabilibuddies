import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/goal_template_provider.dart';
import '../models/goal_template.dart';
import '../models/goal_category.dart';
import '../widgets/goal_category_selector.dart';

class EditGoalTemplateScreen extends StatefulWidget {
  final GoalTemplate template;

  const EditGoalTemplateScreen({
    super.key,
    required this.template,
  });

  @override
  State<EditGoalTemplateScreen> createState() => _EditGoalTemplateScreenState();
}

class _EditGoalTemplateScreenState extends State<EditGoalTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _frequencyController = TextEditingController();

  late GoalType _selectedType;
  late String _selectedCategory;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.template.name;
    _descriptionController.text = widget.template.description;
    _frequencyController.text = widget.template.defaultFrequency.toString();
    _selectedType = widget.template.type;
    _selectedCategory = widget.template.category;

    // Listen for changes to enable/disable save button
    _nameController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _frequencyController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    final hasChanges = _nameController.text.trim() != widget.template.name ||
        _descriptionController.text.trim() != widget.template.description ||
        _frequencyController.text != widget.template.defaultFrequency.toString() ||
        _selectedType != widget.template.type ||
        _selectedCategory != widget.template.category;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goal Template'),
        actions: [
          TextButton(
            onPressed: _isLoading || !_hasChanges ? null : _saveTemplate,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template info header
              _buildTemplateInfoHeader(),
              
              const SizedBox(height: 24),
              
              // Basic Information
              _buildBasicInformationSection(),
              
              const SizedBox(height: 24),
              
              // Goal Type Selection
              _buildGoalTypeSection(),
              
              const SizedBox(height: 24),
              
              // Frequency Configuration
              _buildFrequencySection(),
              
              const SizedBox(height: 24),
              
              // Category Selection
              _buildCategorySection(),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.template.isActive ? Icons.flag : Icons.archive,
                color: widget.template.isActive 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.template.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.template.isActive 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.template.isActive ? 'Active' : 'Archived',
                  style: TextStyle(
                    color: widget.template.isActive 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Used ${widget.template.totalChallengesUsed} times',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Text(
                'Created ${_formatDate(widget.template.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Goal Name',
            hintText: 'e.g., Morning Exercise',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.flag),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a goal name';
            }
            if (value.trim().length < 3) {
              return 'Goal name must be at least 3 characters';
            }
            if (value.trim().length > 50) {
              return 'Goal name must be less than 50 characters';
            }
            
            // Check for duplicate names (excluding current template)
            final provider = context.read<GoalTemplateProvider>();
            final trimmedName = value.trim().toLowerCase();
            final hasDuplicate = provider.activeTemplates.any((template) =>
                template.id != widget.template.id &&
                template.name.toLowerCase() == trimmedName);
            
            if (hasDuplicate) {
              return 'A template with this name already exists';
            }
            
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'e.g., 30+ minutes of cardiovascular exercise',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value != null && value.trim().length > 200) {
              return 'Description must be less than 200 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGoalTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.template.totalChallengesUsed > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Changing the goal type may affect how this template works in future challenges.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Choose how this goal should be tracked',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        const SizedBox(height: 16),
        Column(
          children: GoalType.values.map((type) {
            return RadioListTile<GoalType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    // Update frequency based on type if changing from original
                    if (value != widget.template.type) {
                      if (value == GoalType.daily) {
                        _frequencyController.text = '5';
                      } else {
                        _frequencyController.text = '10';
                      }
                    }
                    _onFormChanged();
                  });
                }
              },
              title: Text(_getGoalTypeTitle(type)),
              subtitle: Text(_getGoalTypeDescription(type)),
              secondary: Icon(_getGoalTypeIcon(type)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getFrequencyLabel(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getFrequencyDescription(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _frequencyController,
          decoration: InputDecoration(
            labelText: _getFrequencyInputLabel(),
            hintText: _getFrequencyHint(),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.repeat),
            suffixText: _getFrequencySuffix(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a ${_getFrequencyLabel().toLowerCase()}';
            }
            final number = int.tryParse(value);
            if (number == null || number <= 0) {
              return 'Please enter a valid positive number';
            }
            if (_selectedType == GoalType.daily && number > 7) {
              return 'Daily goals cannot exceed 7 days per week';
            }
            if (number > 50) {
              return 'Value cannot exceed 50';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a category to help organize your goals',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        GoalCategoryDropdown(
          selectedCategory: _selectedCategory,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
                _onFormChanged();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading || !_hasChanges ? null : _saveTemplate,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isLoading ? null : _handleCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ),
        if (widget.template.isActive) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Template Actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isLoading ? null : _archiveTemplate,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive Template'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.outline,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _reactivateTemplate,
              icon: const Icon(Icons.unarchive_outlined),
              label: const Text('Reactivate Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper methods (same as create screen)
  String _getGoalTypeTitle(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return 'Daily Goal';
      case GoalType.total:
        return 'Total Goal';
    }
  }

  String _getGoalTypeDescription(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return 'Complete once per day, up to X days per week. Cannot earn multiple completions on the same day.';
      case GoalType.total:
        return 'Reach a target number of completions during the challenge. Can earn multiple completions per day.';
    }
  }

  IconData _getGoalTypeIcon(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return Icons.today;
      case GoalType.total:
        return Icons.track_changes;
    }
  }

  String _getFrequencyLabel() {
    switch (_selectedType) {
      case GoalType.daily:
        return 'Days Per Week';
      case GoalType.total:
        return 'Target Completions';
    }
  }

  String _getFrequencyDescription() {
    switch (_selectedType) {
      case GoalType.daily:
        return 'How many days per week you want to complete this goal (1-7 days)';
      case GoalType.total:
        return 'Total number of completions you want to achieve during the challenge';
    }
  }

  String _getFrequencyInputLabel() {
    switch (_selectedType) {
      case GoalType.daily:
        return 'Days per week';
      case GoalType.total:
        return 'Total completions';
    }
  }

  String _getFrequencyHint() {
    switch (_selectedType) {
      case GoalType.daily:
        return 'e.g., 5';
      case GoalType.total:
        return 'e.g., 10';
    }
  }

  String? _getFrequencySuffix() {
    switch (_selectedType) {
      case GoalType.daily:
        return 'days/week';
      case GoalType.total:
        return 'total';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<GoalTemplateProvider>();
      
      final updatedTemplate = widget.template.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        defaultFrequency: int.parse(_frequencyController.text),
        category: _selectedCategory,
      );

      final success = await provider.updateTemplate(updatedTemplate);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to update template'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCancel() async {
    if (_hasChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      
      if (shouldDiscard == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _archiveTemplate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Template'),
        content: Text('Are you sure you want to archive "${widget.template.name}"? You can reactivate it later.'),
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
      setState(() {
        _isLoading = true;
      });

      final provider = context.read<GoalTemplateProvider>();
      final success = await provider.archiveTemplate(widget.template.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template archived successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to archive template'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reactivateTemplate() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<GoalTemplateProvider>();
    final success = await provider.reactivateTemplate(widget.template.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template reactivated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reactivate template'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
}