import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/challenge_goal.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/proof_providers.dart';
import 'multi_goal_proof_submission_widget.dart';

class ProofSubmissionWidget extends ConsumerStatefulWidget {
  const ProofSubmissionWidget({
    required this.challengeId,
    required this.participationId,
    required this.goals,
    super.key,
  });

  final String challengeId;
  final String participationId;
  final Map<String, ChallengeGoal> goals;

  @override
  ConsumerState<ProofSubmissionWidget> createState() => _ProofSubmissionWidgetState();
}

class _ProofSubmissionWidgetState extends ConsumerState<ProofSubmissionWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedGoalId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Please log in to submit proofs'),
        ),
      );
    }

    if (widget.goals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No goals to submit proofs for'),
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
              
              // Goal Selection
              Text(
                'Select Goal',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedGoalId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose a goal to submit proof for',
                ),
                items: widget.goals.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          entry.value.frequencyDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGoalId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a goal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Proof Description
              Text(
                'Proof Description',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe how you completed this goal...',
                  isDense: true,
                ),
                maxLines: 2,
                maxLength: 150,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a proof description';
                  }
                  if (value.trim().length < 5) {
                    return 'Description must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProof,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Proof'),
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Info text
              Text(
                'Your proof will be reviewed by other party members before being approved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Multi-goal submission option
              Center(
                child: TextButton.icon(
                  onPressed: () => _showMultiGoalSubmission(context),
                  icon: const Icon(Icons.multiple_stop, size: 16),
                  label: const Text('Submit to Multiple Goals'),
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProof() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(userProvider);
    if (user == null || _selectedGoalId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create challenge-goal state for the selected goal
      final challengeGoalState = ChallengeGoalProofState(
        challengeId: widget.challengeId,
        participationId: widget.participationId,
        goalTemplateId: _selectedGoalId!,
        status: ProofStatus.pending,
      );
      
      final challengeGoalStates = <String, ChallengeGoalProofState>{
        '${widget.challengeId}:$_selectedGoalId': challengeGoalState,
      };

      final proof = ProofSubmission(
        id: '', // Will be set by repository
        userId: user.id,
        userName: user.displayName ?? user.email,
        submissionDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contentType: ProofContentType.text,
        description: _descriptionController.text.trim(),
        challengeGoalStates: challengeGoalStates,
      );

      final proofRepository = ref.read(proofRepositoryProvider);
      final result = await proofRepository.submitProof(proof);

      if (result.isSuccess) {
        final goalName = widget.goals[_selectedGoalId!]?.name ?? 'goal';
        
        // Clear form
        _descriptionController.clear();
        setState(() {
          _selectedGoalId = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proof submitted for $goalName!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit proof: ${result.failureOrNull?.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      logger.error('Error submitting proof', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting proof: $e'),
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

  void _showMultiGoalSubmission(BuildContext context) {
    showModalBottomSheet(
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
                    Icons.multiple_stop,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Submit to Multiple Goals',
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
              const Expanded(
                child: SingleChildScrollView(
                  child: MultiGoalProofSubmissionWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}