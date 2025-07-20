import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isEmailVerified,
    required this.createdAt,
    this.lastSignInAt,
    this.metadata,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSignInAt: json['lastSignInAt'] != null
          ? DateTime.parse(json['lastSignInAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        isEmailVerified,
        createdAt,
        lastSignInAt,
        metadata,
      ];
}

class AuthState extends Equatable {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isOnboarded;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    required this.isAuthenticated,
    required this.isOnboarded,
    required this.isLoading,
    this.error,
  });

  const AuthState.initial()
      : user = null,
        isAuthenticated = false,
        isOnboarded = false,
        isLoading = false,
        error = null;

  const AuthState.loading()
      : user = null,
        isAuthenticated = false,
        isOnboarded = false,
        isLoading = true,
        error = null;

  const AuthState.authenticated({
    required this.user,
    required this.isOnboarded,
  })  : isAuthenticated = true,
        isLoading = false,
        error = null;

  const AuthState.unauthenticated({this.error})
      : user = null,
        isAuthenticated = false,
        isOnboarded = false,
        isLoading = false;

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isOnboarded,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        user,
        isAuthenticated,
        isOnboarded,
        isLoading,
        error,
      ];
}

// Login/Register request models
class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class RegisterRequest extends Equatable {
  final String email;
  final String password;
  final String? displayName;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

class ForgotPasswordRequest extends Equatable {
  final String email;

  const ForgotPasswordRequest({
    required this.email,
  });

  @override
  List<Object> get props => [email];
}