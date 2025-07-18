// utils/confirmation_dialog_util.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Displays a confirmation dialog for the given image.
/// Returns the action taken by the user: 'cancel', 'change', or 'confirm'.
Future<String?> showImageConfirmationDialog(
    BuildContext context, XFile image) async {
  final String? action = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirmation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            kIsWeb
                ? Image.network(
                    image.path,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    io.File(image.path),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 10),
            const Text("Do you want to use this photo?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'change'),
            child: const Text("Change Photo"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: const Text("Confirm"),
          ),
        ],
      );
    },
  );
  return action;
}
