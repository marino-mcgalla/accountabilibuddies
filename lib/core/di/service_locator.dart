import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logging/logger_service.dart';

/// Service locator instance
final sl = GetIt.instance;

/// Service locator setup
class ServiceLocator {
  ServiceLocator._();

  /// Initialize all dependencies
  static Future<void> init() async {
    // External dependencies
    await _initExternalDependencies();

    // Core
    _initCore();

    // Features - will be added as we implement them
    // _initAuth();
    // _initGoals();
    // _initParty();
    // _initProofs();
    // _initChallenge();
  }

  /// Initialize external dependencies
  static Future<void> _initExternalDependencies() async {
    // SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(sharedPreferences);

    // Dio
    sl.registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      )..interceptors.addAll([
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            error: true,
            logPrint: (log) => sl<LoggerService>().debug(log.toString()),
          ),
        ]),
    );
  }

  /// Initialize core services
  static void _initCore() {
    // Logger
    sl.registerLazySingleton<LoggerService>(
      () => LoggerService(),
    );
  }

  /// Clean up resources (for testing)
  static Future<void> reset() async {
    await sl.reset();
  }

  /// Check if service is registered
  static bool isRegistered<T extends Object>({
    String? instanceName,
  }) {
    return sl.isRegistered<T>(instanceName: instanceName);
  }
}

/// Extension for easier service locator access
extension ServiceLocatorExtension on GetIt {
  /// Get service with type safety
  T get<T extends Object>() => call<T>();
  
  /// Get service async with type safety
  Future<T> getAsync<T extends Object>() => getAsync<T>();
}