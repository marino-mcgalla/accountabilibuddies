import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility functions for the application
class Utils {
  /// Returns a list of ISO date strings for the current week starting from Monday
  static List<String> getCurrentWeekDays(DateTime now) {
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Start from Monday
    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return date.toIso8601String().split('T').first;
    });
  }

  /// Formats a date to a day abbreviation (Mon, Tue, etc.)
  static String getDayAbbreviation(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('EEE').format(date);
  }

  /// Gets a short day abbreviation (M, T, W, etc.)
  static String getShortDayAbbreviation(String isoDate) {
    final date = DateTime.parse(isoDate);
    final dayOfWeek = date.weekday;
    return ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][dayOfWeek];
  }

  /// Formats a date for display (MM/DD/YYYY)
  static String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Shows a snackbar with the given message
  static void showFeedback(BuildContext context, String message,
      {bool isError = false}) {
    // Safely show feedback only if the context is still mounted
    try {
      // Only try to show if the context is still valid
      if (context is StatefulElement && context.state.mounted) {
        // Get a global key for the scaffold messenger
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : null,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // If we can't show the feedback (context issue, etc), just print to console
      print('Could not show feedback: $message');
    }
  }

  /// Returns a color based on status string
  static Color getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.yellow;
      case 'pending':
        return Colors.yellow;
      case 'completed':
        return Colors.green;
      case 'skipped':
        return const Color.fromARGB(255, 80, 80, 80);
      case 'denied':
        return const Color.fromARGB(255, 118, 14, 7); // Dark red
      case 'planned':
        return Colors.blue;
      case 'default':
      default:
        return Colors.grey;
    }
  }
}
