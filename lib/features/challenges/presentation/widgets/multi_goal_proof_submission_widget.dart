import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:html' as html show FileReader, Url;
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
  final Set<String> _selectedGoalKeys = {};
  final Map<String, bool> _existingProofStatus = {}; // Track which goals have existing proofs today
  DateTime _selectedDate = DateTime.now(); // Date for proof submission
  XFile? _selectedImage; // Selected image from gallery
  bool _isSubmitting = false;
  bool _showGoalSelection = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingProofs(List<SelectableGoal> selectableGoals, String userId) async {
    final checkDate = _selectedDate;
    final checkDateString = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    
    _existingProofStatus.clear();
    
    for (final goal in selectableGoals) {
      if (goal.goalType == GoalType.daily) {
        // Check if there's already a proof for this goal today
        final challengeProofsAsync = ref.read(challengeProofsProvider(goal.challengeId));
        final allProofs = challengeProofsAsync.value ?? [];
        
        final hasExistingProof = allProofs.any((proof) {
          if (proof.userId != userId) return false;
          
          final proofDateString = '${proof.submissionDate.year}-${proof.submissionDate.month.toString().padLeft(2, '0')}-${proof.submissionDate.day.toString().padLeft(2, '0')}';
          if (proofDateString != checkDateString) return false;
          
          // Check if this proof is for the same goal
          return proof.challengeGoalStates.containsKey(goal.key);
        });
        
        setState(() {
          _existingProofStatus[goal.key] = hasExistingProof;
        });
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
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Submit Proof',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Goal Selection Section (moved to top)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Goals (${_selectedGoalKeys.length})',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      if (!_showGoalSelection) {
                        // Check for existing proofs when opening the selection
                        await _checkExistingProofs(selectableGoals, user.id);
                      }
                      setState(() {
                        _showGoalSelection = !_showGoalSelection;
                      });
                    },
                    icon: Icon(_showGoalSelection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    label: Text(_showGoalSelection ? 'Hide Goals' : 'Select Goals'),
                  ),
                ],
              ),
              
              if (_selectedGoalKeys.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Please select at least one goal',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              
              if (_selectedGoalKeys.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Goals:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final key in _selectedGoalKeys) ...[
                        () {
                          final goal = selectableGoals.firstWhere((g) => g.key == key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    goal.displayText,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),
                      ],
                    ],
                  ),
                ),
              
              // Expandable Goal Selection
              if (_showGoalSelection) ...[
                const SizedBox(height: 8),
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
                      final isSelected = _selectedGoalKeys.contains(goal.key);
                      final hasExistingProof = _existingProofStatus[goal.key] ?? false;
                      
                      return CheckboxListTile(
                        dense: true,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.goalName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (hasExistingProof && goal.goalType == GoalType.daily) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _selectedDate.day == DateTime.now().day && 
                                  _selectedDate.month == DateTime.now().month && 
                                  _selectedDate.year == DateTime.now().year
                                      ? 'Already submitted today'
                                      : 'Already submitted',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                        secondary: hasExistingProof && goal.goalType == GoalType.daily
                            ? Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange[700],
                                size: 20,
                              )
                            : null,
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedGoalKeys.add(goal.key);
                            } else {
                              _selectedGoalKeys.remove(goal.key);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Camera image preview (for camera submissions)
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
                const SizedBox(height: 12),
              ],
              
              // Image picker button for gallery submissions (moved to top)
              if (widget.imageBlob == null) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                      });
                    }
                  },
                  icon: Icon(_selectedImage != null ? Icons.check_circle : Icons.photo_library),
                  label: Text(_selectedImage != null ? 'Image Selected' : 'Choose from Gallery'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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
                
                // Date selector with 7 radio buttons for the week
                Text(
                  'Proof Date',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                _buildWeeklyDateSelector(selectableGoals, user.id),
                const SizedBox(height: 12),
              ],
              
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _selectedGoalKeys.isEmpty) ? null : () => _showConfirmationDialog(selectableGoals, user),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Submit Proof for ${_selectedGoalKeys.length} Goal${_selectedGoalKeys.length == 1 ? '' : 's'}'),
                ),
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

  Widget _buildWeeklyDateSelector(List<SelectableGoal> selectableGoals, String userId) {
    // Get challenge dates from the first selectable goal
    List<DateTime> weekDates = [];
    
    if (selectableGoals.isNotEmpty) {
      final firstGoal = selectableGoals.first;
      final challengeAsync = ref.watch(challengeProvider(firstGoal.challengeId));
      
      weekDates = challengeAsync.when(
        data: (challenge) {
          if (challenge != null) {
            final now = DateTime.now();
            final challengeStart = challenge.startDate;
            final challengeEnd = challenge.endDate;
            
            // Calculate how many days are in the challenge (max 7)
            final challengeDuration = challengeEnd.difference(challengeStart).inDays + 1;
            final daysToShow = challengeDuration > 7 ? 7 : challengeDuration;
            
            // Generate dates based on challenge dates, showing the most recent period
            if (challengeDuration <= 7) {
              // Show all challenge days if 7 or fewer
              return List.generate(daysToShow, (index) {
                return challengeStart.add(Duration(days: index));
              });
            } else {
              // Show the 7 most recent days of the challenge up to today
              final endDate = now.isBefore(challengeEnd) ? now : challengeEnd;
              return List.generate(7, (index) {
                return endDate.subtract(Duration(days: 6 - index));
              }).where((date) => 
                !date.isBefore(challengeStart) && !date.isAfter(challengeEnd)
              ).toList();
            }
          } else {
            // Fallback if challenge is null
            final now = DateTime.now();
            return List.generate(7, (index) {
              return now.subtract(Duration(days: 6 - index));
            });
          }
        },
        loading: () {
          // Fallback to last 7 days if challenge data is loading
          final now = DateTime.now();
          return List.generate(7, (index) {
            return now.subtract(Duration(days: 6 - index));
          });
        },
        error: (_, __) {
          // Fallback to last 7 days if there's an error
          final now = DateTime.now();
          return List.generate(7, (index) {
            return now.subtract(Duration(days: 6 - index));
          });
        },
      );
    } else {
      // Fallback to last 7 days if no selectable goals
      final now = DateTime.now();
      weekDates = List.generate(7, (index) {
        return now.subtract(Duration(days: 6 - index));
      });
    }

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
            children: weekDates.map((date) {
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
          // Date numbers and status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDates.map((date) {
              final isSelected = _selectedDate.day == date.day && 
                                 _selectedDate.month == date.month && 
                                 _selectedDate.year == date.year;
              final dayColor = _getDayProofStatusColor(date, selectableGoals, userId);
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(date.year, date.month, date.day);
                    });
                    // Recheck existing proofs for the new selected date
                    _checkExistingProofs(selectableGoals, userId);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: dayColor == Colors.transparent ? Theme.of(context).colorScheme.surface : dayColor,
                            shape: BoxShape.circle,
                            border: isSelected 
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                              : Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
                          ),
                          child: Center(
                            child: isSelected 
                              ? Icon(
                                  Icons.check,
                                  color: dayColor == Colors.transparent 
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                  size: 16,
                                )
                              : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              _buildLegendItem(Colors.green, 'Approved'),
              _buildLegendItem(Colors.orange, 'Pending'),
              _buildLegendItem(Colors.red, 'Disputed'),
              _buildLegendItem(Colors.transparent, 'No proof'),
              _buildLegendItem(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), 'Select goals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color == Colors.transparent ? Theme.of(context).colorScheme.surface : color,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Color _getDayProofStatusColor(DateTime date, List<SelectableGoal> selectableGoals, String userId) {
    // If no goals are selected, show neutral color
    if (_selectedGoalKeys.isEmpty) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3); // Neutral - no goals selected
    }
    
    // Get only the selected goals
    final selectedGoals = selectableGoals.where((g) => _selectedGoalKeys.contains(g.key)).toList();
    if (selectedGoals.isEmpty) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);
    }
    
    // Format date for comparison
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Track statuses across all selected goals and challenges
    bool hasAnyApproved = false;
    bool hasAnyPending = false;
    bool hasAnyDisputed = false;
    bool hasAnyProofs = false;
    
    // Group selected goals by challenge to get proofs efficiently
    final goalsByChallenge = <String, List<SelectableGoal>>{};
    for (final goal in selectedGoals) {
      goalsByChallenge.putIfAbsent(goal.challengeId, () => []).add(goal);
    }
    
    // Check proof status for each challenge
    for (final entry in goalsByChallenge.entries) {
      final challengeId = entry.key;
      final challengeGoals = entry.value;
      
      final challengeProofsAsync = ref.read(challengeProofsProvider(challengeId));
      final allProofs = challengeProofsAsync.value ?? [];
      
      // Filter proofs for this user and the goals in this challenge
      final relevantProofs = allProofs.where((proof) {
        if (proof.userId != userId) return false;
        
        // Check if this proof is for any of the selected goals in this challenge
        return challengeGoals.any((goal) => 
          proof.challengeGoalStates.containsKey('${challengeId}:${goal.goalTemplateId}')
        );
      }).toList();
      
      // Now filter by date - for total goals, only show status on the actual submission date
      final dayProofs = relevantProofs.where((proof) {
        final proofDateString = '${proof.submissionDate.year}-${proof.submissionDate.month.toString().padLeft(2, '0')}-${proof.submissionDate.day.toString().padLeft(2, '0')}';
        
        // Only show proof status on the exact date it was submitted
        // This ensures total goals don't show status on other days
        return proofDateString == dateString;
      }).toList();
      
      if (dayProofs.isNotEmpty) {
        hasAnyProofs = true;
        
        // Check statuses for each goal in this challenge
        for (final goal in challengeGoals) {
          for (final proof in dayProofs) {
            if (proof.isApprovedFor(challengeId, goal.goalTemplateId)) {
              hasAnyApproved = true;
            } else if (proof.isPendingFor(challengeId, goal.goalTemplateId)) {
              hasAnyPending = true;
            } else {
              final state = proof.getStateFor(challengeId, goal.goalTemplateId);
              if (state?.status == ProofStatus.disputed) {
                hasAnyDisputed = true;
              }
            }
          }
        }
      }
    }
    
    // Determine color based on aggregated status
    if (!hasAnyProofs) {
      return Colors.transparent; // No proofs for selected goals
    } else if (hasAnyDisputed) {
      return Colors.red; // Any disputed takes priority
    } else if (hasAnyPending) {
      return Colors.orange; // Pending if no disputes
    } else if (hasAnyApproved) {
      return Colors.green; // All approved
    } else {
      return Colors.grey; // Edge case - proofs exist but unclear status
    }
  }

  Future<void> _showConfirmationDialog(List<SelectableGoal> selectableGoals, UserModel user) async {
    final selectedGoals = selectableGoals.where((g) => _selectedGoalKeys.contains(g.key)).toList();
    
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
              
              // Date
              if (widget.imageBlob == null) ...[
                const Text(
                  'Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                const SizedBox(height: 12),
              ],
              
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
    if (!_formKey.currentState!.validate() || _selectedGoalKeys.isEmpty) return;

    // Check if any selected goals have existing proofs
    final goalsWithExistingProofs = <SelectableGoal>[];
    for (final goalKey in _selectedGoalKeys) {
      if (_existingProofStatus[goalKey] == true) {
        final goal = selectableGoals.firstWhere((g) => g.key == goalKey);
        if (goal.goalType == GoalType.daily) {
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
      for (final goalKey in _selectedGoalKeys) {
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
                submissionDate: _selectedDate,
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
                submissionDate: _selectedDate,
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
          _selectedGoalKeys.clear();
          _showGoalSelection = false;
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
}

