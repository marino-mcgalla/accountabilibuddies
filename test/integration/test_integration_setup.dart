import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/test_helper.dart';
import '../helpers/test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test Infrastructure', () {
    testWidgets('should run integration tests', (tester) async {
      await TestSetup.initialize();

      // Create a simple app for integration testing
      final app = TestHelper.createTestableWidget(
        child: const Scaffold(
          body: Center(
            child: Text('Integration Test App'),
          ),
        ),
      );

      // Pump the app
      await tester.pumpWidget(app);

      // Verify the app loads
      TestHelper.expectSingleWidget(TestHelper.findByText('Integration Test App'));

      await TestSetup.cleanup();
    });

    testWidgets('should handle app lifecycle', (tester) async {
      await TestSetup.initialize();

      // Create a simple app
      final app = TestHelper.createTestableWidget(
        child: const _TestApp(),
      );

      // Pump the app
      await tester.pumpWidget(app);

      // Verify initial state
      TestHelper.expectSingleWidget(TestHelper.findByText('Welcome'));

      // Simulate app background/foreground
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeSuccessEnvelope('AppLifecycleState.paused'),
        (data) {},
      );

      await tester.pumpAndSettle();

      // App should still be working
      TestHelper.expectSingleWidget(TestHelper.findByText('Welcome'));

      await TestSetup.cleanup();
    });
  });
}

/// Test app for integration testing
class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome'),
            SizedBox(height: 20),
            Text('AccountabiliBuddies'),
          ],
        ),
      ),
    );
  }
}