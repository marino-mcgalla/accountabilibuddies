import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.io) 'dart:io' as io;

class SandboxScreen extends StatefulWidget {
  @override
  _SandboxScreenState createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref =
            storage.ref().child('uploads/${DateTime.now().toIso8601String()}');

        UploadTask uploadTask;

        if (kIsWeb) {
          // Web-specific handling: read as bytes and upload
          final bytes = await pickedFile.readAsBytes();
          uploadTask =
              ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          final file = io.File(pickedFile.path);
          uploadTask = ref.putFile(file);
        }

        await uploadTask;
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
