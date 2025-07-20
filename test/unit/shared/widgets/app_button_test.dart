import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/shared/widgets/widgets.dart';

void main() {
  group('AppButton', () {
    Widget buildButton({
      required String text,
      VoidCallback? onPressed,
      AppButtonType type = AppButtonType.primary,
      AppButtonSize size = AppButtonSize.medium,
      bool isLoading = false,
      bool isDisabled = false,
      bool fullWidth = false,
      IconData? icon,
      IconPosition iconPosition = IconPosition.left,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: text,
            onPressed: onPressed,
            type: type,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            fullWidth: fullWidth,
            icon: icon,
            iconPosition: iconPosition,
          ),
        ),
      );
    }

    group('Primary Button', () {
      testWidgets('should render primary button with text', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Primary Button',
          onPressed: () {},
        ));

        expect(find.text('Primary Button'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should call onPressed when tapped', (tester) async {
        var pressed = false;
        await tester.pumpWidget(buildButton(
          text: 'Tap Me',
          onPressed: () => pressed = true,
        ));

        await tester.tap(find.byType(ElevatedButton));
        expect(pressed, isTrue);
      });

      testWidgets('should be disabled when isDisabled is true', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Disabled',
          onPressed: () {},
          isDisabled: true,
        ));

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });

      testWidgets('should show loading indicator when isLoading is true', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Loading',
          onPressed: () {},
          isLoading: true,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading'), findsNothing);
      });

      testWidgets('should render with icon on left by default', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'With Icon',
          onPressed: () {},
          icon: Icons.add,
        ));

        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('With Icon'), findsOneWidget);
      });

      testWidgets('should render with icon on right when specified', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'With Icon',
          onPressed: () {},
          icon: Icons.add,
          iconPosition: IconPosition.right,
        ));

        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('With Icon'), findsOneWidget);
      });
    });

    group('Button Types', () {
      testWidgets('should render secondary button', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Secondary',
          onPressed: () {},
          type: AppButtonType.secondary,
        ));

        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Secondary'), findsOneWidget);
      });

      testWidgets('should render outlined button', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Outlined',
          onPressed: () {},
          type: AppButtonType.outlined,
        ));

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.text('Outlined'), findsOneWidget);
      });

      testWidgets('should render text button', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Text',
          onPressed: () {},
          type: AppButtonType.text,
        ));

        expect(find.byType(TextButton), findsOneWidget);
        expect(find.text('Text'), findsOneWidget);
      });

      testWidgets('should render icon button', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Icon',
          onPressed: () {},
          type: AppButtonType.icon,
          icon: Icons.star,
        ));

        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });
    });

    group('Button Sizes', () {
      testWidgets('should render small button', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Small',
          onPressed: () {},
          size: AppButtonSize.small,
        ));

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.height, equals(36));
      });

      testWidgets('should render medium button', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Medium',
          onPressed: () {},
          size: AppButtonSize.medium,
        ));

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.height, equals(48));
      });

      testWidgets('should render large button', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Large',
          onPressed: () {},
          size: AppButtonSize.large,
        ));

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.height, equals(56));
      });
    });

    group('Full Width', () {
      testWidgets('should render full width button when fullWidth is true', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Full Width',
          onPressed: () {},
          fullWidth: true,
        ));

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, equals(double.infinity));
      });

      testWidgets('should not render full width button when fullWidth is false', (tester) async {
        await tester.pumpWidget(buildButton(
          text: 'Not Full Width',
          onPressed: () {},
          fullWidth: false,
        ));

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, isNull);
      });
    });
  });
}