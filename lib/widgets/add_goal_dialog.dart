import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/new_goals_service.dart';
import '../../models/goal_model.dart';

class AddGoalDialog extends StatefulWidget {
  final GoalsService goalsService;
  final Function onGoalAdded;

  const AddGoalDialog({
    required this.goalsService,
    required this.onGoalAdded,
    super.key,
  });

  @override
  AddGoalDialogState createState() => AddGoalDialogState();
}

class AddGoalDialogState extends State<AddGoalDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController criteriaController = TextEditingController();
  final TextEditingController completionsController = TextEditingController();
  double selectedFrequency = 1;
  String? errorMessage;
  int selectedGoalType = 0; // 0 for daily completions, 1 for total completions

  @override
  void dispose() {
    nameController.dispose();
    criteriaController.dispose();
    completionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create a Goal"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Goal Name"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("Goal Type"),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    "Daily Completions: Completions must be done on separate days of the week\n"
                    "Total Completions: Multiple completions can be earned on the same day",
                child: Icon(Icons.info_outline, size: 18),
              ),
            ],
          ),
          ToggleButtons(
            isSelected: [selectedGoalType == 0, selectedGoalType == 1],
            onPressed: (index) {
              setState(() {
                selectedGoalType = index;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Daily Completions"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Total Completions"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedGoalType == 0) ...[
            const Text("Frequency (per week)"),
            Slider(
              value: selectedFrequency,
              min: 1,
              max: 7,
              divisions: 6,
              label: selectedFrequency.round().toString(),
              onChanged: (value) {
                setState(() {
                  selectedFrequency = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('1'),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Text('7'),
                ),
              ],
            ),
          ] else ...[
            const Text("Total Completions (per week)"),
            TextField(
              controller: completionsController,
              decoration: const InputDecoration(labelText: "Completions"),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: criteriaController,
            decoration: const InputDecoration(labelText: "Goal Criteria"),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
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
                (selectedGoalType == 0 ||
                    completionsController.text.isNotEmpty)) {
              final goal = Goal(
                id: '',
                goalName: nameController.text,
                frequency: selectedGoalType == 0
                    ? selectedFrequency.round()
                    : int.tryParse(completionsController.text) ?? 0,
                criteria: criteriaController.text,
                goalType: selectedGoalType == 0
                    ? "daily"
                    : "total", //TODO: probably don't use 0 and 1 for this, just use a string
                ownerId: 'ownerId',
                history: [],
              );
              await widget.goalsService.createGoal(
                  goal.goalName, goal.frequency, goal.criteria, goal.goalType);
              Navigator.pop(context);
              widget.onGoalAdded(); // Callback to refresh the goals
            } else {
              setState(() {
                errorMessage = "Please fill in all fields.";
              });
            }
          },
          child: const Text("Add Goal"),
        ),
      ],
    );
  }
}
