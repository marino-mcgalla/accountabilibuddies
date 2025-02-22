import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goals_provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';

class EditGoalDialog extends StatefulWidget {
  final Goal goal;

  const EditGoalDialog({required this.goal, super.key});

  @override
  EditGoalDialogState createState() => EditGoalDialogState();
}

class EditGoalDialogState extends State<EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _goalName;
  late int _goalFrequency;
  late String _goalCriteria;
  late String _goalType;
  late Map<String, dynamic> _currentWeekCompletions;
  List<bool> _selectedGoalType = [false, false];

  @override
  void initState() {
    super.initState();
    _goalName = widget.goal.goalName;
    _goalCriteria = widget.goal.goalCriteria;
    _goalType = widget.goal.goalType;
    _goalFrequency = widget.goal.goalFrequency;
    _currentWeekCompletions = widget.goal.currentWeekCompletions;
    _selectedGoalType = [_goalType == 'total', _goalType == 'weekly'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _goalName,
              decoration: InputDecoration(labelText: 'Goal Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a goal name';
                }
                return null;
              },
              onSaved: (value) {
                _goalName = value!;
              },
            ),
            ToggleButtons(
              isSelected: _selectedGoalType,
              onPressed: (index) {
                setState(() {
                  for (int i = 0; i < _selectedGoalType.length; i++) {
                    _selectedGoalType[i] = i == index;
                  }
                  _goalType = index == 0 ? 'total' : 'weekly';
                  if (_goalType == 'total') {
                    _goalFrequency = 0;
                  } else if (_goalType == 'weekly') {
                    _goalFrequency =
                        4; // Set to 4 as default since it's in the middle
                  }
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Total'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Weekly'),
                ),
              ],
            ),
            if (_goalType == 'total')
              TextFormField(
                initialValue: _goalFrequency.toString(),
                decoration: InputDecoration(labelText: 'Goal Frequency'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal frequency';
                  }
                  return null;
                },
                onSaved: (value) {
                  _goalFrequency = int.parse(value!);
                },
              ),
            if (_goalType == 'weekly')
              Column(
                children: [
                  Text('Goal Frequency: $_goalFrequency days/week'),
                  Slider(
                    value: _goalFrequency.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: _goalFrequency.toString(),
                    onChanged: (value) {
                      setState(() {
                        _goalFrequency = value.toInt();
                      });
                    },
                  ),
                ],
              ),
            TextFormField(
              initialValue: _goalCriteria,
              decoration: InputDecoration(labelText: 'Goal Criteria'),
              onSaved: (value) {
                _goalCriteria = value!;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Goal updatedGoal;
              DateTime now = DateTime.now();
              if (_goalType == 'total') {
                updatedGoal = TotalGoal(
                  id: widget.goal.id,
                  ownerId: widget.goal.ownerId,
                  goalName: _goalName,
                  goalCriteria: _goalCriteria,
                  active: widget.goal.active,
                  goalFrequency: _goalFrequency,
                  weekStartDate: now,
                  currentWeekCompletions:
                      Map<String, int>.from(_currentWeekCompletions),
                );
              } else {
                updatedGoal = WeeklyGoal(
                  id: widget.goal.id,
                  ownerId: widget.goal.ownerId,
                  goalName: _goalName,
                  goalCriteria: _goalCriteria,
                  active: widget.goal.active,
                  goalFrequency: _goalFrequency,
                  weekStartDate: now,
                  currentWeekCompletions:
                      Map<String, String>.from(_currentWeekCompletions),
                );
              }
              Provider.of<GoalsProvider>(context, listen: false)
                  .editGoal(updatedGoal);
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
