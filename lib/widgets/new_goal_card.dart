import 'package:auth_test/models/goal_model.dart';
import 'package:auth_test/models/progress_tracker_model.dart';
import 'package:auth_test/services/new_goals_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/daily_progress_tracker.dart';
import '../widgets/total_progress_tracker.dart';
import '../widgets/edit_goal_dialog.dart';

class GoalCard extends StatefulWidget {
  final String goalId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;
  final String goalType;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onSimulateEndOfWeek; // Add the callback

  const GoalCard({
    required this.goalId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    required this.goalType,
    this.onDelete,
    this.onEdit,
    this.onSimulateEndOfWeek, // Add the callback
    super.key,
  });

  @override
  GoalCardState createState() => GoalCardState();
}

class GoalCardState extends State<GoalCard> {
  ProgressTrackerModel? _progressTracker;
  Goal? _goal;
  final GoalsService _goalsService = GoalsService();

  @override
  void initState() {
    super.initState();
    _fetchGoal();
    _fetchProgressTracker();
  }

  Future<void> _fetchGoal() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('goals')
        .doc(widget.goalId)
        .get();
    if (doc.exists) {
      setState(() {
        _goal = Goal.fromFirestore(doc);
        print(_goal?.toMap()); // Debug print
        print('up there');
      });
    }
  }

  Future<void> _fetchProgressTracker() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('weekly_progress')
        .doc(widget.goalId)
        .get();
    if (doc.exists) {
      setState(() {
        _progressTracker = ProgressTrackerModel.fromFirestore(doc);
        // print('Fetched progress tracker: $_progressTracker'); // Debug print
      });
    } else {
      setState(() {
        _progressTracker = null;
      });
    }
  }

  Future<void> _simulateEndOfWeek() async {
    if (_goal != null) {
      await _goalsService.archiveCurrentWeek(_goal!.id);
      await _goalsService.createFreshWeek(
          _goal!.id, _goal!.goalType, _goal!.frequency);
      await _fetchGoal(); // Fetch the updated goal
      await _fetchProgressTracker(); // Fetch the updated progress tracker
      setState(() {
        // Ensure the state is updated to trigger a rebuild
        print('down there');
        print(_goal?.toMap()); // Debug print
        //   print(
        //       'Updated progress tracker after simulateEndOfWeek: $_progressTracker'); // Debug print
      });
      // Call the onSimulateEndOfWeek callback to refresh the goals list in the parent widget
      if (widget.onSimulateEndOfWeek != null) {
        widget.onSimulateEndOfWeek!();
      }
    } else {
      // print('Goal is null');
    }
  }

  void _showEditGoalDialog(BuildContext context) {
    print('Current goal: $_goal'); // Log the current goal
    showEditGoalDialog(context, _goal!, _goalsService, () async {
      print('Goal history: ${_goal?.history}'); // Log the goal history
      await _fetchGoal();
      await _fetchProgressTracker();
      setState(() {
        // Ensure the state is updated to trigger a rebuild
        print('Updated goal after edit: ${_goal?.toMap()}'); // Debug print
        print(
            'Updated progress tracker after edit: $_progressTracker'); // Debug print
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goalName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Frequency: ${widget.goalFrequency}'),
            Text('Criteria: ${widget.goalCriteria}'),
            Text('Type: ${widget.goalType}'),
            SizedBox(height: 16),
            if (_progressTracker != null)
              _goal?.goalType ==
                      'daily' // Use _goal?.goalType instead of widget.goalType
                  ? DailyProgressGrid(progressTracker: _progressTracker!)
                  : TotalProgressBar(progressTracker: _progressTracker!),
            // Other UI elements...
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _simulateEndOfWeek,
              child: Text('Simulate End of Week'),
            ),
            if (widget.onDelete != null)
              ElevatedButton(
                onPressed: widget.onDelete,
                child: Text('Delete Goal'),
              ),
            if (widget.onEdit != null)
              ElevatedButton(
                onPressed: widget
                    .onEdit, // Ensure this is correctly calling the function
                child: Text('Edit Goal'),
              ),
          ],
        ),
      ),
    );
  }
}
