import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import '../../features/challenges/presentation/widgets/multi_goal_proof_submission_widget.dart';

/// Global provider for proof submission functionality
final proofSubmissionServiceProvider = Provider<ProofSubmissionService>((ref) {
  return ProofSubmissionService();
});

class ProofSubmissionService {
  /// Show the proof submission menu with camera, gallery, and text options
  Future<void> showProofSubmissionMenu(BuildContext context) async {
    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6), // Dark overlay
      builder: (BuildContext context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuOption(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Open Camera',
                    value: 'camera',
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    context,
                    icon: Icons.photo_library,
                    title: 'Choose from Gallery',
                    value: 'gallery',
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    context,
                    icon: Icons.text_fields,
                    title: 'Text Proof',
                    value: 'text',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null && context.mounted) {
      switch (result) {
        case 'camera':
          await _openCamera(context);
          break;
        case 'gallery':
          await _openGallery(context);
          break;
        case 'text':
          await _openTextProof(context);
          break;
      }
    }
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null && context.mounted) {
        final bytes = await photo.readAsBytes();
        if (context.mounted) {
          if (kIsWeb) {
            // Convert bytes to blob for web
            final blob = html.Blob([bytes], 'image/jpeg');
            await _showMultiGoalSubmission(context, blob);
          } else {
            await _showMultiGoalSubmission(context, bytes);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
    }
  }
  
  Future<void> _showCameraOverlay(BuildContext context, html.MediaStream stream) async {
    // Create camera overlay UI
    final container = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100vw'
      ..style.height = '100vh'
      ..style.backgroundColor = 'black'
      ..style.zIndex = '9999'
      ..style.display = 'flex'
      ..style.flexDirection = 'column'
      ..style.justifyContent = 'center'
      ..style.alignItems = 'center';
    
    final video = html.VideoElement()
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    
    final canvas = html.CanvasElement()
      ..style.display = 'none';
    
    final buttonContainer = html.DivElement()
      ..style.position = 'absolute'
      ..style.bottom = '20px'
      ..style.display = 'flex'
      ..style.gap = '20px';
    
    final captureButton = html.ButtonElement()
      ..text = 'Capture'
      ..style.padding = '12px 24px'
      ..style.backgroundColor = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '6px'
      ..style.fontSize = '16px';
    
    final cancelButton = html.ButtonElement()
      ..text = 'Cancel'
      ..style.padding = '12px 24px'
      ..style.backgroundColor = 'rgba(255,255,255,0.3)'
      ..style.color = 'white'
      ..style.border = '1px solid white'
      ..style.borderRadius = '6px'
      ..style.fontSize = '16px';
    
    buttonContainer.children.addAll([cancelButton, captureButton]);
    container.children.addAll([video, canvas, buttonContainer]);
    html.document.body?.append(container);
    
    // Start video stream
    video.srcObject = stream;
    await video.play();
    
    // Handle capture button
    captureButton.onClick.listen((event) async {
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      canvas.context2D.drawImage(video, 0, 0);
      
      canvas.toBlob('image/jpeg', 0.85).then((blob) async {
        // Stop camera and cleanup
        final tracks = stream.getVideoTracks();
        for (var track in tracks) {
          track.stop();
        }
        container.remove();
        
        // Show multi-goal submission with captured image
        if (context.mounted) {
          await _showMultiGoalSubmission(context, blob);
        }
      });
    });
    
    // Handle cancel button
    cancelButton.onClick.listen((event) {
      // Stop camera and cleanup
      final tracks = stream.getVideoTracks();
      for (var track in tracks) {
        track.stop();
      }
      container.remove();
    });
  }

  Future<void> _openGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (photo != null && context.mounted) {
        final bytes = await photo.readAsBytes();
        if (context.mounted) {
          if (kIsWeb) {
            // Convert bytes to blob for web - same as dashboard
            final blob = html.Blob([bytes], 'image/jpeg');
            await _showMultiGoalSubmission(context, blob);
          } else {
            await _showMultiGoalSubmission(context, bytes);
          }
        }
      }
    } catch (e) {
      // Handle errors silently
    }
  }

  Future<void> _openTextProof(BuildContext context) async {
    await _showMultiGoalSubmission(context, null);
  }

  Future<void> _showMultiGoalSubmission(BuildContext context, dynamic imageBlob) async {
    if (!context.mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(
                    imageBlob != null ? Icons.camera_alt : Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    imageBlob != null ? 'Submit Photo Proof' : 'Submit Proof',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Multi-goal submission widget
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MultiGoalProofSubmissionWidget(imageBlob: imageBlob),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Handle result if needed
    if (result != null) {
      // Process successful submission
    }
  }
}