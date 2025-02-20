import 'package:flutter/material.dart';
import 'package:auth_test/models/goal_model.dart';
import 'package:auth_test/services/new_goals_service.dart';
import 'package:flutter/services.dart';

void showEditGoalDialog(BuildContext context, Goal goal,
    GoalsService goalsService, VoidCallback onGoalEdited) {
  TextEditingController nameController =
      TextEditingController(text: goal.goalName);
  TextEditingController criteriaController =
      TextEditingController(text: goal.criteria);
  TextEditingController completionsController =
      TextEditingController(text: goal.frequency.toString());
  double selectedFrequency = goal.frequency.toDouble();
  int selectedGoalType = goal.goalType == 'daily' ? 0 : 1;
  String? errorMessage;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Goal"),
            content: SingleChildScrollView(
              child: Column(
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
                        if (selectedGoalType == 0 && selectedFrequency > 7) {
                          selectedFrequency =
                              1; // Reset frequency to 1 when switching to daily
                        }
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
                      decoration:
                          const InputDecoration(labelText: "Completions"),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: criteriaController,
                    decoration:
                        const InputDecoration(labelText: "Goal Criteria"),
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
                    final updatedGoal = Goal(
                      id: goal.id,
                      ownerId: goal.ownerId, // Keep the existing ownerId
                      goalName: nameController.text,
                      frequency: selectedGoalType == 0
                          ? selectedFrequency.round()
                          : int.tryParse(completionsController.text) ?? 0,
                      criteria: criteriaController.text,
                      goalType: selectedGoalType == 0 ? "daily" : "total",
                      history: goal.history, // Keep the existing history
                    );
                    await goalsService.editGoal(updatedGoal);
                    Navigator.pop(context);
                    onGoalEdited(); // Call the callback function to update the state
                  } else {
                    setState(() {
                      errorMessage = "Please fill in all fields.";
                    });
                  }
                },
                child: const Text("Save Changes"),
              ),
            ],
          );
        },
      );
    },
  );
}
