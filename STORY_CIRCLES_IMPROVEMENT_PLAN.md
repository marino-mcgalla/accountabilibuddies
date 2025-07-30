# Story Circles Improvement Plan

## Current Implementation Analysis

### 1. Current Behavior
- **Sorting**: Proofs are sorted by submission date (oldest first)
- **Viewing**: All proofs are shown regardless of status or whether user has viewed them
- **Approval**: Once approved, proof cannot be disputed
- **Tracking**: `viewedBy` field exists but is only used to prevent re-marking as viewed
- **Display**: No visual distinction between viewed/unviewed proofs

### 2. Requested Features
1. **Prioritize pending proofs** - Show unapproved pending proofs first, oldest first
2. **Session-based viewing** - Show only unviewed proofs in a viewing session (like Snapchat)
3. **Review all mode** - Allow explicit access to view all proofs including viewed ones
4. **Track view status per user** - Know which users have seen which proofs
5. **Allow disputes on approved proofs** - Let users dispute even after approval
6. **Visual feedback** - Show unviewed status even for approved proofs

## Implementation Plan

### Phase 1: Backend Changes (Firestore Impact)

#### 1.1 Proof Submission Model Updates
**Current**: `viewedBy: List<String>` - Simple list of user IDs

**Proposed**: Keep the same structure but enhance usage:
- Continue using `viewedBy` array for tracking
- No schema changes needed
- Firestore impact: 1 additional write per proof view (already implemented)

#### 1.2 Dispute Logic Enhancement
**Current**: `canApproveBy()` only allows approval/dispute for pending/disputed proofs

**Changes Needed**:
- Modify `canApproveBy()` to allow disputes on approved proofs
- Add new method `canDisputeBy()` for clearer logic
- Update `ProofApprovalService` to handle disputes on approved proofs

**Firestore Impact**: 
- No additional reads
- Same write pattern (1 write per dispute action)

### Phase 2: Frontend Changes

#### 2.1 Story Circle Indicators
**Current**: Shows count and pending indicator

**Proposed Enhancement**:
```dart
// Add to story circle display logic:
- Count only unviewed proofs for the indicator number
- Show different badge color for "has unviewed" vs "all viewed"
- Maintain pending indicator for approval needs
```

#### 2.2 Session-Based Viewing (Snapchat-like)
```dart
// Two distinct viewing modes:
enum ViewingMode {
  newOnly,    // Default: Show only unviewed proofs
  reviewAll,  // Explicit: Show all proofs including viewed
}

List<ProofSubmission> getProofsForSession(
  List<ProofSubmission> allProofs, 
  String currentUserId,
  ViewingMode mode,
) {
  switch (mode) {
    case ViewingMode.newOnly:
      // Filter to only unviewed proofs
      final unviewedProofs = allProofs.where(
        (p) => !p.hasBeenViewedBy(currentUserId)
      ).toList();
      
      // Sort with pending first, then by date (oldest first)
      unviewedProofs.sort((a, b) {
        // Pending proofs come first
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        // Within same status, sort by date
        return a.submissionDate.compareTo(b.submissionDate);
      });
      
      return unviewedProofs;
      
    case ViewingMode.reviewAll:
      // Show all proofs, but still prioritize pending
      final sortedProofs = List<ProofSubmission>.from(allProofs);
      sortedProofs.sort((a, b) {
        // Unviewed pending first
        if (a.isPending && !a.hasBeenViewedBy(currentUserId) && 
            !(b.isPending && !b.hasBeenViewedBy(currentUserId))) return -1;
        if (!(a.isPending && !a.hasBeenViewedBy(currentUserId)) && 
            b.isPending && !b.hasBeenViewedBy(currentUserId)) return 1;
        // Then by date
        return a.submissionDate.compareTo(b.submissionDate);
      });
      
      return sortedProofs;
  }
}
```

#### 2.3 Story Circle Interaction
```dart
// Default tap behavior - show only new proofs
onTap: () => _openStoryViewer(
  proofs: getProofsForSession(allProofs, userId, ViewingMode.newOnly),
),

// Long press or explicit button - show all proofs
onLongPress: () => _openStoryViewer(
  proofs: getProofsForSession(allProofs, userId, ViewingMode.reviewAll),
),
```

#### 2.3 Story Viewer UI Updates
1. **Progress Indicator**: Show which proofs are unviewed
2. **Action Buttons**: 
   - Show "Dispute" button even for approved proofs
   - Disable "Approve" for already approved proofs
3. **Visual Feedback**: Different styling for viewed vs unviewed

### Phase 3: Performance Optimization

#### 3.1 Read/Write Analysis
**Current State**:
- Reads: 1 query per challenge for all proofs
- Writes: 1 per proof submission, 1 per approval

**After Implementation**:
- Reads: Same (no additional queries needed)
- Writes: +1 per proof view (already implemented)

#### 3.2 Optimization Strategies
1. **Client-side filtering**: Sort/filter proofs in memory rather than multiple queries
2. **Batch updates**: When marking multiple proofs as viewed
3. **Local caching**: Cache viewed status locally to reduce re-renders

### Phase 4: Implementation Steps

1. **Update Domain Logic** (30 min)
   - Modify `canApproveBy()` to check status properly
   - Add `canDisputeBy()` method
   - Update dispute handling logic

2. **Update Story Circle Widget** (45 min)
   - Implement new sorting algorithm
   - Update badge indicators
   - Add unviewed count logic

3. **Update Story Viewer** (45 min)
   - Modify action buttons visibility
   - Add visual indicators for viewed/unviewed
   - Update navigation logic

4. **Update Proof Service** (30 min)
   - Modify approval service to handle approved->disputed transition
   - Ensure proper status updates

5. **Testing & Bug Fixes** (1 hour)
   - Test all edge cases
   - Verify no existing functionality broken

**Total Estimated Time**: 3.5 hours

### Risk Mitigation

1. **Backwards Compatibility**: All changes are additive, no breaking changes
2. **Performance**: No additional database queries, only client-side filtering
3. **Data Integrity**: Existing data structure unchanged
4. **User Experience**: Graceful fallbacks if no unviewed proofs

### Key Benefits

1. **Better UX**: Users see what needs attention first
2. **Accountability**: Can dispute even after approval
3. **Awareness**: Know which proofs team hasn't seen
4. **Performance**: No significant impact on read/write costs
5. **Flexibility**: Can show all proofs when desired