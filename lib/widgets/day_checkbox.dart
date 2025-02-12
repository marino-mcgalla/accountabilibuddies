import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

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
  final ImagePicker _picker = ImagePicker();

  bool isFutureDay(String dayDate) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return DateTime.parse(dayDate).isAfter(DateTime.now());
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
    );
    return result as File? ?? file;
  }

  Future<void> _uploadImageAndSubmitProof(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref =
            storage.ref().child('uploads/${DateTime.now().toIso8601String()}');

        UploadTask uploadTask;
        String downloadUrl = "";

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          uploadTask =
              ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          final file = io.File(pickedFile.path);
          final compressedFile = await _compressImage(file);
          uploadTask = ref.putFile(compressedFile);
        }

        await uploadTask;
        downloadUrl = await ref.getDownloadURL();

        await _submitProof(context, downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proof submitted for today")),
        );
        setState(() {
          buttonColor = Colors.yellow;
        });
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
