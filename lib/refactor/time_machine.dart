import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'datetime_provider.dart';

class TimeMachineScreen extends StatefulWidget {
  const TimeMachineScreen({super.key});

  @override
  _TimeMachineScreenState createState() => _TimeMachineScreenState();
}

class _TimeMachineScreenState extends State<TimeMachineScreen> {
  DateTime _selectedDateTime = DateTime.now();
  Duration _advanceDuration = Duration(hours: 1);

  @override
  Widget build(BuildContext context) {
    final dateTimeProvider = Provider.of<DateTimeProvider>(context);
    final DateFormat dateFormat = DateFormat('MM-dd-yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Time Machine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text('Current Date and Time'),
              subtitle: Text(dateFormat.format(dateTimeProvider.now)),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Set Custom Date and Time'),
              subtitle: Text(dateFormat.format(_selectedDateTime)),
              trailing: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateTime,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                dateTimeProvider.setCustomDateTime(_selectedDateTime);
              },
              child: Text('Set Custom Date and Time'),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Advance Time by'),
              subtitle: Text(_formatDuration(_advanceDuration)),
              trailing: IconButton(
                icon: Icon(Icons.timer),
                onPressed: () async {
                  Duration? pickedDuration = await showDurationPicker(
                    context: context,
                    initialDuration: _advanceDuration,
                  );
                  if (pickedDuration != null) {
                    setState(() {
                      _advanceDuration = pickedDuration;
                    });
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                dateTimeProvider.advanceTime(_advanceDuration);
              },
              child: Text('Advance Time'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                dateTimeProvider.resetToRealTime();
              },
              child: Text('Reset to Real Time'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }
}

Future<Duration?> showDurationPicker({
  required BuildContext context,
  required Duration initialDuration,
}) async {
  return showDialog<Duration>(
    context: context,
    builder: (context) {
      Duration selectedDuration = initialDuration;
      return AlertDialog(
        title: Text('Pick Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DurationPicker(
              duration: selectedDuration,
              onChange: (duration) {
                selectedDuration = duration;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(selectedDuration);
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

class DurationPicker extends StatefulWidget {
  final Duration duration;
  final ValueChanged<Duration> onChange;

  const DurationPicker({
    required this.duration,
    required this.onChange,
    Key? key,
  }) : super(key: key);

  @override
  _DurationPickerState createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Hours:'),
            Expanded(
              child: Slider(
                value: _duration.inHours.toDouble(),
                min: 0,
                max: 24,
                divisions: 24,
                label: _duration.inHours.toString(),
                onChanged: (value) {
                  setState(() {
                    _duration = Duration(
                        hours: value.toInt(),
                        minutes: _duration.inMinutes % 60);
                    widget.onChange(_duration);
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Minutes:'),
            Expanded(
              child: Slider(
                value: (_duration.inMinutes % 60).toDouble(),
                min: 0,
                max: 59,
                divisions: 59,
                label: (_duration.inMinutes % 60).toString(),
                onChanged: (value) {
                  setState(() {
                    _duration = Duration(
                        hours: _duration.inHours, minutes: value.toInt());
                    widget.onChange(_duration);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
