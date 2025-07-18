import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/multi_party_challenge_provider.dart';
import '../../party/providers/simple_party_provider.dart';

/// Screen for creating multi-party challenges
class CreateMultiPartyChallengeScreen extends StatefulWidget {
  const CreateMultiPartyChallengeScreen({super.key});

  @override
  State<CreateMultiPartyChallengeScreen> createState() => _CreateMultiPartyChallengeScreenState();
}

class _CreateMultiPartyChallengeScreenState extends State<CreateMultiPartyChallengeScreen> {
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  final int _totalSteps = 3; // Basic Settings, Party Selection, Review
  
  // Challenge configuration
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));
  final List<String> _selectedParties = [];
  bool _allowCrossPartyApproval = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Basic settings
        if (_startDate.isAfter(_endDate)) {
          _showSnackBar('End date must be after start date', isError: true);
          return false;
        }
        return true;
      case 1: // Party selection
        if (_selectedParties.isEmpty) {
          _showSnackBar('Please select at least one party to invite', isError: true);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _createChallenge() async {
    setState(() => _isCreating = true);

    try {
      final challengeProvider = Provider.of<MultiPartyChallengeProvider>(context, listen: false);
      final partyProvider = Provider.of<SimplePartyProvider>(context, listen: false);
      
      final currentPartyId = partyProvider.currentPartyId;
      if (currentPartyId == null) {
        throw Exception('No party selected');
      }

      final challengeId = await challengeProvider.createMultiPartyChallenge(
        creatorPartyId: currentPartyId,
        startDate: _startDate,
        endDate: _endDate,
        invitedParties: _selectedParties,
        allowCrossPartyApproval: _allowCrossPartyApproval,
      );

      if (challengeId != null && mounted) {
        _showSnackBar('Multi-party challenge created successfully!', isError: false);
        context.go('/home');
      } else {
        throw Exception('Failed to create challenge');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error creating challenge: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Multi-Party Challenge'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicSettingsStep(),
                _buildPartySelectionStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (index < _totalSteps - 1) const SizedBox(width: 8),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicSettingsStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure the basic settings for your multi-party challenge.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Start Date
                  _buildDateSelector(
                    title: 'Start Date',
                    date: _startDate,
                    onDateSelected: (date) => setState(() => _startDate = date),
                    icon: Icons.calendar_today,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // End Date
                  _buildDateSelector(
                    title: 'End Date',
                    date: _endDate,
                    onDateSelected: (date) => setState(() => _endDate = date),
                    icon: Icons.event,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Cross-party approval setting
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Cross-Party Proof Approval',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Allow members from different parties to approve each other\'s proof submissions.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            value: _allowCrossPartyApproval,
                            onChanged: (value) => setState(() => _allowCrossPartyApproval = value),
                            title: Text(
                              _allowCrossPartyApproval ? 'Enabled' : 'Disabled',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              _allowCrossPartyApproval 
                                  ? 'Members can approve proofs from any party'
                                  : 'Members can only approve proofs from their own party',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartySelectionStep() {
    return Consumer<SimplePartyProvider>(
      builder: (context, partyProvider, child) {
        final allParties = partyProvider.parties;
        final currentPartyId = partyProvider.currentPartyId;
        
        // Filter out the current party since it's automatically included
        final availableParties = allParties
            .where((party) => party['id'] != currentPartyId)
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite Parties',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select other parties to invite to your challenge. Your current party will be automatically included.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              if (availableParties.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Other Parties Available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You need to be a member of multiple parties to create multi-party challenges.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: availableParties.length,
                    itemBuilder: (context, index) {
                      final party = availableParties[index];
                      final partyId = party['id'] as String;
                      final partyName = party['name'] as String;
                      final memberCount = (party['members'] as List?)?.length ?? 0;
                      final isSelected = _selectedParties.contains(partyId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedParties.add(partyId);
                              } else {
                                _selectedParties.remove(partyId);
                              }
                            });
                          },
                          title: Text(partyName),
                          subtitle: Text('$memberCount members'),
                          secondary: CircleAvatar(
                            backgroundColor: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            foregroundColor: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            child: Text(
                              partyName.isNotEmpty ? partyName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewStep() {
    return Consumer<SimplePartyProvider>(
      builder: (context, partyProvider, child) {
        final currentParty = partyProvider.currentParty;
        final currentPartyName = currentParty?['name'] ?? 'Unknown Party';
        final selectedPartyNames = _selectedParties
            .map((id) => partyProvider.parties
                .where((party) => party['id'] == id)
                .firstOrNull?['name'] ?? 'Unknown')
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review & Create',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review your challenge configuration before creating.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildReviewSection(
                        'Challenge Details',
                        Column(
                          children: [
                            _buildReviewRow('Duration', '${_endDate.difference(_startDate).inDays} days'),
                            _buildReviewRow('Start Date', _formatDate(_startDate)),
                            _buildReviewRow('End Date', _formatDate(_endDate)),
                            _buildReviewRow('Cross-Party Approval', _allowCrossPartyApproval ? 'Enabled' : 'Disabled'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildReviewSection(
                        'Participating Parties',
                        Column(
                          children: [
                            _buildPartyRow(currentPartyName, isCreator: true),
                            ...selectedPartyNames.map((name) => _buildPartyRow(name)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Next Steps',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Challenge will be created and invitations sent\n'
                              '2. Invited parties can accept or decline\n'
                              '3. Accepting parties can lock in their goals\n'
                              '4. Challenge becomes active once members lock in',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelector({
    required String title,
    required DateTime date,
    required ValueChanged<DateTime> onDateSelected,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(_formatDate(date)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final newDate = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (newDate != null) {
            onDateSelected(newDate);
          }
        },
      ),
    );
  }

  Widget _buildReviewSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyRow(String partyName, {bool isCreator = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isCreator
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            child: Text(
              partyName.isNotEmpty ? partyName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isCreator
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              partyName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Creator',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isCreating ? null : _previousStep,
                child: const Text('Back'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isCreating ? null : () {
                if (_currentStep == _totalSteps - 1) {
                  _createChallenge();
                } else {
                  if (_canProceedToNextStep()) {
                    _nextStep();
                  }
                }
              },
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == _totalSteps - 1 ? 'Create Challenge' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}