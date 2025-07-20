import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:accountabilibuddies/core/core.dart';
import '../../../helpers/test_setup.dart';

void main() {
  group('ServiceLocator', () {
    setUpAll(() async {
      await TestSetup.initialize();
    });

    tearDown(() async {
      await ServiceLocator.reset();
    });

    test('should initialize successfully', () async {
      // Act
      await ServiceLocator.init();

      // Assert
      expect(ServiceLocator.isRegistered<SharedPreferences>(), isTrue);
      expect(ServiceLocator.isRegistered<Dio>(), isTrue);
      expect(ServiceLocator.isRegistered<LoggerService>(), isTrue);
    });

    test('should get SharedPreferences instance', () async {
      // Arrange
      await ServiceLocator.init();

      // Act
      final prefs = sl<SharedPreferences>();

      // Assert
      expect(prefs, isA<SharedPreferences>());
    });

    test('should get Dio instance', () async {
      // Arrange
      await ServiceLocator.init();

      // Act
      final dio = sl<Dio>();

      // Assert
      expect(dio, isA<Dio>());
      expect(dio.options.connectTimeout, equals(const Duration(seconds: 30)));
      expect(dio.options.receiveTimeout, equals(const Duration(seconds: 30)));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
    });

    test('should get LoggerService instance', () async {
      // Arrange
      await ServiceLocator.init();

      // Act
      final logger = sl<LoggerService>();

      // Assert
      expect(logger, isA<LoggerService>());
    });

    test('should handle reset correctly', () async {
      // Arrange
      await ServiceLocator.init();
      expect(ServiceLocator.isRegistered<LoggerService>(), isTrue);

      // Act
      await ServiceLocator.reset();

      // Assert
      expect(ServiceLocator.isRegistered<LoggerService>(), isFalse);
    });

    test('should throw when getting unregistered service', () async {
      // Act & Assert
      expect(
        () => sl<String>(),
        throwsA(isA<Error>()),
      );
    });
  });
}