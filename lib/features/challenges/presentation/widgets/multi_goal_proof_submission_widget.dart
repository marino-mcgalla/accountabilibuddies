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
import '../../../parties/domain/entities/party.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../domain/entities/challenge_goal.dart';
import '../../domain/entities/proof_submission.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../providers/challenge_providers.dart';
import '../providers/proof_providers.dart';
import '../../../../core/utils/display_name_utils.dart';

/// Represents a selectable goal across challenges
class SelectableGoal {
  const SelectableGoal({
    required this.challengeId,
    required this.participationId,
    required this.goalTemplateId,
    required this.goalName,
    required this.partyName,
    required this.frequency,
    required this.challengeGoal,
  });

  final String challengeId;
  final String participationId;
  final String goalTemplateId;
  final String goalName;
  final String partyName;
  final String frequency;
  final ChallengeGoal challengeGoal;

  String get displayText => '$goalName ($partyName)';
  String get key => '$challengeId:$goalTemplateId';
  GoalType get goalType => challengeGoal.goalType;
}

class MultiGoalProofSubmissionWidget extends ConsumerStatefulWidget {
  const MultiGoalProofSubmissionWidget({
    this.imageBlob,
    super.key,
  });

  /// Optional image blob for photo proofs (web only)
  final dynamic imageBlob; // html.Blob on web, null on mobile

  @override
  ConsumerState<MultiGoalProofSubmissionWidget> createState() => _MultiGoalProofSubmissionWidgetState();
}

class _MultiGoalProofSubmissionWidgetState extends ConsumerState<MultiGoalProofSubmissionWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late final ValueNotifier<Set<String>> _selectedGoalKeysNotifier; // Use ValueNotifier for selected goals
  late final ValueNotifier<DateTime> _selectedDateNotifier; // Use ValueNotifier to avoid full rebuilds
  XFile? _selectedImage; // Selected image from gallery
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedGoalKeysNotifier = ValueNotifier<Set<String>>({});
    _selectedDateNotifier = ValueNotifier<DateTime>(DateTime.now());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _selectedGoalKeysNotifier.dispose();
    _selectedDateNotifier.dispose();
    _cleanupCamera(); // Ensure camera is stopped when widget is disposed
    super.dispose();
  }

  /// Cleanup camera resources - stops all video tracks and removes camera container
  void _cleanupCamera() {
    if (kIsWeb) {
      try {
        // Find and stop any active camera streams
        final container = html.document.getElementById('camera-container');
        if (container != null) {
          final video = container.querySelector('#camera-preview') as html.VideoElement?;
          if (video?.srcObject != null) {
            final stream = video!.srcObject as html.MediaStream;
            final tracks = stream.getVideoTracks();
            for (var track in tracks) {
              track.stop();
            }
          }
          container.remove();
        }
      } catch (e) {
        // Silently handle cleanup errors to avoid disrupting app flow
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final partiesAsync = ref.watch(partiesProvider);
    
    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Please log in to submit proofs'),
        ),
      );
    }

    return partiesAsync.when(
      data: (parties) => _buildProofSubmissionForm(parties, user),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading parties: $error'),
        ),
      ),
    );
  }

  Widget _buildProofSubmissionForm(List<Party> parties, UserModel user) {
    // Get all selectable goals across all parties
    final selectableGoals = _getSelectableGoals(parties, user.id);

    if (selectableGoals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No active challenges with goals available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.imageBlob != null ? Icons.photo_camera : Icons.photo_library,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.imageBlob != null ? 'Submit Photo' : 'Submit Proof',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Show helpful text based on flow
              if (widget.imageBlob != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Photo selected! Choose which goals to submit this proof for.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Camera image preview (for camera submissions) - show at top
              if (widget.imageBlob != null) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb && widget.imageBlob != null
                        ? Image.network(
                            html.Url.createObjectUrl(widget.imageBlob),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                child: const Center(
                                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 100,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            child: const Center(
                              child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Goal Selection Section
              ValueListenableBuilder<Set<String>>(
                valueListenable: _selectedGoalKeysNotifier,
                builder: (context, selectedGoalKeys, child) {
                  return Text(
                    'Select Goals (${selectedGoalKeys.length})',
                    style: Theme.of(context).textTheme.labelLarge,
                  );
                },
              ),
              const SizedBox(height: 6),
              
              
              // Goal Selection List
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: selectableGoals.length,
                  itemBuilder: (context, index) {
                    final goal = selectableGoals[index];
                    
                    return ValueListenableBuilder<Set<String>>(
                      valueListenable: _selectedGoalKeysNotifier,
                      builder: (context, selectedGoalKeys, child) {
                        final isSelected = selectedGoalKeys.contains(goal.key);
                        
                        return CheckboxListTile(
                          dense: true,
                          title: Text(
                            goal.goalName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Party: ${goal.partyName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                goal.frequency,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            final currentSet = Set<String>.from(_selectedGoalKeysNotifier.value);
                            if (value == true) {
                              currentSet.add(goal.key);
                            } else {
                              currentSet.remove(goal.key);
                            }
                            _selectedGoalKeysNotifier.value = currentSet;
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Image picker button for gallery submissions (only show when no camera image)
              if (widget.imageBlob == null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add proof (optional)',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          _cleanupCamera(); // Stop camera when opening gallery
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85, // Compress to reduce file size
                          );
                          if (image != null) {
                            if (_isValidImageFile(image)) {
                              setState(() {
                                _selectedImage = image;
                              });
                            } else {
                              _showInvalidFileTypeError();
                            }
                          }
                        },
                        icon: Icon(_selectedImage != null ? Icons.check_circle : Icons.photo_library),
                        label: Text(_selectedImage != null ? 'Image Selected' : 'Choose from Gallery'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Or submit with text description only',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Image preview (new)
                if (_selectedImage != null) ...[
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  child: const Center(
                                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  child: const Center(
                                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedImage!.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              
              // Date selector with 7 radio buttons for the week (always show)
              Text(
                'Proof Date',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<DateTime>(
                valueListenable: _selectedDateNotifier,
                builder: (context, selectedDate, child) {
                  // Get challenge date range from the first selectable goal
                  DateTime? challengeStartDate;
                  DateTime? challengeEndDate;
                  
                  if (selectableGoals.isNotEmpty) {
                    final firstGoal = selectableGoals.first;
                    final challengeAsync = ref.watch(challengeProvider(firstGoal.challengeId));
                    challengeAsync.whenData((challenge) {
                      if (challenge != null) {
                        challengeStartDate = challenge.startDate;
                        challengeEndDate = challenge.endDate;
                      }
                    });
                  }
                  
                  return SimpleDateSelector(
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      _selectedDateNotifier.value = date; // Only updates the date selector
                    },
                    startDate: challengeStartDate,
                    endDate: challengeEndDate,
                  );
                },
              ),
              const SizedBox(height: 12),
              
              // Proof Description (moved after date picker)
              Text(
                'Proof Description',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe how you completed your goal(s)...',
                  isDense: true,
                ),
                maxLines: 2,
                maxLength: 150,
                validator: (value) {
                  // Description is now optional
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Submit Button
              ValueListenableBuilder<Set<String>>(
                valueListenable: _selectedGoalKeysNotifier,
                builder: (context, selectedGoalKeys, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || selectedGoalKeys.isEmpty) ? null : () => _showConfirmationDialog(selectableGoals, user),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(selectedGoalKeys.isEmpty 
                              ? 'Please select at least one goal' 
                              : 'Submit Proof for ${selectedGoalKeys.length} Goal${selectedGoalKeys.length == 1 ? '' : 's'}'),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 6),
              
              // Info text
              Text(
                'Separate proof submissions will be created for each challenge. Each will be reviewed independently by party members.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SelectableGoal> _getSelectableGoals(List<Party> parties, String userId) {
    final selectableGoals = <SelectableGoal>[];
    
    for (final party in parties) {
      final currentChallengeAsync = ref.watch(currentChallengeProvider(party.id));
      
      currentChallengeAsync.whenData((challenge) {
        if (challenge != null) {
          final participationsAsync = ref.watch(challengeParticipationsProvider(challenge.id));
          
          participationsAsync.whenData((participations) {
            UserChallengeParticipation? userParticipation;
            try {
              userParticipation = participations.firstWhere((p) => p.userId == userId);
            } catch (e) {
              userParticipation = null;
            }
            
            if (userParticipation != null && userParticipation.isLockedIn) {
              for (final entry in userParticipation.goals.entries) {
                selectableGoals.add(SelectableGoal(
                  challengeId: challenge.id,
                  participationId: userParticipation.id,
                  goalTemplateId: entry.key,
                  goalName: entry.value.name,
                  partyName: party.name,
                  frequency: entry.value.frequencyDisplay,
                  challengeGoal: entry.value,
                ));
              }
            }
          });
        }
      });
    }
    
    return selectableGoals;
  }



  Future<void> _showConfirmationDialog(List<SelectableGoal> selectableGoals, UserModel user) async {
    final selectedGoals = selectableGoals.where((g) => _selectedGoalKeysNotifier.value.contains(g.key)).toList();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Proof Submission'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview (if available)
              if (_selectedImage != null || widget.imageBlob != null) ...[
                const Text(
                  'Image:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.imageBlob != null
                        ? (kIsWeb
                            ? Image.network(
                                html.Url.createObjectUrl(widget.imageBlob),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 100,
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    child: const Center(
                                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                height: 100,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                child: const Center(
                                  child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                ),
                              ))
                        : (_selectedImage != null
                            ? (kIsWeb
                                ? Image.network(
                                    _selectedImage!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 100,
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        child: const Center(
                                          child: Icon(Icons.image, size: 50, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 100,
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        child: const Center(
                                          child: Icon(Icons.image, size: 50, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ))
                            : Container(
                                height: 100,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                child: const Center(
                                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              )),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Date (always show)
              const Text(
                'Date:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${_selectedDateNotifier.value.month}/${_selectedDateNotifier.value.day}/${_selectedDateNotifier.value.year}'),
              const SizedBox(height: 12),
              
              // Description
              if (_descriptionController.text.trim().isNotEmpty) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_descriptionController.text.trim()),
                const SizedBox(height: 12),
              ],
              
              // Goals
              const Text(
                'Goals:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...selectedGoals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        goal.displayText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit Proof'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _submitProof(selectableGoals, user);
    }
  }

  Future<void> _submitProof(List<SelectableGoal> selectableGoals, UserModel user) async {
    if (_selectedGoalKeysNotifier.value.isEmpty) return;

    // Check if any selected goals have existing proofs
    final goalsWithExistingProofs = <SelectableGoal>[];
    final checkDateString = '${_selectedDateNotifier.value.year}-${_selectedDateNotifier.value.month.toString().padLeft(2, '0')}-${_selectedDateNotifier.value.day.toString().padLeft(2, '0')}';
    
    for (final goalKey in _selectedGoalKeysNotifier.value) {
      final goal = selectableGoals.firstWhere((g) => g.key == goalKey);
      if (goal.goalType == GoalType.daily) {
        final challengeProofsAsync = ref.read(challengeProofsProvider(goal.challengeId));
        final allProofs = challengeProofsAsync.value ?? [];
        
        final hasExistingProof = allProofs.any((proof) {
          if (proof.userId != user.id) return false;
          
          final proofDateString = '${proof.submissionDate.year}-${proof.submissionDate.month.toString().padLeft(2, '0')}-${proof.submissionDate.day.toString().padLeft(2, '0')}';
          if (proofDateString != checkDateString) return false;
          
          return proof.challengeGoalStates.containsKey(goal.key);
        });
        
        if (hasExistingProof) {
          goalsWithExistingProofs.add(goal);
        }
      }
    }

    // Show confirmation dialog if there are existing proofs
    if (goalsWithExistingProofs.isNotEmpty) {
      final shouldContinue = await _showDuplicateProofDialog(goalsWithExistingProofs);
      if (!shouldContinue) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final proofRepository = ref.read(proofRepositoryProvider);
      final submissionResults = <Result<ProofSubmission>>[];
      String? sharedImageUrl;
      
      // If it's an image proof, upload it once and reuse the URL
      if (widget.imageBlob != null) {
        sharedImageUrl = await _uploadImageToFirebase(widget.imageBlob);
      } else if (_selectedImage != null) {
        sharedImageUrl = await _uploadXFileToFirebase(_selectedImage!);
      }
      
      // Create separate ProofSubmission for each selected goal (complete independence)
      for (final goalKey in _selectedGoalKeysNotifier.value) {
        final goal = selectableGoals.firstWhere((g) => g.key == goalKey);
        
        // Each proof submission is completely independent with only one challenge/goal state
        final challengeGoalStates = <String, ChallengeGoalProofState>{
          goalKey: ChallengeGoalProofState(
            challengeId: goal.challengeId,
            participationId: goal.participationId,
            goalTemplateId: goal.goalTemplateId,
            status: ProofStatus.pending,
          ),
        };

        final proof = sharedImageUrl != null
            ? ProofSubmission(
                id: '', // Will be set by repository
                userId: user.id,
                userName: DisplayNameUtils.getDisplayNameSync(user),
                submissionDate: _selectedDateNotifier.value,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                contentType: ProofContentType.image,
                imageUrls: [sharedImageUrl],
                description: _descriptionController.text.trim(),
                challengeGoalStates: challengeGoalStates,
              )
            : ProofSubmission(
                id: '', // Will be set by repository
                userId: user.id,
                userName: DisplayNameUtils.getDisplayNameSync(user),
                submissionDate: _selectedDateNotifier.value,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                contentType: ProofContentType.text,
                description: _descriptionController.text.trim(),
                challengeGoalStates: challengeGoalStates,
              );

        // Submit each proof independently
        final result = await proofRepository.submitProof(proof);
        submissionResults.add(result);
      }

      // Check results
      final successCount = submissionResults.where((r) => r.isSuccess).length;
      final totalCount = submissionResults.length;
      
      if (successCount == totalCount) {
        // All submissions successful
        _descriptionController.clear();
        setState(() {
          _selectedGoalKeysNotifier.value = {};
          _selectedImage = null;
        });

        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Proof submitted to $totalCount independent challenge${totalCount == 1 ? '' : 's'}!'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
          
          // Close the modal after successful submission
          _cleanupCamera(); // Stop camera before closing modal
          Navigator.of(context).pop();
        }
      } else {
        // Some or all submissions failed
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('$successCount of $totalCount proofs submitted successfully'),
          //     backgroundColor: successCount > 0 ? Colors.orange : Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      logger.error('Error submitting proof', error: e);
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error submitting proof: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Upload image blob to Firebase Storage and return download URL
  Future<String> _uploadImageToFirebase(dynamic imageBlob) async {
    if (kIsWeb) {
      // Convert blob to Uint8List for Firebase upload
      final completer = Completer<Uint8List>();
      
      // Use FileReader to convert blob to Uint8List
      final reader = html.FileReader();
      reader.onLoad.listen((e) {
        completer.complete(reader.result as Uint8List);
      });
      reader.readAsArrayBuffer(imageBlob);
      final imageData = await completer.future;
      
      // Upload to Firebase Storage
      final uuid = const Uuid();
      final fileName = 'proof_${uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('proof_images')
          .child(fileName);

      final uploadTask = storageRef.putData(imageData);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } else {
      throw Exception('Image upload not supported on this platform');
    }
  }

  /// Upload XFile to Firebase Storage and return download URL
  Future<String> _uploadXFileToFirebase(XFile imageFile) async {
    try {
      // Read image data from XFile
      final imageData = await imageFile.readAsBytes();
      
      // Upload to Firebase Storage
      final uuid = const Uuid();
      final fileName = 'proof_${uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('proof_images')
          .child(fileName);

      final uploadTask = storageRef.putData(imageData);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logger.error('Error uploading image to Firebase', error: e);
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<bool> _showDuplicateProofDialog(List<SelectableGoal> goalsWithExistingProofs) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace Existing Proofs?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have already submitted proofs for the following daily goals today:',
            ),
            const SizedBox(height: 12),
            ...goalsWithExistingProofs.map((goal) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${goal.goalName} (${goal.partyName})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
            const Text(
              'Daily goals only allow one proof per day. Submitting new proofs will replace the existing ones.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Replace Proofs'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Validates that the selected file is a supported image format
  bool _isValidImageFile(XFile file) {
    // On web, file.path might be a blob URL, so we primarily rely on MIME type
    if (kIsWeb && file.mimeType != null) {
      const allowedMimeTypes = [
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/webp'
      ];
      return allowedMimeTypes.contains(file.mimeType!.toLowerCase());
    }
    
    // For non-web platforms or when MIME type is not available, check extension
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    final extension = file.path.toLowerCase().split('.').last;
    
    // Check if the path is a blob URL (web)
    if (file.path.startsWith('blob:')) {
      // For blob URLs without MIME type, we can't validate - allow it
      return true;
    }
    
    // Check file extension
    return allowedExtensions.contains(extension);
  }

  /// Shows an error dialog for invalid file types
  void _showInvalidFileTypeError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Invalid File Type'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select a valid image file.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('Supported formats:'),
            const SizedBox(height: 4),
            const Text('• JPEG (.jpg, .jpeg)'),
            const Text('• PNG (.png)'),
            const Text('• WebP (.webp)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Other formats may cause upload failures',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// A simple date selector widget that manages its own state to avoid re-rendering the parent
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

