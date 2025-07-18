// utils/image_picker_util.dart
import 'package:image_picker/image_picker.dart';

/// Picks an image from the gallery.
/// Returns an [XFile] if the user picks an image or null if canceled.
Future<XFile?> pickImageFromGallery() async {
  final ImagePicker picker = ImagePicker();
  return await picker.pickImage(source: ImageSource.gallery);
}
