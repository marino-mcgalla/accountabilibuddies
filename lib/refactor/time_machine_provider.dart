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

  void setCustomDateTime(DateTime dateTime) {
    print('time set to: ${dateTime}');
    _customDateTime = dateTime;
    _useCustomDateTime = true;
    notifyListeners();
  }

  void resetToRealTime() {
    _customDateTime = null;
    _useCustomDateTime = false;
    print('time set to: ${DateTime.now()}');
    notifyListeners();
  }

  void advanceTime(Duration duration) {
    _useCustomDateTime = true;
    if (_useCustomDateTime && _customDateTime != null) {
      _customDateTime = _customDateTime!.add(duration);
      print('time set to ${_customDateTime}');
      notifyListeners();
    } else {
      _customDateTime = DateTime.now();
      _customDateTime = _customDateTime!.add(duration);
      print('time set to ${_customDateTime}');
      notifyListeners();
    }
  }
}
