---
title: Technical Debt Master Document
tags:
  - architecture
  - tech-debt
  - refactoring
  - priorities
created: 2025-10-08
source: docs/TECH_DEBT.md
last-updated: 2025-10-09
status: in-progress
---

# Technical Debt Master Document
**Last Updated:** October 9, 2025
**Investigation:** Checkpoint-1 comprehensive codebase audit
**Status:** 6 critical issues, 2 medium issues, 5 low-priority items
**Recent Win:** ✅ StateFlow delegation complete (145 lines, 6% LiveScoringViewModel reduction)

---

## Executive Summary

**Project Health:** 98% feature complete, but carrying significant architectural debt

**Total Estimated Effort to Address:** 12-15 weeks of focused work

**Primary Concerns:**
- **God class antipattern** across ViewModels (LiveScoringViewModel: 2,134 lines, down from 2,808)
- **Repository bloat** (5,959 lines across 5 files violating SRP)
- **Incomplete features** marked as "complete" in documentation
- **Documentation chaos** (10+ severely outdated files)

**Recommended Strategy:** Incremental extraction over 3 months, prioritized by user impact

---

## Priority Matrix

### 🚨 CRITICAL (P0) - Address Before Next Feature Epoch

| Issue | Impact | Effort | Priority Score | Status |
|-------|--------|--------|----------------|--------|
| N+1 Query Pattern | HIGH | 2 hours | ⭐⭐⭐⭐⭐ | ✅ DONE |
| Average Score Bug | MEDIUM | 30 min | ⭐⭐⭐⭐⭐ | ✅ DONE |
| TournamentSyncService Extraction | HIGH | 1 week | ⭐⭐⭐⭐⭐ | ✅ DONE |
| ScoreConflictResolution Extraction | HIGH | 1 week | ⭐⭐⭐⭐⭐ | ✅ DONE |
| EndCompletionService Extraction | HIGH | 1 week | ⭐⭐⭐⭐⭐ | ✅ DONE |
| StateFlow Delegation | MEDIUM | 3 days | ⭐⭐⭐⭐ | ✅ DONE (Oct 9) |
| Tournament Rank Bug | HIGH | 1 hour | ⭐⭐⭐⭐⭐ | ✅ DONE (Oct 9) |
| Tie-Breaking Implementation | HIGH | 4-8 hours | ⭐⭐⭐⭐ | ✅ DONE |
| LiveScoringViewModel Extraction | CRITICAL | 2-3 weeks | ⭐⭐⭐ | 🔄 IN PROGRESS (68% done) |

### 🟡 HIGH (P1) - Next 2-3 Months

| Issue | Impact | Effort | Priority Score |
|-------|--------|--------|----------------|
| Repository God Classes | HIGH | 6-7 weeks | ⭐⭐⭐ |
| Documentation Cleanup | MEDIUM | 1 week | ⭐⭐⭐ |
| Missing Indexes | MEDIUM | 2 hours | ⭐⭐ |

### 🟢 MEDIUM (P2) - Future Improvements

| Issue | Impact | Effort |
|-------|--------|--------|
| RoundViewModel Size | LOW | 3-4 weeks |
| ActiveScoringScreen Size | LOW | 2-3 weeks |

---

## Critical Issues (P0)

### 1. N+1 Query Pattern ✅ **FIXED**

**File:** `RoundRepository.kt:97-99, 194-196` | `RoundDao.kt:558-624`
**Impact:** 30-end round = 31 database queries instead of 1 (3000% overhead!)
**Status:** ✅ COMPLETED - October 4, 2025

**Problem (BEFORE):**
```kotlin
// N+1 anti-pattern
val endScores = roundDao.getEndScoresForRound(roundId)  // 1 query
val ends = endScores.map { endScore ->
    val arrows = roundDao.getArrowScoresForEnd(endScore.id.toLong())  // N queries!
    EndScoreWithArrows(endScore, arrows)
}
```

**Solution Implemented:**
```kotlin
// Single optimized LEFT JOIN query
val endWithArrowData = roundDao.getEndsWithArrowsForRound(roundId)  // 1 query
val ends = groupEndWithArrowData(endWithArrowData)
```

**Performance Gain:** 85-95% reduction (31 queries → 1 query)
**User Impact:** Noticeably faster round loading, better battery life

---

### 2. Average Score Always Shows 0.0 ✅ **FIXED**

**File:** `FirebaseTournamentRepository.kt:1115-1137`
**Impact:** All tournament leaderboards show "Avg 0.0" (100% of users affected)
**Status:** ✅ COMPLETED - October 4, 2025

**Solution Implemented:**
```kotlin
// Calculate average score per end
val newAverageScore = if (newEndsCompleted > 0) {
    newTotal.toDouble() / newEndsCompleted
} else {
    0.0
}

val participantUpdateData = mapOf(
    "currentScore" to newTotal,
    "arrowsShot" to newArrowsShot,
    "endsCompleted" to newEndsCompleted,
    "averageScore" to newAverageScore,  // ✅ NOW INCLUDED
    ...
)
```

**User Impact:** Professional-looking leaderboards with accurate statistics

---

### 3. TournamentSyncService Extraction ✅ **COMPLETE**

**Files:**
- `TournamentSyncService.kt` (NEW) - 556 lines extracted from LiveScoringViewModel
- `LiveScoringViewModel.kt` - Reduced from 2,808 → 2,252 lines (initial extraction)
**Impact:** First phase of LiveScoringViewModel god class refactoring
**Status:** ✅ COMPLETED - October 5, 2025
**Commit:** `b810eea` - "refactor: Extract TournamentSyncService from LiveScoringViewModel"

**Solution Implemented:**
```kotlin
@Singleton
class TournamentSyncService @Inject constructor(
    private val context: Context,
    private val repositoryFactory: RepositoryFactory,
    private val serviceScope: CoroutineScope? = null
) {
    // 5 StateFlows for tournament state
    val syncStatus: StateFlow<TournamentSyncStatus>
    val tournamentRoundState: StateFlow<TournamentRound?>
    val incomingTournamentScores: StateFlow<List<TournamentScore>>
    val liveLeaderboard: StateFlow<List<LeaderboardEntry>>
    val tournamentParticipants: StateFlow<List<TournamentParticipant>>

    // Core sync methods
    fun setupTournamentSync(tournamentId: String, currentRoundNumber: Int = 1)
    fun syncTournamentScoresManually(tournamentId: String, currentParticipantIds: List<String>)
    suspend fun submitTournamentScoreWithRetry(...)
    suspend fun updateTournamentRoundStatus(...)
    fun observeTournamentRoundState(tournamentId: String, roundNumber: Int)
    fun cleanup()
}
```

**Benefits:**
- ✅ 556 lines extracted from LiveScoringViewModel
- ✅ Clear separation of concerns (tournament sync vs. scoring logic)
- ✅ Easier to test tournament sync in isolation
- ✅ Foundation for future service extractions
- ✅ Proof-of-concept for ViewModel refactoring strategy

---

### 4. ScoreConflictResolutionService Extraction ✅ **COMPLETE**

**File:** `ScoreConflictResolutionService.kt` (NEW) - 262 lines extracted from LiveScoringViewModel
**Impact:** Second phase of LiveScoringViewModel god class refactoring
**Status:** ✅ COMPLETED - October 2025
**Commit:** `4d38c7b` - "feat: Implement tournament tie-breaking and extract ScoreConflictResolutionService"

**Solution Implemented:**
```kotlin
@Singleton
class ScoreConflictResolutionService @Inject constructor(
    private val serviceScope: CoroutineScope? = null
) {
    // Conflict state management
    val detectedConflicts: StateFlow<List<ScoreConflict>>
    val hasActiveConflicts: StateFlow<Boolean>

    // Core conflict methods
    fun detectConflicts(...)
    fun resolveConflict(...)
    fun clearConflicts()
}
```

**Benefits:**
- ✅ 262 lines extracted from LiveScoringViewModel
- ✅ Isolated conflict resolution logic for easier testing
- ✅ Reusable conflict resolution strategies
- ✅ Clear separation of concerns

---

### 5. EndCompletionService Extraction ✅ **COMPLETE**

**File:** `EndCompletionService.kt` (NEW) - 400 lines extracted from LiveScoringViewModel
**Impact:** Third phase of LiveScoringViewModel god class refactoring
**Status:** ✅ COMPLETED - October 6, 2025

**Solution Implemented:**
```kotlin
@Singleton
class EndCompletionService @Inject constructor(
    private val application: Application,
    private val roundRepository: RoundRepository,
    private val repositoryFactory: RepositoryFactory,
    private val tournamentSyncService: TournamentSyncService,
    private val serviceScope: CoroutineScope? = null
) {
    suspend fun recordEndCompletion(...)
    suspend fun completeCurrentEnd(...)
    fun finalizeEnd(...)
    fun checkAllParticipantsComplete(...)
}
```

**Benefits:**
- ✅ 400 lines extracted from LiveScoringViewModel
- ✅ Clear end completion logic boundary
- ✅ Delegates tournament submission to TournamentSyncService
- ✅ Comprehensive test coverage

---

### 6. StateFlow Delegation ✅ **COMPLETE**

**File:** `LiveScoringViewModel.kt`
**Impact:** Fourth optimization phase - removed duplicate StateFlows
**Status:** ✅ COMPLETED - October 9, 2025
**Lines Removed:** 145 lines

**Problem (BEFORE):**
```kotlin
// Duplicate StateFlows in LiveScoringViewModel
private val _syncStatus = MutableStateFlow<TournamentSyncStatus>(TournamentSyncStatus.Idle)
val syncStatus: StateFlow<TournamentSyncStatus> = _syncStatus.asStateFlow()

private val _tournamentRoundState = MutableStateFlow<com.archeryapprentice.data.models.TournamentRound?>(null)
val tournamentRoundState: StateFlow<com.archeryapprentice.data.models.TournamentRound?> = _tournamentRoundState.asStateFlow()
```

**Solution Implemented:**
```kotlin
// ARCHITECTURAL COMPLIANCE: Expose TournamentSyncService StateFlows instead of duplicating
val syncStatus: StateFlow<TournamentSyncStatus> = tournamentSyncService.syncStatus
val tournamentRoundState: StateFlow<com.archeryapprentice.data.models.TournamentRound?> = tournamentSyncService.tournamentRoundState
```

**Methods Delegated:**
- `observeTournamentRoundState()`: 73 → 43 lines (30-line reduction)
- `updateTournamentRoundStatus()`: 25 → 6 lines (19-line reduction)

**Dead Code Removed:**
- `syncDetailedTournamentScores()`: 94 lines (never called)

**Benefits:**
- ✅ 145 lines removed through delegation
- ✅ Single source of truth for tournament state
- ✅ Reduced complexity
- ✅ All 84 LiveScoringViewModel tests passing

---

### 7. Tournament Rank Display Bug ✅ **FIXED**

**File:** `RoundViewModel.kt:1022-1024, 1377-1388`
**Impact:** All participants showed incorrect rank "3rd / 3 Participants" regardless of actual ranking
**Status:** ✅ COMPLETED - October 9, 2025

**Problem (BEFORE):**
```kotlin
// Used Round.participants[LocalUser].id which was "local_user" (default)
// But Firebase stores participants with actual Firebase UID as document ID
val muId = targetParticipantId ?: localParticipant?.id  // "local_user" - WRONG!
```

**Solution Implemented:**
```kotlin
// BUG FIX: Use current Firebase UID directly, not the Round's participant ID
// The Round's LocalUser.id is often "local_user" (default), but in Firebase
// the participant is stored with the actual Firebase UID as the document ID
val currentFirebaseUid = try {
    com.google.firebase.auth.FirebaseAuth.getInstance().currentUser?.uid
} catch (e: Exception) {
    android.util.Log.w("RoundViewModel", "Failed to get Firebase UID for rank retrieval", e)
    null
}

// Use explicit targetParticipantId if provided, otherwise use current Firebase UID
val muId = targetParticipantId ?: currentFirebaseUid
```

**User Impact:** Tournament leaderboard now shows correct rank for each participant (1st, 2nd, 3rd, etc.)

---

### 8. Tie-Breaking ✅ **COMPLETE**

**Files:**
- `TournamentParticipant.kt:38-39` - xCount & tenCount fields added
- `FirebaseTournamentRepository.kt:1179-1180` - Multi-field ordering implemented

**Impact:** Fair competition with standard archery tie-breaking rules
**Status:** ✅ COMPLETED - October 2025
**Commit:** `4d38c7b` - "feat: Implement tournament tie-breaking and extract ScoreConflictResolutionService"

**Implementation:**
```kotlin
participantsRef
    .orderBy("currentScore", Query.Direction.DESCENDING)
    .orderBy("xCount", Query.Direction.DESCENDING)
    .orderBy("tenCount", Query.Direction.DESCENDING)
```

**User Impact:** Fair competition with standard archery rules compliance

---

### 9. LiveScoringViewModel God Class 🔄 **IN PROGRESS**

**File:** `LiveScoringViewModel.kt` (2,134 lines, down from 2,808)
**Impact:** High bug risk, difficult maintenance, slow feature development
**Status:** 🔄 4 of 6 optimizations complete (1,363 lines extracted/removed, 68% progress)

**Current Metrics:**
- **Lines:** 2,134 (target: <1,900) - ⬇️ 674 lines from peak
- **Extractions Complete:** 4/6
  - ✅ TournamentSyncService (556 lines)
  - ✅ ScoreConflictResolutionService (262 lines)
  - ✅ EndCompletionService (400 lines)
  - ✅ StateFlow Delegation (145 lines)
- **Remaining Extractions:** 2 services (~350 lines estimated)
- **Progress:** 68% complete

**Root Cause:** Tournament Phases 2.2-4.1 added ~1,300 lines without extraction
**Progress:** Systematic extraction underway using proven copy-delegate-validate pattern

**Extraction Roadmap:**

See [[Architecture/LiveScoringVM-Analysis]] for comprehensive analysis.

**✅ Priority 1: TournamentSyncService** (556 lines) - COMPLETE (Oct 5)
- Firebase synchronization
- Score queueing
- Leaderboard management

**✅ Priority 2: ScoreConflictResolutionService** (262 lines) - COMPLETE (Oct 2025)
- Conflict detection
- Resolution strategies
- Version management

**✅ Priority 3: EndCompletionService** (400 lines) - COMPLETE (Oct 6)
- End finalization
- End recording and Firebase submission
- Retry logic with exponential backoff
- Multi-participant completion checking

**✅ Priority 4: StateFlow Delegation** (145 lines) - COMPLETE (Oct 9)
- Removed duplicate StateFlows
- Delegated observeTournamentRoundState()
- Delegated updateTournamentRoundStatus()
- Removed dead code

**🔲 Priority 5: TournamentRoundLifecycleService** (~200 lines, 3 days) - TODO
- Round initialization
- Completion handling
- State transitions

**🔲 Priority 6: StatisticsAggregationService** (~150 lines, 2 days) - TODO
- Real-time stats calculation
- Leaderboard updates
- Trend detection

**Progress:**
- **Extracted/Removed:** 1,363 lines (4/6 optimizations)
- **Remaining:** ~350 lines (2/6 services)
- **Final Target:** ~1,900 lines (healthy coordinator size)

**Remaining Effort:** 1-2 weeks (2 services remaining)
**Benefits:**
- Clear separation of concerns
- Easier testing (mock only needed services)
- Lower cognitive load for developers
- Proven extraction pattern established (100% success rate)

**Acceptance Criteria:**
- [x] Each service <500 lines
- [ ] LiveScoringViewModel <1,900 lines (currently 2,134, 89% to target)
- [x] All existing tests pass
- [x] No functionality regression
- [x] Proven extraction pattern validated (4/4 success)

---

## High Priority (P1)

### 10. Repository God Classes 🟡

**Files:**
- `FirebaseTournamentRepository.kt`: 1,707 lines
- `HybridTournamentRepository.kt`: 1,506 lines
- `RoundRepository.kt`: 1,443 lines
- `TournamentRepository.kt` (interface): 395 lines, 51 methods

**Total:** 5,959 lines violating Single Responsibility Principle

**Standard:** 200-400 lines, 10-15 methods per repository

**Refactoring Plan:**

**Split TournamentRepository → 4 repositories:**
1. **TournamentCrudRepository** (~300 lines) - CRUD operations
2. **TournamentSyncRepository** (~400 lines) - Firebase sync, conflicts
3. **TournamentScoreRepository** (~500 lines) - Score submission, caching
4. **TournamentAnalyticsRepository** (~200 lines) - Leaderboards, statistics

**Split RoundRepository → 3 repositories:**
1. **RoundCrudRepository** (~400 lines) - Round management
2. **RoundScoringRepository** (~500 lines) - End/arrow scoring
3. **RoundStatisticsRepository** (~400 lines) - Stats, trends

**Effort:** 6-7 weeks
**Priority:** HIGH but lower than LiveScoringViewModel (data layer vs UI layer)

---

### 11. Documentation Chaos 🟡

**Status:** 10+ files severely outdated, claiming features "planned" that are complete

**Critical Documentation Issues:**

**1. tournament/README.md** - SEVERELY OUTDATED
- Claims "In Progress": Tournament UI, real-time updates (DONE!)
- Claims "Planned": Tournament creation, cloud sync (DONE!)
- Missing: Phases 1-5.2 completion, smart caching

**2. TOURNAMENT_SYSTEM_DOCUMENTATION.md** - 8-9 MONTHS OLD
- All testing checkboxes unchecked
- Lists complete features as "Future Enhancements"

**3. README.md (project root)** - 3 MONTHS OUTDATED
- Last update: July 2025
- Missing: Aug-Oct tournament completion, Firebase integration, caching

**Solution:**
1. **Archive old files** to `docs/COLD_STORAGE/` (70 files already moved)
2. **Update critical docs:**
   - README.md → Current status, Aug-Oct work
   - Tournament README → Mark Phases 1-5 complete
   - TOURNAMENT_SYSTEM_DOCUMENTATION.md → Update testing status
3. **Remove misleading planning docs** that claim "complete" but zero implementation

**Effort:** 1 week (8-10 hours)
**Priority:** MEDIUM - doesn't affect code but affects development velocity

---

### 12. Missing Database Indexes 🟡

**Status:** 90% coverage, 2 missing composite indexes

**Missing Index 1: Equipment Performance Query (MEDIUM)**
```sql
CREATE INDEX idx_arrow_scores_equipment_time
ON arrow_scores(bowSetupId, scoredAt DESC)
```

**Impact:** Equipment performance screen slow with large datasets
**Effort:** 2 hours (write migration, test)
**Priority:** MEDIUM

---

## Medium Priority (P2)

### 13. RoundViewModel Size (2,079 lines)

**Status:** STABLE - don't touch immediately

**Recommendation:** DEFER
- Monitor growth
- Extract only if exceeds 2,500 lines
- Focus on LiveScoringViewModel first

**Effort:** 3-4 weeks (if needed)
**Priority:** LOW (stable, functional)

---

### 14. ActiveScoringScreen Size (1,958 lines)

**File:** `ActiveScoringScreen.kt`
**Status:** UI component bloat

**Recommendation:** Extract composable components
- Visual scoring UI (~400 lines)
- Traditional scoring UI (~300 lines)
- Participant management (~250 lines)
- Statistics display (~200 lines)

**Effort:** 2-3 weeks
**Priority:** MEDIUM (lower than ViewModels and repositories)

---

## Implementation Roadmap

### Phase A: Quick Wins ✅ **COMPLETE**

**Week 1:** ✅ **COMPLETE**
- ✅ **DONE** Fix N+1 query pattern (2 hours) - Commit `698e634`
- ✅ **DONE** Fix average score bug (30 min) - Commit `698e634`

**Week 2:** ✅ **COMPLETE**
- ✅ **DONE** Implement tie-breaking (8 hours) - Commit `4d38c7b`
- ✅ **DONE** Extract TournamentSyncService (1 week) - Commit `b810eea`
- ✅ **DONE** Extract ScoreConflictResolutionService (1 week) - Commit `4d38c7b`

**Completed Impact:**
- ✅ Major user-facing bugs fixed (average score, tournament rank)
- ✅ 85-95% performance improvement (31 queries → 1 query)
- ✅ Fair competition with tie-breaking (X count, 10 count)
- ✅ 1,363 lines extracted/removed from LiveScoringViewModel

---

### Phase B: LiveScoringViewModel Extraction 🔄 **IN PROGRESS**

**Week 1-2:** ✅ **COMPLETE** - TournamentSyncService
- ✅ Extract 556 lines
- ✅ Validate copy-delegate-validate pattern
- ✅ Comprehensive testing

**Week 3:** ✅ **COMPLETE** - ScoreConflictResolutionService
- ✅ Extract 262 lines
- ✅ Validate extraction pattern
- ✅ Comprehensive testing

**Week 4:** ✅ **COMPLETE** - EndCompletionService
- ✅ Extract 400 lines
- ✅ Validate delegation pattern
- ✅ Fix failing tests

**Week 5:** ✅ **COMPLETE** - StateFlow Delegation
- ✅ Remove 145 lines
- ✅ Delegate to TournamentSyncService
- ✅ Remove dead code

**Week 6:** 🔲 **TODO** - Remaining Services
- 🔲 TournamentRoundLifecycleService (~200 lines)
- 🔲 StatisticsAggregationService (~150 lines)

**Week 7:** 🔲 **TODO** - Final Cleanup
- Integration testing
- Performance validation
- Documentation updates

**Progress:** 68% complete (4/6 optimizations done, 1,363 lines extracted/removed)
**Expected Final Impact:** ~1,900 line ViewModel, easier maintenance, lower bug risk

---

### Phase C: Repository Refactoring (6-7 weeks)

**Weeks 1-3:** TournamentRepository Split
- Design 4 focused repositories
- Migrate implementations
- Update dependency injection

**Weeks 4-5:** RoundRepository Split
- Design 3 focused repositories
- Migrate implementations
- Update dependency injection

**Weeks 6-7:** Testing & Validation
- Integration testing
- Performance validation
- Bug fixes

**Expected Impact:** Better architecture, easier testing, clearer domain boundaries

---

## Lessons Learned

### Pattern: "Planning != Implementation"

**Discovered:** Multiple features marked "complete" in docs with zero implementation

**Solution:**
- Definition of Done: Code merged + tests passing + docs updated
- Code review validates implementation, not just planning
- Regular architecture audits (like this checkpoint)

### Pattern: "Incremental Addition Without Extraction"

**Discovered:** Tournament features added ~1,300 lines to LiveScoringViewModel without refactoring

**Solution:**
- Line count thresholds with pre-commit hooks
- Mandatory extraction when ViewModel exceeds 1,500 lines
- Architecture review for features adding >200 lines to single class

### Pattern: "Documentation Drift"

**Discovered:** 10+ files claiming features "planned" that are complete

**Solution:**
- Documentation update as part of Definition of Done
- Quarterly documentation audit
- Archive old docs to prevent confusion

---

## Related Documentation

- [[Project-Status/Implementation-Status-10-09-25|Implementation Status (Oct 9)]]
- [[Project-Status/Checkpoint-Findings|Checkpoint Findings]] - Detailed investigation report
- [[Architecture/LiveScoringVM-Analysis|LiveScoringVM Analysis]] - Deep dive with progress tracking
- [[Project-Status/Current-TODO|Current TODO]] - Current project priorities
- [[Architecture/MVVM-Patterns|MVVM Patterns]]
