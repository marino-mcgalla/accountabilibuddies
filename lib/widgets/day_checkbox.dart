import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DayCheckbox extends StatelessWidget {
  final String goalId;
  final String date;
  final String status;
  final Function(BuildContext, String, String, String) toggleStatus;

  const DayCheckbox(
      {required this.goalId,
      required this.date,
      required this.status,
      required this.toggleStatus,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Color buttonColor = Colors.white;
    IconData? iconData;
    switch (status) {
      case 'skipped':
        buttonColor = Colors.grey;
        iconData = Icons.block;
        break;
      case 'pending':
        buttonColor = Colors.yellow;
        iconData = Icons.warning;
        break;
      case 'approved':
        buttonColor = Colors.green;
        iconData = Icons.check;
        break;
      case 'denied':
        buttonColor = Colors.red;
        iconData = Icons.close;
        break;
      default:
        buttonColor = Colors.white;
        iconData = null;
    }

    return Container(
      decoration: BoxDecoration(
        border: date == today ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: ElevatedButton(
        onPressed: () => toggleStatus(context, goalId, date, status),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
        ),
        child: iconData != null
            ? Icon(iconData, color: Colors.black)
            : const SizedBox.shrink(),
      ),
    );
  }
}
