// lib/features/proof_submission/services/image_picker_service_stub.dart
import 'dart:typed_data';

/// This is a stub implementation that will never actually be used
/// It exists only to satisfy the conditional import for non-web platforms
class WebImagePickerService {
  Future<Uint8List?> pickImage() {
    throw UnsupportedError('WebImagePickerService is only available for web');
  }

  Future<Uint8List?> takePhoto() {
    throw UnsupportedError('WebImagePickerService is only available for web');
  }

  Future<Uint8List?> takePhotoFallback() {
    throw UnsupportedError('WebImagePickerService is only available for web');
  }
}
