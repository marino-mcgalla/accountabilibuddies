import 'package:flutter/material.dart';
import 'week_view_grid.dart';
import '../../services/goals_service.dart';

class GoalCard extends StatefulWidget {
  final String goalId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;
  final List<dynamic> week;
  // final Function(BuildContext, String, String, String) scheduleOrSkip;
  final VoidCallback? onDelete; // Optional callback for delete action
  final VoidCallback? onEdit; // Optional callback for edit action

  const GoalCard({
    required this.goalId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    required this.week,
    // required this.scheduleOrSkip,
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
    _weekStatus = List.from(widget.week);
  }

  void _setEditMode(String mode) {
    setState(() {
      _editMode = mode;
    });
  }

  void _handleDayPress(
      BuildContext context, String goalId, String date, String currentStatus) {
    print('handleDayPressed');
    if (_editMode == 'schedule') {
      setState(() {
        int index = _weekStatus.indexWhere((day) => day['date'] == date);
        if (index != -1) {
          _weekStatus[index]['status'] = 'scheduled';
        }
      });
    } else if (_editMode == 'skip') {
      setState(() {
        int index = _weekStatus.indexWhere((day) => day['date'] == date);
        if (index != -1) {
          _weekStatus[index]['status'] = 'skipped';
        }
      });
    } else {
      ('idk the other one');
      // widget.scheduleOrSkip(context, widget.goalId, date, currentStatus);
    }
  }

  Future<void> _saveChanges() async {
    // Update the status of the days in Firebase
    await GoalsService().updateWeek(widget.goalId, _weekStatus);
    setState(() {
      _editMode = null;
    });
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
            WeekViewGrid(
                goalId: widget.goalId,
                week: _weekStatus,
                scheduleOrSkip: _handleDayPress),
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
