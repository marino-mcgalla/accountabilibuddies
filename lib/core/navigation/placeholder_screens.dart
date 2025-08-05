import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/core.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/auth/auth.dart';
import '../../features/goals/goals.dart';
import '../../features/parties/domain/entities/party.dart';
import '../../features/parties/domain/entities/party_invite.dart';
import '../../features/parties/presentation/providers/party_providers.dart';
import '../../features/challenges/presentation/providers/challenge_providers.dart';
import '../../features/challenges/domain/entities/challenge.dart';

// Placeholder screens for navigation setup
// These will be replaced with actual feature screens later

// Global function to show pending invites modal
void showPendingInvites(BuildContext context, WidgetRef ref, List<PartyInvite> invites) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail),
                const SizedBox(width: 8),
                Text(
                  'Party Invitations (${invites.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: invites.length,
              itemBuilder: (context, index) {
                final invite = invites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                invite.partyName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invite.partyName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Invited by ${invite.inviterName}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expires in ${invite.daysUntilExpiration} days',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  final controller = ref.read(partyControllerProvider);
                                  final success = await controller.declineInvite(invite.id);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success 
                                            ? 'Invite declined' 
                                            : 'Failed to decline invite'),
                                        backgroundColor: success ? Colors.orange : Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  final controller = ref.read(partyControllerProvider);
                                  final success = await controller.acceptInvite(invite.id);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      success
                                          ? SnackBar(content: Text('Joined ${invite.partyName}!'))
                                          : const SnackBar(
                                              content: Text('Failed to accept invite'),
                                              backgroundColor: Colors.red,
                                            ),
                                    );
                                  }
                                },
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    // Wait for auth state to be determined
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      final authState = ref.read(authControllerProvider);
      
      if (authState.isAuthenticated) {
        if (authState.isOnboarded) {
          context.go(AppRoutes.dashboard);
        } else {
          context.go(AppRoutes.onboarding);
        }
      } else {
        context.go(AppRoutes.authLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 64),
            SizedBox(height: 16),
            Text('AccountabiliBuddies', style: TextStyle(fontSize: 24)),
            SizedBox(height: 32),
            AppLoading(),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to AccountabiliBuddies!',
      description: 'Stay accountable to your goals with help from friends and the power of social proof.',
      icon: Icons.flag,
    ),
    OnboardingPage(
      title: 'Set Your Goals',
      description: 'Create meaningful goals and track your progress with daily, weekly, or monthly targets.',
      icon: Icons.track_changes,
    ),
    OnboardingPage(
      title: 'Submit Proof',
      description: 'Share photo evidence of your progress and get validated by your accountability buddies.',
      icon: Icons.camera_alt,
    ),
    OnboardingPage(
      title: 'Build Your Party',
      description: 'Invite friends or join groups to create accountability partnerships that work.',
      icon: Icons.group,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    try {
      await ref.read(authControllerProvider.notifier).markAsOnboarded();
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      // If marking as onboarded fails, still allow them to proceed
      // but log the error
      logger.error('OnboardingScreen: Failed to mark user as onboarded', error: e);
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 120,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _pages.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == entry.key
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authControllerProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag, size: 64),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (authState.isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _onLoginPressed,
                  child: const Text('Login'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.authRegister),
                child: const Text('Don\'t have an account? Register'),
              ),
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag, size: 64),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (authState.isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _onRegisterPressed,
                  child: const Text('Register'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.authLogin),
                child: const Text('Already have an account? Login'),
              ),
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const Center(
        child: Text('Forgot Password Screen'),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final pendingInvitesAsync = ref.watch(pendingInvitesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Notification badge for pending invites
          pendingInvitesAsync.when(
            data: (invites) {
              if (invites.isEmpty) {
                return const SizedBox.shrink();
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => showPendingInvites(context, ref, invites),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${invites.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh goals and party data
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeSection(context, user),
              const SizedBox(height: 24),
              
              // Quick stats
              _buildQuickStats(context),
              const SizedBox(height: 24),
              
              // Current challenge section
              _buildCurrentChallengeSection(context, ref),
              const SizedBox(height: 24),
              
              // Parties section (with pending invites indicator)
              _buildPartiesSection(context, ref),
              const SizedBox(height: 24),
              
              // Recent activity
              _buildRecentActivitySection(context),
              const SizedBox(height: 24),
              
              // Quick actions
              _buildQuickActionsSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/goals/templates/create'),
        tooltip: 'Create Goal Template',
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _buildWelcomeSection(BuildContext context, UserModel? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor,
              child: user?.photoUrl != null 
                  ? ClipOval(
                      child: Image.network(
                        user!.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 
                      user?.email.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user?.displayName ?? user?.email.split('@')[0] ?? 'User'}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let\'s make today count!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(userStatsProvider);
        
        return statsAsync.when(
          data: (stats) => Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Active Goals',
                  value: '${stats.activeGoals}',
                  icon: Icons.track_changes,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Progress',
                  value: '${(stats.averageProgress * 100).toInt()}%',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Completed',
                  value: '${stats.completedGoals}',
                  icon: Icons.check_circle,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          loading: () => Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Active Goals',
                  value: '...',
                  icon: Icons.track_changes,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Progress',
                  value: '...',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Completed',
                  value: '...',
                  icon: Icons.check_circle,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          error: (error, stack) => Text('Error loading stats'),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentChallengeSection(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partiesProvider);
    final goalTemplatesAsync = ref.watch(goalTemplatesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        partiesAsync.when(
          data: (parties) {
            // Check if there are any active challenges
            bool hasActiveChallenge = false;
            // This is a simplified check - in real implementation, you'd check for active challenges per party
            // For now, we'll assume no active challenges and show templates
            
            if (hasActiveChallenge) {
              // Show challenge section
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Current Challenge',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.party),
                        child: const Text('View Parties'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: _ActiveChallengeDisplay(parties: parties),
                  ),
                ],
              );
            } else {
              // Show goal templates section
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Planned Goals for Next Challenge',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.goals),
                        child: const Text('Manage Templates'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: goalTemplatesAsync.when(
                      data: (templates) => _buildGoalTemplatesDisplay(context, templates),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stack) => _buildNoTemplatesCard(context),
                    ),
                  ),
                ],
              );
            }
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Planned Goals for Next Challenge',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.goals),
                    child: const Text('Manage Templates'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: goalTemplatesAsync.when(
                  data: (templates) => _buildGoalTemplatesDisplay(context, templates),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => _buildNoTemplatesCard(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalTemplatesDisplay(BuildContext context, List<GoalTemplate> templates) {
    // Filter to only show active templates
    final activeTemplates = templates.where((template) => template.isActive).toList();
    
    if (activeTemplates.isEmpty) {
      return _buildNoTemplatesCard(context);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review and adjust your goals before the next challenge starts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          // Display templates in a grid layout
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: activeTemplates.map((template) => _buildTemplateCard(context, template)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, GoalTemplate template) {
    final frequencyText = _getTemplateFrequencyText(template);
    
    return InkWell(
      onTap: () => context.go('/goals/templates/${template.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: (MediaQuery.of(context).size.width - 72) / 2, // Responsive width for 2 columns
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              template.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              frequencyText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTemplatesCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No goal templates yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create goal templates to plan for your next challenge!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.go('/goals/templates/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
          ),
        ],
      ),
    );
  }

  String _getTemplateFrequencyText(GoalTemplate template) {
    final frequency = template.plannedFrequency ?? 0;
    final goalTypeString = template.goalType.toString();
    
    if (goalTypeString.contains('daily')) {
      if (frequency == 7) {
        return 'Daily';
      } else if (frequency == 1) {
        return '1 day/week';
      } else {
        return '$frequency days/week';
      }
    } else if (goalTypeString.contains('total')) {
      return '$frequency total';
    } else {
      return '$frequency times';
    }
  }
  
  Widget _buildChallengeCard(BuildContext context, Challenge challenge, Party party) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  party.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Party: ${party.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getChallengeStatusColor(challenge.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  challenge.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getChallengeStatusColor(challenge.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatChallengeDate(challenge.startDate)} - ${_formatChallengeDate(challenge.endDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (challenge.status == ChallengeStatus.pending) ...[
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Waiting for members to commit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutesExtension.partyDetail(party.id)),
              child: Text(challenge.status == ChallengeStatus.pending 
                  ? 'Set Your Goals' 
                  : 'View Challenge'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoChallengeCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No active challenge',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back soon or ask your party leader to start one!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getChallengeStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.pending:
        return Colors.orange;
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.settling:
        return Colors.blue;
      case ChallengeStatus.completed:
        return Colors.purple;
      case ChallengeStatus.cancelled:
        return Colors.red;
      case ChallengeStatus.summary:
        return Colors.indigo;
    }
  }
  
  String _formatChallengeDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }


  Widget _buildPartiesSection(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partiesProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Parties',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.party),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            partiesAsync.when(
              data: (parties) {
                if (parties.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(Icons.group, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No parties yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/party/create'),
                          child: const Text('Create a Party'),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: parties.take(3).map((party) => 
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          party.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(party.name),
                      subtitle: Text('${party.memberCount} members'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('${AppRoutes.party}/${party.id}'),
                    ),
                  ).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Failed to load parties',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.timeline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/goals/templates/create'),
                    icon: const Icon(Icons.flag),
                    label: const Text('New Template'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/proof/submit'),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Submit Proof'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/party/create'),
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create Party'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/party/join'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Join Party'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Goals screens - Use real implementation
class GoalsScreen extends GoalsPage {
  const GoalsScreen({super.key});
}

// CreateGoalScreen removed - users create goal templates instead

// Goal Template screens - Use real implementation from goals feature
class CreateGoalTemplateScreen extends CreateGoalTemplatePage {
  const CreateGoalTemplateScreen({super.key});
}

// Template detail screen - Use real implementation
class GoalTemplateDetailScreen extends GoalTemplateDetailPage {
  const GoalTemplateDetailScreen({required String templateId, super.key})
      : super(templateId: templateId);
}

// Edit template screen - Use real implementation
class EditGoalTemplateScreen extends EditGoalTemplatePage {
  const EditGoalTemplateScreen({required String templateId, super.key})
      : super(templateId: templateId);
}

class EditGoalScreen extends StatelessWidget {
  const EditGoalScreen({required this.goalId, super.key});
  final String goalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Goal')),
      body: Center(child: Text('Edit Goal Screen - Coming Soon\nGoal ID: $goalId')),
    );
  }
}

class GoalDetailsScreen extends StatelessWidget {
  const GoalDetailsScreen({required this.goalId, super.key});
  final String goalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Details')),
      body: Center(child: Text('Goal Details Screen - Coming Soon\nGoal ID: $goalId')),
    );
  }
}

class SubmitProofScreen extends StatelessWidget {
  const SubmitProofScreen({this.goalId, super.key});
  final String? goalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Proof')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Submit Proof Screen - Coming Soon'),
            if (goalId != null) ...[
              const SizedBox(height: 16),
              Text('Goal ID: $goalId'),
            ],
          ],
        ),
      ),
    );
  }
}

// Party screens
class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key});
  
  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final userPartiesAsync = ref.watch(partiesProvider);
    
    return userPartiesAsync.when(
      data: (parties) {
        if (parties.isEmpty) {
          return _buildEmptyState(context);
        }
        
        // If user has parties and we haven't navigated yet, navigate to the first one
        if (!_hasNavigated) {
          _hasNavigated = true;
          // Using addPostFrameCallback to avoid building during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/party/${parties.first.id}');
            }
          });
        }
        
        // Return empty container while navigating
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error loading parties: $error'),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parties'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.group,
                size: 96,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                'No parties yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create or join a party to start building accountability with friends and track your goals together.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/party/create'),
                      icon: const Icon(Icons.group_add),
                      label: const Text('Create Party'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/party/join'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Join Party'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/party/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// CreatePartyScreen placeholder removed - using real CreatePartyPage implementation

// JoinPartyScreen placeholder removed - using real JoinPartyPage implementation

// InviteToPartyScreen placeholder removed - using real InviteToPartyPage implementation

class PartyMembersScreen extends ConsumerWidget {
  const PartyMembersScreen({this.partyId, super.key});
  final String? partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (partyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Party Members')),
        body: const Center(
          child: Text('No party selected'),
        ),
      );
    }

    final partyAsync = ref.watch(partyProvider(partyId!));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Party Members')),
      body: partyAsync.when(
        data: (party) {
          if (party == null) {
            return const Center(child: Text('Party not found'));
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '${party.memberCount} Members',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...party.memberIds.map((memberId) {
                        final isOwner = party.isOwner(memberId);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isOwner 
                              ? Theme.of(context).primaryColor 
                              : Theme.of(context).primaryColor.withOpacity(0.3),
                            child: Text(
                              memberId.substring(0, 2).toUpperCase(),
                              style: TextStyle(
                                color: isOwner ? Colors.white : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          title: Text('User: ${memberId.substring(0, 8)}...'),
                          subtitle: isOwner ? const Text('Party Leader') : null,
                          trailing: isOwner 
                            ? Icon(Icons.star, color: Theme.of(context).primaryColor)
                            : null,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading members: $error'),
        ),
      ),
    );
  }
}

class ProofApprovalsScreen extends StatelessWidget {
  const ProofApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proof Approvals')),
      body: const Center(child: Text('Proof Approvals Screen - Coming Soon')),
    );
  }
}

// Profile screens
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    final newDisplayName = _displayNameController.text.trim();
    if (newDisplayName.isEmpty) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.updateProfile(displayName: newDisplayName);
      
      if (mounted) {
        result.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Display name updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _displayNameController.clear();
          },
          onFailure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update display name: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: user?.photoUrl != null 
                              ? ClipOval(
                                  child: Image.network(
                                    user!.photoUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  user?.displayName?.substring(0, 1).toUpperCase() ?? 
                                  user?.email.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'No display name set',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'No email',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Display Name Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Name',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your display name is shown to other users in parties and challenges.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'New display name',
                        hintText: user?.displayName ?? 'Enter your display name',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isUpdating
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateDisplayName,
                        child: _isUpdating
                            ? const Text('Updating...')
                            : const Text('Update Display Name'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Account Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Email',
                      user?.email ?? 'Not available',
                      Icons.email,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Email Verified',
                      user?.isEmailVerified == true ? 'Yes' : 'No',
                      user?.isEmailVerified == true ? Icons.verified : Icons.warning,
                      valueColor: user?.isEmailVerified == true ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Member Since',
                      user?.createdAt != null 
                          ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                          : 'Not available',
                      Icons.calendar_today,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(child: Text('Edit Profile Screen - Coming Soon')),
    );
  }
}

// Settings screens
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
            subtitle: const Text('Sign out of your account'),
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await ref.read(authControllerProvider.notifier).signOut();
                // Navigation will be handled by auth state changes
              }
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            subtitle: Text('Coming soon'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy'),
            subtitle: Text('Coming soon'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('Coming soon'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: const Center(child: Text('Notification Settings Screen - Coming Soon')),
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: const Center(child: Text('Privacy Settings Screen - Coming Soon')),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About Screen - Coming Soon')),
    );
  }
}

class _ActiveChallengeDisplay extends ConsumerWidget {
  const _ActiveChallengeDisplay({required this.parties});
  
  final List<Party> parties;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    for (final party in parties) {
      final currentChallengeAsync = ref.watch(currentChallengeProvider(party.id));
      
      final challenge = currentChallengeAsync.valueOrNull;
      if (challenge != null) {
        return _buildChallengeCard(context, challenge, party);
      }
    }
    
    // No challenges found in any party
    return _buildNoChallengeCard(context);
  }
  
  Widget _buildChallengeCard(BuildContext context, Challenge challenge, Party party) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  party.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Party: ${party.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getChallengeStatusColor(challenge.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  challenge.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getChallengeStatusColor(challenge.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatChallengeDate(challenge.startDate)} - ${_formatChallengeDate(challenge.endDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (challenge.status == ChallengeStatus.pending) ...[
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Waiting for members to commit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutesExtension.partyDetail(party.id)),
              child: Text(challenge.status == ChallengeStatus.pending 
                  ? 'Set Your Goals' 
                  : 'View Challenge'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoChallengeCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No active challenge',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back soon or ask your party leader to start one!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getChallengeStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.pending:
        return Colors.orange;
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.settling:
        return Colors.blue;
      case ChallengeStatus.completed:
        return Colors.purple;
      case ChallengeStatus.cancelled:
        return Colors.red;
      case ChallengeStatus.summary:
        return Colors.indigo;
    }
  }
  
  String _formatChallengeDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
