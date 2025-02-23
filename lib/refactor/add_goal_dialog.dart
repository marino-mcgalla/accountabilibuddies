import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'goals_provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'datetime_provider.dart'; // Import DateTimeProvider

class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({super.key});

  @override
  AddGoalDialogState createState() => AddGoalDialogState();
}

class AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  String _goalName = '';
  int _goalFrequency = 1; // Default to 1
  String _goalCriteria = '';
  String _goalType = 'total';
  final Map<String, bool> _completions = {};
  List<bool> _selectedGoalType = [true, false]; // Default to 'total'

  @override
  Widget build(BuildContext context) {
    final dateTimeProvider =
        Provider.of<DateTimeProvider>(context, listen: false);

    return AlertDialog(
      title: Row(
        children: [
          Text('Add Goal'),
          SizedBox(width: 8),
          Tooltip(
            message:
                'Total: Can earn multiple completions per day\nWeekly: Maximum 1 completion per day',
            child: Icon(Icons.info_outline, color: Colors.grey),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToggleButtons(
              isSelected: _selectedGoalType,
              onPressed: (index) {
                setState(() {
                  for (int i = 0; i < _selectedGoalType.length; i++) {
                    _selectedGoalType[i] = i == index;
                  }
                  _goalType = index == 0 ? 'total' : 'weekly';
                  if (_goalType == 'total') {
                    _goalFrequency = 1; // Reset to 1 for total goals
                  } else if (_goalType == 'weekly') {
                    _goalFrequency = 4; // Set to 4 as default for weekly goals
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
            TextFormField(
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
            if (_goalType == 'total')
              TextFormField(
                decoration: InputDecoration(labelText: 'Goal Frequency'),
                keyboardType: TextInputType.number,
                initialValue: _goalFrequency.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal frequency';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
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
              Goal newGoal;
              DateTime currentDateTime =
                  dateTimeProvider.now; // Use DateTimeProvider
              if (_goalType == 'total') {
                newGoal = TotalGoal(
                  id: FirebaseFirestore.instance.collection('goals').doc().id,
                  ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  goalName: _goalName,
                  goalCriteria: _goalCriteria,
                  active: false,
                  goalFrequency: _goalFrequency,
                  weekStartDate: currentDateTime,
                  currentWeekCompletions: {},
                );
              } else {
                newGoal = WeeklyGoal(
                  id: FirebaseFirestore.instance.collection('goals').doc().id,
                  ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  goalName: _goalName,
                  goalCriteria: _goalCriteria,
                  active: false,
                  goalFrequency: _goalFrequency,
                  weekStartDate: currentDateTime,
                  currentWeekCompletions: {},
                );
              }
              Provider.of<GoalsProvider>(context, listen: false)
                  .addGoal(newGoal);
              Navigator.of(context).pop();
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
