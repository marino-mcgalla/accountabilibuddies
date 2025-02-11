import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DayCheckbox extends StatelessWidget {
  final String goalId;
  final String date;

  const DayCheckbox({required this.goalId, required this.date, Key? key})
      : super(key: key);

  Future<void> _toggleSkipStatus(
      BuildContext context, String currentStatus) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    DocumentReference goalRef =
        FirebaseFirestore.instance.collection('goals').doc(goalId);
    DocumentSnapshot goalDoc = await goalRef.get();
    if (goalDoc.exists) {
      List<dynamic> weekStatus = goalDoc['weekStatus'];
      int index = weekStatus.indexWhere((day) => day['date'] == date);
      if (index != -1) {
        String newStatus = currentStatus == 'skipped' ? 'blank' : 'skipped';
        weekStatus[index]['status'] = newStatus;
        weekStatus[index]['updatedBy'] = currentUserId;
        weekStatus[index]['updatedAt'] = Timestamp.now();
        await goalRef.update({'weekStatus': weekStatus});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .doc(goalId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return Container(
            decoration: BoxDecoration(
              border: date == today
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const SizedBox.shrink(),
            ),
          );
        }
        var goal = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> weekStatus = goal['weekStatus'];
        var dayStatus = weekStatus.firstWhere((day) => day['date'] == date,
            orElse: () => {'status': 'blank'});
        String goalStatus = dayStatus['status'];

        Color buttonColor = Colors.white;
        IconData? iconData;
        switch (goalStatus) {
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
            border:
                date == today ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: ElevatedButton(
            onPressed: () => _toggleSkipStatus(context, goalStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
            ),
            child: iconData != null
                ? Icon(iconData, color: Colors.black)
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
