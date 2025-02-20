import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress_tracker_model.dart';

class DailyProgressGrid extends StatefulWidget {
  final ProgressTrackerModel progressTracker;

  const DailyProgressGrid({required this.progressTracker, super.key});

  @override
  _DailyProgressGridState createState() => _DailyProgressGridState();
}

class _DailyProgressGridState extends State<DailyProgressGrid> {
  late List<DayProgress> _days;
  String? _editMode;

  @override
  void initState() {
    super.initState();
    _days = widget.progressTracker.days ?? [];
  }

  @override
  void didUpdateWidget(DailyProgressGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progressTracker != oldWidget.progressTracker) {
      setState(() {
        _days = widget.progressTracker.days ?? [];
      });
    }
  }

  void _setDayStatus(int index, String status) {
    setState(() {
      _days[index] = DayProgress(
        date: _days[index].date,
        status: status,
      );
    });
  }

  Future<void> _saveChanges() async {
    // Update Firestore
    await FirebaseFirestore.instance
        .collection('weekly_progress')
        .doc(widget.progressTracker.goalId)
        .update({
      'days': _days.map((day) => day.toMap()).toList(),
    });

    // Reset mode and update state
    setState(() {
      _editMode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_editMode == null) ...[
          ElevatedButton(
            onPressed: () {
              setState(() {
                _editMode = 'skipped';
              });
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _editMode = 'scheduled';
              });
            },
            child: const Text('Schedule'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _saveChanges,
            child: const Text('Save'),
          ),
        ],
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days in a week
            ),
            itemCount: _days.length,
            itemBuilder: (context, index) {
              DayProgress dayProgress = _days[index];
              return GestureDetector(
                onTap: () {
                  if (_editMode != null) {
                    _setDayStatus(
                        index, _editMode!); // Set status based on edit mode
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: _getColorForStatus(dayProgress.status),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      dayProgress.date.day.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
