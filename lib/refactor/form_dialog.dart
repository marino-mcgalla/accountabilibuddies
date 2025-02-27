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
