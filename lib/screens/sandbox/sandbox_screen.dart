import 'package:flutter/material.dart';
import '../../utils/image_handler.dart';

class SandboxScreen extends StatefulWidget {
  @override
  _SandboxScreenState createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final ImageHandler _imageHandler = ImageHandler();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sandbox Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _imageHandler.uploadImageAndSubmitProof(
              context, (context, url) {}),
          child: Text('Upload Photo'),
        ),
      ),
    );
  }
}
