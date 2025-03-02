// lib/features/proof_submission/services/image_picker_service.dart
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'dart:js' as js;
import 'package:flutter/material.dart';

class ImagePickerService {
  // Pick an image from the gallery for web
  Future<Uint8List?> pickImage() async {
    final completer = Completer<Uint8List?>();

    // Create a file input element
    final html.FileUploadInputElement input = html.FileUploadInputElement()
      ..accept = 'image/*';

    // Add the input to the body
    html.document.body?.append(input);

    // Set up the onchange listener
    input.onChange.listen((e) {
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        final reader = html.FileReader();

        reader.onLoad.listen((e) {
          final result = reader.result as Uint8List;
          completer.complete(result);
        });

        reader.onError.listen((e) {
          debugPrint('Error reading file: $e');
          completer.complete(null);
        });

        reader.readAsArrayBuffer(file);
      } else {
        completer.complete(null);
      }

      // Clean up
      input.remove();
    });

    // Trigger click to open file picker
    input.click();

    return completer.future;
  }

  // Take a photo using direct camera access for web
  Future<Uint8List?> takePhoto() async {
    final completer = Completer<Uint8List?>();

    // Create UI elements for camera
    final html.DivElement container = html.DivElement()
      ..id = 'camera-container'
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0,0,0,0.9)'
      ..style.zIndex = '9999'
      ..style.display = 'flex'
      ..style.flexDirection = 'column'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center';

    final html.VideoElement video = html.VideoElement()
      ..id = 'camera-preview'
      ..autoplay = true
      ..style.width = '100%'
      ..style.maxWidth = '500px'
      ..style.borderRadius = '8px';

    final html.CanvasElement canvas = html.CanvasElement()
      ..id = 'canvas-element'
      ..style.display = 'none';

    final html.DivElement buttonsContainer = html.DivElement()
      ..style.display = 'flex'
      ..style.marginTop = '20px';

    final html.ButtonElement captureButton = html.ButtonElement()
      ..id = 'capture-button'
      ..text = 'Take Photo'
      ..style.padding = '10px 20px'
      ..style.margin = '0 10px'
      ..style.backgroundColor = '#4CAF50'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '4px'
      ..style.cursor = 'pointer';

    final html.ButtonElement cancelButton = html.ButtonElement()
      ..id = 'cancel-button'
      ..text = 'Cancel'
      ..style.padding = '10px 20px'
      ..style.margin = '0 10px'
      ..style.backgroundColor = '#f44336'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '4px'
      ..style.cursor = 'pointer';

    // Add elements to DOM
    buttonsContainer.children.add(captureButton);
    buttonsContainer.children.add(cancelButton);
    container.children.add(video);
    container.children.add(canvas);
    container.children.add(buttonsContainer);
    html.document.body?.append(container);

    // Set up event listeners
    cancelButton.onClick.listen((event) {
      stopCamera(video);
      container.remove();
      completer.complete(null);
    });

    captureButton.onClick.listen((event) {
      // Capture image from video
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      canvas.context2D.drawImage(video, 0, 0);

      // Convert to blob
      try {
        canvas.toBlob('image/jpeg', 0.85).then((blob) {
          stopCamera(video);

          // Convert blob to array buffer
          final reader = html.FileReader();
          reader.onLoad.listen((e) {
            final result = reader.result as Uint8List;
            container.remove();
            completer.complete(result);
          });

          reader.readAsArrayBuffer(blob);
        });
      } catch (e) {
        debugPrint('Error capturing image: $e');
        stopCamera(video);
        container.remove();
        completer.complete(null);
      }
    });

    // Start camera
    try {
      html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'environment', // Use back camera if available
        },
        'audio': false,
      }).then((stream) {
        video.srcObject = stream;
      }).catchError((error) {
        debugPrint('Error accessing camera: $error');
        container.remove();
        completer.complete(null);
      });
    } catch (e) {
      debugPrint('Error starting camera: $e');
      container.remove();
      completer.complete(null);
    }

    return completer.future;
  }

  // Helper method to stop camera stream
  void stopCamera(html.VideoElement video) {
    final stream = video.srcObject as html.MediaStream?;
    if (stream != null) {
      final tracks = stream.getVideoTracks();
      for (var track in tracks) {
        track.stop();
      }
    }
  }

  // Fallback method if direct camera access doesn't work
  Future<Uint8List?> takePhotoFallback() async {
    final completer = Completer<Uint8List?>();

    // Create a file input with capture attribute explicitly set
    final html.FileUploadInputElement input = html.FileUploadInputElement()
      ..accept = 'image/*';

    // Try multiple ways to set capture
    input.setAttribute('capture', 'environment');
    input.setAttribute('capture', 'camera');

    try {
      // This is an attempt to directly set the property (may work in some browsers)
      js.context.callMethod('eval', [
        'document.querySelector("input[type=file]").capture = "environment";'
      ]);
    } catch (e) {
      // Ignore errors, just try the next approach
    }

    // Add the input to the body
    html.document.body?.append(input);

    // Set up the onchange listener
    input.onChange.listen((e) {
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        final reader = html.FileReader();

        reader.onLoad.listen((e) {
          final result = reader.result as Uint8List;
          completer.complete(result);
        });

        reader.onError.listen((e) {
          debugPrint('Error reading file: $e');
          completer.complete(null);
        });

        reader.readAsArrayBuffer(file);
      } else {
        completer.complete(null);
      }

      // Clean up
      input.remove();
    });

    // Trigger click to open camera
    input.click();

    return completer.future;
  }
}
