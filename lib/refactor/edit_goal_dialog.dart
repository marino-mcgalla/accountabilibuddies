import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goals_provider.dart';
import 'goal_model.dart';

class EditGoalDialog extends StatefulWidget {
  final Goal goal;

  const EditGoalDialog({required this.goal, Key? key}) : super(key: key);

  @override
  _EditGoalDialogState createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _goalName;
  late int _goalFrequency;
  late String _goalCriteria;
  late String _goalType;

  @override
  void initState() {
    super.initState();
    _goalName = widget.goal.goalName;
    _goalFrequency = widget.goal.goalFrequency;
    _goalCriteria = widget.goal.goalCriteria;
    _goalType = widget.goal.goalType;
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
            TextFormField(
              initialValue: _goalCriteria,
              decoration: InputDecoration(labelText: 'Goal Criteria'),
              onSaved: (value) {
                _goalCriteria = value!;
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
              Provider.of<GoalsProvider>(context, listen: false).editGoal(
                widget.goal.id,
                _goalName,
                _goalFrequency,
                _goalCriteria,
                _goalType,
              );
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
