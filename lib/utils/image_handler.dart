import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import 'firebase_storage_util.dart';

class ImageHandler {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorageUtil _storageUtil = FirebaseStorageUtil();

  Future<io.File> compressImage(io.File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 50, // Lower quality for more compression
    );
    if (result != null) {
      return io.File(result.path);
    } else {
      throw Exception('Image compression faileddoesthiswork');
    }
  }

  Future<Uint8List> compressImageWeb(Uint8List bytes) async {
    return FlutterImageCompress.compressWithList(
      bytes,
      quality: 10, // Lower quality for more compression
    );
  }

  Future<int> getFileSize(io.File file) async {
    return file.lengthSync();
  }

  Future<void> uploadImageAndSubmitProof(
      BuildContext context, Function(BuildContext, String) submitProof) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final originalSize = bytes.lengthInBytes;

          final compressedBytes = await compressImageWeb(bytes);
          final compressedSize = compressedBytes.length;

          // Log to the console
          print('Original Size: $originalSize bytes');
          print('Compressed Size: $compressedSize bytes');

          // Use FirebaseStorageUtil to upload the file
          String downloadUrl = await _storageUtil.uploadBytes(compressedBytes);

          await submitProof(context, downloadUrl);
          print('Upload successful');
        }
        // mobile
        else {
          final file = io.File(pickedFile.path);
          final originalSize = await getFileSize(file);
          final compressedFile = await compressImage(file);
          final compressedSize = await getFileSize(compressedFile);

          // Log to the console
          print('Original Size: $originalSize bytes');
          print('Compressed Size: $compressedSize bytes');

          // Use FirebaseStorageUtil to upload the file
          String downloadUrl = await _storageUtil.uploadFile(compressedFile);

          await submitProof(context, downloadUrl);
          print('Upload successful');
        }
      } catch (e) {
        print('Operation failed: $e');
      }
    } else {
      print('No image selected');
    }
  }
}
