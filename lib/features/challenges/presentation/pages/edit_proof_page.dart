import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/core.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/proof_providers.dart';

class EditProofPage extends ConsumerStatefulWidget {
  const EditProofPage({
    required this.proof,
    super.key,
  });

  final ProofSubmission proof;

  @override
  ConsumerState<EditProofPage> createState() => _EditProofPageState();
}

class _EditProofPageState extends ConsumerState<EditProofPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final ValueNotifier<DateTime> _selectedDateNotifier;
  XFile? _newImage;
  html.Blob? _webImageBlob; // For web camera captures
  bool _isSubmitting = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.proof.description);
    _selectedDateNotifier = ValueNotifier<DateTime>(widget.proof.submissionDate);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    print('DEBUG: _pickImage called - should open gallery');
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    print('DEBUG: Gallery picker returned, image is ${image != null ? 'not null' : 'null'}');
    
    if (image != null) {
      setState(() {
        _newImage = image;
        _imageChanged = true;
      });
      print('DEBUG: Gallery image set successfully');
    }
  }

  Future<void> _retakePhoto() async {
    try {
      print('DEBUG: _retakePhoto called - should open camera');
      print('DEBUG: Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      
      if (kIsWeb) {
        // For web, use the native camera implementation like in dashboard
        print('DEBUG: Web platform detected, opening native camera');
        await _openWebCamera();
      } else {
        // For mobile platforms
        print('DEBUG: Mobile platform detected');
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        
        print('DEBUG: Mobile camera picker returned, image is ${image != null ? 'not null' : 'null'}');
        
        if (image != null) {
          setState(() {
            _newImage = image;
            _imageChanged = true;
          });
          print('DEBUG: Mobile image set successfully');
        }
      }
    } catch (e) {
      print('DEBUG: Camera error: $e');
      // If camera fails, show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera not available: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWebCamera() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('Camera API not supported in this browser');
      }

      // Create simple camera overlay
      final overlay = html.DivElement()
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'black'
        ..style.zIndex = '9999'
        ..style.display = 'flex'
        ..style.flexDirection = 'column'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center';

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '70%'
        ..style.objectFit = 'cover';

      final canvas = html.CanvasElement()
        ..style.display = 'none';

      final captureButton = html.ButtonElement()
        ..text = 'Capture Photo'
        ..style.padding = '12px 24px'
        ..style.margin = '10px'
        ..style.backgroundColor = 'white'
        ..style.border = 'none'
        ..style.borderRadius = '8px'
        ..style.fontSize = '16px'
        ..style.cursor = 'pointer';

      final cancelButton = html.ButtonElement()
        ..text = 'Cancel'
        ..style.padding = '12px 24px'
        ..style.margin = '10px'
        ..style.backgroundColor = 'gray'
        ..style.color = 'white'
        ..style.border = 'none'
        ..style.borderRadius = '8px'
        ..style.fontSize = '16px'
        ..style.cursor = 'pointer';

      overlay.children.addAll([video, captureButton, cancelButton, canvas]);
      html.document.body!.children.add(overlay);

      // Get camera stream
      final stream = await mediaDevices.getUserMedia({'video': true});
      video.srcObject = stream;

      // Handle capture
      captureButton.onClick.listen((event) async {
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        final context = canvas.getContext('2d') as html.CanvasRenderingContext2D;
        context.drawImage(video, 0, 0);
        
        canvas.toBlob('image/jpeg', 0.85).then((blob) async {
          // Stop camera and close overlay
          final tracks = stream.getVideoTracks();
          for (var track in tracks) {
            track.stop();
          }
          overlay.remove();
          
          setState(() {
            _newImage = null; // We'll handle blob directly
            _imageChanged = true;
          });
          
          print('DEBUG: Web camera photo captured successfully');
          
          // Store blob for upload
          _webImageBlob = blob;
        });
      });

      // Handle cancel
      cancelButton.onClick.listen((event) {
        final tracks = stream.getVideoTracks();
        for (var track in tracks) {
          track.stop();
        }
        overlay.remove();
      });
      
    } catch (e) {
      print('DEBUG: Web camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera not available: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<String?> _uploadImage() async {
    if (!_imageChanged) {
      // Return existing image URL if no new image
      return widget.proof.imageUrls.isNotEmpty ? widget.proof.imageUrls.first : null;
    }

    // Check if we have either a new file or web blob
    if (_newImage == null && _webImageBlob == null) {
      return widget.proof.imageUrls.isNotEmpty ? widget.proof.imageUrls.first : null;
    }

    try {
      final user = ref.read(userProvider);
      if (user == null) return null;

      final String fileName = '${const Uuid().v4()}.jpg';
      final String storagePath = 'proofs/${user.id}/$fileName';
      
      final Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      
      // Upload the image
      if (kIsWeb && _webImageBlob != null) {
        // Upload web camera blob
        final reader = html.FileReader();
        reader.readAsArrayBuffer(_webImageBlob!);
        await reader.onLoadEnd.first;
        final uint8List = reader.result as Uint8List;
        await storageRef.putData(uint8List);
      } else if (_newImage != null) {
        if (kIsWeb) {
          final bytes = await _newImage!.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          final File file = File(_newImage!.path);
          await storageRef.putFile(file);
        }
      }
      
      // Get download URL
      final String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logger.error('Error uploading image', error: e);
      return null;
    }
  }

  Future<void> _updateProof() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload new image if changed
      String? imageUrl;
      if (_imageChanged && _newImage != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      } else {
        // Keep existing image
        imageUrl = widget.proof.imageUrls.isNotEmpty ? widget.proof.imageUrls.first : null;
      }

      // Create updated proof
      final updatedProof = ProofSubmission(
        id: widget.proof.id,
        userId: widget.proof.userId,
        userName: widget.proof.userName,
        challengeGoalStates: widget.proof.challengeGoalStates,
        submissionDate: _selectedDateNotifier.value,
        createdAt: widget.proof.createdAt,
        updatedAt: DateTime.now(),
        contentType: widget.proof.contentType,
        imageUrls: imageUrl != null ? [imageUrl] : [],
        description: _descriptionController.text.trim(),
        metadata: widget.proof.metadata,
      );

      // For now, we'll delete and re-submit the proof as update is not implemented
      final repository = ref.read(proofRepositoryProvider);
      
      // Delete old proof
      final deleteResult = await repository.deleteProof(widget.proof.id);
      if (deleteResult.isFailure) {
        throw Exception('Failed to update proof: ${deleteResult.failureOrNull?.message}');
      }
      
      // Submit updated proof with same ID
      final result = await repository.submitProof(updatedProof);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proof updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          throw Exception(result.failureOrNull?.message ?? 'Failed to update proof');
        }
      }
    } catch (e) {
      logger.error('Error updating proof', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Proof'),
        actions: [
          if (!_isSubmitting)
            TextButton(
              onPressed: _updateProof,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Text(
                'Proof Image',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Display current or new image
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImagePreview(),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Image action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _retakePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Retake Photo'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Date selection
              Text(
                'Proof Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ValueListenableBuilder<DateTime>(
                valueListenable: _selectedDateNotifier,
                builder: (context, selectedDate, child) {
                  return SimpleDateSelector(
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      _selectedDateNotifier.value = date;
                    },
                    // Allow editing dates from the past year up to today
                    startDate: DateTime.now().subtract(const Duration(days: 365)),
                    endDate: DateTime.now(),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Description section
              Text(
                'Description (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Add a description for your proof...',
                ),
                maxLines: 3,
                enabled: !_isSubmitting,
              ),
              
              const SizedBox(height: 24),
              
              // Submit date info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Originally submitted: ${_formatDateTime(widget.proof.submissionDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _updateProof,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageChanged && _newImage != null) {
      // Show new image
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _newImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
        return Image.file(
          File(_newImage!.path),
          fit: BoxFit.cover,
        );
      }
    } else if (widget.proof.imageUrls.isNotEmpty) {
      // Show existing image
      return Image.network(
        widget.proof.imageUrls.first,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // No image placeholder
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No image',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class SimpleDateSelector extends StatefulWidget {
  const SimpleDateSelector({
    required this.selectedDate,
    required this.onDateSelected,
    this.startDate,
    this.endDate,
    super.key,
  });

  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<SimpleDateSelector> createState() => _SimpleDateSelectorState();
}

class _SimpleDateSelectorState extends State<SimpleDateSelector> {
  late DateTime _localSelectedDate;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _localSelectedDate = widget.selectedDate;
    _generateDates();
  }
  
  @override
  void didUpdateWidget(SimpleDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _localSelectedDate = widget.selectedDate;
    }
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      _generateDates();
    }
  }
  
  void _generateDates() {
    final now = DateTime.now();
    
    if (widget.startDate != null && widget.endDate != null) {
      // Use challenge date range
      final challengeStart = widget.startDate!;
      final challengeEnd = widget.endDate!;
      
      // Calculate how many days are in the challenge (max 7)
      final challengeDuration = challengeEnd.difference(challengeStart).inDays + 1;
      
      if (challengeDuration <= 7) {
        // Show all challenge days if 7 or fewer
        _dates = List.generate(challengeDuration, (index) {
          return challengeStart.add(Duration(days: index));
        });
      } else {
        // Show the most recent 7 days of the challenge up to today
        final endDate = now.isBefore(challengeEnd) ? now : challengeEnd;
        _dates = List.generate(7, (index) {
          return endDate.subtract(Duration(days: 6 - index));
        }).where((date) => 
          !date.isBefore(challengeStart) && !date.isAfter(challengeEnd)
        ).toList();
      }
    } else {
      // Fallback to last 7 days
      _dates = List.generate(7, (index) {
        return now.subtract(Duration(days: 6 - index));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dates.map((date) {
              final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
              return Expanded(
                child: Text(
                  dayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Date buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dates.map((date) {
              final isSelected = _localSelectedDate.day == date.day && 
                                 _localSelectedDate.month == date.month && 
                                 _localSelectedDate.year == date.year;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _localSelectedDate = DateTime(date.year, date.month, date.day);
                    });
                    widget.onDateSelected(_localSelectedDate);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${date.day}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary 
                          : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}