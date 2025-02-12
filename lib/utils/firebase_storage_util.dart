import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;
import 'dart:typed_data';

class FirebaseStorageUtil {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(io.File file) async {
    try {
      Reference ref =
          _storage.ref().child('uploads/${DateTime.now().toIso8601String()}');
      UploadTask uploadTask = ref.putFile(file);

      await uploadTask;
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  Future<String> uploadBytes(Uint8List bytes) async {
    try {
      Reference ref =
          _storage.ref().child('uploads/${DateTime.now().toIso8601String()}');
      UploadTask uploadTask =
          ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      await uploadTask;
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Bytes upload failed: $e');
    }
  }
}
