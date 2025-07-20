import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/core/core.dart';

void main() {
  group('LoggerService', () {
    late LoggerService loggerService;
    
    setUp(() {
      loggerService = LoggerService();
    });

    test('should be singleton', () {
      // Arrange & Act
      final logger1 = LoggerService();
      final logger2 = LoggerService();

      // Assert
      expect(identical(logger1, logger2), isTrue);
    });

    test('should add and notify listeners', () {
      // Arrange
      LogLevel? capturedLevel;
      String? capturedMessage;
      dynamic capturedError;

      void listener(LogLevel level, String message, dynamic error, StackTrace? stackTrace) {
        capturedLevel = level;
        capturedMessage = message;
        capturedError = error;
      }

      loggerService.addListener(listener);

      // Act
      loggerService.error('Test error', error: 'Error object');

      // Assert
      expect(capturedLevel, equals(LogLevel.error));
      expect(capturedMessage, equals('Test error'));
      expect(capturedError, equals('Error object'));
    });

    test('should remove listeners', () {
      // Arrange
      bool listenerCalled = false;

      void listener(LogLevel level, String message, dynamic error, StackTrace? stackTrace) {
        listenerCalled = true;
      }

      loggerService.addListener(listener);
      loggerService.removeListener(listener);

      // Act
      loggerService.info('Test message');

      // Assert
      expect(listenerCalled, isFalse);
    });

    test('should respect log level', () {
      // Arrange
      int callCount = 0;

      void listener(LogLevel level, String message, dynamic error, StackTrace? stackTrace) {
        callCount++;
      }

      loggerService.addListener(listener);
      loggerService.setLogLevel(LogLevel.warning);

      // Act
      loggerService.debug('Debug message'); // Should not be logged
      loggerService.info('Info message'); // Should not be logged
      loggerService.warning('Warning message'); // Should be logged
      loggerService.error('Error message'); // Should be logged

      // Assert
      expect(callCount, equals(2));
    });

    test('should handle listener errors gracefully', () {
      // Arrange
      void badListener(LogLevel level, String message, dynamic error, StackTrace? stackTrace) {
        throw Exception('Listener error');
      }

      void goodListener(LogLevel level, String message, dynamic error, StackTrace? stackTrace) {
        // This should still be called
      }

      loggerService.addListener(badListener);
      loggerService.addListener(goodListener);

      // Act & Assert - should not throw
      expect(() => loggerService.info('Test message'), returnsNormally);
    });

    group('log methods', () {
      test('should log verbose messages', () {
        // Arrange
        String? capturedMessage;
        loggerService.setLogLevel(LogLevel.verbose);
        loggerService.addListener((level, message, error, stackTrace) {
          if (level == LogLevel.verbose) capturedMessage = message;
        });

        // Act
        loggerService.verbose('Verbose message');

        // Assert
        expect(capturedMessage, equals('Verbose message'));
      });

      test('should log debug messages', () {
        // Arrange
        String? capturedMessage;
        loggerService.addListener((level, message, error, stackTrace) {
          if (level == LogLevel.debug) capturedMessage = message;
        });

        // Act
        loggerService.debug('Debug message');

        // Assert
        expect(capturedMessage, equals('Debug message'));
      });

      test('should log info messages', () {
        // Arrange
        String? capturedMessage;
        loggerService.addListener((level, message, error, stackTrace) {
          if (level == LogLevel.info) capturedMessage = message;
        });

        // Act
        loggerService.info('Info message');

        // Assert
        expect(capturedMessage, equals('Info message'));
      });

      test('should log warning messages', () {
        // Arrange
        String? capturedMessage;
        loggerService.addListener((level, message, error, stackTrace) {
          if (level == LogLevel.warning) capturedMessage = message;
        });

        // Act
        loggerService.warning('Warning message');

        // Assert
        expect(capturedMessage, equals('Warning message'));
      });

      test('should log error messages with error object', () {
        // Arrange
        String? capturedMessage;
        dynamic capturedError;
        loggerService.addListener((level, message, error, stackTrace) {
          if (level == LogLevel.error) {
            capturedMessage = message;
            capturedError = error;
          }
        });

        // Act
        loggerService.error('Error message', error: Exception('Test exception'));

        // Assert
        expect(capturedMessage, equals('Error message'));
        expect(capturedError, isA<Exception>());
      });

      test('should log fatal messages', () {
        // Arrange
        String? capturedMessage;
        loggerService.addListener((level, message, error, stackTrace) {
          if (level == LogLevel.fatal) capturedMessage = message;
        });

        // Act
        loggerService.fatal('Fatal message');

        // Assert
        expect(capturedMessage, equals('Fatal message'));
      });
    });
  });
}