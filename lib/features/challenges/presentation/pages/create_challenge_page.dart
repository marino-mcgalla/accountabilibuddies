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
  final _descriptionController = TextEditingController();
  
  late DateTime _startDate;
  late DateTime _endDate;
  late String _challengeName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use the helper method from Challenge entity to get next Monday
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _startDate = _getNextMonday(now);
    _endDate = _startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    _challengeName = _formatWeekRange(_startDate, _endDate);
  }

  DateTime _getNextMonday(DateTime date) {
    final today = DateTime(date.year, date.month, date.day);
    final weekday = today.weekday;
    
    if (weekday == DateTime.monday) {
      return today; // Today is Monday
    } else {
      final daysUntilMonday = DateTime.monday - weekday + 7;
      return today.add(Duration(days: daysUntilMonday % 7));
    }
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    final startMonth = _getMonthAbbreviation(start.month);
    final endMonth = _getMonthAbbreviation(end.month);
    
    if (start.month == end.month) {
      return 'Week of $startMonth ${start.day}-${end.day}, ${start.year}';
    } else {
      return 'Week of $startMonth ${start.day} - $endMonth ${end.day}, ${start.year}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
                            Icons.flag,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'New Challenge',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _challengeName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Members can join anytime and lock in their personal goals with custom wagers.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
              const SizedBox(height: 24),

              // Date Range Section
              Text(
                'Challenge Dates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Start Date',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_startDate),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'End Date',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_endDate),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum challenge duration: 7 days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Optional Description
              Text(
                'Challenge Description (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Add a theme or motivation for this week',
                  hintText: 'e.g., "New Year, New Me!" or "Spring Training Week"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return 'Description must be less than 200 characters';
                  }
                  return null;
                },
              ),

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
                'Once created, party members can immediately start locking in their goals and wagers.',
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


  void _createChallenge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('You must be logged in to create a challenge'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final createChallengeUseCase = ref.read(createChallengeUseCaseProvider);
      
      final description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Weekly challenge for personal goals and accountability';
      
      final result = await createChallengeUseCase.call(
        CreateChallengeParams(
          partyId: widget.party.id,
          createdBy: user.id,
          name: _challengeName,
          description: description,
          startDate: _startDate,
          endDate: _endDate,
          commitmentDeadline: null, // No longer using commitment deadlines
        ),
      );

      if (mounted) {
        result.fold(
          onSuccess: (challenge) {
            Navigator.of(context).pop();
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(
            //     content: Text('Challenge created successfully!'),
            //     backgroundColor: Colors.green,
            //   ),
            // );
          },
          onFailure: (failure) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Failed to create challenge: ${failure.message}'),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to create challenge: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow selecting up to 30 days in the past
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Start Date',
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        
        // Adjust end date if needed to maintain max 7 days
        final maxEndDate = _startDate.add(const Duration(days: 7));
        if (_endDate.isAfter(maxEndDate)) {
          _endDate = maxEndDate.subtract(const Duration(seconds: 1)); // End at 23:59:59
        }
        
        // Ensure end date is not before start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        }
        
        // Update challenge name
        _challengeName = _formatWeekRange(_startDate, _endDate);
      });
    }
  }

  void _selectEndDate(BuildContext context) async {
    final maxEndDate = _startDate.add(const Duration(days: 7));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(maxEndDate) ? maxEndDate : _endDate,
      firstDate: _startDate,
      lastDate: maxEndDate,
      helpText: 'Select End Date',
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        // Set to end of day (23:59:59)
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        
        // Update challenge name
        _challengeName = _formatWeekRange(_startDate, _endDate);
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}