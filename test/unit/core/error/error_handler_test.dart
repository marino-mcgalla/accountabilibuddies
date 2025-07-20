import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:accountabilibuddies/core/core.dart';

void main() {
  group('ErrorHandler', () {
    group('handle', () {
      test('should return failure as-is if already a failure', () {
        // Arrange
        const originalFailure = UnknownFailure(message: 'Test failure');

        // Act
        final result = ErrorHandler.handle(originalFailure);

        // Assert
        expect(result, equals(originalFailure));
      });

      test('should handle DioException with connection timeout', () {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        // Act
        final result = ErrorHandler.handle(dioError);

        // Assert
        expect(result, isA<NetworkFailure>());
        expect(result.code, equals('TIMEOUT'));
      });

      test('should handle DioException with no connection', () {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        // Act
        final result = ErrorHandler.handle(dioError);

        // Assert
        expect(result, isA<NetworkFailure>());
        expect(result.code, equals('NO_CONNECTION'));
      });

      test('should handle DioException with 401 response', () {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final result = ErrorHandler.handle(dioError);

        // Assert
        expect(result, isA<AuthFailure>());
        expect(result.code, equals('UNAUTHORIZED'));
      });

      test('should handle DioException with 403 response', () {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        );

        // Act
        final result = ErrorHandler.handle(dioError);

        // Assert
        expect(result, isA<PermissionFailure>());
        expect(result.code, equals('FORBIDDEN'));
      });

      test('should handle FormatException', () {
        // Arrange
        const error = FormatException('Invalid format');

        // Act
        final result = ErrorHandler.handle(error);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result.message, contains('Invalid format'));
      });

      test('should handle ArgumentError', () {
        // Arrange
        final error = ArgumentError('Invalid argument');

        // Act
        final result = ErrorHandler.handle(error);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result.message, equals('Invalid argument'));
      });

      test('should handle unknown errors', () {
        // Arrange
        const error = 'Unknown error string';

        // Act
        final result = ErrorHandler.handle(error);

        // Assert
        expect(result, isA<UnknownFailure>());
        expect(result.message, equals(error));
      });

      test('should handle null errors', () {
        // Act
        final result = ErrorHandler.handle(null);

        // Assert
        expect(result, isA<UnknownFailure>());
        expect(result.message, equals('An unexpected error occurred'));
      });
    });

    group('guard', () {
      test('should return value on success', () async {
        // Arrange
        Future<int> operation() async => 42;

        // Act
        final result = await ErrorHandler.guard(operation);

        // Assert
        expect(result, equals(42));
      });

      test('should throw handled failure on error', () async {
        // Arrange
        Future<int> operation() async => throw const FormatException('Test');

        // Act & Assert
        expect(
          () => ErrorHandler.guard(operation),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });

    group('guardSync', () {
      test('should return value on success', () {
        // Arrange
        int operation() => 42;

        // Act
        final result = ErrorHandler.guardSync(operation);

        // Assert
        expect(result, equals(42));
      });

      test('should throw handled failure on error', () {
        // Arrange
        int operation() => throw const FormatException('Test');

        // Act & Assert
        expect(
          () => ErrorHandler.guardSync(operation),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });
  });
}