import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/core/core.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result', () {
        // Arrange & Act
        final result = Result.success(42);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.valueOrNull, equals(42));
        expect(result.failureOrNull, isNull);
      });

      test('should map success value', () {
        // Arrange
        final result = Result.success(10);

        // Act
        final mapped = result.map((value) => value * 2);

        // Assert
        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, equals(20));
      });

      test('should flat map success value', () {
        // Arrange
        final result = Result.success(10);

        // Act
        final flatMapped = result.flatMap(
          (value) => Result.success(value.toString()),
        );

        // Assert
        expect(flatMapped.isSuccess, isTrue);
        expect(flatMapped.valueOrNull, equals('10'));
      });

      test('should fold success value', () {
        // Arrange
        final result = Result.success(42);

        // Act
        final folded = result.fold(
          onSuccess: (value) => 'Success: $value',
          onFailure: (failure) => 'Failure: ${failure.message}',
        );

        // Assert
        expect(folded, equals('Success: 42'));
      });

      test('should get value or else for success', () {
        // Arrange
        final result = Result.success(42);

        // Act
        final value = result.getOrElse(0);

        // Assert
        expect(value, equals(42));
      });

      test('should execute onSuccess callback', () {
        // Arrange
        final result = Result.success(42);
        int? capturedValue;

        // Act
        result.onSuccess((value) => capturedValue = value);

        // Assert
        expect(capturedValue, equals(42));
      });
    });

    group('Failure', () {
      test('should create failure result', () {
        // Arrange
        const failure = UnknownFailure(message: 'Test error');

        // Act
        final result = Result<int>.failure(failure);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.failureOrNull, equals(failure));
      });

      test('should not map on failure', () {
        // Arrange
        const failure = UnknownFailure(message: 'Test error');
        final result = Result<int>.failure(failure);

        // Act
        final mapped = result.map((value) => value * 2);

        // Assert
        expect(mapped.isFailure, isTrue);
        expect(mapped.failureOrNull, equals(failure));
      });

      test('should map failure', () {
        // Arrange
        const failure = UnknownFailure(message: 'Test error');
        final result = Result<int>.failure(failure);

        // Act
        final mapped = result.mapFailure(
          (f) => ValidationFailure(message: 'Mapped: ${f.message}'),
        );

        // Assert
        expect(mapped.isFailure, isTrue);
        expect(mapped.failureOrNull?.message, equals('Mapped: Test error'));
      });

      test('should fold failure value', () {
        // Arrange
        const failure = UnknownFailure(message: 'Test error');
        final result = Result<int>.failure(failure);

        // Act
        final folded = result.fold(
          onSuccess: (value) => 'Success: $value',
          onFailure: (failure) => 'Failure: ${failure.message}',
        );

        // Assert
        expect(folded, equals('Failure: Test error'));
      });

      test('should get default value for failure', () {
        // Arrange
        const failure = UnknownFailure(message: 'Test error');
        final result = Result<int>.failure(failure);

        // Act
        final value = result.getOrElse(0);

        // Assert
        expect(value, equals(0));
      });

      test('should execute onFailure callback', () {
        // Arrange
        const failure = UnknownFailure(message: 'Test error');
        final result = Result<int>.failure(failure);
        Failure? capturedFailure;

        // Act
        result.onFailure((f) => capturedFailure = f);

        // Assert
        expect(capturedFailure, equals(failure));
      });

      test('should throw when getOrThrow called on failure', () {
        // Arrange
        const failure = UnknownFailure(message: 'Test error');
        final result = Result<int>.failure(failure);

        // Act & Assert
        expect(() => result.getOrThrow(), throwsA(equals(failure)));
      });
    });

    group('Async Extensions', () {
      test('should map async success value', () async {
        // Arrange
        final result = Future.value(Result.success(10));

        // Act
        final mapped = await result.mapAsync(
          (value) => Future.value(value * 2),
        );

        // Assert
        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, equals(20));
      });

      test('should flat map async success value', () async {
        // Arrange
        final result = Future.value(Result.success(10));

        // Act
        final flatMapped = await result.flatMapAsync(
          (value) => Future.value(Result.success(value.toString())),
        );

        // Assert
        expect(flatMapped.isSuccess, isTrue);
        expect(flatMapped.valueOrNull, equals('10'));
      });
    });
  });
}