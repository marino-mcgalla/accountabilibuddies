import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/party_provider.dart';
import '../../goals/models/goal_model.dart';
import 'proof_item_widget.dart';
import '../../common/utils/utils.dart';

class PendingProofsWidget extends StatefulWidget {
  const PendingProofsWidget({Key? key}) : super(key: key);

  @override
  _PendingProofsWidgetState createState() => _PendingProofsWidgetState();
}

class _PendingProofsWidgetState extends State<PendingProofsWidget> {
  List<Map<String, dynamic>> _submittedGoals = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadSubmittedGoals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSubmittedGoals();
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _isLoadingData = true; // Prevent any new operations
    super.dispose();
  }

  Future<void> _loadSubmittedGoals() async {
    // Prevent multiple simultaneous loads or loading after disposal
    if (_isLoadingData || !mounted) return;
    _isLoadingData = true;

    try {
      // Get provider before async operation
      final partyProvider = Provider.of<PartyProvider>(context, listen: false);
      final submittedGoals = await partyProvider.fetchSubmittedProofs();

      // Check again if still mounted after async operation
      if (!mounted) return;

      setState(() {
        _submittedGoals = submittedGoals;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading proofs: $e';
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        _isLoadingData = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remove the Selector completely - it's creating a feedback loop
    if (_isLoading && _submittedGoals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_submittedGoals.isEmpty) {
      return const Center(child: Text('No pending proofs'));
    }

    // Don't use a single key for the entire list
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        // Remove the key from here - each item will have its own key
        shrinkWrap: true,
        itemCount: _submittedGoals.length,
        itemBuilder: (context, index) {
          final goalData = _submittedGoals[index];
          final Goal goal = goalData['goal'];
          final String userId = goalData['userId'];

          // Get user name from member details
          final partyProvider =
              Provider.of<PartyProvider>(context, listen: false);
          final String userName = partyProvider.memberDetails[userId]
                  ?['displayName'] ??
              partyProvider.memberDetails[userId]?['username'] ??
              partyProvider.memberDetails[userId]?['email'] ??
              'Unknown User';

          // Create a unique key for each proof item
          final String proofKey =
              '${goal.id}-${goalData['date'] ?? 'total'}-$userId-$index';

          return ProofItem(
            key: ValueKey(proofKey),
            goal: goal,
            userName: userName,
            userId: userId,
            date: goalData['date'],
            proof: goalData['proof'],
            onAction: _handleAction,
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
      String goalId, String? date, bool isApprove) async {
    int itemIndex = _submittedGoals.indexWhere(
        (item) => item['goal'].id == goalId && item['date'] == date);

    if (itemIndex == -1) return;

    final String userId = _submittedGoals[itemIndex]['userId'];

    final BuildContext currentContext = context;

    setState(() {
      _submittedGoals.removeAt(itemIndex);
    });

    final partyProvider =
        Provider.of<PartyProvider>(currentContext, listen: false);

    try {
      if (isApprove) {
        await partyProvider.approveProof(userId, goalId, date);
        if (mounted) {
          Utils.showFeedback(currentContext, 'Proof approved');
        }
      } else {
        await partyProvider.denyProof(goalId, date);
        if (mounted) {
          Utils.showFeedback(currentContext, 'Proof denied');
        }
      }
    } catch (e) {
      if (mounted) {
        Utils.showFeedback(currentContext, 'Error: $e', isError: true);
        _loadSubmittedGoals();
      }
    }
  }
}
