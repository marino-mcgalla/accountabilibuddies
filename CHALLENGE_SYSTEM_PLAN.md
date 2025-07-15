# Challenge System Implementation Plan

## Current State Analysis

### **✅ What's Working**
- Goal templates creation/management (`GoalTemplateProvider`)
- Basic party system (`SimplePartyProvider`)
- Goal loading from party challenges (`SimpleGoalsProvider`)
- Basic proof submission functionality
- Party management (create/join parties, manage members)
- ChallengeActions for basic challenge operations

### **❌ Critical Issues Identified**

1. **Type Inconsistency**: 
   - Goal templates use `daily` type (`GoalTemplate.type`)
   - Goal instances use `weekly` type (`Goal.type`)
   - Located in: `/lib/features/goals/models/goal_template.dart` vs `/lib/features/goals/models/goal_model.dart`

2. **Incomplete Challenge Flow**: 
   - Setup → Active → Complete lifecycle is broken
   - No UI for challenge setup/start
   - No proper goal instance creation from templates
   - No automatic challenge progression

3. **No Goal Instance Creation**: 
   - Templates don't properly convert to challenge-specific instances
   - Missing template-to-instance conversion logic

4. **Proof Approval System**: 
   - Only stub implementation exists in `PendingProofsWidget`
   - Approval workflow is incomplete

### **🔧 Multi-Party Edge Cases**

#### Current Support:
- Users can be in multiple parties ✅ (via `SimplePartyProvider`)
- Goals stored per-party in challenge context ✅

#### Missing Functionality:
- Same goal template needs different instances per party ❌
- Different frequencies per party not handled ❌
- No cross-party goal synchronization ❌
- No proper handling of same goal across parties ❌

## Database Schema Analysis

### Current Structure:
```
parties/{partyId}/
├── activeChallenge/
│   ├── id: string
│   ├── status: 'setup'|'active'|'completed'|'payout'
│   ├── startDate: Timestamp
│   ├── endDate: Timestamp
│   ├── lockedInMembers: string[]
│   ├── optedOutMembers: string[]
│   ├── wagers: {userId: amount}
│   ├── goalCompletions: {userId: boolean}
│   ├── payouts: {userId: amount}
│   └── memberGoals: {userId: Goal[]}
├── pendingChallenge/ (similar structure)
└── members: string[]

users/{userId}/
└── goalTemplates/{templateId}/
    ├── name: string
    ├── description: string
    ├── type: 'daily'|'total'  // INCONSISTENT WITH GOAL INSTANCES
    ├── defaultFrequency: number
    └── category: string

userGoals/{userId}/ (LEGACY - should be removed)
└── goals: Goal[]
```

## Implementation Plan

### **Phase 1: Fix Foundation (Critical)**

#### 1. Resolve Type Inconsistency
- **Goal**: Standardize on `weekly`/`daily`/`total` types across templates and instances
- **Files to Update**:
  - `/lib/features/goals/models/goal_template.dart`
  - `/lib/features/goals/models/goal_model.dart`
- **Action**: Update GoalTemplate enum to match Goal enum

#### 2. Design Optimal Goal Instance Structure
```
parties/{partyId}/activeChallenge/memberGoals/{userId}/[
  {
    id: string,
    templateId: string, // Links back to user's template
    partyId: string,    // Which party this instance belongs to
    type: 'weekly'|'daily'|'total',
    frequency: number,  // Can differ from template default
    name: string,       // Copied from template at creation
    description: string, // Copied from template at creation
    category: string,   // Copied from template at creation
    challengeData: ChallengeData // Tracks completions, proofs for this challenge
  }
]
```

#### 3. Template-to-Instance Conversion Logic
- Create method to convert goal templates to challenge-specific instances
- Handle frequency customization per party
- Ensure template changes don't affect active challenge instances

### **Phase 2: Build Challenge Lifecycle**

#### 1. Challenge Setup Flow
- **UI Component**: Challenge setup screen for party leaders
- **Functionality**:
  - Party leader selects goal templates from available templates
  - Convert templates to goal instances for each member
  - Allow frequency customization per party
  - Set challenge start/end dates

#### 2. Challenge States & Transitions
- **Setup**: Party leader configures challenge
- **Lock-in**: Members confirm participation and lock in their goals
- **Active**: Challenge is running, members submit proofs
- **Complete**: Challenge ended, calculate results
- **Payout**: Distribute rewards (if wagering enabled)

#### 3. Goal Instance Management
- Isolate goal instances per party/challenge
- Track proof submissions per instance
- Handle completion tracking per challenge period

### **Phase 3: Multi-Party Goal Management**

#### 1. Goal Instance Isolation
- Each party gets separate goal instances from same template
- Template changes don't affect active challenges
- Track which templates are used in which parties

#### 2. Cross-Party Considerations
- Same user can have same goal template in multiple parties
- Different frequencies allowed per party
- Separate progress tracking per party

#### 3. Template Usage Tracking
- Track which templates are actively used in challenges
- Prevent deletion of templates in active use
- Show usage status in template management

### **Phase 4: Proof System Enhancement**

#### 1. Complete Proof Approval Workflow
- Build out `PendingProofsWidget` functionality
- Create approval interface for party members
- Implement proof status management (pending → approved/denied)

#### 2. Progress Tracking Integration
- Update progress trackers to show real challenge data
- Remove mock data from `SimpleProgressTracker`
- Integrate with proof approval results

## Key Files and Their Status

### **Active Files (Currently Used)**
- `SimpleGoalsProvider` - Loading goals from challenges ✅
- `SimplePartyProvider` - Party and basic challenge management ✅
- `ChallengeActions` - Challenge operations ✅
- `GoalTemplateProvider` - Template management ✅
- `SimpleProgressTracker` - Progress display ✅

### **Files Needing Updates**
- `goal_template.dart` - Fix type enum inconsistency
- `goal_model.dart` - Ensure consistency with templates
- `challenge_actions.dart` - Add template-to-instance conversion
- `simple_goals_provider.dart` - Handle new goal instance structure

### **Legacy Files (Can be Removed)**
- `GoalsProvider` - Old complex system ❌
- `PartyProvider` - Old complex system ❌
- `MultiPartyProvider` - Multi-party system ❌
- `PartyGoalsService` - Old goal management ❌

## Next Steps

1. **Start with Phase 1**: Fix the type inconsistency between goal templates and instances
2. **Design goal instance structure**: Create proper separation between templates and challenge instances
3. **Build template-to-instance conversion**: Enable proper goal instance creation from templates
4. **Implement challenge lifecycle**: Complete the setup → active → complete flow
5. **Enhance proof system**: Build out the approval workflow

## Risk Mitigation

- **Backup current working functionality** before making changes
- **Test multi-party scenarios** thoroughly
- **Ensure backward compatibility** for existing data
- **Phase implementation** to avoid breaking existing features

## Phase 1 Progress Update ✅

### **Completed Tasks:**

#### ✅ Task 1: Fix Type Inconsistency
- **Status**: COMPLETED
- **Changes Made**:
  - Updated `Goal` enum in `goal_model.dart` to use `daily` and `total` (was `weekly` and `total`)
  - Added legacy support for "weekly" in `GoalType.fromString()` for backward compatibility
  - Updated all references across the codebase:
    - `proof_actions.dart`
    - `goals_actions.dart` 
    - `my_goals_screen.dart`
    - `simple_goals_provider.dart`
- **Result**: Both GoalTemplate and Goal now use consistent `daily` and `total` types

#### ✅ Task 2: Design Optimal Goal Instance Structure
- **Status**: COMPLETED
- **New Model Created**: `/lib/features/goals/models/goal_instance.dart`
- **Key Features**:
  - Instance isolation (each party gets separate instances)
  - Template independence (changes don't affect other instances)
  - Frequency flexibility (custom frequencies per party)
  - Complete challenge tracking via `ChallengeData`
  - Full CRUD operations (add/approve/deny proofs)

#### ✅ Task 3: Create Template-to-Instance Conversion Logic
- **Status**: COMPLETED  
- **New Service Created**: `/lib/features/goals/services/goal_instance_service.dart`
- **Key Features**:
  - Convert templates to instances for challenges
  - Save/load instances from party challenges
  - Submit/approve/deny proofs
  - Get pending proofs across parties
  - Complete CRUD operations for goal instances

#### ✅ Task 4: Create New Provider System
- **Status**: COMPLETED
- **New Provider Created**: `/lib/features/goals/providers/goal_instance_provider.dart`
- **Key Features**:
  - Manages goal instances within challenges
  - Integrates with GoalInstanceService
  - Provides reactive UI updates
  - Maintains backward compatibility with existing UI

### **Next Steps:**
- Phase 2: Build complete challenge lifecycle (setup → lock-in → active → complete)
- Phase 3: Update UI components to use new goal instance system
- Phase 4: Migrate existing data to new structure

---

*Generated from comprehensive code analysis on 2025-01-14*
*Last updated: Phase 1 COMPLETED - Goal instance foundation established*