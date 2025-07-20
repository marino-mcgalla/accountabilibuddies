import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, code, originalError];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Network connection failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Permission failures
class PermissionFailure extends Failure {
  final String permission;

  const PermissionFailure({
    required super.message,
    required this.permission,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [...super.props, permission];
}

/// Firebase-specific failures
class FirebaseFailure extends Failure {
  const FirebaseFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Storage-related failures
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
    super.code,
    super.originalError,
    super.stackTrace,
  });
}