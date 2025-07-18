import 'package:flutter/material.dart';

/// A reusable form dialog widget
class FormDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String cancelText;
  final String submitText;
  final bool isSubmitEnabled;
  final bool isLoading;

  const FormDialog({
    required this.title,
    required this.child,
    required this.onCancel,
    required this.onSubmit,
    this.cancelText = 'Cancel',
    this.submitText = 'Submit',
    this.isSubmitEnabled = true,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check screen size for responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // On mobile, use a more appropriate dialog size
    if (isSmallScreen) {
      return Dialog(
        // Make the dialog larger on smaller screens
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title row with loading indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable content
              SingleChildScrollView(
                child: child,
              ),

              const SizedBox(height: 24),

              // Action buttons - stacked for mobile
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed:
                        (isLoading || !isSubmitEnabled) ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(submitText),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isLoading ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(cancelText),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Original desktop layout
      return AlertDialog(
        title: Row(
          children: [
            Text(title),
            if (isLoading) ...[
              const SizedBox(width: 16),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        content: SingleChildScrollView(
          child: child,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: (isLoading || !isSubmitEnabled) ? null : onSubmit,
            child: Text(submitText),
          ),
        ],
      );
    }
  }
}
