import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_goal.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/challenge_providers.dart';
import '../providers/proof_providers.dart';
import '../../../../core/utils/display_name_utils.dart';

/// Quick proof submission widget for dashboard - one-click proof submission
class QuickProofSubmissionWidget extends ConsumerWidget {
  const QuickProofSubmissionWidget({
    required this.challenge,
    super.key,
  });

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    final userParticipationAsync = ref.watch(userParticipationProvider((
      challengeId: challenge.id,
      userId: user.id,
    )));

    return userParticipationAsync.when(
      data: (participation) {
        if (participation == null || participation.goals.isEmpty) {
          return const SizedBox.shrink();
        }

        // Find goals that haven't been completed today
        final today = _formatDateForCompletion(DateTime.now());
        final incompleteGoals = participation.goals.values
            .where((goal) => !goal.completedDates.contains(today))
            .toList();

        if (incompleteGoals.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All goals completed for today!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show quick submission for first incomplete goal
        final nextGoal = incompleteGoals.first;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quick Proof Submission',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Goal info
                Text(
                  'Ready to submit proof for: ${nextGoal.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                
                // Quick submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showQuickProofDialog(
                      context,
                      ref,
                      challenge,
                      participation.id,
                      nextGoal,
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Submit Proof Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  String _formatDateForCompletion(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  void _showQuickProofDialog(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
    String participationId,
    ChallengeGoal goal,
  ) {
    showDialog(
      context: context,
      builder: (context) => _QuickProofDialog(
        challenge: challenge,
        participationId: participationId,
        goal: goal,
      ),
    );
  }
}

class _QuickProofDialog extends ConsumerStatefulWidget {
  const _QuickProofDialog({
    required this.challenge,
    required this.participationId,
    required this.goal,
  });

  final Challenge challenge;
  final String participationId;
  final ChallengeGoal goal;

  @override
  ConsumerState<_QuickProofDialog> createState() => _QuickProofDialogState();
}

class _QuickProofDialogState extends ConsumerState<_QuickProofDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.flash_on,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Quick Proof',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal: ${widget.goal.name}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Quick description',
              hintText: 'I completed this goal by...',
              isDense: true,
            ),
            maxLines: 2,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Tip: A quick note helps your buddies verify your progress!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitQuickProof,
          icon: _isSubmitting 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send, size: 18),
          label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
        ),
      ],
    );
  }

  Future<void> _submitQuickProof() async {
    final description = _controller.text.trim();
    if (description.isEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Please add a quick description'),
      //     backgroundColor: Colors.orange,
      //   ),
      // );
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final proof = ProofSubmission(
        id: '', // Will be set by repository
        challengeId: widget.challenge.id,
        participationId: widget.participationId,
        goalTemplateId: widget.goal.templateId,
        userId: user.id,
        userName: DisplayNameUtils.getDisplayNameSync(user),
        submissionDate: DateTime.now(),
        status: ProofStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contentType: ProofContentType.text,
        description: description,
      );

      final proofRepository = ref.read(proofRepositoryProvider);
      final result = await proofRepository.submitProof(proof);

      if (mounted) {
        if (result.isSuccess) {
          Navigator.of(context).pop();
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Quick proof submitted for ${widget.goal.name}!'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Failed to submit proof: ${result.failureOrNull?.message ?? 'Unknown error'}'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
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
}