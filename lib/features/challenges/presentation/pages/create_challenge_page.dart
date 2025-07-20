import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../parties/domain/entities/party.dart';
import '../../domain/usecases/create_challenge_usecase.dart';
import '../providers/challenge_providers.dart';

class CreateChallengePage extends ConsumerStatefulWidget {
  const CreateChallengePage({
    required this.party,
    super.key,
  });

  final Party party;

  @override
  ConsumerState<CreateChallengePage> createState() => _CreateChallengePageState();
}

class _CreateChallengePageState extends ConsumerState<CreateChallengePage> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));
  DateTime? _commitmentDeadline;
  bool _hasCommitmentDeadline = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to next Monday for start date
    _startDate = _getNextMonday();
    _endDate = _startDate.add(const Duration(days: 6)); // Sunday
    _commitmentDeadline = _startDate.subtract(const Duration(hours: 12)); // Sunday noon
  }

  DateTime _getNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
    return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Challenge'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Party Info
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Creating challenge for',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              widget.party.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Challenge Preview
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.preview,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Challenge Preview',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _generateChallengeName(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Members will commit to their personal goals for this week',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date Selection
              Text(
                'Challenge Duration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(_formatDate(_startDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectStartDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // End Date
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('End Date'),
                subtitle: Text(_formatDate(_endDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectEndDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Duration Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${_endDate.difference(_startDate).inDays + 1} days',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Commitment Deadline
              Text(
                'Commitment Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                value: _hasCommitmentDeadline,
                onChanged: (value) {
                  setState(() {
                    _hasCommitmentDeadline = value ?? false;
                    if (_hasCommitmentDeadline && _commitmentDeadline == null) {
                      _commitmentDeadline = _startDate.subtract(const Duration(hours: 12));
                    }
                  });
                },
                title: const Text('Set commitment deadline'),
                subtitle: const Text('Members must commit by a specific time'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              if (_hasCommitmentDeadline) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Commitment Deadline'),
                  subtitle: Text(_formatDateTime(_commitmentDeadline!)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectCommitmentDeadline(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createChallenge,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Challenge'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Once created, party members will be notified to set their goals and wagers.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Adjust end date if needed
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 6));
        }
        // Adjust commitment deadline if needed
        if (_hasCommitmentDeadline) {
          _commitmentDeadline = _startDate.subtract(const Duration(hours: 12));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectCommitmentDeadline(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _commitmentDeadline ?? _startDate.subtract(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: _startDate,
    );
    
    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_commitmentDeadline ?? DateTime.now()),
      );
      
      if (pickedTime != null) {
        setState(() {
          _commitmentDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _createChallenge() async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a challenge'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final createChallengeUseCase = ref.read(createChallengeUseCaseProvider);
      
      final result = await createChallengeUseCase.call(
        CreateChallengeParams(
          partyId: widget.party.id,
          createdBy: user.id,
          name: _generateChallengeName(),
          description: 'Members will commit to their personal goals for this week',
          startDate: _startDate,
          endDate: _endDate,
          commitmentDeadline: _hasCommitmentDeadline ? _commitmentDeadline : null,
        ),
      );

      if (mounted) {
        result.fold(
          onSuccess: (challenge) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Challenge created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onFailure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create challenge: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _generateChallengeName() {
    final startMonth = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_startDate.month - 1];
    final endMonth = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_endDate.month - 1];
    
    if (_startDate.month == _endDate.month) {
      return 'Week of $startMonth ${_startDate.day}-${_endDate.day}, ${_startDate.year}';
    } else {
      return 'Week of $startMonth ${_startDate.day} - $endMonth ${_endDate.day}, ${_startDate.year}';
    }
  }
}