import 'package:flutter/material.dart';
import '../models/goal_category.dart';

class GoalCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final bool showAllOption;
  final bool showPopular;
  final bool horizontal;

  const GoalCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.showAllOption = false,
    this.showPopular = false,
    this.horizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return _buildHorizontalSelector(context);
    } else {
      return _buildVerticalSelector(context);
    }
  }

  Widget _buildHorizontalSelector(BuildContext context) {
    final categories = _getCategoriesToShow();
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = selectedCategory == item['value'];
          
          return Padding(
            padding: EdgeInsets.only(
              right: index < categories.length - 1 ? 8 : 0,
            ),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item['icon'] != null) ...[
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary
                          : item['color'] as Color?,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(item['name'] as String),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(item['value'] as String);
                }
              },
              backgroundColor: item['color'] != null
                  ? (item['color'] as Color).withValues(alpha: 0.1)
                  : null,
              selectedColor: item['color'] as Color? ?? Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalSelector(BuildContext context) {
    final categories = _getCategoriesToShow();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((item) {
            final isSelected = selectedCategory == item['value'];
            
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item['icon'] != null) ...[
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary
                          : item['color'] as Color?,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(item['name'] as String),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(item['value'] as String);
                }
              },
              backgroundColor: item['color'] != null
                  ? (item['color'] as Color).withValues(alpha: 0.1)
                  : null,
              selectedColor: item['color'] as Color? ?? Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getCategoriesToShow() {
    final categories = <Map<String, dynamic>>[];
    
    // Add "All" option if requested
    if (showAllOption) {
      categories.add({
        'value': 'all',
        'name': 'All',
        'icon': Icons.apps,
        'color': Colors.grey[600],
      });
    }
    
    // Determine which categories to show
    final goalCategories = showPopular 
        ? GoalCategory.popular 
        : GoalCategory.all;
    
    // Add category options
    for (final category in goalCategories) {
      categories.add({
        'value': category.value,
        'name': category.displayName,
        'icon': category.icon,
        'color': category.color,
      });
    }
    
    return categories;
  }
}

// Grid version for selection screens
class GoalCategoryGrid extends StatelessWidget {
  final String? selectedCategory;
  final Function(GoalCategory) onCategorySelected;
  final bool showPopular;

  const GoalCategoryGrid({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.showPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    final categories = showPopular 
        ? GoalCategory.popular 
        : GoalCategory.all;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategory == category.value;
        
        return GestureDetector(
          onTap: () => onCategorySelected(category),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withValues(alpha: 0.2)
                  : category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: category.color, width: 2)
                  : null,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 32,
                  color: category.color,
                ),
                const SizedBox(height: 8),
                Text(
                  category.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? category.color : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dropdown version for forms
class GoalCategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onChanged;
  final String? labelText;
  final String? hintText;

  const GoalCategoryDropdown({
    super.key,
    this.selectedCategory,
    required this.onChanged,
    this.labelText,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: labelText ?? 'Category',
        hintText: hintText ?? 'Select a category',
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: GoalCategory.all.map((category) {
        return DropdownMenuItem<String>(
          value: category.value,
          child: Row(
            children: [
              Icon(
                category.icon,
                size: 20,
                color: category.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }
}