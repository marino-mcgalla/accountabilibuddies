import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/proof_providers.dart';
import '../providers/challenge_providers.dart';
import '../../../../core/utils/display_name_utils.dart';
import 'edit_proof_page.dart';

class ProofStoryViewer extends ConsumerStatefulWidget {
  const ProofStoryViewer({
    required this.userId,
    required this.userName,
    required this.proofs,
    required this.challengeId,
    super.key,
  });

  final String userId;
  final String userName;
  final List<ProofSubmission> proofs;
  final String challengeId;

  @override
  ConsumerState<ProofStoryViewer> createState() => _ProofStoryViewerState();
}

class _ProofStoryViewerState extends ConsumerState<ProofStoryViewer>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _markCurrentProofAsViewed();
  }


  void _nextProof() {
    if (_currentIndex < widget.proofs.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markCurrentProofAsViewed();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousProof() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _markCurrentProofAsViewed() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final currentProof = widget.proofs[_currentIndex];
    if (!currentProof.hasBeenViewedBy(user.id)) {
      final proofRepository = ref.read(proofRepositoryProvider);
      await proofRepository.markProofAsViewed(currentProof.id, user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    if (widget.proofs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            '${widget.userName} - No Proofs',
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'No proofs to review',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final currentProof = widget.proofs[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: null,
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _previousProof();
          } else {
            _nextProof();
          }
        },
        onTapCancel: null,
        child: Stack(
          children: [
            // Main content
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Proof content
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Goal name and date
                          Row(
                            children: [
                              Icon(
                                Icons.flag,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Goal Proof',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Text(
                            _formatDateTime(currentProof.submissionDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Goal name and description
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final goalInfo = _getGoalInfoForProof(currentProof, ref);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            goalInfo.name,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (goalInfo.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        goalInfo.description,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Proof content (image or text)
                          _buildProofContent(currentProof),
                          
                          // Proof description (if available)
                          if (currentProof.description != null && currentProof.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.description,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Proof Description',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    currentProof.description!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(currentProof.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(currentProof.status),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              currentProof.statusDisplay,
                              style: TextStyle(
                                color: _getStatusColor(currentProof.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top bar with progress indicators
            SafeArea(
              child: Column(
                children: [
                  // Progress bars
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: List.generate(
                        widget.proofs.length,
                        (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(
                              right: index < widget.proofs.length - 1 ? 4 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: index < _currentIndex
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: index <= _currentIndex
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Header with user info and close button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                          child: Text(
                            widget.userName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom action buttons for other users - show for pending AND approved proofs (allow disputes)
            if ((currentProof.isPending || currentProof.isApproved) && !_isProcessing && user != null && user.id != currentProof.userId)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: currentProof.isApproved 
                      ? // Smaller dispute button for approved proofs
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _confirmAndDisputeProof(currentProof),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            icon: const Icon(Icons.flag, size: 18),
                            label: const Text('Dispute', style: TextStyle(fontSize: 14)),
                          ),
                        )
                      : // Normal buttons for pending proofs
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _disputeProof(currentProof),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('Dispute'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveProof(currentProof),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ),

            // Bottom action buttons for own proofs - show edit option
            if (!_isProcessing && user != null && user.id == currentProof.userId)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _editProof(currentProof),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Proof'),
                      ),
                    ),
                  ),
                ),
              ),

            // Processing indicator
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofContent(ProofSubmission proof) {
    // Handle image proofs
    if (proof.contentType == ProofContentType.image && proof.imageUrls.isNotEmpty) {
      return Container(
        constraints: const BoxConstraints(
          maxHeight: 300,
          maxWidth: double.infinity,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(proof.imageUrls.first),
            child: Image.network(
              proof.imageUrls.first,
              fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'URL: ${proof.imageUrls.first}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            ),
          ),
        ),
      );
    }
    
    // Handle text proofs (fallback) - if no image, show a placeholder
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Text Proof',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveProof(ProofSubmission proof) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final approval = ProofApproval(
        userId: user.id,
        userName: DisplayNameUtils.getDisplayNameSync(user),
        approved: true,
        timestamp: DateTime.now(),
      );

      final proofApprovalService = ref.read(proofApprovalServiceProvider);
      final result = await proofApprovalService.approveProof(proof.id, approval);

      if (mounted) {
        if (result.isSuccess) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Proof approved and goal completion updated!'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
          _nextProof();
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Failed to approve proof: ${result.failureOrNull?.message ?? 'Unknown error'}'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      logger.error('Error approving proof', error: e);
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to approve proof: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _confirmAndDisputeProof(ProofSubmission proof) async {
    // Show confirmation dialog for approved proofs
    final bool shouldDispute = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispute Approved Proof?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This proof has already been approved.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Disputing will remove the goal completion and require re-approval.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Are you sure you want to dispute this proof?'),
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Dispute'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldDispute) {
      await _disputeProof(proof);
    }
  }

  Future<void> _disputeProof(ProofSubmission proof) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final approval = ProofApproval(
        userId: user.id,
        userName: DisplayNameUtils.getDisplayNameSync(user),
        approved: false,
        timestamp: DateTime.now(),
        comment: 'Disputed via story viewer',
      );

      final proofApprovalService = ref.read(proofApprovalServiceProvider);
      final result = await proofApprovalService.approveProof(proof.id, approval);

      if (mounted) {
        if (result.isSuccess) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Proof disputed.'),
          //     backgroundColor: Colors.orange,
          //   ),
          // );
          _nextProof();
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Failed to dispute proof: ${result.failureOrNull?.message ?? 'Unknown error'}'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      logger.error('Error disputing proof', error: e);
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to dispute proof: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Color _getStatusColor(ProofStatus status) {
    switch (status) {
      case ProofStatus.pending:
        return Colors.orange;
      case ProofStatus.approved:
        return Colors.green;
      case ProofStatus.disputed:
        return Colors.red;
      case ProofStatus.rejected:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.white70),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  ({String name, String description}) _getGoalInfoForProof(ProofSubmission proof, WidgetRef ref) {
    // Try to get the goal info from the challenge participation
    final user = ref.read(userProvider);
    if (user == null) {
      return (name: 'Unknown Goal', description: '');
    }

    final userParticipationAsync = ref.watch(userParticipationProvider((
      challengeId: widget.challengeId,
      userId: proof.userId,
    )));

    return userParticipationAsync.when(
      data: (participation) {
        if (participation != null) {
          // Goals are stored as a map with templateId as key
          final goal = participation.goals[proof.goalTemplateId];
          if (goal != null) {
            return (name: goal.name, description: goal.description);
          }
        }
        final goalId = proof.goalTemplateId;
        final displayId = goalId.length > 8 ? goalId.substring(0, 8) : goalId;
        return (name: 'Goal ($displayId...)', description: '');
      },
      loading: () => (name: 'Loading...', description: ''),
      error: (_, __) {
        final goalId = proof.goalTemplateId;
        final displayId = goalId.length > 8 ? goalId.substring(0, 8) : goalId;
        return (name: 'Goal ($displayId...)', description: '');
      },
    );
  }

  Future<void> _editProof(ProofSubmission proof) async {
    // Navigate to edit proof page
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProofPage(proof: proof),
      ),
    );
    
    // If proof was updated, refresh the proofs and move to next
    if (result == true && mounted) {
      // Refresh the proofs provider to get updated data
      ref.refresh(challengeProofsProvider(widget.challengeId));
      
      // Move to the next proof or close if this was the last one
      if (_currentIndex < widget.proofs.length - 1) {
        _nextProof();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

}