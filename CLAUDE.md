# AccountabiliBuddies App Architecture

## Overview
AccountabiliBuddies is a Flutter mobile app for group accountability and goal tracking. Users create or join parties, set weekly/total goals, submit proof of completion, and approve/deny each other's proofs. The app uses a wager-based commitment system to incentivize goal completion.

## Frontend Architecture (Flutter/Dart)

### Directory Structure
```
lib/
├── features/
│   ├── auth/                     # Authentication
│   ├── challenge/                # Challenge dashboard & widgets
│   ├── common/                   # Shared utilities & widgets
│   ├── goals/                    # Goal management
│   ├── party/                    # Party/group management
│   ├── proof_submission/         # Proof submission & streams
│   └── time_machine/             # Date/time utilities
├── main.dart                     # App entry point
└── utils/                        # Global utilities
```

### State Management Pattern
- **Provider Pattern**: Using `ChangeNotifier` with Provider package
- **Stream-based**: Real-time updates via Firestore streams
- **Separation of Concerns**: Actions, State, Streams, Repositories

### Key Providers
1. **GoalsProvider** (`lib/features/goals/providers/goals_provider.dart`)
   - Manages user's personal goals
   - CRUD operations for goals
   - Real-time goal updates via streams

2. **PartyProvider** (`lib/features/party/providers/party_provider.dart`)
   - Manages party/group functionality
   - Challenge lifecycle (start, lock-in, cancel)
   - Member management and permissions
   - Proof approval/denial

### Data Models

#### Goal Model (Dual Format - Legacy & New)
**Legacy Format** (`goal_model.dart`):
```dart
class Goal {
  String id, ownerId, goalName, goalType, goalCriteria;
  int goalFrequency;
  bool active;
  Map<String, String> currentWeekCompletions; // "date" -> "completed"/"pending"/"denied"
  Map<String, dynamic>? challenge; // Raw challenge data
}
```

**New Format** (`goal_model_new.dart`):
```dart
abstract class Goal {
  ChallengeData? challengeData;
}

class ChallengeData {
  Map<String, String> completions;    // date -> status
  List<Proof> proofs;                 // For total goals
  Map<String, Proof> dailyProofs;     // For weekly goals
}
```

#### Party Model
```dart
class PartyState {
  String? partyId, partyName, partyLeaderId;
  List<String> members, lockedInMembers, optedOutMembers;
  Map<String, Map<String, dynamic>> memberDetails;
  Map<String, dynamic>? activeChallenge, pendingChallenge;
  Map<String, dynamic> memberWagers;
  int challengeStartDay;
  bool isLoading;
}
```

### Key Features Implementation

#### 1. Challenge Dashboard (`lib/features/challenge/screens/challenge_dashboard.dart`)
- **Your Progress**: Shows user's active goals with colored progress indicators
- **Party Progress**: Displays all party members' goal progress
- **Proof Notifications**: Instagram/Snapchat-style story interface for pending proofs
- **Challenge Header**: Shows challenge status (preparation, active, locked-in)

#### 2. Proof System
**Submission** (`lib/features/proof_submission/`):
- Image capture/selection
- Text description
- Date selection (today/yesterday)

**Approval** (`lib/features/party/widgets/proof_approval_widget.dart`):
- Story-style horizontal scrolling interface
- Full-screen proof viewer with approve/deny buttons
- Real-time updates via streams

#### 3. Progress Indicators (`lib/features/challenge/widgets/compact_progress_bar.dart`)
**Weekly Goals**: 7-segment progress bar (M-T-W-T-F-S-S)
- Blue: Planned
- Yellow: Pending approval
- Green: Approved/Completed
- Grey: Default/Skipped
- Dark Red: Denied

**Total Goals**: Stacked progress bar
- Yellow layer: Pending proofs + approved proofs
- Green layer: Approved proofs only

## Backend Architecture (Firebase)

### Firebase Services Used
1. **Authentication**: User login/registration
2. **Firestore**: Real-time database
3. **Storage**: Image/file uploads for proof photos
4. **Security Rules**: Access control for data

### Firestore Data Structure

#### Users Collection (`users/`)
```
users/{userId} {
  email: string,
  username?: string,
  displayName?: string,
  createdAt: timestamp
}
```

#### User Goals Collection (`userGoals/`)
```
userGoals/{userId} {
  goals: [
    {
      id: string,
      ownerId: string,
      goalName: string,
      goalType: "weekly" | "total",
      goalCriteria: string,
      goalFrequency: number,
      active: boolean,
      currentWeekCompletions: {
        "YYYY-MM-DD": "completed" | "pending" | "denied" | "skipped"
      },
      challenge?: {
        completions: {
          "YYYY-MM-DD": "completed" | "pending" | "denied"
        },
        proofs: {
          // For weekly goals (Map)
          "YYYY-MM-DD": {
            proofText: string,
            imageUrl?: string,
            status: "pending" | "approved" | "denied",
            submissionDate: string,
            approvedBy?: string,
            approvedAt?: string
          }
        } | [
          // For total goals (Array)
          {
            proofText: string,
            imageUrl?: string,
            status: "pending" | "approved" | "denied",
            submissionDate: string,
            approvedBy?: string,
            approvedAt?: string
          }
        ]
      }
    }
  ]
}
```

#### Parties Collection (`parties/`)
```
parties/{partyId} {
  partyName: string,
  partyLeaderId: string,
  members: string[], // Array of user IDs
  createdAt: timestamp,
  
  // Challenge state
  activeChallenge?: {
    challengeId: string,
    startDate: string,
    endDate: string,
    status: "active"
  },
  
  pendingChallenge?: {
    challengeId: string,
    status: "preparation",
    lockedInMembers: string[],
    optedOutMembers: string[],
    memberWagers: {
      [userId]: number
    }
  },
  
  challengeStartDay: number // 0-6 (Sunday-Saturday)
}
```

#### Invites Collection (`invites/`)
```
invites/{inviteId} {
  partyId: string,
  inviterEmail: string,
  inviteeEmail: string,
  status: "pending" | "accepted" | "declined" | "cancelled",
  createdAt: timestamp,
  expiresAt: timestamp
}
```

#### Proof Events Collection (`proofEvents/`)
```
proofEvents/{partyId}/events/{eventId} {
  type: "submitted" | "approved" | "denied",
  userId: string,
  goalId: string,
  proofDate?: string, // For weekly goals
  data: {
    proofText?: string,
    imageUrl?: string,
    goalName?: string,
    goalType?: string,
    approvedBy?: string,
    deniedBy?: string
  },
  timestamp: timestamp
}
```

### Storage Structure
```
gs://bucket/
├── proofs/
│   └── {userId}/
│       └── {goalId}/
│           └── {timestamp}_{filename}
└── profile-images/
    └── {userId}/
        └── profile_{timestamp}
```

## Data Flow Architecture

### 1. Goal Management Flow
```
User Input → GoalsProvider → GoalsActions → GoalsRepository → Firestore
                ↓
GoalsStreamManager ← Firestore (real-time updates)
                ↓
GoalsProvider → UI Components
```

### 2. Party Management Flow
```
User Action → PartyProvider → PartyActions → PartyRepository → Firestore
                ↓
PartyStreamManager ← Firestore (real-time updates)
                ↓
PartyProvider → UI Components
```

### 3. Proof Submission Flow
```
User Submits → ProofService → Goal.addProof() → GoalsRepository → Firestore
                ↓
ProofStreamManager.emitProofEvent() → Firestore (proofEvents)
                ↓
Real-time streams → PendingProofsWidget
```

### 4. Proof Approval Flow
```
User Approves → PartyProvider.approveProof() → Firestore Transaction:
  1. Update goal.challenge.completions[date] = "completed"
  2. Update goal.currentWeekCompletions[date] = "completed"
  3. Mark proof.status = "approved"
                ↓
ProofStreamManager.emitProofEvent() → Real-time updates
                ↓
UI automatically refreshes via Firestore streams
```

## Current Technical Debt & Issues

### 1. Data Model Migration Status ✅ COMPLETE
- **MIGRATION COMPLETE**: Successfully migrated from Legacy (`goal_model.dart`) to New (`goal_model_new.dart`)
- **Legacy System**: Commented out to prevent conflicts
- **New System**: Using structured ChallengeData class and proper typed models with template support
- **Dashboard**: Fully updated with goal templates and challenge integration

### 1.1. Goal System Migration Complete ✅
- **NEW SYSTEM**: `SimpleGoalsProvider` using `goal_model_new.dart`
- **Dashboard**: Updated to use new goal models with proper ChallengeData structure
- **Database**: Uses `userGoals/{userId}` collection with structured goal arrays
- **Features**: Goal creation, progress tracking, proof submission working
- **Templates**: Goal templates fully reintegrated with template-based goal creation
- **Challenges**: Full challenge lifecycle with wagers, lock-in/opt-out functionality

### 1.2. Legacy Systems (COMMENTED OUT - DO NOT UNCOMMENT)
- **Files**: 
  - `/lib/features/goals/providers/goals_provider.dart` (old version)
  - `/lib/features/goals/models/goal_model.dart` (old version)
  - `/lib/features/party/providers/party_provider.dart` (old version)
- **Status**: Commented out in `main.dart` to prevent conflicts
- **Note**: These will cause type conflicts if uncommented. Full migration to new system is complete.

### 2. Stream Management
- **Multiple stream sources**: Goals, Party, Proofs handled separately
- **Manual refresh**: Some components try to force refresh instead of relying on streams
- **Memory leaks**: Potential unclosed stream subscriptions

### 3. State Synchronization
- **Approval updates**: Must update multiple data structures for compatibility
- **Real-time sync**: Delays between approval and UI updates
- **Error handling**: Type casting errors when data formats change

### 4. UI Performance
- **Screen flashing**: During data updates
- **Redundant rebuilds**: Components rebuilding unnecessarily
- **Debug logging**: Excessive console output

## Recommended Restructuring

### 1. Unify Data Models
- Migrate entirely to new Goal model format
- Standardize on String-based completion statuses
- Create proper TypeScript-like interfaces for all data

### 2. Simplify State Management
- Single source of truth for each data domain
- Consistent stream-based updates
- Remove manual refresh mechanisms

### 3. Optimize Real-time Updates
- Batch related updates in transactions
- Use Firestore's offline capabilities
- Implement proper error boundaries

### 4. Performance Improvements
- Implement proper memoization
- Use const constructors where possible
- Optimize stream subscriptions