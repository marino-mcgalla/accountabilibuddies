import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/image_picker_util.dart';
import '../utils/confirmation_dialog_util.dart';
import '../utils/submit_image_util.dart';

class DayCheckbox extends StatefulWidget {
  final String goalId;
  final String date;
  final String status;
  final Function(BuildContext, String, String, String) scheduleOrSkip;

  const DayCheckbox({
    required this.goalId,
    required this.date,
    required this.status,
    required this.scheduleOrSkip,
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

  //TODO: didn't we make a util for this?
  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid || Platform.isIOS) {
      PermissionStatus cameraStatus = await Permission.camera.status;
      PermissionStatus photosStatus;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 32) {
          photosStatus = await Permission.storage.status;
          if (!photosStatus.isGranted) {
            photosStatus = await Permission.storage.request();
          }
        } else {
          photosStatus = await Permission.photos.status;
          if (!photosStatus.isGranted) {
            photosStatus = await Permission.photos.request();
          }
        }
      } else {
        photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
      }

      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }
      return cameraStatus.isGranted && photosStatus.isGranted;
    }
    return false;
  }

  Future<void> _handleUploadProof(BuildContext context) async {
    XFile? image;
    bool confirmed = false;

    while (!confirmed) {
      // STEP 1: Pick image
      image = await pickImageFromGallery();
      if (image == null) return; // User canceled picking

      // STEP 2: Confirm image
      String? action = await showImageConfirmationDialog(context, image);
      if (action == 'cancel') return; // User did not confirm the image
      if (action == 'confirm') confirmed = true;
      if (action == 'change') continue; // User wants to change the photo
    }

    // STEP 3: Submit (upload) image
    await submitImage(
      context: context,
      goalId: widget.goalId,
      date: widget.date,
      image: image!,
    );
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    IconData? iconData;

    //TODO: move this probably
    switch (widget.status) {
      case 'skipped':
        buttonColor = const Color.fromARGB(255, 194, 192, 192);
        iconData = Icons.redo;
        break;
      case 'scheduled':
        buttonColor = Colors.blue;
        iconData = Icons.calendar_month;
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
      // }
    }

    //TODO: reimplement this somewhere else
    void _onDayPressed(BuildContext newContext) async {
      //   if (!isFutureDay(widget.date)) {
      //     if (DateTime.parse(widget.date).isBefore(DateTime.now()) ||
      //         widget.date == today) {
      //       if (await _requestPermissions()) {
      //         // Ask the user if they want to upload proof.
      //         bool? uploadProof = await showDialog<bool>(
      //           context: newContext,
      //           builder: (BuildContext context) {
      //             return AlertDialog(
      //               title: const Text("Upload Proof"),
      //               content:
      //                   const Text("Do you want to upload proof for this day?"),
      //               actions: [
      //                 TextButton(
      //                   onPressed: () => Navigator.pop(context, false),
      //                   child: const Text("Cancel"),
      //                 ),
      //                 ElevatedButton(
      //                   onPressed: () => Navigator.pop(context, true),
      //                   child: const Text("Upload Proof"),
      //                 ),
      //               ],
      //             );
      //           },
      //         );

      //         if (uploadProof == true) {
      //           await _handleUploadProof(newContext);
      //         }
      //       } else {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           const SnackBar(content: Text('Photo permissions denied')),
      //         );
      //       }
      //     }
      //   } else {
      //     widget.scheduleOrSkip(context, widget.goalId, widget.date, widget.status);
      //   }
    }

    return Container(
      decoration: BoxDecoration(
        border: widget.date == today
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Builder(
        builder: (BuildContext newContext) {
          return ElevatedButton(
            onPressed: () {
              widget.scheduleOrSkip(
                  newContext, widget.goalId, widget.date, widget.status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(5),
              minimumSize: const Size(40, 40),
            ),
            child: Center(
              child: iconData != null
                  ? Icon(iconData, color: Colors.black, size: 20)
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
