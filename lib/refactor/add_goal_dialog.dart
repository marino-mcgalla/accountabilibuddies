import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goals_provider.dart';

class AddGoalDialog extends StatefulWidget {
  @override
  _AddGoalDialogState createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  String _goalName = '';
  int _goalFrequency = 0;
  String _goalCriteria = '';
  String _goalType = 'daily';

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
                print('Goal Name: $_goalName');
              },
            ),
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
                print('Goal Frequency: $_goalFrequency');
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Goal Criteria'),
              onSaved: (value) {
                _goalCriteria = value!;
                print('Goal Criteria: $_goalCriteria');
              },
            ),
            DropdownButtonFormField<String>(
              value: _goalType,
              decoration: InputDecoration(labelText: 'Goal Type'),
              items: ['daily', 'weekly', 'additive']
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
                print('Goal Type: $_goalType');
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
              print('Form Saved:');
              print('Goal Name: $_goalName');
              print('Goal Frequency: $_goalFrequency');
              print('Goal Criteria: $_goalCriteria');
              print('Goal Type: $_goalType');
              Provider.of<GoalsProvider>(context, listen: false).addGoal(
                _goalName,
                _goalFrequency,
                _goalCriteria,
                _goalType,
              );
              Navigator.of(context).pop();
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
