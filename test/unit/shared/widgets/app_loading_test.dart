import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/shared/widgets/widgets.dart';

void main() {
  group('AppLoading', () {
    Widget buildLoading({
      AppLoadingType type = AppLoadingType.circular,
      AppLoadingSize size = AppLoadingSize.medium,
      String? message,
      bool overlay = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppLoading(
            type: type,
            size: size,
            message: message,
            overlay: overlay,
          ),
        ),
      );
    }

    group('Loading Types', () {
      testWidgets('should render circular loading indicator', (tester) async {
        await tester.pumpWidget(buildLoading(
          type: AppLoadingType.circular,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should render linear loading indicator', (tester) async {
        await tester.pumpWidget(buildLoading(
          type: AppLoadingType.linear,
        ));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should render dots loading indicator', (tester) async {
        await tester.pumpWidget(buildLoading(
          type: AppLoadingType.dots,
        ));

        expect(find.byType(AppLoading), findsOneWidget);
      });

      testWidgets('should render pulse loading indicator', (tester) async {
        await tester.pumpWidget(buildLoading(
          type: AppLoadingType.pulse,
        ));

        expect(find.byType(AppLoading), findsOneWidget);
      });
    });

    group('Loading Sizes', () {
      testWidgets('should render small loading indicator', (tester) async {
        await tester.pumpWidget(buildLoading(
          size: AppLoadingSize.small,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should render medium loading indicator', (tester) async {
        await tester.pumpWidget(buildLoading(
          size: AppLoadingSize.medium,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should render large loading indicator', (tester) async {
        await tester.pumpWidget(buildLoading(
          size: AppLoadingSize.large,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Message', () {
      testWidgets('should render loading indicator with message', (tester) async {
        await tester.pumpWidget(buildLoading(
          message: 'Loading...',
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
      });

      testWidgets('should render loading indicator without message', (tester) async {
        await tester.pumpWidget(buildLoading());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Text), findsNothing);
      });
    });

    group('Overlay', () {
      testWidgets('should render overlay when overlay is true', (tester) async {
        await tester.pumpWidget(buildLoading(
          overlay: true,
        ));

        expect(find.byType(Material), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should not render overlay when overlay is false', (tester) async {
        await tester.pumpWidget(buildLoading(
          overlay: false,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });

  group('AppLoadingOverlay', () {
    testWidgets('should show and hide overlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppLoadingOverlay.show(context),
                child: const Text('Show Loading'),
              ),
            ),
          ),
        ),
      );

      // Initially no overlay
      expect(find.byType(AppLoading), findsNothing);

      // Show overlay
      await tester.tap(find.text('Show Loading'));
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);

      // Hide overlay
      AppLoadingOverlay.hide();
      await tester.pump();

      expect(find.byType(AppLoading), findsNothing);
    });

    testWidgets('should show overlay with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppLoadingOverlay.show(
                  context,
                  message: 'Please wait...',
                ),
                child: const Text('Show Loading'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
    });
  });
}