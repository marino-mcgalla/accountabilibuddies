// lib/features/proof_submission/services/firebase_storage_service.dart
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload an image to Firebase Storage and return the download URL (web version)
  Future<String?> uploadProofImage(
      Uint8List imageData, String goalId, String fileName) async {
    try {
      // Get current user ID
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Error: User is not logged in');
        return null;
      }

      // Create a unique file name with timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String storagePath = 'proofs/$userId/$goalId/${timestamp}_$fileName';

      // Create storage reference
      final storageRef = _storage.ref().child(storagePath);

      // Upload the data
      final uploadTask = storageRef.putData(
        imageData,
        SettableMetadata(
            contentType: 'image/jpeg'), // Assume JPEG for simplicity
      );

      // Wait for the upload to complete
      final taskSnapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Delete a proof image from Firebase Storage
  Future<bool> deleteProofImage(String imageUrl) async {
    try {
      // Extract the path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
}
