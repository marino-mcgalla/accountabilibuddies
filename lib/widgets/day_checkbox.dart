import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.io) 'dart:io' as io;

class SandboxScreen extends StatefulWidget {
  @override
  _SandboxScreenState createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<String?> _uploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref =
            storage.ref().child('uploads/${DateTime.now().toIso8601String()}');

        UploadTask uploadTask;

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          uploadTask =
              ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          final file = io.File(pickedFile.path);
          uploadTask = ref.putFile(file);
        }

        await uploadTask;
        String downloadURL = await ref.getDownloadURL();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful')),
        );
        return downloadURL;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
        return null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sandbox Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _uploadImage,
          child: Text('Upload Photo'),
        ),
      ),
    );
  }
}

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

  bool isFutureDay(String dayDate) {
    return DateTime.parse(dayDate).isAfter(DateTime.now());
  }

  Future<void> _submitProof(String proofUrl) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    DocumentReference goalRef =
        FirebaseFirestore.instance.collection('goals').doc(widget.goalId);
    DocumentSnapshot goalDoc = await goalRef.get();

    if (goalDoc.exists) {
      List<dynamic> weekStatus = goalDoc['weekStatus'];
      int index = weekStatus.indexWhere((day) => day['date'] == widget.date);
      if (index != -1) {
        weekStatus[index]['status'] = 'pending';
        weekStatus[index]['proofUrl'] = proofUrl;
        weekStatus[index]['updatedBy'] = currentUserId;
        weekStatus[index]['updatedAt'] = Timestamp.now();
        await goalRef.update({'weekStatus': weekStatus});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proof submitted for today")),
        );
        setState(() {
          buttonColor = Colors.yellow;
        });
      }
    }
  }

  void _onDayPressed() async {
    if (!isFutureDay(widget.date)) {
      bool? uploadProof = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Upload Proof"),
            content: const Text("Do you want to upload proof for this day?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                  String? proofUrl = await _uploadImageFromDayCheckbox();
                  if (proofUrl != null) {
                    await _submitProof(proofUrl);
                  }
                },
                child: const Text("Upload Proof"),
              ),
            ],
          );
        },
      );
    } else {
      widget.toggleStatus(context, widget.goalId, widget.date, 'skipped');
    }
  }

  Future<String?> _uploadImageFromDayCheckbox() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref =
            storage.ref().child('uploads/${DateTime.now().toIso8601String()}');

        UploadTask uploadTask;

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          uploadTask =
              ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          final file = io.File(pickedFile.path);
          uploadTask = ref.putFile(file);
        }

        await uploadTask;
        return await ref.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
        return null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    IconData? iconData;

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
          padding: EdgeInsets.all(20),
        ),
        child: iconData != null
            ? Icon(iconData, color: Colors.black)
            : const SizedBox.shrink(),
      ),
    );
  }
}
