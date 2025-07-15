import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../goals/models/proof_model.dart';
import '../../goals/models/goal_model.dart';
import '../../goals/providers/simple_goals_provider.dart';
import '../../party/providers/simple_party_provider.dart';

class ProofStoryViewer extends StatefulWidget {
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> pendingProofs; // List of {proof, instance, goalName}
  final String currentUserId;

  const ProofStoryViewer({
    super.key,
    required this.userId,
    required this.userName,
    required this.pendingProofs,
    required this.currentUserId,
  });

  @override
  State<ProofStoryViewer> createState() => _ProofStoryViewerState();
}

class _ProofStoryViewerState extends State<ProofStoryViewer> {
  int _currentIndex = 0;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    if (widget.pendingProofs.isEmpty) {
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
            'No pending proofs to review',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final currentProofData = widget.pendingProofs[_currentIndex];
    final proof = currentProofData['proof'] as Proof;
    final goalName = currentProofData['goalName'] as String;
    final canApprove = widget.userId != widget.currentUserId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with user info and progress indicators
            _buildHeader(),
            
            // Main proof content (with tap navigation)
            Expanded(
              child: GestureDetector(
                onTapUp: (details) {
                  // Tap right side to go to next proof, left side to go to previous
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx > screenWidth * 0.7) {
                    // Right side tap - next proof
                    _moveToNextProofOrClose();
                  } else if (details.globalPosition.dx < screenWidth * 0.3 && _currentIndex > 0) {
                    // Left side tap - previous proof
                    setState(() {
                      _currentIndex--;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Goal name
                      Text(
                        goalName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Proof content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.text_snippet,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              proof.proofText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Submitted ${_formatDate(proof.submissionDate)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons (only show for other users' proofs)
            if (canApprove) _buildActionButtons(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              widget.userName.isNotEmpty 
                  ? widget.userName.substring(0, 2).toUpperCase()
                  : '??',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} of ${widget.pendingProofs.length} proofs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicators
          Row(
            children: widget.pendingProofs.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = index == _currentIndex;
              return Container(
                width: 30,
                height: 3,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: isActive 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _disputeProof(),
              icon: const Icon(Icons.close),
              label: const Text('Dispute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _approveProof(),
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final submissionDate = DateTime(date.year, date.month, date.day);
    
    if (submissionDate == today) {
      return 'today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (submissionDate == today.subtract(const Duration(days: 1))) {
      return 'yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _approveProof() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final currentProofData = widget.pendingProofs[_currentIndex];
      final proof = currentProofData['proof'] as Proof;
      final goal = currentProofData['instance'] as Goal;
      
      // Get the date from the proof
      final date = proof.submissionDate.toIso8601String().split('T')[0];
      
      // Use the goal's approveProof method to get the updated goal
      final updatedGoal = goal.approveProof(proof.id, date);
      
      // Save the updated goal back to the database
      await _saveGoalToDatabase(updatedGoal, widget.userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Move to next proof or close
        _moveToNextProofOrClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _disputeProof() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final currentProofData = widget.pendingProofs[_currentIndex];
      final proof = currentProofData['proof'] as Proof;
      final goal = currentProofData['instance'] as Goal;
      
      // Get the date from the proof
      final date = proof.submissionDate.toIso8601String().split('T')[0];
      
      // Use the goal's denyProof method to get the updated goal
      final updatedGoal = goal.denyProof(proof.id, date);
      
      // Save the updated goal back to the database
      await _saveGoalToDatabase(updatedGoal, widget.userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof disputed successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Move to next proof or close
        _moveToNextProofOrClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disputing proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Save updated goal back to the database in the subcollection structure
  Future<void> _saveGoalToDatabase(Goal updatedGoal, String goalOwnerId) async {
    try {
      print('PROOF APPROVAL: Saving ${updatedGoal.goalName} for user $goalOwnerId');
      
      // Get party info to find the challenge ID
      final partyProvider = Provider.of<SimplePartyProvider>(context, listen: false);
      if (!partyProvider.hasParties) {
        throw Exception('No party found');
      }
      
      final firstParty = partyProvider.parties.first;
      final activeChallenge = firstParty['activeChallenge'] as Map<String, dynamic>?;
      final pendingChallenge = firstParty['pendingChallenge'] as Map<String, dynamic>?;
      
      String? challengeId;
      if (activeChallenge != null) {
        challengeId = activeChallenge['id'] as String?;
      } else if (pendingChallenge != null) {
        challengeId = pendingChallenge['id'] as String?;
      }
      
      if (challengeId == null) {
        throw Exception('No challenge ID found');
      }
      
      // Load the current memberGoals document to update just this goal
      final firestore = FirebaseFirestore.instance;
      final memberGoalsDoc = await firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('memberGoals')
          .doc(goalOwnerId)
          .get();
      
      if (!memberGoalsDoc.exists) {
        throw Exception('No memberGoals document found for user $goalOwnerId');
      }
      
      final memberGoalsData = memberGoalsDoc.data() as Map<String, dynamic>;
      final userGoals = List<Map<String, dynamic>>.from(memberGoalsData['goals'] ?? []);
      
      // Find and update the specific goal
      bool goalUpdated = false;
      for (int i = 0; i < userGoals.length; i++) {
        if (userGoals[i]['id'] == updatedGoal.id) {
          userGoals[i] = updatedGoal.toMap();
          goalUpdated = true;
          break;
        }
      }
      
      if (!goalUpdated) {
        throw Exception('Goal ${updatedGoal.id} not found in user goals');
      }
      
      // Save back to Firestore
      await firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('memberGoals')
          .doc(goalOwnerId)
          .update({
        'goals': userGoals,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('PROOF APPROVAL: Successfully saved to database - SimpleGoalsProvider should auto-update via real-time listener');
    } catch (e) {
      print('PROOF APPROVAL ERROR: $e');
      rethrow;
    }
  }

  void _moveToNextProofOrClose() {
    if (_currentIndex < widget.pendingProofs.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // All proofs reviewed, close the viewer
      Navigator.of(context).pop();
    }
  }
}