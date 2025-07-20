import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/core/core.dart';
import 'package:accountabilibuddies/shared/widgets/widgets.dart';

void main() {
  group('AppErrorWidget', () {
    Widget buildErrorWidget({
      required Failure failure,
      VoidCallback? onRetry,
      bool showRetryButton = true,
      bool compact = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppErrorWidget(
            failure: failure,
            onRetry: onRetry,
            showRetryButton: showRetryButton,
            compact: compact,
          ),
        ),
      );
    }

    group('Error Types', () {
      testWidgets('should render network error', (tester) async {
        const failure = NetworkFailure(message: 'Network error');
        await tester.pumpWidget(buildErrorWidget(failure: failure));

        expect(find.text('Connection Error'), findsOneWidget);
        expect(find.text('Please check your internet connection and try again.'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('should render auth error', (tester) async {
        const failure = AuthFailure(message: 'Auth error');
        await tester.pumpWidget(buildErrorWidget(failure: failure));

        expect(find.text('Authentication Error'), findsOneWidget);
        expect(find.text('Authentication failed. Please sign in again.'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });

      testWidgets('should render validation error', (tester) async {
        const failure = ValidationFailure(message: 'Validation failed');
        await tester.pumpWidget(buildErrorWidget(failure: failure));

        expect(find.text('Invalid Input'), findsOneWidget);
        expect(find.text('Validation failed'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should render unknown error', (tester) async {
        const failure = UnknownFailure(message: 'Unknown error');
        await tester.pumpWidget(buildErrorWidget(failure: failure));

        expect(find.text('Error'), findsOneWidget);
        expect(find.text('Unknown error'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('Retry Button', () {
      testWidgets('should show retry button when showRetryButton is true', (tester) async {
        const failure = NetworkFailure(message: 'Network error');
        await tester.pumpWidget(buildErrorWidget(
          failure: failure,
          showRetryButton: true,
          onRetry: () {},
        ));

        expect(find.text('Retry'), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      });

      testWidgets('should not show retry button when showRetryButton is false', (tester) async {
        const failure = NetworkFailure(message: 'Network error');
        await tester.pumpWidget(buildErrorWidget(
          failure: failure,
          showRetryButton: false,
        ));

        expect(find.text('Retry'), findsNothing);
        expect(find.byType(AppButton), findsNothing);
      });

      testWidgets('should not show retry button when onRetry is null', (tester) async {
        const failure = NetworkFailure(message: 'Network error');
        await tester.pumpWidget(buildErrorWidget(
          failure: failure,
          showRetryButton: true,
          onRetry: null,
        ));

        expect(find.text('Retry'), findsNothing);
        expect(find.byType(AppButton), findsNothing);
      });

      testWidgets('should call onRetry when retry button is tapped', (tester) async {
        const failure = NetworkFailure(message: 'Network error');
        var retryPressed = false;
        
        await tester.pumpWidget(buildErrorWidget(
          failure: failure,
          onRetry: () => retryPressed = true,
        ));

        await tester.tap(find.text('Retry'));
        expect(retryPressed, isTrue);
      });
    });

    group('Compact Mode', () {
      testWidgets('should render compact error widget', (tester) async {
        const failure = NetworkFailure(message: 'Network error');
        await tester.pumpWidget(buildErrorWidget(
          failure: failure,
          compact: true,
        ));

        expect(find.text('Connection Error'), findsOneWidget);
        expect(find.text('Please check your internet connection and try again.'), findsOneWidget);
        // In compact mode, icon should not be shown
        expect(find.byIcon(Icons.wifi_off), findsNothing);
      });
    });
  });

  group('AppErrorBoundary', () {
    testWidgets('should render child when no error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorBoundary(
              child: const Text('Normal content'),
            ),
          ),
        ),
      );

      expect(find.text('Normal content'), findsOneWidget);
      expect(find.byType(AppErrorWidget), findsNothing);
    });

    testWidgets('should render error widget when error occurs', (tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: AppErrorBoundary(
            child: const Text('Normal content'),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('Normal content'), findsOneWidget);
    });
  });

  group('AppSnackbar', () {
    testWidgets('should show error snackbar', (tester) async {
      const failure = NetworkFailure(message: 'Network error');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.showError(context, failure),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show success snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.showSuccess(context, 'Success!'),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Success!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should show info snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.showInfo(context, 'Info message'),
                child: const Text('Show Info'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Info message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should show warning snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.showWarning(context, 'Warning message'),
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Warning message'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });
  });
}