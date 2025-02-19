import 'package:auth_test/models/goal_model.dart';
import 'package:auth_test/models/progress_tracker_model.dart';
import 'package:auth_test/services/new_goals_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/daily_progress_tracker.dart';
import '../widgets/total_progress_tracker.dart';

class GoalCard extends StatefulWidget {
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
          widget.goalId, _goal!.goalType, _goal!.frequency);
      _fetchProgressTracker(); // Refresh the progress tracker for the new week
    } else {}
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
              widget.goalType == 'daily'
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
                onPressed: widget.onEdit,
                child: Text('Edit Goal'),
              ),
          ],
        ),
      ),
    );
  }
}
