import 'package:flutter/material.dart';
import 'edit_goal_dialog.dart';
import 'goal_model.dart';

class GoalCard extends StatelessWidget {
  final String goalId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;
  final String goalType;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const GoalCard({
    required this.goalId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    required this.goalType,
    this.onDelete,
    this.onEdit,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(goalName),
        subtitle: Text(
            'Frequency: $goalFrequency\nCriteria: $goalCriteria\nType: $goalType'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
