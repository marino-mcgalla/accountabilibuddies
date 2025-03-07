// lib/features/goals/widgets/proof_submission_dialog.dart
import 'dart:typed_data';
import 'package:auth_test/features/time_machine/providers/time_machine_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../../proof_submission/services/image_picker_service.dart';
import '../../proof_submission/services/firebase_storage_service.dart';
import 'package:intl/date_time_patterns.dart';

class ProofSubmissionDialog extends StatefulWidget {
  final Goal goal;
  final Function(String, String?, bool) onSubmit;

  const ProofSubmissionDialog({
    required this.goal,
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  State<ProofSubmissionDialog> createState() => _ProofSubmissionDialogState();
}

class _ProofSubmissionDialogState extends State<ProofSubmissionDialog> {
  final TextEditingController _proofController = TextEditingController();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  Uint8List? _selectedImageData;
  String? _selectedImageName;
  bool _isUploading = false;
  String? _errorMessage;
  String? _statusMessage;
  bool yesterday = false; // [Yesterday, Today]

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    Navigator.of(context).pop(); // Close the dialog temporarily

    try {
      // Use the image picker service
      final imageData = await _imagePickerService.pickImage();

      if (imageData != null && mounted) {
        setState(() {
          _selectedImageData = imageData;
          _selectedImageName =
              'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          _statusMessage = 'Image selected';
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error selecting image: $e';
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    Navigator.of(context).pop(); // Close the dialog temporarily

    try {
      // Try the direct camera method first
      Uint8List? imageData = await _imagePickerService.takePhoto();

      // If direct method fails, try the fallback
      if (imageData == null) {
        debugPrint('Direct camera access failed, trying fallback method...');
        imageData = await _imagePickerService.takePhotoFallback();
      }

      if (imageData != null && mounted) {
        setState(() {
          _selectedImageData = imageData;
          _selectedImageName =
              'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          _statusMessage = 'Photo captured';
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error capturing photo: $e';
        });
      }
    }
  }

  void _showImageOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Image Source'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: _takePhoto,
              child: const ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
              ),
            ),
            SimpleDialogOption(
              onPressed: _pickImage,
              child: const ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitProof() async {
    if (_proofController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter proof details';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _statusMessage = 'Preparing submission...';
    });

    String? imageUrl;
    try {
      // Upload image if selected
      if (_selectedImageData != null && _selectedImageName != null) {
        setState(() {
          _statusMessage = 'Uploading image...';
        });

        debugPrint('Starting image upload for goal ${widget.goal.id}');
        imageUrl = await _storageService.uploadProofImage(
          _selectedImageData!,
          widget.goal.id,
          _selectedImageName!,
        );

        if (imageUrl == null) {
          setState(() {
            _errorMessage = 'Failed to upload image';
            _isUploading = false;
          });
          return;
        }

        debugPrint('Image uploaded successfully. URL: $imageUrl');
        setState(() {
          _statusMessage = 'Image uploaded successfully';
        });
      }

      // Call the onSubmit callback with the proof text and image URL
      setState(() {
        _statusMessage = 'Submitting proof...';
      });

      await widget.onSubmit(_proofController.text, imageUrl, yesterday);

      setState(() {
        _statusMessage = 'Proof submitted successfully';
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Error submitting proof: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeMachineProvider =
        Provider.of<TimeMachineProvider>(context, listen: false);
    final now = timeMachineProvider.now;

    return AlertDialog(
      title: const Text('Submit Proof'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal: ${widget.goal.goalName}'),
            const SizedBox(height: 16),
            TextField(
              controller: _proofController,
              decoration: const InputDecoration(
                labelText: 'Proof Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Yesterday/Today radio buttons, centered, with today on the right side and padding at the bottom
            // Only show this if it is not Monday.
            // TODO: CHANGE DAY TO START DAY PARAMETER

            if (now.weekday != DateTime.monday)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: yesterday,
                      onChanged: (value) {
                        setState(() {
                          yesterday = value!;
                        });
                      },
                    ),
                    const Text('Yesterday'),
                    Radio<bool>(
                      value: false,
                      groupValue: yesterday,
                      onChanged: (value) {
                        setState(() {
                          yesterday = value!;
                        });
                      },
                    ),
                    const Text('Today'),
                  ],
                ),
              ),

            // Image selection button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _showImageOptions,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photo'),
              ),
            ),

            // Selected image preview
            if (_selectedImageData != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedImageData!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (!_isUploading)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 5)],
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedImageData = null;
                              _selectedImageName = null;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Status message (upload progress, etc.)
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],

            // Progress indicator for uploads
            if (_isUploading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isUploading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submitProof,
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
