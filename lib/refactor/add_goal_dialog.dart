import 'package:auth_test/refactor/goal_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goals_provider.dart';
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
  int _goalFrequency = 0;
  String _goalCriteria = '';
  String _goalType = 'total';
  final Map<String, bool> _completions = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            TextFormField(
              decoration: InputDecoration(labelText: 'Goal Criteria'),
              onSaved: (value) {
                _goalCriteria = value!;
              },
            ),
            DropdownButtonFormField<String>(
              value: _goalType,
              decoration: InputDecoration(labelText: 'Goal Type'),
              items: ['total', 'weekly']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _goalType = value!;
                });
              },
              onSaved: (value) {
                _goalType = value!;
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
              if (_goalType == 'total') {
                newGoal = TotalGoal(
                  id: FirebaseFirestore.instance.collection('goals').doc().id,
                  ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  goalName: _goalName,
                  goalCriteria: _goalCriteria,
                  goalFrequency: _goalFrequency,
                );
              } else {
                newGoal = WeeklyGoal(
                  id: FirebaseFirestore.instance.collection('goals').doc().id,
                  ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  goalName: _goalName,
                  goalCriteria: _goalCriteria,
                  completions: _completions,
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
