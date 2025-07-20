import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/shared/widgets/widgets.dart';

void main() {
  group('AppDialog', () {
    Widget buildDialog({
      String? title,
      IconData? titleIcon,
      Widget? content,
      AppDialogAction? primaryAction,
      AppDialogAction? secondaryAction,
      bool showCloseButton = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppDialog(
            title: title,
            titleIcon: titleIcon,
            content: content,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            showCloseButton: showCloseButton,
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render dialog with title', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
        ));

        expect(find.text('Test Dialog'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('should render dialog with title and icon', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
          titleIcon: Icons.info,
        ));

        expect(find.text('Test Dialog'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
      });

      testWidgets('should render dialog with content', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
          content: const Text('Dialog content'),
        ));

        expect(find.text('Dialog content'), findsOneWidget);
      });

      testWidgets('should render close button when showCloseButton is true', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
          showCloseButton: true,
        ));

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should not render close button when showCloseButton is false', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
          showCloseButton: false,
        ));

        expect(find.byIcon(Icons.close), findsNothing);
      });
    });

    group('Actions', () {
      testWidgets('should render primary action', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
          primaryAction: const AppDialogAction(text: 'Primary'),
        ));

        expect(find.text('Primary'), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      });

      testWidgets('should render secondary action', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
          secondaryAction: const AppDialogAction(text: 'Secondary'),
        ));

        expect(find.text('Secondary'), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      });

      testWidgets('should render both primary and secondary actions', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
          primaryAction: const AppDialogAction(text: 'Primary'),
          secondaryAction: const AppDialogAction(text: 'Secondary'),
        ));

        expect(find.text('Primary'), findsOneWidget);
        expect(find.text('Secondary'), findsOneWidget);
        expect(find.byType(AppButton), findsNWidgets(2));
      });

      testWidgets('should not render actions when none provided', (tester) async {
        await tester.pumpWidget(buildDialog(
          title: 'Test Dialog',
        ));

        expect(find.byType(AppButton), findsNothing);
      });
    });
  });

  group('AppDialogs', () {
    testWidgets('should show confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialogs.showConfirmation(
                  context: context,
                  title: 'Confirm Action',
                  message: 'Are you sure?',
                ),
                child: const Text('Show Confirmation'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Confirmation'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should show destructive confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialogs.showDestructiveConfirmation(
                  context: context,
                  title: 'Delete Item',
                  message: 'This action cannot be undone.',
                ),
                child: const Text('Show Destructive'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Destructive'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('should show info dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialogs.showInfo(
                  context: context,
                  title: 'Information',
                  message: 'This is an info message.',
                ),
                child: const Text('Show Info'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();

      expect(find.text('Information'), findsOneWidget);
      expect(find.text('This is an info message.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should show error dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialogs.showError(
                  context: context,
                  title: 'Error',
                  message: 'Something went wrong.',
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show success dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialogs.showSuccess(
                  context: context,
                  title: 'Success',
                  message: 'Operation completed successfully.',
                ),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Operation completed successfully.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should show loading dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialogs.showLoading(
                  context: context,
                  title: 'Loading',
                  message: 'Please wait...',
                ),
                child: const Text('Show Loading'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pumpAndSettle();

      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
      expect(find.byType(AppLoading), findsOneWidget);
    });

    testWidgets('should show text input dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialogs.showTextInput(
                  context: context,
                  title: 'Enter Text',
                  message: 'Please enter some text:',
                  hintText: 'Type here...',
                ),
                child: const Text('Show Text Input'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Text Input'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Text'), findsOneWidget);
      expect(find.text('Please enter some text:'), findsOneWidget);
      expect(find.text('Type here...'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should return input text when OK is pressed', (tester) async {
      String? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialogs.showTextInput(
                    context: context,
                    title: 'Enter Text',
                    message: 'Please enter some text:',
                  );
                },
                child: const Text('Show Text Input'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Text Input'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test input');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, equals('test input'));
    });

    testWidgets('should return null when Cancel is pressed', (tester) async {
      String? result = 'initial';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialogs.showTextInput(
                    context: context,
                    title: 'Enter Text',
                    message: 'Please enter some text:',
                  );
                },
                child: const Text('Show Text Input'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Text Input'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}