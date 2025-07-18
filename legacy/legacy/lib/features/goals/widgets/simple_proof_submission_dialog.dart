import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../proof_submission/services/firebase_storage_service.dart';
import '../../proof_submission/services/image_picker_service.dart';
import '../models/goal_model.dart';

class SimpleProofSubmissionDialog extends StatefulWidget {
  final Goal goal;
  final Function(String?, bool) onSubmit; // imageUrl, yesterday
  final bool isOverwrite;

  const SimpleProofSubmissionDialog({
    required this.goal,
    required this.onSubmit,
    this.isOverwrite = false,
    Key? key,
  }) : super(key: key);

  @override
  State<SimpleProofSubmissionDialog> createState() => _SimpleProofSubmissionDialogState();
}

class _SimpleProofSubmissionDialogState extends State<SimpleProofSubmissionDialog> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  
  Uint8List? _imageData;
  bool _isUploading = false;

  Future<void> _pickImageFromGallery() async {
    try {
      final imageData = await _imagePickerService.pickImage();
      if (imageData != null && mounted) {
        setState(() {
          _imageData = imageData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      // Show loading indicator while camera is being accessed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening camera...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      final imageData = await _imagePickerService.takePhoto();
      if (imageData != null && mounted) {
        setState(() {
          _imageData = imageData;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No photo taken or camera access denied'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitProof() async {
    if (_imageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload image
      final imageName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageUrl = await _storageService.uploadProofImage(
        _imageData!,
        widget.goal.id,
        imageName,
      );

      if (imageUrl != null) {
        await widget.onSubmit(imageUrl, false); // Always submit for today
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.isOverwrite ? "Replace" : "Submit"} Photo Proof'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview or placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _imageData != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageData!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('Add Photo', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          
          // Camera/Gallery buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: _isUploading ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              TextButton.icon(
                onPressed: _isUploading ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading || _imageData == null ? null : _submitProof,
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isOverwrite ? 'Replace' : 'Submit'),
        ),
      ],
    );
  }
}