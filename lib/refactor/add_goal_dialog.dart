import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'goals_provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';

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
    return AlertDialog(
      title: Text('Add Goal'),
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
              DateTime placeholderDate = DateTime(1970, 1, 1);
              if (_goalType == 'total') {
                newGoal = TotalGoal(
                  id: FirebaseFirestore.instance.collection('goals').doc().id,
                  ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  goalName: _goalName,
                  goalCriteria: _goalCriteria,
                  active: false,
                  goalFrequency: _goalFrequency,
                  weekStartDate: placeholderDate,
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
                  weekStartDate: placeholderDate,
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
