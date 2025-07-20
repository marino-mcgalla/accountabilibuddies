# AccountabiliBuddies Project State Documentation
Last Updated: 2025-01-19

## Overview
This document maintains the current state of the AccountabiliBuddies Flutter rebuild, tracking implemented features, architecture decisions, and key code locations. This serves as a quick reference to avoid repeated codebase searches.

## Project Structure

```
lib/
├── core/                           # Shared utilities and core services
│   ├── constants/                  # App constants
│   ├── di/                        # Dependency injection
│   │   └── service_locator.dart   # GetIt service locator setup
│   ├── error/                     # Error handling
│   │   ├── failures.dart          # Failure types (NetworkFailure, AuthFailure, etc.)
│   │   ├── result.dart            # Result<T> pattern for error handling
│   │   └── error_handler.dart     # Global error handler
│   ├── logging/
│   │   └── logger_service.dart    # Logger service with debug/info/error levels
│   ├── navigation/
│   │   ├── app_router.dart        # GoRouter configuration
│   │   ├── app_routes.dart        # Route definitions
│   │   └── placeholder_screens.dart # Dashboard, Party screen, etc.
│   ├── services/
│   │   └── notification_service.dart # In-app notification service
│   ├── theme/
│   │   └── app_theme.dart         # Material Design 3 theme
│   └── core.dart                  # Core module exports
├── features/                      # Feature modules (clean architecture)
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── firebase_auth_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── register_page.dart
│   │       └── providers/
│   │           └── auth_provider.dart # AuthNotifier with user state
│   ├── challenges/                # NEW: Challenge/wagering system
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── challenge_model.dart
│   │   │   │   └── challenge_commitment_model.dart
│   │   │   └── repositories/
│   │   │       └── firebase_challenge_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── challenge.dart # Challenge entity with lifecycle
│   │   │   │   └── challenge_commitment.dart # Member commitments
│   │   │   ├── repositories/
│   │   │   │   └── challenge_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_challenge_usecase.dart
│   │   │       ├── commit_to_challenge_usecase.dart
│   │   │       ├── opt_out_of_challenge_usecase.dart
│   │   │       ├── start_challenge_usecase.dart
│   │   │       ├── get_party_challenges_usecase.dart
│   │   │       └── get_current_challenge_usecase.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── challenge_commitment_page.dart
│   │       │   └── challenge_management_page.dart
│   │       └── widgets/
│   │           ├── goal_selection_widget.dart
│   │           └── wager_setting_widget.dart
│   ├── goals/
│   │   ├── data/
│   │   │   └── models/
│   │   │       ├── goal_model.dart
│   │   │       ├── goal_instance_model.dart
│   │   │       └── goal_template_model.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── goal.dart
│   │   │   │   ├── goal_instance.dart
│   │   │   │   └── goal_template.dart # Templates with categories & stats
│   │   │   └── repositories/
│   │   │       ├── goal_repository.dart
│   │   │       └── goal_template_repository.dart
│   │   └── presentation/
│   │       └── providers/
│   │           ├── goal_providers.dart
│   │           └── goal_template_providers.dart
│   └── parties/
│       ├── data/
│       │   ├── models/
│       │   │   ├── party_model.dart
│       │   │   └── party_invite_model.dart
│       │   └── repositories/
│       │       └── firebase_party_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── party.dart # Has ownerId (leader), memberIds, canStartChallenges
│       │   │   └── party_invite.dart
│       │   └── repositories/
│       │       └── party_repository.dart
│       └── presentation/
│           └── providers/
│               └── party_providers.dart
└── main.dart

test/
├── unit/
├── widget/
└── integration/
```

## Key Entities & Their Relationships

### User (Authentication)
- **Location**: `lib/features/auth/domain/entities/user.dart`
- **Fields**: id, email, displayName, photoUrl, emailVerified, metadata
- **Metadata includes**: onboarded (bool) - tracks if user completed onboarding

### Party
- **Location**: `lib/features/parties/domain/entities/party.dart`
- **Fields**: id, name, description, ownerId (leader), memberIds[], inviteCode, status
- **Key Methods**:
  - `isLeader(userId)` - Check if user is party leader
  - `canStartChallenges` - Returns true if party has 2+ members
- **Notes**: Only party leader can create challenges

### PartyInvite
- **Location**: `lib/features/parties/domain/entities/party_invite.dart`
- **Fields**: id, partyId, partyName, inviterUserId, inviteeEmail, status, expiresAt
- **States**: pending, accepted, declined, expired
- **Notes**: Invites are email-based, expire after 7 days

### GoalTemplate
- **Location**: `lib/features/goals/domain/entities/goal_template.dart`
- **Fields**: id, userId, title, description, category, goalType, plannedFrequency
- **Categories**: health, fitness, learning, habits, career, personal, other
- **Types**: daily (max 1/day), total (multiple/day allowed)
- **Stats**: Tracks totalInstances, totalCompletions, averageCompletionRate

### Challenge (NEW)
- **Location**: `lib/features/challenges/domain/entities/challenge.dart`
- **Fields**: id, partyId, name, description, startDate, endDate, status, createdBy
- **Statuses**: 
  - `pending` - Accepting commitments
  - `active` - Challenge running
  - `settling` - Calculating results
  - `completed` - Finalized
  - `cancelled` - Stopped
- **Key Methods**:
  - `isAcceptingCommitments` - Check if can still commit
  - `hasEnded` - Check if challenge is over
  - `timeProgress` - Get progress percentage (0.0-1.0)

### ChallengeCommitment (NEW)
- **Location**: `lib/features/challenges/domain/entities/challenge_commitment.dart`
- **Fields**: id, challengeId, userId, goalConfigs[], wagerAmount, status
- **Statuses**: pending, committed, optedOut
- **GoalCommitment**: goalId, goalName, weeklyFrequency, parameters

## Key Features & Implementation Status

### ✅ Completed Features

1. **Authentication System**
   - Firebase Auth integration
   - Login/Register pages
   - Auth state management with Riverpod
   - Onboarding status tracking

2. **Party Management**
   - Create/join parties
   - Email-based invite system
   - Party member management
   - Leader permissions

3. **Party Invites**
   - Send invites by email
   - Accept/decline invites
   - Real-time invite notifications
   - Invite expiration (7 days)

4. **Challenge System** (NEW)
   - Challenge creation by party leaders
   - Challenge lifecycle management
   - Member commitment flow
   - Individual wager amounts
   - Goal selection with frequencies
   - Opt-out functionality
   - Rich management UI

5. **Notification System**
   - In-app notification service
   - Challenge-related notifications
   - Extensible for push notifications

### 🚧 In Progress Features

1. **Goals Feature**
   - Goal templates created
   - Need: Goal creation UI
   - Need: Goal instance management
   - Need: Progress tracking

2. **Proofs Feature**
   - Not started
   - Need: Camera integration
   - Need: Photo upload
   - Need: Proof approval flow

3. **Dashboard**
   - Basic placeholder exists
   - Need: Real dashboard with stats
   - Need: Challenge progress display
   - Need: Weekly overview

### 📋 Not Started Features

1. **Real-time Sync**
2. **Offline Support**
3. **Payment Integration**
4. **Analytics**
5. **Settings/Profile Management**

## Current State Notes

### Navigation Structure
- Using GoRouter for navigation
- Main routes: `/`, `/login`, `/register`, `/parties`, `/party/:id`
- Bottom navigation: Dashboard, Challenges, Party, Profile

### State Management
- Using Riverpod with code generation
- Auth state in `AuthNotifier` (StateNotifier)
- Party state uses streams for real-time updates
- Providers use `@riverpod` annotation

### Firebase Structure
- **Collections**:
  - `users` - User profiles
  - `parties` - Party data
  - `partyInvites` - Party invitations
  - `challenges` - Challenge data
  - `challengeCommitments` - Member commitments
  - `goalTemplates` - User goal templates (planned)
  - `proofs` - Proof submissions (planned)

### Recent Changes (from debugging session)
1. Fixed Firebase composite index issue for party invites
2. Made onboarding status persistent in user metadata
3. Added party notifications to Dashboard
4. Removed all debug logging statements
5. Implemented complete challenge/wagering system

### Known Issues & TODOs
1. Goal templates need actual provider implementation (currently mocked)
2. Challenge pages need navigation routing setup
3. Use cases have mocked API calls - need actual implementation
4. No unit tests for challenge features yet
5. Dashboard needs real implementation (currently placeholder)

## Code Patterns & Conventions

### Error Handling
- Use `Result<T>` pattern for all operations that can fail
- Custom `Failure` types for different error scenarios
- Always handle both success and failure cases

### Repository Pattern
```dart
// Domain layer - interface
abstract class SomeRepository {
  Future<Result<Entity>> getSomething(String id);
}

// Data layer - implementation
class FirebaseSomeRepository implements SomeRepository {
  @override
  Future<Result<Entity>> getSomething(String id) async {
    try {
      // Implementation
      return Result.success(entity);
    } catch (e, stackTrace) {
      return Result.failure(_mapException(e, stackTrace));
    }
  }
}
```

### Use Case Pattern
```dart
class SomeUseCase {
  final Repository _repository;
  
  SomeUseCase(this._repository);
  
  Future<Result<Output>> call(Input params) async {
    // Validation
    // Business logic
    // Return result
  }
}
```

### Widget Structure
- Prefer `ConsumerWidget` or `ConsumerStatefulWidget` for Riverpod
- Use `const` constructors whenever possible
- Extract reusable widgets to separate files
- Keep build methods small and readable

## Development Commands

```bash
# Run the app
flutter run

# Generate code (Riverpod, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Check for issues
flutter analyze

# Format code
dart format lib test
```

## Next Implementation Priorities

1. **Wire up challenge UI to navigation**
   - Add routes for challenge pages
   - Add challenge creation button for party leaders
   - Show current challenge on party page

2. **Implement goal template providers**
   - Replace mocked goal templates with real data
   - Create goal template management UI

3. **Connect challenge use cases to providers**
   - Create challenge providers
   - Wire up actual API calls
   - Add loading states

4. **Create proof submission flow**
   - Camera integration
   - Photo upload to Firebase Storage
   - Proof approval UI

5. **Build real dashboard**
   - Current challenge overview
   - Weekly progress tracking
   - Party activity feed

---

## Recent Updates (2025-01-19)

### Challenge UI Navigation Added
- Created `PartyDetailPage` with "Start Challenge" button for party leaders
- Created `CreateChallengePage` for challenge creation flow  
- Added navigation routes: `/party/:partyId` and challenge creation
- Made party cards clickable to navigate to detail page
- Connected challenge creation to party leader permissions

### Files Added/Modified
- `lib/features/parties/presentation/pages/party_detail_page.dart` (NEW)
- `lib/features/challenges/presentation/pages/create_challenge_page.dart` (NEW)
- Updated `app_router.dart` and `app_routes.dart` for navigation
- Updated `placeholder_screens.dart` to make party cards clickable

### How to Start a Challenge
1. Go to Party screen
2. Tap on a party card (if you're the leader)
3. Click "Start New Challenge" button
4. Fill out challenge details (name, dates, commitment deadline)
5. Challenge is created and members can commit

---

This document should be updated whenever significant changes are made to the codebase structure, new features are added, or architectural decisions are made.