import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/core.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.authLogin),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isEmailSent ? _buildEmailSentView(theme) : _buildResetForm(theme, authState),
        ),
      ),
    );
  }

  Widget _buildResetForm(ThemeData theme, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          
          Icon(
            Icons.lock_reset,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          
          Text(
            'Forgot Password?',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Email field
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.email_outlined),
            enabled: !authState.isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!_isValidEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onSubmitted: (_) => _handleResetPassword(),
          ),
          const SizedBox(height: 24),
          
          // Reset button
          AppButton(
            text: 'Send Reset Link',
            onPressed: authState.isLoading ? null : _handleResetPassword,
            isLoading: authState.isLoading,
            fullWidth: true,
          ),
          const SizedBox(height: 16),
          
          // Back to login
          AppButton(
            text: 'Back to Sign In',
            type: AppButtonType.text,
            onPressed: authState.isLoading ? null : () => context.go(AppRoutes.authLogin),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        
        Icon(
          Icons.mark_email_read,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        
        Text(
          'Email Sent!',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        Text(
          'Please check your email and follow the instructions to reset your password.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        // Resend button
        AppButton(
          text: 'Resend Email',
          type: AppButtonType.outlined,
          onPressed: _handleResendEmail,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        
        // Back to login
        AppButton(
          text: 'Back to Sign In',
          type: AppButtonType.text,
          onPressed: () => context.go(AppRoutes.authLogin),
        ),
      ],
    );
  }

  void _handleResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authController = ref.read(authControllerProvider.notifier);
      await authController.sendPasswordResetEmail(_emailController.text.trim());
      
      // Check if there was an error
      final authState = ref.read(authControllerProvider);
      if (authState.error != null) {
        if (mounted) {
          AppSnackbar.showError(
            context,
            UnknownFailure(message: authState.error!),
          );
        }
      } else {
        // Success - show email sent view
        setState(() {
          _isEmailSent = true;
        });
      }
    }
  }

  void _handleResendEmail() async {
    final authController = ref.read(authControllerProvider.notifier);
    await authController.sendPasswordResetEmail(_emailController.text.trim());
    
    // Check if there was an error
    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          UnknownFailure(message: authState.error!),
        );
      }
    } else {
      // Success - show confirmation
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Reset link sent again!',
        );
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}