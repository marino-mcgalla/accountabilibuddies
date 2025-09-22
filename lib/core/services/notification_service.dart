import '../core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return InAppNotificationService();
});

/// Types of notifications that can be sent
enum NotificationType {
  challengeCreated,
  challengeStarted,
  challengeCompleted,
  commitmentRequired,
  commitmentDeadline,
  memberCommitted,
  memberOptedOut,
  proofSubmitted,
}

/// Represents a notification to be sent
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.recipients,
    this.data = const {},
    this.scheduledTime,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final List<String> recipients; // User IDs
  final Map<String, dynamic> data;
  final DateTime? scheduledTime;
}

/// Service for managing notifications
abstract class NotificationService {
  /// Send a notification immediately
  Future<Result<void>> sendNotification(AppNotification notification);

  /// Schedule a notification for later
  Future<Result<void>> scheduleNotification(AppNotification notification);

  /// Cancel a scheduled notification
  Future<Result<void>> cancelNotification(String notificationId);

  /// Send challenge-related notifications
  Future<Result<void>> sendChallengeCreatedNotification({
    required String challengeId,
    required String challengeName,
    required String partyName,
    required List<String> memberIds,
    required String creatorName,
  });

  Future<Result<void>> sendChallengeStartedNotification({
    required String challengeId,
    required String challengeName,
    required List<String> memberIds,
  });

  Future<Result<void>> sendCommitmentRequiredNotification({
    required String challengeId,
    required String challengeName,
    required List<String> memberIds,
    required DateTime deadline,
  });

  Future<Result<void>> sendMemberCommittedNotification({
    required String challengeId,
    required String challengeName,
    required String memberName,
    required List<String> recipientIds,
  });

  Future<Result<void>> sendMemberOptedOutNotification({
    required String challengeId,
    required String challengeName,
    required String memberName,
    required List<String> recipientIds,
  });

  Future<Result<void>> sendProofSubmittedNotification({
    required String challengeId,
    required String challengeName,
    required String submitterName,
    required List<String> recipientIds,
  });
}

/// Simple in-app notification service implementation
class InAppNotificationService implements NotificationService {
  final List<AppNotification> _notifications = [];

  @override
  Future<Result<void>> sendNotification(AppNotification notification) async {
    try {
      logger.info('InAppNotificationService: Sending notification "${notification.title}" to ${notification.recipients.length} recipients');
      
      // In a real implementation, this would send push notifications
      // For now, we just log and store the notification
      _notifications.add(notification);
      
      return Result.success(null);
    } catch (e, stackTrace) {
      logger.error('InAppNotificationService: Error sending notification', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to send notification',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> scheduleNotification(AppNotification notification) async {
    try {
      logger.info('InAppNotificationService: Scheduling notification "${notification.title}" for ${notification.scheduledTime}');
      
      // In a real implementation, this would schedule push notifications
      _notifications.add(notification);
      
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'Failed to schedule notification',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> cancelNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(UnknownFailure(
        message: 'Failed to cancel notification',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void>> sendChallengeCreatedNotification({
    required String challengeId,
    required String challengeName,
    required String partyName,
    required List<String> memberIds,
    required String creatorName,
  }) async {
    final notification = AppNotification(
      id: 'challenge_created_$challengeId',
      type: NotificationType.challengeCreated,
      title: 'New Challenge: $challengeName',
      body: '$creatorName started a new challenge in $partyName. Set your goals and wager now!',
      recipients: memberIds,
      data: {
        'challengeId': challengeId,
        'challengeName': challengeName,
        'partyName': partyName,
        'creatorName': creatorName,
      },
    );

    return await sendNotification(notification);
  }

  @override
  Future<Result<void>> sendChallengeStartedNotification({
    required String challengeId,
    required String challengeName,
    required List<String> memberIds,
  }) async {
    final notification = AppNotification(
      id: 'challenge_started_$challengeId',
      type: NotificationType.challengeStarted,
      title: 'Challenge Started: $challengeName',
      body: 'The challenge has begun! Start working towards your goals.',
      recipients: memberIds,
      data: {
        'challengeId': challengeId,
        'challengeName': challengeName,
      },
    );

    return await sendNotification(notification);
  }

  @override
  Future<Result<void>> sendCommitmentRequiredNotification({
    required String challengeId,
    required String challengeName,
    required List<String> memberIds,
    required DateTime deadline,
  }) async {
    final notification = AppNotification(
      id: 'commitment_required_$challengeId',
      type: NotificationType.commitmentRequired,
      title: 'Commitment Required: $challengeName',
      body: 'Don\'t forget to set your goals and wager before the deadline!',
      recipients: memberIds,
      data: {
        'challengeId': challengeId,
        'challengeName': challengeName,
        'deadline': deadline.toIso8601String(),
      },
    );

    return await sendNotification(notification);
  }

  @override
  Future<Result<void>> sendMemberCommittedNotification({
    required String challengeId,
    required String challengeName,
    required String memberName,
    required List<String> recipientIds,
  }) async {
    final notification = AppNotification(
      id: 'member_committed_${challengeId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.memberCommitted,
      title: '$memberName Committed',
      body: '$memberName has committed to the challenge "$challengeName"',
      recipients: recipientIds,
      data: {
        'challengeId': challengeId,
        'challengeName': challengeName,
        'memberName': memberName,
      },
    );

    return await sendNotification(notification);
  }

  @override
  Future<Result<void>> sendMemberOptedOutNotification({
    required String challengeId,
    required String challengeName,
    required String memberName,
    required List<String> recipientIds,
  }) async {
    final notification = AppNotification(
      id: 'member_opted_out_${challengeId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.memberOptedOut,
      title: '$memberName Opted Out',
      body: '$memberName has opted out of the challenge "$challengeName"',
      recipients: recipientIds,
      data: {
        'challengeId': challengeId,
        'challengeName': challengeName,
        'memberName': memberName,
      },
    );

    return await sendNotification(notification);
  }

  @override
  Future<Result<void>> sendProofSubmittedNotification({
    required String challengeId,
    required String challengeName,
    required String submitterName,
    required List<String> recipientIds,
  }) async {
    final notification = AppNotification(
      id: 'proof_submitted_${challengeId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.proofSubmitted,
      title: '📸 New Proof Submitted!',
      body: '$submitterName just submitted proof for "$challengeName"',
      recipients: recipientIds,
      data: {
        'challengeId': challengeId,
        'challengeName': challengeName,
        'submitterName': submitterName,
      },
    );

    return await sendNotification(notification);
  }

  /// Get all notifications (for debugging/testing)
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Clear all notifications (for testing)
  void clearNotifications() => _notifications.clear();
}