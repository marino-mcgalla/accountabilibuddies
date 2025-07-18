# Technical Architecture Plan
# AccountabiliBuddies Flutter Rebuild

## 1. System Architecture Overview

### 1.1 High-Level Architecture
AccountabiliBuddies follows a **Clean Architecture** pattern with clear separation between presentation, domain, and data layers. The app is designed with **offline-first** capabilities and **real-time synchronization** as core requirements.

```
┌─────────────────────────────────────────────────────────┐
│                 Presentation Layer                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │   Widgets   │ │  Providers  │ │    Pages    │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────┐
│                   Domain Layer                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │  Entities   │ │  Use Cases  │ │ Repositories│       │
│  │             │ │             │ │ (Interfaces)│       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │ Repositories│ │ Data Sources│ │    Models   │       │
│  │   (Impl)    │ │Local/Remote │ │    (DTOs)   │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Core Architectural Principles
- **Feature-Based Organization**: Code organized by business features
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Single Responsibility**: Each class has one reason to change
- **Offline-First**: Local storage as primary source, sync when online
- **Real-time Sync**: Immediate propagation of changes across all clients
- **Testability**: Every component can be tested in isolation

### 1.3 Technology Stack
- **Frontend**: Flutter with Dart
- **State Management**: Riverpod with code generation
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Local Storage**: Hive for structured data, Flutter Secure Storage for sensitive data
- **Networking**: Dio for HTTP requests
- **Navigation**: GoRouter for declarative routing
- **Image Handling**: image_picker, cached_network_image
- **Testing**: mockito, integration_test

## 2. Component Breakdown

### 2.1 Feature Components

#### Authentication Feature
```
features/authentication/
├── data/
│   ├── datasources/
│   │   ├── auth_local_datasource.dart      # Local auth state
│   │   └── auth_remote_datasource.dart     # Firebase Auth
│   ├── models/
│   │   ├── user_model.dart                 # User DTO
│   │   └── auth_result_model.dart          # Auth result DTO
│   └── repositories/
│       └── auth_repository_impl.dart       # Auth repository implementation
├── domain/
│   ├── entities/
│   │   ├── user.dart                       # User entity
│   │   └── auth_result.dart                # Auth result entity
│   ├── repositories/
│   │   └── auth_repository.dart            # Auth repository interface
│   └── usecases/
│       ├── login_user.dart                 # Login use case
│       ├── register_user.dart              # Registration use case
│       ├── logout_user.dart                # Logout use case
│       └── get_current_user.dart           # Get current user use case
└── presentation/
    ├── providers/
    │   ├── auth_provider.dart              # Auth state management
    │   └── login_form_provider.dart        # Login form state
    ├── pages/
    │   ├── login_page.dart                 # Login screen
    │   ├── register_page.dart              # Registration screen
    │   └── auth_gate.dart                  # Auth routing
    └── widgets/
        ├── login_form.dart                 # Login form widget
        ├── register_form.dart              # Registration form widget
        └── auth_loading.dart               # Auth loading indicator
```

#### Goals Feature
```
features/goals/
├── data/
│   ├── datasources/
│   │   ├── goals_local_datasource.dart     # Hive storage
│   │   └── goals_remote_datasource.dart    # Firestore
│   ├── models/
│   │   ├── goal_model.dart                 # Goal DTO
│   │   ├── goal_template_model.dart        # Template DTO
│   │   └── goal_progress_model.dart        # Progress DTO
│   └── repositories/
│       └── goals_repository_impl.dart      # Goals repository implementation
├── domain/
│   ├── entities/
│   │   ├── goal.dart                       # Goal entity
│   │   ├── goal_template.dart              # Template entity
│   │   ├── goal_progress.dart              # Progress entity
│   │   └── goal_type.dart                  # Goal type enum
│   ├── repositories/
│   │   └── goals_repository.dart           # Goals repository interface
│   └── usecases/
│       ├── create_goal.dart                # Create goal use case
│       ├── update_goal.dart                # Update goal use case
│       ├── delete_goal.dart                # Delete goal use case
│       ├── get_user_goals.dart             # Get user goals use case
│       ├── create_goal_template.dart       # Create template use case
│       └── calculate_progress.dart         # Calculate progress use case
└── presentation/
    ├── providers/
    │   ├── goals_provider.dart             # Goals state management
    │   ├── goal_templates_provider.dart    # Templates state management
    │   └── goal_form_provider.dart         # Goal form state
    ├── pages/
    │   ├── goals_list_page.dart            # Goals list screen
    │   ├── goal_detail_page.dart           # Goal detail screen
    │   ├── create_goal_page.dart           # Create goal screen
    │   └── goal_templates_page.dart        # Templates screen
    └── widgets/
        ├── goal_card.dart                  # Goal card widget
        ├── goal_progress_bar.dart          # Progress bar widget
        ├── goal_form.dart                  # Goal form widget
        └── template_selector.dart          # Template selector widget
```

#### Proofs Feature
```
features/proofs/
├── data/
│   ├── datasources/
│   │   ├── proofs_local_datasource.dart    # Local proof storage
│   │   ├── proofs_remote_datasource.dart   # Firestore
│   │   └── image_storage_datasource.dart   # Firebase Storage
│   ├── models/
│   │   ├── proof_model.dart                # Proof DTO
│   │   └── proof_submission_model.dart     # Submission DTO
│   └── repositories/
│       ├── proofs_repository_impl.dart     # Proofs repository implementation
│       └── image_storage_repository_impl.dart # Image storage implementation
├── domain/
│   ├── entities/
│   │   ├── proof.dart                      # Proof entity
│   │   ├── proof_status.dart               # Proof status enum
│   │   └── proof_submission.dart           # Submission entity
│   ├── repositories/
│   │   ├── proofs_repository.dart          # Proofs repository interface
│   │   └── image_storage_repository.dart   # Image storage interface
│   └── usecases/
│       ├── submit_proof.dart               # Submit proof use case
│       ├── approve_proof.dart              # Approve proof use case
│       ├── deny_proof.dart                 # Deny proof use case
│       ├── get_pending_proofs.dart         # Get pending proofs use case
│       └── upload_proof_image.dart         # Upload image use case
└── presentation/
    ├── providers/
    │   ├── proofs_provider.dart            # Proofs state management
    │   ├── camera_provider.dart            # Camera state management
    │   └── proof_submission_provider.dart  # Submission state
    ├── pages/
    │   ├── camera_page.dart                # Camera screen
    │   ├── proof_submission_page.dart      # Proof submission screen
    │   ├── proof_review_page.dart          # Proof review screen
    │   └── proof_history_page.dart         # Proof history screen
    └── widgets/
        ├── camera_widget.dart              # Camera widget
        ├── proof_card.dart                 # Proof card widget
        ├── proof_submission_form.dart      # Submission form widget
        ├── proof_approval_widget.dart      # Approval widget
        └── story_viewer.dart               # Story-style viewer widget
```

#### Parties Feature
```
features/parties/
├── data/
│   ├── datasources/
│   │   ├── parties_local_datasource.dart   # Local party data
│   │   └── parties_remote_datasource.dart  # Firestore
│   ├── models/
│   │   ├── party_model.dart                # Party DTO
│   │   ├── party_member_model.dart         # Member DTO
│   │   └── party_invitation_model.dart     # Invitation DTO
│   └── repositories/
│       └── parties_repository_impl.dart    # Parties repository implementation
├── domain/
│   ├── entities/
│   │   ├── party.dart                      # Party entity
│   │   ├── party_member.dart               # Member entity
│   │   ├── party_invitation.dart           # Invitation entity
│   │   └── party_role.dart                 # Role enum
│   ├── repositories/
│   │   └── parties_repository.dart         # Parties repository interface
│   └── usecases/
│       ├── create_party.dart               # Create party use case
│       ├── join_party.dart                 # Join party use case
│       ├── leave_party.dart                # Leave party use case
│       ├── invite_member.dart              # Invite member use case
│       ├── get_user_parties.dart           # Get user parties use case
│       └── manage_party_members.dart       # Manage members use case
└── presentation/
    ├── providers/
    │   ├── parties_provider.dart           # Parties state management
    │   ├── party_members_provider.dart     # Members state management
    │   └── party_invitations_provider.dart # Invitations state
    ├── pages/
    │   ├── parties_list_page.dart          # Parties list screen
    │   ├── party_detail_page.dart          # Party detail screen
    │   ├── create_party_page.dart          # Create party screen
    │   └── join_party_page.dart            # Join party screen
    └── widgets/
        ├── party_card.dart                 # Party card widget
        ├── party_member_list.dart          # Members list widget
        ├── party_invitation_card.dart      # Invitation card widget
        └── party_settings.dart             # Party settings widget
```

#### Weekly Cycles Feature
```
features/weekly_cycles/
├── data/
│   ├── datasources/
│   │   ├── weekly_local_datasource.dart    # Local weekly data
│   │   └── weekly_remote_datasource.dart   # Firestore
│   ├── models/
│   │   ├── weekly_challenge_model.dart     # Weekly cycle DTO
│   │   ├── weekly_participant_model.dart   # Participant DTO
│   │   └── weekly_goal_config_model.dart   # Goal config DTO
│   └── repositories/
│       └── weekly_repository_impl.dart     # Weekly repository implementation
├── domain/
│   ├── entities/
│   │   ├── weekly_challenge.dart           # Weekly cycle entity
│   │   ├── weekly_participant.dart         # Participant entity
│   │   ├── weekly_status.dart              # Status enum
│   │   └── wager.dart                      # Wager entity
│   ├── repositories/
│   │   └── weekly_repository.dart          # Weekly repository interface
│   └── usecases/
│       ├── start_new_week.dart             # Start new week use case
│       ├── configure_week_goals.dart       # Configure goals for week
│       ├── lock_in_week.dart               # Lock in goals and wager
│       ├── complete_week.dart              # Complete week and calculate
│       ├── get_week_progress.dart          # Get current week progress
│       └── adjust_week_goals.dart          # Modify goals (before lock-in)
└── presentation/
    ├── providers/
    │   ├── weekly_cycle_provider.dart      # Weekly cycle state
    │   ├── week_config_provider.dart       # Goal configuration state
    │   └── week_progress_provider.dart     # Progress tracking state
    ├── pages/
    │   ├── week_setup_page.dart            # Sunday prep screen
    │   ├── goal_selection_page.dart        # Select goals for week
    │   ├── wager_setup_page.dart           # Set individual wager
    │   ├── week_progress_page.dart         # Current week dashboard
    │   └── week_history_page.dart          # Past weeks history
    └── widgets/
        ├── goal_frequency_selector.dart    # Set frequency for goal
        ├── week_progress_grid.dart         # 7-day visual grid
        ├── total_progress_bar.dart         # Percentage progress bar
        ├── wager_input.dart                # Wager amount input
        └── week_summary_card.dart          # Week completion summary
```

### 2.2 Shared Components

#### Core Services
```
core/
├── constants/
│   ├── app_constants.dart                  # App-wide constants
│   ├── api_constants.dart                  # API endpoints
│   └── storage_constants.dart              # Storage keys
├── errors/
│   ├── exceptions.dart                     # Custom exceptions
│   ├── failures.dart                       # Failure classes
│   └── error_handler.dart                  # Global error handling
├── services/
│   ├── logger_service.dart                 # Logging service
│   ├── analytics_service.dart              # Analytics service
│   ├── connectivity_service.dart           # Network connectivity
│   ├── notification_service.dart           # Flexible notification system
│   ├── sync_service.dart                   # Data synchronization
│   └── goal_parameter_service.dart         # Parameter validation and formatting
└── utils/
    ├── date_utils.dart                     # Date/time utilities
    ├── validation_utils.dart               # Input validation
    ├── image_utils.dart                    # Image processing
    ├── crypto_utils.dart                   # Cryptography utilities
    └── formatting_utils.dart               # Text formatting
```

#### Shared Widgets
```
shared/
├── widgets/
│   ├── common/
│   │   ├── app_button.dart                 # Standardized button
│   │   ├── app_text_field.dart             # Standardized text field
│   │   ├── app_loading.dart                # Loading indicators
│   │   ├── app_error.dart                  # Error display widget
│   │   └── app_empty_state.dart            # Empty state widget
│   ├── navigation/
│   │   ├── app_bottom_nav.dart             # Bottom navigation
│   │   ├── app_drawer.dart                 # Navigation drawer
│   │   └── app_tab_bar.dart                # Tab bar widget
│   └── feedback/
│       ├── success_dialog.dart             # Success feedback
│       ├── error_dialog.dart               # Error feedback
│       ├── confirmation_dialog.dart        # Confirmation dialog
│       └── snackbar_utils.dart             # Snackbar utilities
├── theme/
│   ├── app_theme.dart                      # Theme configuration
│   ├── app_colors.dart                     # Color palette
│   ├── app_text_styles.dart                # Text styles
│   └── app_dimensions.dart                 # Spacing and sizing
└── navigation/
    ├── app_router.dart                     # Route configuration
    ├── route_names.dart                    # Route constants
    └── navigation_service.dart             # Navigation utilities
```

#### Notification System Architecture
```
core/services/notification/
├── notification_service.dart               # Main notification service interface
├── notification_types.dart                 # Event type definitions
├── notification_preferences.dart           # User preference models
├── providers/
│   ├── immediate_provider.dart             # Real-time notifications
│   ├── batched_provider.dart               # Batched/scheduled notifications
│   └── silent_provider.dart                # No notifications (tracking only)
├── templates/
│   ├── proof_notification_template.dart    # Proof submission/approval templates
│   ├── week_notification_template.dart     # Weekly cycle templates
│   └── party_notification_template.dart    # Party management templates
└── delivery/
    ├── push_notification_delivery.dart     # Firebase push notifications
    ├── in_app_notification_delivery.dart   # In-app notification banners
    └── email_notification_delivery.dart    # Email notifications (future)
```

#### Proof Approval Components
```
shared/widgets/proof_approval/
├── proof_context_card.dart                 # Shows goal requirements during approval
├── goal_parameters_display.dart            # Displays current week's goal parameters
├── approval_context_overlay.dart           # Overlay showing goal details
└── parameter_comparison_widget.dart        # Shows how requirements changed
```

## 3. Data Models

### 3.1 Core Entities

#### User Entity
```dart
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, email, displayName, profileImageUrl];
}
```

#### GoalTemplate Entity
```dart
class GoalTemplate extends Equatable {
  const GoalTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    required this.defaultFrequency,
    required this.category,
    required this.parameterDefinitions,
    required this.createdAt,
    required this.updatedAt,
    this.totalCompletions = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final GoalType type;
  final int defaultFrequency;
  final String category;
  final List<GoalParameterDefinition> parameterDefinitions; // Configurable parameters
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalCompletions; // All-time completions
  final int currentStreak;
  final int longestStreak;

  @override
  List<Object?> get props => [
    id, userId, name, description, type, defaultFrequency, category, parameterDefinitions
  ];
}

enum GoalType { daily, weekly, total }
```

#### Proof Entity
```dart
class Proof extends Equatable {
  const Proof({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.weekId,
    required this.goalConfig,
    required this.text,
    this.imageUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String goalId;
  final String userId;
  final String weekId; // Which week this proof belongs to
  final WeeklyGoalConfig goalConfig; // Goal requirements when submitted
  final String text;
  final String? imageUrl;
  final ProofStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  @override
  List<Object?> get props => [
    id, goalId, userId, weekId, goalConfig, text, imageUrl, status, submittedAt
  ];
}

enum ProofStatus { pending, approved, denied, disputed }
```

#### Party Entity
```dart
class Party extends Equatable {
  const Party({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String leaderId;
  final List<PartyMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final bool isActive;

  @override
  List<Object?> get props => [
    id, name, leaderId, members, createdAt, updatedAt, description, isActive
  ];
}
```

#### WeeklyChallenge Entity
```dart
class WeeklyChallenge extends Equatable {
  const WeeklyChallenge({
    required this.id,
    required this.partyId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.status,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String partyId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final WeeklyChallengeStatus status;
  final List<WeeklyParticipant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id, partyId, weekStartDate, weekEndDate, status, participants
  ];
}

enum WeeklyChallengeStatus { preparation, active, completed }

class WeeklyParticipant extends Equatable {
  const WeeklyParticipant({
    required this.userId,
    required this.wagerAmount,
    required this.selectedGoals,
    required this.completionPercentage,
    required this.isLockedIn,
  });

  final String userId;
  final double wagerAmount;
  final List<WeeklyGoalConfig> selectedGoals;
  final double completionPercentage;
  final bool isLockedIn;

  @override
  List<Object> get props => [userId, wagerAmount, selectedGoals, completionPercentage, isLockedIn];
}

class WeeklyGoalConfig extends Equatable {
  const WeeklyGoalConfig({
    required this.goalId,
    required this.frequency,
    required this.plannedDays,
    required this.parameters,
  });

  final String goalId;
  final int frequency;
  final List<int> plannedDays; // For weekly goals: which days of week
  final Map<String, dynamic> parameters; // Flexible goal parameters (duration, distance, reps, etc.)

  @override
  List<Object> get props => [goalId, frequency, plannedDays, parameters];
}

// Goal parameter definitions for different goal types
class GoalParameterDefinition extends Equatable {
  const GoalParameterDefinition({
    required this.key,
    required this.label,
    required this.type,
    required this.unit,
    this.isRequired = true,
    this.defaultValue,
    this.minValue,
    this.maxValue,
  });

  final String key;
  final String label;
  final GoalParameterType type;
  final String unit;
  final bool isRequired;
  final dynamic defaultValue;
  final dynamic minValue;
  final dynamic maxValue;

  @override
  List<Object?> get props => [key, label, type, unit, isRequired, defaultValue, minValue, maxValue];
}

enum GoalParameterType { duration, distance, count, weight, percentage }
```

### 3.2 Value Objects

#### Goal Progress
```dart
class GoalProgress extends Equatable {
  const GoalProgress({
    required this.completedCount,
    required this.totalCount,
    required this.completionPercentage,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
  });

  final int completedCount;
  final int totalCount;
  final double completionPercentage;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  @override
  List<Object?> get props => [
    completedCount, totalCount, completionPercentage, 
    currentStreak, longestStreak, lastCompletedDate
  ];
}
```

#### Wager
```dart
class Wager extends Equatable {
  const Wager({
    required this.userId,
    required this.amount,
    required this.currency,
    required this.isConfirmed,
  });

  final String userId;
  final double amount;
  final String currency;
  final bool isConfirmed;

  @override
  List<Object> get props => [userId, amount, currency, isConfirmed];
}
```

## 4. State Management Approach

### 4.1 Riverpod Architecture

#### Provider Types and Usage
```dart
// Repository providers (singleton)
@riverpod
GoalsRepository goalsRepository(GoalsRepositoryRef ref) {
  return GoalsRepositoryImpl(
    localDataSource: ref.read(goalsLocalDataSourceProvider),
    remoteDataSource: ref.read(goalsRemoteDataSourceProvider),
  );
}

// Use case providers
@riverpod
CreateGoal createGoal(CreateGoalRef ref) {
  return CreateGoal(ref.read(goalsRepositoryProvider));
}

// State providers for weekly cycle management
@riverpod
class WeeklyGoalsNotifier extends _$WeeklyGoalsNotifier {
  @override
  AsyncValue<WeeklyGoalState> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadCurrentWeek() async {
    state = const AsyncValue.loading();
    
    final templates = await ref.read(goalTemplatesProvider);
    final currentWeek = await ref.read(currentWeekProvider);
    
    state = AsyncValue.data(WeeklyGoalState(
      templates: templates,
      weekConfig: currentWeek,
      selectedGoals: {},
    ));
  }

  void selectGoalForWeek(String templateId, int frequency, List<int> plannedDays) {
    state.whenData((current) {
      final updated = current.copyWith(
        selectedGoals: {
          ...current.selectedGoals,
          templateId: WeeklyGoalConfig(
            goalId: templateId,
            frequency: frequency,
            plannedDays: plannedDays,
          ),
        },
      );
      state = AsyncValue.data(updated);
    });
  }

  Future<void> lockInWeek(double wagerAmount) async {
    // Lock in selected goals with wager for the week
    final result = await ref.read(weeklyRepositoryProvider)
      .lockInWeek(state.value!.selectedGoals, wagerAmount);
      
    result.when(
      success: (_) => ref.read(routerProvider).go('/dashboard'),
      failure: (error) => ref.read(notificationServiceProvider).showError(error.toString()),
    );
  }
}

// Stream providers for real-time data
@riverpod
Stream<List<Proof>> pendingProofs(PendingProofsRef ref, String partyId) {
  return ref.read(proofsRepositoryProvider).watchPendingProofs(partyId);
}
```

#### State Management Patterns
- **AsyncValue**: For handling loading, data, and error states
- **Family Providers**: For parameterized providers (e.g., party-specific data)
- **AutoDispose**: For providers that should dispose when no longer used
- **KeepAlive**: For providers that should persist across widget rebuilds

### 4.2 Offline State Synchronization

#### Offline Queue Management
```dart
@riverpod
class OfflineSyncNotifier extends _$OfflineSyncNotifier {
  @override
  OfflineSyncState build() {
    return const OfflineSyncState(
      pendingActions: [],
      isOnline: true,
      lastSyncTime: null,
    );
  }

  void addPendingAction(OfflineAction action) {
    final currentState = state;
    state = currentState.copyWith(
      pendingActions: [...currentState.pendingActions, action],
    );
  }

  Future<void> syncWhenOnline() async {
    if (!state.isOnline || state.pendingActions.isEmpty) return;

    for (final action in state.pendingActions) {
      try {
        await _executeAction(action);
        _removePendingAction(action);
      } catch (e) {
        // Log error and continue with next action
        ref.read(loggerServiceProvider).error('Sync failed for action: $action');
      }
    }

    state = state.copyWith(lastSyncTime: DateTime.now());
  }
}
```

## 5. API Integration Details

### 5.1 Firebase Integration

#### Firestore Collections Structure
```
users/
├── {userId}/
│   ├── profile                    # User profile data
│   ├── settings                   # User preferences including notifications
│   └── stats                      # User statistics

goalTemplates/
├── {userId}/
│   └── {templateId}               # Long-term goal definitions with parameter schemas

parties/
├── {partyId}/
│   ├── metadata                   # Party information
│   ├── members/                   # Party members
│   │   └── {userId}
│   └── weeks/                     # Weekly cycles
│       └── {weekId}/
│           ├── config             # Week configuration
│           └── participants/      # Member goals with parameters and wagers
│               └── {userId}/
│                   ├── goalConfigs        # Selected goals with custom parameters
│                   └── wager              # Individual wager amount

proofs/
├── {partyId}/
│   └── {weekId}/
│       └── {proofId}              # Proof submissions with goal context
│           ├── metadata           # Proof content and timestamps
│           ├── goalSnapshot       # Goal requirements when submitted
│           └── approvalContext    # Additional context for approvers

userSettings/
├── {userId}/
│   └── notifications              # Notification preferences
│       ├── enabledTypes: []       # Which events trigger notifications
│       ├── frequency: 'immediate' | 'hourly' | 'daily' | 'none'
│       └── quietHours: { start: '22:00', end: '08:00' }
```

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Goals are private to users
    match /goals/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Party members can access party data
    match /parties/{partyId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
    
    // Proofs are accessible to party members
    match /proofs/{partyId}/{document=**} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/parties/$(partyId)) &&
        request.auth.uid in get(/databases/$(database)/documents/parties/$(partyId)).data.members;
    }
  }
}
```

#### Real-time Listeners Setup
```dart
class GoalsRemoteDataSource {
  final FirebaseFirestore _firestore;

  Stream<List<GoalModel>> watchUserGoals(String userId) {
    return _firestore
        .collection('goals')
        .doc(userId)
        .collection('active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ProofModel>> watchPendingProofs(String partyId) {
    return _firestore
        .collection('proofs')
        .doc(partyId)
        .collection('pending')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProofModel.fromFirestore(doc))
            .toList());
  }
}
```

### 5.2 Local Storage Strategy

#### Hive Box Structure
```dart
// Box definitions for different data types
class StorageBoxes {
  static const String users = 'users';
  static const String goals = 'goals';
  static const String proofs = 'proofs';
  static const String parties = 'parties';
  static const String challenges = 'challenges';
  static const String settings = 'settings';
  static const String syncQueue = 'sync_queue';
}

// Local data source implementation
class GoalsLocalDataSource {
  late Box<GoalModel> _goalsBox;

  Future<void> initialize() async {
    _goalsBox = await Hive.openBox<GoalModel>(StorageBoxes.goals);
  }

  Future<List<GoalModel>> getAllGoals() async {
    return _goalsBox.values.toList();
  }

  Future<void> saveGoal(GoalModel goal) async {
    await _goalsBox.put(goal.id, goal);
  }

  Future<void> deleteGoal(String goalId) async {
    await _goalsBox.delete(goalId);
  }
}
```

#### Offline Sync Strategy
```dart
class SyncService {
  final ConnectivityService _connectivity;
  final List<LocalDataSource> _dataSources;

  Future<void> startSync() async {
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        _syncAllPendingChanges();
      }
    });

    // Periodic sync when online
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_connectivity.isConnected) {
        _syncAllPendingChanges();
      }
    });
  }

  Future<void> _syncAllPendingChanges() async {
    for (final dataSource in _dataSources) {
      try {
        await dataSource.syncWithRemote();
      } catch (e) {
        // Log error but continue with other data sources
        logger.error('Sync failed for ${dataSource.runtimeType}', error: e);
      }
    }
  }
}
```

## 6. Navigation Flow

### 6.1 Route Structure
```dart
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth routes
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
    ),
    
    // Main app routes (requires authentication)
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/goals',
          builder: (context, state) => const GoalsListPage(),
          routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CreateGoalPage(),
            ),
            GoRoute(
              path: '/:goalId',
              builder: (context, state) => GoalDetailPage(
                goalId: state.pathParameters['goalId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/parties',
          builder: (context, state) => const PartiesListPage(),
          routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CreatePartyPage(),
            ),
            GoRoute(
              path: '/:partyId',
              builder: (context, state) => PartyDetailPage(
                partyId: state.pathParameters['partyId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/camera',
          builder: (context, state) => const CameraPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
```

### 6.2 Navigation Patterns

#### Deep Linking Support
```dart
class DeepLinkHandler {
  static void handleInvitationLink(String inviteCode) {
    // Navigate to join party with invite code
    GoRouter.of(context).go('/parties/join?code=$inviteCode');
  }

  static void handleProofNotification(String proofId) {
    // Navigate to proof review
    GoRouter.of(context).go('/proofs/$proofId');
  }

  static void handleChallengeNotification(String challengeId) {
    // Navigate to challenge detail
    GoRouter.of(context).go('/challenges/$challengeId');
  }
}
```

#### Navigation Guards
```dart
class AuthGuard {
  static String? redirectLogic(BuildContext context, GoRouterState state) {
    final isAuthenticated = context.read(authProvider).value?.isAuthenticated ?? false;
    
    final isAuthRoute = state.location.startsWith('/auth');
    
    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }
    
    if (isAuthenticated && isAuthRoute) {
      return '/dashboard';
    }
    
    return null; // No redirect needed
  }
}
```

## 7. Error Handling Strategy

### 7.1 Error Classification
```dart
// Base error classes
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection failed']);
}

class AuthenticationException extends AppException {
  const AuthenticationException([super.message = 'Authentication failed']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class StorageException extends AppException {
  const StorageException([super.message = 'Local storage operation failed']);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied']);
}
```

### 7.2 Global Error Handling
```dart
class GlobalErrorHandler {
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      logger.error('Flutter Error', error: details.exception, stackTrace: details.stack);
      _reportError(details.exception, details.stack);
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.error('Async Error', error: error, stackTrace: stack);
      _reportError(error, stack);
      return true;
    };
  }

  static void _reportError(dynamic error, StackTrace? stackTrace) {
    // Report to analytics service
    // Show user-friendly error message
    // Log for debugging
  }
}
```

### 7.3 User-Facing Error Messages
```dart
class ErrorMessageProvider {
  static String getDisplayMessage(AppException exception) {
    return switch (exception) {
      NetworkException() => 'Please check your internet connection and try again.',
      AuthenticationException() => 'Please log in again to continue.',
      ValidationException() => exception.message,
      StorageException() => 'Unable to save data. Please try again.',
      PermissionException() => 'Permission is required to access this feature.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  static void showError(BuildContext context, AppException exception) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getDisplayMessage(exception)),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}
```

### 7.4 Retry Mechanisms
```dart
class RetryHandler {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempts++;
        
        final shouldAttemptRetry = shouldRetry?.call(error) ?? 
            (error is NetworkException && attempts < maxRetries);
            
        if (!shouldAttemptRetry) {
          rethrow;
        }
        
        if (attempts < maxRetries) {
          await Future.delayed(delay * attempts); // Exponential backoff
        }
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts');
  }
}
```

## 8. Proof Approval UX Design

### 8.1 Goal Parameter Examples

#### Common Goal Parameter Definitions
```dart
// Cardio goal template with duration parameter
final cardioTemplate = GoalTemplate(
  id: 'cardio_001',
  name: 'Daily Cardio',
  description: 'Get your heart pumping with cardio exercise',
  type: GoalType.daily,
  defaultFrequency: 3,
  category: 'fitness',
  parameterDefinitions: [
    GoalParameterDefinition(
      key: 'duration',
      label: 'Duration',
      type: GoalParameterType.duration,
      unit: 'minutes',
      defaultValue: 30,
      minValue: 10,
      maxValue: 120,
    ),
    GoalParameterDefinition(
      key: 'intensity',
      label: 'Intensity Level',
      type: GoalParameterType.percentage,
      unit: '%',
      defaultValue: 0.7, // 70%
      minValue: 0.5,
      maxValue: 1.0,
    ),
  ],
);

// Reading goal with page count
final readingTemplate = GoalTemplate(
  id: 'reading_001',
  name: 'Daily Reading',
  description: 'Read to expand your knowledge',
  type: GoalType.daily,
  defaultFrequency: 5,
  category: 'education',
  parameterDefinitions: [
    GoalParameterDefinition(
      key: 'pages',
      label: 'Pages',
      type: GoalParameterType.count,
      unit: 'pages',
      defaultValue: 20,
      minValue: 5,
      maxValue: 100,
    ),
  ],
);

// Weekly goal configuration example (Week 1: 30min x 3 times, Week 2: 45min x 4 times)
final week1Config = WeeklyGoalConfig(
  goalId: 'cardio_001',
  frequency: 3,
  plannedDays: [1, 3, 5], // Monday, Wednesday, Friday
  parameters: {
    'duration': 30,
    'intensity': 0.7,
  },
);

final week2Config = WeeklyGoalConfig(
  goalId: 'cardio_001',
  frequency: 4,
  plannedDays: [1, 2, 4, 6], // Monday, Tuesday, Thursday, Saturday
  parameters: {
    'duration': 45,
    'intensity': 0.6, // Lower intensity for longer duration
  },
);
```

### 8.2 Approval Context UI

#### Goal Requirements Display During Approval
```dart
class ProofApprovalScreen extends StatelessWidget {
  const ProofApprovalScreen({
    super.key,
    required this.proof,
  });

  final Proof proof;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen proof image
          Center(
            child: ProofImageViewer(imageUrl: proof.imageUrl),
          ),
          
          // Goal context overlay at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: GoalContextCard(
              goalName: proof.goalTemplate.name,
              submittedBy: proof.userName,
              submittedAt: proof.submittedAt,
              requirements: _buildRequirementsList(proof.goalConfig),
            ),
          ),
          
          // Approval actions at bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: ProofApprovalActions(
              onApprove: () => _approveProof(context),
              onDeny: () => _denyProof(context),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildRequirementsList(WeeklyGoalConfig config) {
    final requirements = <String>[];
    
    // Add frequency requirement
    requirements.add('${config.frequency} times this week');
    
    // Add parameter requirements
    if (config.parameters.containsKey('duration')) {
      final duration = config.parameters['duration'] as int;
      requirements.add('$duration minutes each time');
    }
    
    if (config.parameters.containsKey('intensity')) {
      final intensity = (config.parameters['intensity'] as double * 100).round();
      requirements.add('$intensity% intensity');
    }
    
    if (config.parameters.containsKey('pages')) {
      final pages = config.parameters['pages'] as int;
      requirements.add('$pages pages minimum');
    }
    
    return requirements;
  }
}

class GoalContextCard extends StatelessWidget {
  const GoalContextCard({
    super.key,
    required this.goalName,
    required this.submittedBy,
    required this.submittedAt,
    required this.requirements,
  });

  final String goalName;
  final String submittedBy;
  final DateTime submittedAt;
  final List<String> requirements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Goal name
          Text(
            goalName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Requirements
          Text(
            'Requirements:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...requirements.map((req) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 12),
          
          // Submission info
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.white60),
              const SizedBox(width: 6),
              Text(
                submittedBy,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                ),
              ),
              const Spacer(),
              Text(
                _formatTimeAgo(submittedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
```

### 8.3 Weekly Goal Configuration Interface

#### Dynamic Parameter Input Widget
```dart
class WeeklyGoalSetup extends StatefulWidget {
  const WeeklyGoalSetup({
    super.key,
    required this.goalTemplate,
    required this.previousConfig,
    required this.onConfigChanged,
  });

  final GoalTemplate goalTemplate;
  final WeeklyGoalConfig? previousConfig;
  final void Function(WeeklyGoalConfig) onConfigChanged;

  @override
  State<WeeklyGoalSetup> createState() => _WeeklyGoalSetupState();
}

class _WeeklyGoalSetupState extends State<WeeklyGoalSetup> {
  late int _frequency;
  late List<int> _selectedDays;
  late Map<String, dynamic> _parameters;

  @override
  void initState() {
    super.initState();
    
    // Initialize with previous week's config or defaults
    final prev = widget.previousConfig;
    _frequency = prev?.frequency ?? widget.goalTemplate.defaultFrequency;
    _selectedDays = prev?.plannedDays ?? [];
    _parameters = Map.from(prev?.parameters ?? {});
    
    // Set default parameter values if not present
    for (final paramDef in widget.goalTemplate.parameterDefinitions) {
      _parameters.putIfAbsent(paramDef.key, () => paramDef.defaultValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal name and description
            Text(
              widget.goalTemplate.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              widget.goalTemplate.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Frequency selector
            Text(
              'Frequency',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            FrequencySelector(
              value: _frequency,
              maxValue: 7,
              onChanged: (value) {
                setState(() {
                  _frequency = value;
                });
                _notifyConfigChanged();
              },
            ),
            const SizedBox(height: 16),
            
            // Day selector (for weekly goals)
            if (widget.goalTemplate.type == GoalType.daily) ...[
              Text(
                'Planned Days',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              WeekDaySelector(
                selectedDays: _selectedDays,
                maxSelection: _frequency,
                onChanged: (days) {
                  setState(() {
                    _selectedDays = days;
                  });
                  _notifyConfigChanged();
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Dynamic parameter inputs
            ...widget.goalTemplate.parameterDefinitions.map((paramDef) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildParameterInput(paramDef),
              );
            }),
            
            // Show changes from previous week
            if (widget.previousConfig != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              ParameterChangesDisplay(
                previous: widget.previousConfig!,
                current: WeeklyGoalConfig(
                  goalId: widget.goalTemplate.id,
                  frequency: _frequency,
                  plannedDays: _selectedDays,
                  parameters: _parameters,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParameterInput(GoalParameterDefinition paramDef) {
    return switch (paramDef.type) {
      GoalParameterType.duration => DurationParameterInput(
          definition: paramDef,
          value: _parameters[paramDef.key] as int,
          onChanged: (value) => _updateParameter(paramDef.key, value),
        ),
      GoalParameterType.count => CountParameterInput(
          definition: paramDef,
          value: _parameters[paramDef.key] as int,
          onChanged: (value) => _updateParameter(paramDef.key, value),
        ),
      GoalParameterType.distance => DistanceParameterInput(
          definition: paramDef,
          value: _parameters[paramDef.key] as double,
          onChanged: (value) => _updateParameter(paramDef.key, value),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  void _updateParameter(String key, dynamic value) {
    setState(() {
      _parameters[key] = value;
    });
    _notifyConfigChanged();
  }

  void _notifyConfigChanged() {
    widget.onConfigChanged(WeeklyGoalConfig(
      goalId: widget.goalTemplate.id,
      frequency: _frequency,
      plannedDays: _selectedDays,
      parameters: _parameters,
    ));
  }
}
```

### 8.4 Notification Service Integration

#### Flexible Notification System
```dart
// User can configure notification preferences
class NotificationPreferencesPage extends StatefulWidget {
  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  NotificationFrequency _frequency = NotificationFrequency.immediate;
  Set<NotificationType> _enabledTypes = NotificationType.values.toSet();
  QuietHours _quietHours = const QuietHours(
    start: TimeOfDay(hour: 22, minute: 0),
    end: TimeOfDay(hour: 8, minute: 0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification frequency
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Frequency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...NotificationFrequency.values.map((freq) {
                    return RadioListTile<NotificationFrequency>(
                      title: Text(_getFrequencyLabel(freq)),
                      subtitle: Text(_getFrequencyDescription(freq)),
                      value: freq,
                      groupValue: _frequency,
                      onChanged: (value) {
                        setState(() {
                          _frequency = value!;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notification types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Types',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...NotificationType.values.map((type) {
                    return SwitchListTile(
                      title: Text(_getTypeLabel(type)),
                      subtitle: Text(_getTypeDescription(type)),
                      value: _enabledTypes.contains(type),
                      onChanged: (enabled) {
                        setState(() {
                          if (enabled) {
                            _enabledTypes.add(type);
                          } else {
                            _enabledTypes.remove(type);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quiet hours
          if (_frequency != NotificationFrequency.none) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiet Hours',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notifications during these hours',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start'),
                            subtitle: Text(_formatTime(_quietHours.start)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectStartTime(),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('End'),
                            subtitle: Text(_formatTime(_quietHours.end)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectEndTime(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFrequencyLabel(NotificationFrequency freq) {
    return switch (freq) {
      NotificationFrequency.immediate => 'Immediate',
      NotificationFrequency.hourly => 'Hourly Summary',
      NotificationFrequency.daily => 'Daily Summary',
      NotificationFrequency.none => 'None',
    };
  }

  String _getFrequencyDescription(NotificationFrequency freq) {
    return switch (freq) {
      NotificationFrequency.immediate => 'Get notified as events happen',
      NotificationFrequency.hourly => 'Receive summaries every hour',
      NotificationFrequency.daily => 'One summary per day',
      NotificationFrequency.none => 'No notifications (activity still tracked)',
    };
  }
  
  String _getTypeLabel(NotificationType type) {
    return switch (type) {
      NotificationType.proofSubmitted => 'Proof Submissions',
      NotificationType.proofApproved => 'Proof Approvals',
      NotificationType.proofDenied => 'Proof Denials',
      NotificationType.weekStarted => 'Week Started',
      NotificationType.weekEnding => 'Week Ending Soon',
      NotificationType.partyInvitation => 'Party Invitations',
      NotificationType.memberJoined => 'New Members',
    };
  }
  
  String _getTypeDescription(NotificationType type) {
    return switch (type) {
      NotificationType.proofSubmitted => 'When party members submit proof',
      NotificationType.proofApproved => 'When your proofs are approved',
      NotificationType.proofDenied => 'When your proofs are denied',
      NotificationType.weekStarted => 'When a new week begins',
      NotificationType.weekEnding => 'Reminders before week ends',
      NotificationType.partyInvitation => 'When you\'re invited to parties',
      NotificationType.memberJoined => 'When someone joins your party',
    };
  }
}
```

---

*This technical architecture plan provides the foundation for rebuilding AccountabiliBuddies with clean, maintainable, and scalable code while ensuring offline-first functionality, real-time synchronization, and flexible goal parameter management with clear approval context.*