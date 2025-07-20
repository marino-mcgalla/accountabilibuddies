import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/features/auth/models/user_model.dart';

void main() {
  group('UserModel', () {
    final testUser = UserModel(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      isEmailVerified: true,
      createdAt: DateTime(2023, 1, 1),
      lastSignInAt: DateTime(2023, 1, 2),
      metadata: {'onboarded': true},
    );

    test('should create user with required fields', () {
      final user = UserModel(
        id: 'id',
        email: 'email@test.com',
        isEmailVerified: false,
        createdAt: DateTime(2023, 1, 1),
      );

      expect(user.id, equals('id'));
      expect(user.email, equals('email@test.com'));
      expect(user.isEmailVerified, isFalse);
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    test('should create user with all fields', () {
      expect(testUser.id, equals('test-id'));
      expect(testUser.email, equals('test@example.com'));
      expect(testUser.displayName, equals('Test User'));
      expect(testUser.photoUrl, equals('https://example.com/photo.jpg'));
      expect(testUser.isEmailVerified, isTrue);
      expect(testUser.createdAt, equals(DateTime(2023, 1, 1)));
      expect(testUser.lastSignInAt, equals(DateTime(2023, 1, 2)));
      expect(testUser.metadata, equals({'onboarded': true}));
    });

    test('should support copyWith', () {
      final updatedUser = testUser.copyWith(
        displayName: 'Updated Name',
        isEmailVerified: false,
      );

      expect(updatedUser.id, equals(testUser.id));
      expect(updatedUser.email, equals(testUser.email));
      expect(updatedUser.displayName, equals('Updated Name'));
      expect(updatedUser.isEmailVerified, isFalse);
      expect(updatedUser.photoUrl, equals(testUser.photoUrl));
    });

    test('should convert to JSON', () {
      final json = testUser.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['email'], equals('test@example.com'));
      expect(json['displayName'], equals('Test User'));
      expect(json['photoUrl'], equals('https://example.com/photo.jpg'));
      expect(json['isEmailVerified'], isTrue);
      expect(json['createdAt'], equals('2023-01-01T00:00:00.000'));
      expect(json['lastSignInAt'], equals('2023-01-02T00:00:00.000'));
      expect(json['metadata'], equals({'onboarded': true}));
    });

    test('should create from JSON', () {
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'photoUrl': 'https://example.com/photo.jpg',
        'isEmailVerified': true,
        'createdAt': '2023-01-01T00:00:00.000',
        'lastSignInAt': '2023-01-02T00:00:00.000',
        'metadata': {'onboarded': true},
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      expect(user.isEmailVerified, isTrue);
      expect(user.createdAt, equals(DateTime(2023, 1, 1)));
      expect(user.lastSignInAt, equals(DateTime(2023, 1, 2)));
      expect(user.metadata, equals({'onboarded': true}));
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'displayName': null,
        'photoUrl': null,
        'isEmailVerified': false,
        'createdAt': '2023-01-01T00:00:00.000',
        'lastSignInAt': null,
        'metadata': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.lastSignInAt, isNull);
      expect(user.metadata, isNull);
    });

    test('should support equality comparison', () {
      final user1 = UserModel(
        id: 'id',
        email: 'email@test.com',
        isEmailVerified: false,
        createdAt: DateTime(2023, 1, 1),
      );

      final user2 = UserModel(
        id: 'id',
        email: 'email@test.com',
        isEmailVerified: false,
        createdAt: DateTime(2023, 1, 1),
      );

      final user3 = UserModel(
        id: 'different-id',
        email: 'email@test.com',
        isEmailVerified: false,
        createdAt: DateTime(2023, 1, 1),
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });

  group('AuthState', () {
    final testUser = UserModel(
      id: 'test-id',
      email: 'test@example.com',
      isEmailVerified: true,
      createdAt: DateTime(2023, 1, 1),
    );

    test('should create initial state', () {
      const state = AuthState.initial();

      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isOnboarded, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('should create loading state', () {
      const state = AuthState.loading();

      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isOnboarded, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.error, isNull);
    });

    test('should create authenticated state', () {
      final state = AuthState.authenticated(
        user: testUser,
        isOnboarded: true,
      );

      expect(state.user, equals(testUser));
      expect(state.isAuthenticated, isTrue);
      expect(state.isOnboarded, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('should create unauthenticated state', () {
      const state = AuthState.unauthenticated(error: 'Test error');

      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isOnboarded, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, equals('Test error'));
    });

    test('should support copyWith', () {
      final state = AuthState.authenticated(
        user: testUser,
        isOnboarded: false,
      );

      final updatedState = state.copyWith(
        isOnboarded: true,
        error: 'Test error',
      );

      expect(updatedState.user, equals(testUser));
      expect(updatedState.isAuthenticated, isTrue);
      expect(updatedState.isOnboarded, isTrue);
      expect(updatedState.isLoading, isFalse);
      expect(updatedState.error, equals('Test error'));
    });

    test('should support equality comparison', () {
      final state1 = AuthState.authenticated(
        user: testUser,
        isOnboarded: true,
      );

      final state2 = AuthState.authenticated(
        user: testUser,
        isOnboarded: true,
      );

      final state3 = AuthState.authenticated(
        user: testUser,
        isOnboarded: false,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('LoginRequest', () {
    test('should create login request', () {
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(request.email, equals('test@example.com'));
      expect(request.password, equals('password123'));
    });

    test('should support equality comparison', () {
      const request1 = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      const request2 = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      const request3 = LoginRequest(
        email: 'different@example.com',
        password: 'password123',
      );

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });

  group('RegisterRequest', () {
    test('should create register request', () {
      const request = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      expect(request.email, equals('test@example.com'));
      expect(request.password, equals('password123'));
      expect(request.displayName, equals('Test User'));
    });

    test('should create register request without display name', () {
      const request = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(request.email, equals('test@example.com'));
      expect(request.password, equals('password123'));
      expect(request.displayName, isNull);
    });

    test('should support equality comparison', () {
      const request1 = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      const request2 = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      const request3 = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Different User',
      );

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });

  group('ForgotPasswordRequest', () {
    test('should create forgot password request', () {
      const request = ForgotPasswordRequest(
        email: 'test@example.com',
      );

      expect(request.email, equals('test@example.com'));
    });

    test('should support equality comparison', () {
      const request1 = ForgotPasswordRequest(
        email: 'test@example.com',
      );

      const request2 = ForgotPasswordRequest(
        email: 'test@example.com',
      );

      const request3 = ForgotPasswordRequest(
        email: 'different@example.com',
      );

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });
}