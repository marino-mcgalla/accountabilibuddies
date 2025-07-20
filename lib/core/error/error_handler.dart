import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'failures.dart';

/// Global error handler that converts various exceptions to Failures
class ErrorHandler {
  ErrorHandler._();

  /// Handles any error and converts it to a Failure
  static Failure handle(dynamic error, [StackTrace? stackTrace]) {
    if (error is Failure) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }

    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error, stackTrace);
    }

    if (error is FirebaseException) {
      return _handleFirebaseError(error, stackTrace);
    }

    if (error is FormatException) {
      return ValidationFailure(
        message: 'Invalid format: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is ArgumentError) {
      return ValidationFailure(
        message: error.message?.toString() ?? 'Invalid argument',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Log unexpected errors in debug mode
    if (kDebugMode) {
      print('Unexpected error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }

    return UnknownFailure(
      message: error?.toString() ?? 'An unexpected error occurred',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handles Dio network errors
  static Failure _handleDioError(DioException error, StackTrace? stackTrace) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
          originalError: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'No internet connection. Please check your network.',
          code: 'NO_CONNECTION',
          originalError: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _getServerErrorMessage(error.response);
        
        if (statusCode == 401) {
          return AuthFailure(
            message: message ?? 'Authentication failed. Please login again.',
            code: 'UNAUTHORIZED',
            originalError: error,
            stackTrace: stackTrace,
          );
        }
        
        if (statusCode == 403) {
          return PermissionFailure(
            message: message ?? 'You do not have permission to perform this action.',
            permission: 'unknown',
            code: 'FORBIDDEN',
            originalError: error,
            stackTrace: stackTrace,
          );
        }
        
        return ServerFailure(
          message: message ?? 'Server error occurred.',
          code: statusCode?.toString() ?? 'SERVER_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.cancel:
        return NetworkFailure(
          message: 'Request was cancelled.',
          code: 'CANCELLED',
          originalError: error,
          stackTrace: stackTrace,
        );

      default:
        return NetworkFailure(
          message: error.message ?? 'Network error occurred.',
          code: 'NETWORK_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// Extracts error message from server response
  static String? _getServerErrorMessage(Response? response) {
    if (response?.data == null) return null;
    
    final data = response!.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? 
             data['error'] as String? ?? 
             data['detail'] as String?;
    }
    
    return data.toString();
  }

  /// Handles Firebase Auth errors
  static Failure _handleFirebaseAuthError(
    FirebaseAuthException error,
    StackTrace? stackTrace,
  ) {
    final message = switch (error.code) {
      'user-not-found' => 'No user found with this email.',
      'wrong-password' => 'Invalid password.',
      'email-already-in-use' => 'This email is already registered.',
      'invalid-email' => 'Invalid email address.',
      'weak-password' => 'Password is too weak.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'operation-not-allowed' => 'This operation is not allowed.',
      'network-request-failed' => 'Network error. Please check your connection.',
      _ => error.message ?? 'Authentication error occurred.',
    };

    return AuthFailure(
      message: message,
      code: error.code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handles general Firebase errors
  static Failure _handleFirebaseError(
    FirebaseException error,
    StackTrace? stackTrace,
  ) {
    final message = switch (error.code) {
      'permission-denied' => 'You do not have permission to perform this action.',
      'unavailable' => 'Service is temporarily unavailable. Please try again.',
      'data-loss' => 'Data loss occurred. Please try again.',
      'deadline-exceeded' => 'Operation took too long. Please try again.',
      _ => error.message ?? 'Firebase error occurred.',
    };

    if (error.code == 'permission-denied') {
      return PermissionFailure(
        message: message,
        permission: 'firebase',
        code: error.code,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return FirebaseFailure(
      message: message,
      code: error.code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Wraps an async operation with error handling
  static Future<T> guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      throw handle(error, stackTrace);
    }
  }

  /// Wraps a sync operation with error handling
  static T guardSync<T>(T Function() operation) {
    try {
      return operation();
    } catch (error, stackTrace) {
      throw handle(error, stackTrace);
    }
  }
}