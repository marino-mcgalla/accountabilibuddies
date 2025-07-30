import 'package:equatable/equatable.dart';

/// Represents the status of a challenge
enum ChallengeStatus {
  /// Challenge is active and accepting participation
  active,
  /// Challenge week completed, in summary/review phase
  summary,
  /// Challenge was cancelled
  cancelled,
  
  // Deprecated enum values for backwards compatibility
  @Deprecated('Use active instead')
  pending,
  @Deprecated('Use summary instead')
  settling,
  @Deprecated('Use summary instead')
  completed,
}

/// Represents a wagering period/challenge within a party
class Challenge extends Equatable {
  const Challenge({
    required this.id,
    required this.partyId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.commitmentDeadline,
    this.totalPool = 0.0,
    this.metadata = const {},
  });

  /// Unique identifier for the challenge
  final String id;
  
  /// ID of the party this challenge belongs to
  final String partyId;
  
  /// Challenge name (e.g., "Week of Jan 15-21, 2024")
  final String name;
  
  /// Optional description or theme for the challenge
  final String description;
  
  /// When the challenge period starts (typically Monday)
  final DateTime startDate;
  
  /// When the challenge period ends (typically Sunday)
  final DateTime endDate;
  
  /// Current status of the challenge
  final ChallengeStatus status;
  
  /// User ID of who created/started this challenge
  final String createdBy;
  
  /// When the challenge was created
  final DateTime createdAt;
  
  /// When the challenge was last updated
  final DateTime updatedAt;
  
  /// Deadline for members to commit to the challenge
  final DateTime? commitmentDeadline;
  
  /// Total wager pool from all participants
  final double totalPool;
  
  /// Additional metadata for the challenge
  final Map<String, dynamic> metadata;

  /// Display name for challenge status
  String get statusDisplay {
    switch (status) {
      case ChallengeStatus.active:
        return 'Active';
      case ChallengeStatus.summary:
        return 'Summary Phase';
      case ChallengeStatus.cancelled:
        return 'Cancelled';
      // Handle deprecated enum values
      case ChallengeStatus.pending:
        return 'Pending (Deprecated)';
      case ChallengeStatus.settling:
        return 'Settling (Deprecated)';
      case ChallengeStatus.completed:
        return 'Completed (Deprecated)';
    }
  }

  /// Check if the challenge is currently accepting commitments
  bool get isAcceptingCommitments => status == ChallengeStatus.active;

  /// Check if the challenge is currently active
  bool get isActive => status == ChallengeStatus.active;

  /// Check if the challenge has ended
  bool get hasEnded => 
      status == ChallengeStatus.summary || 
      status == ChallengeStatus.cancelled ||
      DateTime.now().isAfter(endDate);

  /// Duration of the challenge in days
  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Days remaining in the challenge (if active)
  int get daysRemaining {
    if (!isActive) return 0;
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining + 1;
  }

  /// Progress percentage (0.0 to 1.0) based on time elapsed
  double get timeProgress {
    if (!isActive) return status == ChallengeStatus.summary ? 1.0 : 0.0;
    
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    
    final totalDuration = endDate.difference(startDate).inMilliseconds;
    final elapsed = now.difference(startDate).inMilliseconds;
    
    return elapsed / totalDuration;
  }

  Challenge copyWith({
    String? id,
    String? partyId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? commitmentDeadline,
    double? totalPool,
    Map<String, dynamic>? metadata,
  }) {
    return Challenge(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commitmentDeadline: commitmentDeadline ?? this.commitmentDeadline,
      totalPool: totalPool ?? this.totalPool,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partyId,
        name,
        description,
        startDate,
        endDate,
        status,
        createdBy,
        createdAt,
        updatedAt,
        commitmentDeadline,
        totalPool,
        metadata,
      ];

  /// Create a new weekly challenge starting from the next Monday
  static Challenge createWeeklyChallenge({
    required String partyId,
    required String createdBy,
    String? description,
  }) {
    final now = DateTime.now();
    final startOfWeek = _getNextMonday(now);
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    return Challenge(
      id: '', // Will be set by repository
      partyId: partyId,
      name: 'Week of ${_formatWeekRange(startOfWeek, endOfWeek)}',
      description: description ?? 'Weekly challenge',
      startDate: startOfWeek,
      endDate: endOfWeek,
      status: ChallengeStatus.active,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get the next Monday from given date (or today if today is Monday)
  static DateTime _getNextMonday(DateTime date) {
    final now = DateTime(date.year, date.month, date.day);
    final weekday = now.weekday;
    
    if (weekday == DateTime.monday) {
      return now; // Today is Monday
    } else {
      final daysUntilMonday = DateTime.monday - weekday + 7;
      return now.add(Duration(days: daysUntilMonday % 7));
    }
  }

  /// Format week range for display
  static String _formatWeekRange(DateTime start, DateTime end) {
    final startMonth = _getMonthAbbreviation(start.month);
    final endMonth = _getMonthAbbreviation(end.month);
    
    if (start.month == end.month) {
      return '$startMonth ${start.day}-${end.day}, ${start.year}';
    } else {
      return '$startMonth ${start.day} - $endMonth ${end.day}, ${start.year}';
    }
  }

  /// Get month abbreviation
  static String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  String toString() => 'Challenge(id: $id, name: $name, status: $status)';
}