import 'package:flutter/material.dart';
import '../models/progress_tracker_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TotalProgressBar extends StatefulWidget {
  final ProgressTrackerModel progressTracker;

  const TotalProgressBar({required this.progressTracker, super.key});

  @override
  _TotalProgressBarState createState() => _TotalProgressBarState();
}

class _TotalProgressBarState extends State<TotalProgressBar> {
  late int _totalCompletions;

  @override
  void initState() {
    super.initState();
    _totalCompletions = widget.progressTracker.totalCompletions ?? 0;
  }

  @override
  void didUpdateWidget(TotalProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progressTracker != oldWidget.progressTracker) {
      setState(() {
        _totalCompletions = widget.progressTracker.totalCompletions ?? 0;
      });
    }
  }

  Future<void> _incrementTotalCompletions() async {
    setState(() {
      _totalCompletions += 1;
    });

    await FirebaseFirestore.instance
        .collection('weekly_progress')
        .doc(widget.progressTracker.goalId)
        .update({
      'totalCompletions': _totalCompletions,
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress =
        _totalCompletions / (widget.progressTracker.targetCompletions ?? 1);
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey,
          color: Colors.blue,
        ),
        SizedBox(height: 8.0),
        Text('${(progress * 100).toStringAsFixed(1)}% completed'),
        SizedBox(height: 8.0),
        ElevatedButton(
          onPressed: _incrementTotalCompletions,
          child: Icon(Icons.add),
        ),
      ],
    );
  }
}
