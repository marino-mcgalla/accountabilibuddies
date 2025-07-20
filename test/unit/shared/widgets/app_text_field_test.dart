import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/shared/widgets/widgets.dart';

void main() {
  group('AppTextField', () {
    Widget buildTextField({
      TextEditingController? controller,
      String? label,
      String? hint,
      String? helperText,
      String? errorText,
      bool enabled = true,
      bool readOnly = false,
      int maxLines = 1,
      int? maxLength,
      AppTextFieldType type = AppTextFieldType.outlined,
      ValueChanged<String>? onChanged,
      VoidCallback? onTap,
      FocusNode? focusNode,
      bool showCounterText = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: label,
            hint: hint,
            helperText: helperText,
            errorText: errorText,
            enabled: enabled,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            type: type,
            onChanged: onChanged,
            onTap: onTap,
            focusNode: focusNode,
            showCounterText: showCounterText,
          ),
        ),
      );
    }

    group('Basic Functionality', () {
      testWidgets('should render text field with hint', (tester) async {
        await tester.pumpWidget(buildTextField(
          hint: 'Enter text here',
        ));

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Enter text here'), findsOneWidget);
      });

      testWidgets('should render text field with label for outlined type', (tester) async {
        await tester.pumpWidget(buildTextField(
          label: 'Email',
          type: AppTextFieldType.outlined,
        ));

        expect(find.text('Email'), findsOneWidget);
      });

      testWidgets('should call onChanged when text changes', (tester) async {
        String? changedText;
        await tester.pumpWidget(buildTextField(
          onChanged: (text) => changedText = text,
        ));

        await tester.enterText(find.byType(TextFormField), 'test input');
        expect(changedText, equals('test input'));
      });

      testWidgets('should call onTap when tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(buildTextField(
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(TextFormField));
        expect(tapped, isTrue);
      });
    });

    group('States', () {
      testWidgets('should be disabled when enabled is false', (tester) async {
        await tester.pumpWidget(buildTextField(
          enabled: false,
        ));

        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.enabled, isFalse);
      });

      testWidgets('should be read-only when readOnly is true', (tester) async {
        await tester.pumpWidget(buildTextField(
          readOnly: true,
        ));

        // Text field should be present but not editable
        expect(find.byType(TextFormField), findsOneWidget);
        
        // Try to enter text - should not work for read-only field
        await tester.enterText(find.byType(TextFormField), 'test');
        expect(find.text('test'), findsNothing);
      });

      testWidgets('should show error text when provided', (tester) async {
        await tester.pumpWidget(buildTextField(
          errorText: 'This field is required',
        ));

        expect(find.text('This field is required'), findsOneWidget);
      });

      testWidgets('should show helper text when provided and no error', (tester) async {
        await tester.pumpWidget(buildTextField(
          helperText: 'This is a helper text',
        ));

        expect(find.text('This is a helper text'), findsOneWidget);
      });

      testWidgets('should not show helper text when error is present', (tester) async {
        await tester.pumpWidget(buildTextField(
          helperText: 'This is a helper text',
          errorText: 'This field is required',
        ));

        expect(find.text('This field is required'), findsOneWidget);
        expect(find.text('This is a helper text'), findsNothing);
      });
    });

    group('Text Field Types', () {
      testWidgets('should render outlined text field', (tester) async {
        await tester.pumpWidget(buildTextField(
          type: AppTextFieldType.outlined,
        ));

        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('should render filled text field', (tester) async {
        await tester.pumpWidget(buildTextField(
          type: AppTextFieldType.filled,
        ));

        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('should render underline text field', (tester) async {
        await tester.pumpWidget(buildTextField(
          type: AppTextFieldType.underline,
        ));

        expect(find.byType(TextFormField), findsOneWidget);
      });
    });

    group('Multiline', () {
      testWidgets('should support multiline text', (tester) async {
        await tester.pumpWidget(buildTextField(
          maxLines: 3,
        ));

        expect(find.byType(TextFormField), findsOneWidget);
        
        // Enter multiline text
        await tester.enterText(find.byType(TextFormField), 'Line 1\nLine 2\nLine 3');
        expect(find.text('Line 1\nLine 2\nLine 3'), findsOneWidget);
      });
    });

    group('Controller', () {
      testWidgets('should use provided controller', (tester) async {
        final controller = TextEditingController(text: 'initial text');
        await tester.pumpWidget(buildTextField(
          controller: controller,
        ));

        expect(find.text('initial text'), findsOneWidget);
      });

      testWidgets('should update controller when text changes', (tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(buildTextField(
          controller: controller,
        ));

        await tester.enterText(find.byType(TextFormField), 'new text');
        expect(controller.text, equals('new text'));
      });
    });

    group('Counter Text', () {
      testWidgets('should show counter text when enabled with maxLength', (tester) async {
        final controller = TextEditingController(text: 'test');
        await tester.pumpWidget(buildTextField(
          controller: controller,
          showCounterText: true,
          maxLength: 10,
        ));

        expect(find.text('4/10'), findsOneWidget);
      });

      testWidgets('should not show counter text when disabled', (tester) async {
        final controller = TextEditingController(text: 'test');
        await tester.pumpWidget(buildTextField(
          controller: controller,
          showCounterText: false,
          maxLength: 10,
        ));

        expect(find.text('4/10'), findsNothing);
      });
    });

    group('Focus States', () {
      testWidgets('should handle focus changes', (tester) async {
        final focusNode = FocusNode();
        await tester.pumpWidget(buildTextField(
          focusNode: focusNode,
          label: 'Test Label',
          type: AppTextFieldType.outlined,
        ));

        // Initially not focused
        expect(focusNode.hasFocus, isFalse);

        // Tap to focus
        await tester.tap(find.byType(TextFormField));
        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
      });
    });
  });
}