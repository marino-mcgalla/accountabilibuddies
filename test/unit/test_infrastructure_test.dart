import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_setup.dart';

void main() {
  testGroupWithSetup('Test Infrastructure', () {
    testWithSetup('should initialize test environment', () async {
      // This test verifies that our test setup works
      await TestSetup.initialize();
      
      // If we get here without exceptions, the setup is working
      expect(true, isTrue);
    });

    test('should run basic unit tests', () {
      // Basic unit test example
      final result = 2 + 2;
      expect(result, equals(4));
    });

    test('should handle async operations', () async {
      // Async test example
      final future = Future.delayed(
        const Duration(milliseconds: 1),
        () => 'test completed',
      );
      
      final result = await future;
      expect(result, equals('test completed'));
    });

    test('should handle exceptions', () {
      // Exception handling test
      expect(() => throw Exception('test error'), throwsException);
    });

    group('Nested test group', () {
      test('should work within nested groups', () {
        expect(1, isNonNegative);
      });
    });
  });
}