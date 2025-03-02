import 'package:flutter/material.dart';
import '../models/goal_form_model.dart';

class GoalForm extends StatefulWidget {
  final GoalFormModel model;
  final Function(GoalFormModel) onFormChanged;

  const GoalForm({
    required this.model,
    required this.onFormChanged,
    Key? key,
  }) : super(key: key);

  @override
  GoalFormState createState() => GoalFormState();
}

class GoalFormState extends State<GoalForm> {
  late GoalFormModel _model;
  final TextEditingController _criteriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = widget.model;
    _criteriaController.text = _model.goalCriteria;

    // Add listener to update model when text changes
    _criteriaController.addListener(() {
      _model.goalCriteria = _criteriaController.text;
      widget.onFormChanged(_model);
    });
  }

  @override
  void dispose() {
    _criteriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check screen size for responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Form(
      key: _model.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Goal type toggle - using fixed sizes that won't overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToggleButton(0, 'Total', isSmallScreen),
              const SizedBox(width: 8),
              _buildToggleButton(1, 'Weekly', isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 24 : 16),

          // Goal name
          TextFormField(
            initialValue: _model.goalName,
            decoration: InputDecoration(
              labelText: 'Goal Name',
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 16.0 : 12.0,
                horizontal: 16.0,
              ),
            ),
            style: TextStyle(fontSize: isSmallScreen ? 16.0 : 14.0),
            validator: _model.validateName,
            onChanged: (value) {
              setState(() {
                _model.goalName = value;
                widget.onFormChanged(_model);
              });
            },
          ),
          SizedBox(height: isSmallScreen ? 24 : 16),

          // Goal frequency
          if (_model.goalType == 'total')
            TextFormField(
              initialValue: _model.goalFrequency.toString(),
              decoration: InputDecoration(
                labelText: 'Goal Target (Total)',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 16.0 : 12.0,
                  horizontal: 16.0,
                ),
              ),
              style: TextStyle(fontSize: isSmallScreen ? 16.0 : 14.0),
              keyboardType: TextInputType.number,
              validator: _model.validateFrequency,
              onChanged: (value) {
                if (value.isNotEmpty && int.tryParse(value) != null) {
                  setState(() {
                    _model.goalFrequency = int.parse(value);
                    widget.onFormChanged(_model);
                  });
                }
              },
            )
          else
            Column(
              children: [
                Text(
                  'Goal Frequency: ${_model.goalFrequency} days/week',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 14,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: isSmallScreen ? 12 : 10,
                    ),
                    trackHeight: isSmallScreen ? 6 : 4,
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: isSmallScreen ? 24 : 20,
                    ),
                  ),
                  child: Slider(
                    value: _model.goalFrequency.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: _model.goalFrequency.toString(),
                    onChanged: (value) {
                      setState(() {
                        _model.goalFrequency = value.toInt();
                        widget.onFormChanged(_model);
                      });
                    },
                  ),
                ),
              ],
            ),
          SizedBox(height: isSmallScreen ? 24 : 16),

          // Goal criteria with fixed height constraints
          Container(
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? 150 : 120, // Limit max height
            ),
            child: TextFormField(
              controller:
                  _criteriaController, // Use controller instead of initialValue
              decoration: InputDecoration(
                labelText: 'Goal Criteria',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 16.0 : 12.0,
                  horizontal: 16.0,
                ),
                hintText: 'Describe your goal criteria here...',
              ),
              style: TextStyle(fontSize: isSmallScreen ? 16.0 : 14.0),
              // Set a fixed number of lines to prevent unpredictable expansion
              maxLines: isSmallScreen ? 4 : 3,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }

  // Custom toggle button that won't overflow
  Widget _buildToggleButton(int index, String text, bool isSmallScreen) {
    final isSelected = _model.selectedGoalType[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          _model.updateGoalType(index);
          widget.onFormChanged(_model);
        });
      },
      child: Container(
        width: isSmallScreen ? 120 : 100,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
