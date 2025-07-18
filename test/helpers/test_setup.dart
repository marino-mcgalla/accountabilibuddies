import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global test setup for all tests
class TestSetup {
  static bool _initialized = false;

  /// Initialize test environment
  static Future<void> initialize() async {
    if (_initialized) return;

    // Ensure Flutter binding is initialized
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock platform channels
    _mockPlatformChannels();

    // Set up shared preferences
    await _setupSharedPreferences();

    // Set up Firebase mocks (will be implemented later)
    await _setupFirebaseMocks();

    _initialized = true;
  }

  /// Mock platform channels
  static void _mockPlatformChannels() {
    // Mock method channels that might be called during tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      },
    );
  }

  /// Set up shared preferences for testing
  static Future<void> _setupSharedPreferences() async {
    SharedPreferences.setMockInitialValues({});
  }

  /// Set up Firebase mocks (placeholder)
  static Future<void> _setupFirebaseMocks() async {
    // TODO: Implement Firebase mocks when we add Firebase
    // This will mock Firebase services for testing
  }

  /// Clean up after tests
  static Future<void> cleanup() async {
    // Clean up any test resources
    await _cleanupSharedPreferences();
  }

  /// Clean up shared preferences
  static Future<void> _cleanupSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

/// Test group wrapper with setup and teardown
void testGroupWithSetup(
  String description,
  void Function() body, {
  dynamic skip,
}) {
  group(description, () {
    setUpAll(() async {
      await TestSetup.initialize();
    });

    tearDownAll(() async {
      await TestSetup.cleanup();
    });

    body();
  }, skip: skip);
}

/// Test wrapper with setup and teardown
void testWithSetup(
  String description,
  Future<void> Function() body, {
  dynamic skip,
}) {
  test(description, () async {
    await TestSetup.initialize();
    await body();
    await TestSetup.cleanup();
  }, skip: skip);
}

/// Widget test wrapper with setup and teardown
void widgetTestWithSetup(
  String description,
  Future<void> Function(WidgetTester tester) body, {
  dynamic skip,
}) {
  testWidgets(description, (WidgetTester tester) async {
    await TestSetup.initialize();
    await body(tester);
    await TestSetup.cleanup();
  }, skip: skip);
}