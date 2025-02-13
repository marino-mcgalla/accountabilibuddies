import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import '../utils/image_handler.dart';

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
  final ImageHandler _imageHandler = ImageHandler();

  bool isFutureDay(String dayDate) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return DateTime.parse(dayDate).isAfter(DateTime.now());
  }

  Future<void> _uploadImageAndSubmitProof(BuildContext context) async {
    await _imageHandler.uploadImageAndSubmitProof(
      (downloadUrl) async {
        await _submitProof(context, downloadUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload successful')),
          );
        }
      },
      (errorMessage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      },
    );
  }

  Future<void> _submitProof(BuildContext context, String proofUrl) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    DocumentReference goalRef =
        FirebaseFirestore.instance.collection('goals').doc(widget.goalId);
    DocumentSnapshot goalDoc = await goalRef.get();
    if (goalDoc.exists) {
      List<dynamic> weekStatus = goalDoc['weekStatus'];
      int index = weekStatus.indexWhere((day) => day['date'] == widget.date);
      if (index != -1) {
        weekStatus[index]['status'] = 'pending';
        weekStatus[index]['updatedBy'] = currentUserId;
        weekStatus[index]['updatedAt'] = Timestamp.now();
        weekStatus[index]['proofUrl'] = proofUrl;
        await goalRef.update({'weekStatus': weekStatus});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Proof submitted for today")),
          );
          setState(() {
            buttonColor = Colors.yellow;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    IconData? iconData;

    if (isFutureDay(widget.date)) {
      buttonColor = Colors.white;
      iconData = null;
    } else {
      switch (widget.status) {
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
          iconData = Icons.add;
      }
    }

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
                      _uploadImageAndSubmitProof(context);
                    },
                    child: const Text("Upload Proof"),
                  ),
                ],
              );
            },
          );

          if (uploadProof == true) {
            // Additional logic after proof submission if needed.
          }
        }
      } else {
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
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(
              5), // Adjust padding to ensure icon stays centered
          minimumSize: const Size(
              40, 40), // Set minimum size to ensure button is not too small
        ),
        child: Center(
          child: iconData != null
              ? Icon(iconData,
                  color: Colors.black, size: 20) // Adjust icon size if needed
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
