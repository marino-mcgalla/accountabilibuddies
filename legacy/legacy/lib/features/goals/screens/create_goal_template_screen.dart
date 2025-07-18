import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/goal_template_provider.dart';
import '../models/goal_template.dart';
import '../models/goal_category.dart';
import '../widgets/goal_category_selector.dart';

class CreateGoalTemplateScreen extends StatefulWidget {
  const CreateGoalTemplateScreen({super.key});

  @override
  State<CreateGoalTemplateScreen> createState() => _CreateGoalTemplateScreenState();
}

class _CreateGoalTemplateScreenState extends State<CreateGoalTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _frequencyController = TextEditingController();

  GoalType _selectedType = GoalType.daily;
  String _selectedCategory = GoalCategory.general.value;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _frequencyController.text = '5'; // Default frequency (5 days per week)
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
        title: const Text('Create Goal Template'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTemplate,
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
              // Header section
              _buildHeaderSection(),
              
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

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a New Goal Template',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Templates help you quickly set up goals for future challenges. You can reuse them with different frequencies as needed.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
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
                    // Update default frequency based on type
                    if (value == GoalType.daily) {
                      _frequencyController.text = '5'; // 5 days per week
                    } else {
                      _frequencyController.text = '10'; // 10 total completions
                    }
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
              });
            }
          },
        ),
        const SizedBox(height: 12),
        // Show suggested goals for selected category
        _buildSuggestedGoals(),
      ],
    );
  }

  Widget _buildSuggestedGoals() {
    final category = GoalCategory.fromString(_selectedCategory);
    final suggestions = category.suggestedGoals.take(3).toList();
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular ${category.displayName} goals:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: category.color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: suggestions.map((suggestion) {
            return ActionChip(
              label: Text(
                suggestion,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                _nameController.text = suggestion;
              },
              backgroundColor: category.color.withValues(alpha: 0.1),
              side: BorderSide(color: category.color.withValues(alpha: 0.3)),
            );
          }).toList(),
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
            onPressed: _isLoading ? null : _saveTemplate,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Creating...' : 'Create Template'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  // Helper methods for goal type information
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

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<GoalTemplateProvider>();
      
      // Check for duplicate names
      if (provider.hasTemplateWithName(_nameController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A template with this name already exists'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final success = await provider.createTemplate(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        defaultFrequency: int.parse(_frequencyController.text),
        category: _selectedCategory,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal template created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to create template'),
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
}