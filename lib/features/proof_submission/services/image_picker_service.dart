// lib/features/proof_submission/services/image_picker_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import web-specific libraries conditionally
import 'image_picker_service_web.dart'
    if (dart.library.io) 'image_picker_service_stub.dart';

class ImagePickerService {
  // Instance of platform-specific implementation
  final WebImagePickerService _webImagePickerService = WebImagePickerService();
  final ImagePicker _imagePicker = ImagePicker();

  // Pick an image from the gallery
  Future<Uint8List?> pickImage() async {
    if (kIsWeb) {
      return _webImagePickerService.pickImage();
    } else {
      // Mobile implementation using image_picker
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    }
  }

  // Take a photo using camera
  Future<Uint8List?> takePhoto() async {
    if (kIsWeb) {
      try {
        // Try direct camera access first
        final result = await _webImagePickerService.takePhoto();
        if (result != null) {
          return result;
        }
        // Fall back to alternative method if direct access fails
        return _webImagePickerService.takePhotoFallback();
      } catch (e) {
        debugPrint('Error taking photo on web: $e');
        return _webImagePickerService.takePhotoFallback();
      }
    } else {
      // Mobile implementation using image_picker
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    }
  }
}
