import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DayCheckbox extends StatefulWidget {
  final String goalId;
  final String date;
  final String status;
  final Function(BuildContext, String, String, String) toggleStatus;

  const DayCheckbox({
    required this.goalId,
    required this.date,
    required this.status,
    required this.toggleStatus,
    Key? key,
  }) : super(key: key);

  @override
  _DayCheckboxState createState() => _DayCheckboxState();
}

class _DayCheckboxState extends State<DayCheckbox> {
  Color buttonColor = Colors.white;
  bool isProofUploaded = false;

  // Helper function to check if the day is in the future
  bool isFutureDay(String dayDate) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return DateTime.parse(dayDate).isAfter(DateTime.now());
  }

  Future<void> _submitProof(BuildContext context) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    DocumentReference goalRef =
        FirebaseFirestore.instance.collection('goals').doc(widget.goalId);
    DocumentSnapshot goalDoc = await goalRef.get();
    if (goalDoc.exists) {
      List<dynamic> weekStatus = goalDoc['weekStatus'];
      int index = weekStatus.indexWhere((day) => day['date'] == widget.date);
      if (index != -1) {
        weekStatus[index]['status'] = 'pending'; // Change status to 'pending'
        weekStatus[index]['updatedBy'] = currentUserId;
        weekStatus[index]['updatedAt'] = Timestamp.now();
        await goalRef.update({'weekStatus': weekStatus});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proof submitted for today")),
        );
        setState(() {
          buttonColor = Colors
              .yellow; // Change button color to yellow to indicate pending
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    IconData? iconData;

    // Handle the status and appearance for each day
    if (isFutureDay(widget.date)) {
      buttonColor = Colors.white;
      iconData = null;
    } else {
      switch (widget.status) {
        case 'skipped':
          buttonColor = Colors.grey;
          iconData = Icons.block; // Crossed-circle symbol for skipped day
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
          iconData = Icons.add; // Plus sign for today and past days
      }
    }

    // Display upload proof dialog for today and past days
    void _onDayPressed() async {
      if (!isFutureDay(widget.date)) {
        if (DateTime.parse(widget.date).isBefore(DateTime.now()) ||
            widget.date == today) {
          bool? uploadProof = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Upload Proof"),
                content:
                    const Text("Do you want to upload proof for this day?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      _submitProof(context); // Submit proof after confirmation
                    },
                    child: const Text("Upload Proof"),
                  ),
                ],
              );
            },
          );

          // Proceed with the logic if user confirms upload proof
          if (uploadProof == true) {
            // Optionally, you could implement any additional logic after submitting proof.
          }
        }
      } else {
        // Mark future days as skipped when clicked
        widget.toggleStatus(context, widget.goalId, widget.date, 'skipped');
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: widget.date == today
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: ElevatedButton(
        onPressed: _onDayPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: CircleBorder(),
          padding: EdgeInsets.all(20), // Increase the size of the circle
        ),
        child: iconData != null
            ? Icon(iconData, color: Colors.black)
            : const SizedBox.shrink(),
      ),
    );
  }
}
