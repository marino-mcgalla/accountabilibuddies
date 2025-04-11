import 'package:flutter/material.dart';

class TimeMachineProvider with ChangeNotifier {
  DateTime? _customDateTime;
  bool _useCustomDateTime = false;

  DateTime get now {
    if (_useCustomDateTime && _customDateTime != null) {
      return _customDateTime!;
    }
    return DateTime.now();
  }

  DateTime get startOfWeek {
    DateTime currentDateTime = now;
    DateTime startOfWeek = currentDateTime.subtract(
        Duration(days: currentDateTime.weekday - 1)); // Start from Monday
    return DateTime(startOfWeek.year, startOfWeek.month,
        startOfWeek.day); // Set time to midnight
  }

  void setCustomDateTime(DateTime dateTime) {
    _customDateTime = dateTime;
    _useCustomDateTime = true;
    notifyListeners();
  }

  void resetToRealTime() {
    _customDateTime = null;
    _useCustomDateTime = false;
    notifyListeners();
  }

  void advanceTime(Duration duration) {
    _useCustomDateTime = true;
    if (_useCustomDateTime && _customDateTime != null) {
      _customDateTime = _customDateTime!.add(duration);
      notifyListeners();
    } else {
      _customDateTime = DateTime.now();
      _customDateTime = _customDateTime!.add(duration);
      notifyListeners();
    }
  }
}
