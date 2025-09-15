import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/core.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Provider for AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});

// Provider for auth state changes stream
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Provider for current user
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final result = await authRepository.getCurrentUser();
  return result.fold(
    onSuccess: (user) => user,
    onFailure: (failure) => null,
  );
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState.loading()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authRepository.authStateChanges.listen(
      (user) async {
        if (user != null) {
          // Check if user is onboarded
          final isOnboarded = user.metadata?['onboarded'] ?? false;
          state = AuthState.authenticated(
            user: user,
            isOnboarded: isOnboarded,
          );
        } else {
          state = const AuthState.unauthenticated();
        }
      },
      onError: (error) {
        state = AuthState.unauthenticated(error: error.toString());
      },
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState.loading();
    
    final result = await _authRepository.signInWithEmail(email, password);
    
    result.fold(
      onSuccess: (user) {
        // State will be updated by the auth state changes listener
      },
      onFailure: (failure) {
        state = AuthState.unauthenticated(error: failure.message);
      },
    );
  }

  Future<void> signUpWithEmail(String email, String password, String? displayName) async {
    state = const AuthState.loading();
    
    final result = await _authRepository.signUpWithEmail(email, password, displayName);
    
    result.fold(
      onSuccess: (user) {
        // State will be updated by the auth state changes listener
      },
      onFailure: (failure) {
        state = AuthState.unauthenticated(error: failure.message);
      },
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final result = await _authRepository.sendPasswordResetEmail(email);
    
    result.fold(
      onSuccess: (_) {
        // Password reset email sent successfully
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    
    final result = await _authRepository.signOut();
    
    result.fold(
      onSuccess: (_) {
        // State will be updated by the auth state changes listener
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> deleteAccount() async {
    state = const AuthState.loading();
    
    final result = await _authRepository.deleteAccount();
    
    result.fold(
      onSuccess: (_) {
        // State will be updated by the auth state changes listener
      },
      onFailure: (failure) {
        state = AuthState.unauthenticated(error: failure.message);
      },
    );
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    if (state.user == null) return;

    final result = await _authRepository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    
    result.fold(
      onSuccess: (_) {
        // Update local state
        final updatedUser = state.user!.copyWith(
          displayName: displayName,
          photoUrl: photoUrl,
        );
        state = state.copyWith(user: updatedUser);
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> updateEmail(String newEmail) async {
    final result = await _authRepository.updateEmail(newEmail);
    
    result.fold(
      onSuccess: (_) {
        // Email update initiated, user will need to verify new email
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> updatePassword(String newPassword) async {
    final result = await _authRepository.updatePassword(newPassword);
    
    result.fold(
      onSuccess: (_) {
        // Password updated successfully
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> reauthenticateWithEmail(String email, String password) async {
    final result = await _authRepository.reauthenticateWithEmail(email, password);
    
    result.fold(
      onSuccess: (_) {
        // Reauthentication successful
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> sendEmailVerification() async {
    final result = await _authRepository.sendEmailVerification();
    
    result.fold(
      onSuccess: (_) {
        // Email verification sent
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> reloadUser() async {
    final result = await _authRepository.reloadUser();
    
    result.fold(
      onSuccess: (_) {
        // User reloaded, get updated user data
        _getCurrentUser();
      },
      onFailure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> _getCurrentUser() async {
    final result = await _authRepository.getCurrentUser();
    
    result.fold(
      onSuccess: (user) {
        final isOnboarded = user.metadata?['onboarded'] ?? false;
        state = AuthState.authenticated(
          user: user,
          isOnboarded: isOnboarded,
        );
      },
      onFailure: (failure) {
        state = AuthState.unauthenticated(error: failure.message);
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> markAsOnboarded() async {
    if (state.user != null) {
      try {
        // Update the user's metadata in Firebase to persist onboarding status
        final updatedUser = state.user!.copyWith(
          metadata: {
            ...?state.user!.metadata,
            'onboarded': true,
          },
        );
        
        // Update in Firebase
        await _authRepository.updateUser(updatedUser);
        
        // Update local state
        state = state.copyWith(
          user: updatedUser,
          isOnboarded: true,
        );
        
        // logger.debug('AuthController: User marked as onboarded and saved to Firebase');
      } catch (e, stackTrace) {
        logger.error('AuthController: Failed to mark user as onboarded', error: e, stackTrace: stackTrace);
        // Still update local state even if Firebase update fails
        state = state.copyWith(isOnboarded: true);
      }
    }
  }
}

// Utility providers for common auth checks
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAuthenticated;
});

final isOnboardedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isOnboarded;
});

final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.error;
});

final userProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.user;
});