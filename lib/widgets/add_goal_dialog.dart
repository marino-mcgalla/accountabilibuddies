import 'package:flutter/material.dart';
import '../../services/new_goals_service.dart';
import '../../models/goal_model.dart';

class AddGoalDialog extends StatefulWidget {
  final GoalsService goalsService;
  final Function onGoalAdded;

  const AddGoalDialog({
    required this.goalsService,
    required this.onGoalAdded,
    Key? key,
  }) : super(key: key);

  @override
  _AddGoalDialogState createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController criteriaController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    frequencyController.dispose();
    criteriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Goal"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Goal Name"),
          ),
          TextField(
            controller: frequencyController,
            decoration:
                const InputDecoration(labelText: "Frequency (per week)"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: criteriaController,
            decoration: const InputDecoration(labelText: "Goal Criteria"),
          ),
          TextField(
            controller: typeController,
            decoration: const InputDecoration(labelText: "Goal type"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty &&
                frequencyController.text.isNotEmpty) {
              final goal = Goal(
                id: '', // Firebase will generate the ID
                name: nameController.text,
                frequency: int.tryParse(frequencyController.text) ?? 1,
                criteria: criteriaController.text,
                type: typeController.text,
                // weekStatus: [],
              );
              await widget.goalsService.createGoal(
                  goal.name, goal.frequency, goal.criteria, goal.type);
              Navigator.pop(context);
              widget.onGoalAdded(); // Callback to refresh the goals
            }
          },
          child: const Text("Add Goal"),
        ),
      ],
    );
  }
}
