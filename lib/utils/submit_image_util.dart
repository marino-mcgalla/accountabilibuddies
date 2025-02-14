// utils/submit_image_util.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_handler.dart';

/// Submits the given [image] for the specified [goalId] and [date].
/// It uploads the image and then updates the Firestore document.
Future<void> submitImage({
  required BuildContext context,
  required String goalId,
  required String date,
  required XFile image,
}) async {
  final ImageHandler imageHandler = ImageHandler();

  await imageHandler.submit(
    file: image,
    onUploadSuccess: (String downloadUrl) async {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
      DocumentReference goalRef =
          FirebaseFirestore.instance.collection('goals').doc(goalId);
      DocumentSnapshot goalDoc = await goalRef.get();
      if (goalDoc.exists) {
        List<dynamic> weekStatus = goalDoc['weekStatus'];
        int index = weekStatus.indexWhere((day) => day['date'] == date);
        if (index != -1) {
          weekStatus[index]['status'] = 'pending';
          weekStatus[index]['updatedBy'] = currentUserId;
          weekStatus[index]['updatedAt'] = Timestamp.now();
          weekStatus[index]['proofUrl'] = downloadUrl;
          await goalRef.update({'weekStatus': weekStatus});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Proof submitted for today")),
          );
        }
      }
    },
    onUploadFailure: (String errorMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    },
  );
}
