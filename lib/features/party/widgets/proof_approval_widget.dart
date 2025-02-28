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

  Future<void> _loadSubmittedGoals() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingData) return;
    _isLoadingData = true;

    // Store context before the async gap
    final BuildContext currentContext = context;

    // Only set loading state if we're not already showing results
    if (_submittedGoals.isEmpty && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Get provider before async operation
      final partyProvider =
          Provider.of<PartyProvider>(currentContext, listen: false);
      final submittedGoals = await partyProvider.fetchSubmittedGoalsForParty();

      // Make sure the widget is still mounted before updating state
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
      _isLoadingData = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PartyProvider, Map<String, List<Goal>>>(
      selector: (_, provider) => provider.partyMemberGoals,
      builder: (context, partyMemberGoals, child) {
        // When party members' goals change, reload our data
        if (!_isLoadingData) {
          Future.microtask(() {
            if (mounted) {
              _loadSubmittedGoals();
            }
          });
        }

        if (_isLoading && _submittedGoals.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_errorMessage != null) {
          return Center(child: Text(_errorMessage!));
        }

        if (_submittedGoals.isEmpty) {
          return const Center(child: Text('No pending proofs'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            key: ValueKey<int>(_submittedGoals.length),
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
                  'Unknown User';

              // Create a unique key for each proof item
              final String proofKey =
                  '${goal.id}-${goalData['date'] ?? 'total'}-$index';

              return ProofItem(
                key: ValueKey(proofKey),
                goal: goal,
                userName: userName,
                date: goalData['date'],
                proof: goalData['proof'],
                onAction: _handleAction,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
      String goalId, String? date, bool isApprove) async {
    // Find the index of the item before removing it
    int itemIndex = _submittedGoals.indexWhere(
        (item) => item['goal'].id == goalId && item['date'] == date);

    if (itemIndex == -1) return;

    // Store context in a local variable before async operations
    final BuildContext currentContext = context;

    // Remove the item from the list for immediate feedback
    setState(() {
      _submittedGoals.removeAt(itemIndex);
    });

    final partyProvider =
        Provider.of<PartyProvider>(currentContext, listen: false);

    try {
      if (isApprove) {
        await partyProvider.approveProof(goalId, date);
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
        // Reload data if there was an error
        _loadSubmittedGoals();
      }
    }
  }
}
