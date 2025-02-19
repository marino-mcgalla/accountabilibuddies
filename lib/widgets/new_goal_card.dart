import 'package:flutter/material.dart';

class GoalCard extends StatefulWidget {
  final String goalId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;
  final String goalType;
  final VoidCallback? onDelete; // Optional callback for delete action
  final VoidCallback? onEdit; // Optional callback for edit action

  const GoalCard({
    required this.goalId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    required this.goalType,
    this.onDelete, // Optional delete action
    this.onEdit, // Optional edit action
    Key? key,
  }) : super(key: key);

  @override
  _GoalCardState createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  String? _editMode;
  List<Map<String, dynamic>> _weekStatus = [];

  @override
  void initState() {
    super.initState();
  }

  void _setEditMode(String mode) {
    setState(() {
      _editMode = mode;
    });
  }

  Future<void> _saveChanges() async {
    print('saved');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.goalName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Frequency: ${widget.goalFrequency} times per week"),
            const SizedBox(height: 10),
            Text("Criteria: ${widget.goalCriteria}"),
            const SizedBox(height: 20),
            Text("Type: ${widget.goalType}"),
            const SizedBox(height: 20),
            // WeekViewGrid(
            //     goalId: widget.goalId,
            //     week: _weekStatus,
            //     scheduleOrSkip: _handleDayPress),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_editMode == null) ...[
                  ElevatedButton(
                    onPressed: () => _setEditMode('schedule'),
                    child: const Text('Schedule'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _setEditMode('skip'),
                    child: const Text('Skip'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Save'),
                  ),
                ],
                const SizedBox(width: 10),
                if (widget.onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: widget.onEdit,
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
