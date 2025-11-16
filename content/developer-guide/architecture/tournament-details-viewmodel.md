# TournamentDetailsViewModel

## Overview

**Location:** `app/src/main/java/com/archeryapprentice/ui/tournament/TournamentDetailsViewModel.kt`
**Discovered:** 2025-11-15 (Audit verification session)
**Status:** 🔴 God class - extraction planned

### Metrics
- **Lines:** 1,421
- **Methods:** 35
- **Responsibilities:** 9+
- **Test Coverage:** Existing (2,841 line test file)

## God Class Ranking

**Position:** #4 largest file in codebase

| Rank | File | Lines | Methods | Status |
|------|------|-------|---------|--------|
| 1 | FirebaseTournamentRepository | 1,909 | 48 | Assessment deferred |
| 2 | RoundViewModel | 1,508 | 81 | Test coverage enhanced |
| 3 | LiveScoringViewModel | 1,500 | 59 | Extraction in progress |
| **4** | **TournamentDetailsViewModel** | **1,421** | **35** | **Extraction planned** |
| 5 | ActiveScoringScreen | 1,289 | 38 | Monitoring |

## Responsibilities

TournamentDetailsViewModel manages 9 distinct areas of functionality:

### 1. User Identity & Authentication (~130 lines)
- User ID resolution (authenticated vs anonymous)
- Creator verification (multi-case logic)
- Device ID tracking for anonymous creators
- Current user state management

**Key Methods:**
- `resolveUserIdentity()`
- `checkIsCreator()` (complex, 60+ lines)
- `getDeviceId()`
- `isCreatedOnThisDevice()`
- `isUserAnonymous()`

### 2. Tournament Lifecycle Management (~90 lines)
- Tournament start/end operations
- Tournament deletion
- Tournament cancellation
- Creator-only action enforcement

**Key Methods:**
- `startTournament()`
- `endTournament()`
- `deleteTournament()`
- `cancelTournament()`

### 3. Participant Management (~300 lines)
- Participant loading and display
- Join tournament workflow with async sync
- Leave tournament functionality
- Remove participant (with permissions)
- Guest participant creation with validation
- Join status monitoring and retry logic

**Key Methods:**
- `loadParticipants()`
- `joinTournament()` (60+ lines, complex async)
- `retryJoinSync()` (async join retry)
- `leaveTournament()`
- `removeParticipant()` (80+ lines, permissions)
- `addGuestParticipant()` (90+ lines, validation)

**Complex Logic:**
- Guest limit validation (per participant, total)
- Permission checks (creator vs guest host)
- Async join status observer
- User identity resolution for participants

### 4. Scoring Round Management (~280 lines)
- Scoring round creation from tournament
- Participant conversion (Tournament → Session)
- Round continuation after pause
- Existing round detection
- Navigation to scoring screen

**Key Methods:**
- `startScoringRound()` (massive, 245+ lines)
- `continueScoring()`
- `checkForExistingRound()`
- `createRoundFromTournamentRound()` (conversion, 35+ lines)

**Complex Logic:**
- Convert TournamentParticipants to SessionParticipants
- Guest vs NetworkUser vs LocalUser determination
- Round number calculation
- Bow setup creation/selection
- Distance/TargetSize enum conversion

### 5. Equipment/Bow Setup Management (~30 lines)
- Available bow setups loading
- Bow setup selector UI state
- Bow setup selection for rounds

**Key Methods:**
- `loadAvailableBowSetups()`
- `showBowSetupSelector()`
- `selectBowSetup()`

### 6. Settings Management (~100 lines)
- Tournament settings dialog
- Settings loading from tournament
- Settings updates and persistence

**Key Methods:**
- `showSettingsDialog()` (complex, loads settings)
- `hideSettingsDialog()`
- `updateTournamentSettings()` (50+ lines)

### 7. Real-time Updates & Sync (~100 lines)
- Tournament observation (real-time changes)
- Join status monitoring
- Network connectivity awareness
- Refresh coordination

**Key Methods:**
- `setupRealTimeUpdates()` (observes tournament)
- `setupJoinStatusObserver()` (async join status)
- `refreshTournament()`

### 8. Tournament Data Loading (~50 lines)
- Tournament details fetching
- Refresh operations
- Error handling

**Key Methods:**
- `loadTournamentDetails()`
- `refreshTournamentDetails()`

### 9. UI State Management (~10 lines)
- Centralized UI state flow
- Error/success message management
- Navigation event coordination

**StateFlow:** `TournamentDetailsUiState` (17 properties)

## Severity Assessment

**Score:** 7/10 - High complexity warranting extraction

### High Severity Factors (+)
- Large size (1,421 lines)
- Multiple responsibilities (9 areas)
- Complex participant mapping logic
- Async sync complexity (join status, retry)
- Mixed concerns (UI state + business logic + coordination)

### Mitigating Factors (-)
- Better structured than RoundViewModel
- Good use of StateFlows (not excessive)
- Most methods are focused (only 2-3 "mega methods")
- Clear repository delegation
- Decent test coverage exists (2,841 line test file)

### Compared to Other God Classes

**More severe than:** ActiveScoringScreen (UI file, size more acceptable)
**Less severe than:** RoundViewModel (more methods, deeper nesting)
**Similar to:** LiveScoringViewModel (similar size, successful extractions)

## Extraction Plan

Four service candidates identified with estimated 40-55% size reduction.

### Candidate 1: ParticipantManagementService
**Lines to Extract:** ~300
**Effort:** 1 week (most complex)
**Complexity:** High (async sync, guest logic)

**Responsibilities:**
- Join/leave tournament workflows
- Guest participant management
- Permission checks and validation
- Async join status monitoring

**Benefits:**
- Isolates async sync complexity
- Reusable guest management logic
- Better testing of permission boundaries
- Clearer join/leave state machine

### Candidate 2: ScoringRoundService
**Lines to Extract:** ~280
**Effort:** 1 week
**Complexity:** High (participant conversion)

**Responsibilities:**
- Round creation from tournament
- Participant type conversion logic
- Round number calculation
- Navigation coordination

**Benefits:**
- Isolates participant mapping complexity
- Testable conversion logic in isolation
- Reusable for other tournament round operations
- Clearer navigation flow

### Candidate 3: UserIdentityService
**Lines to Extract:** ~130
**Effort:** 1-2 days
**Complexity:** Medium

**Responsibilities:**
- User identity resolution
- Creator verification
- Device ID management
- Anonymous user handling

**Benefits:**
- Reusable across ViewModels (LiveScoringVM, CreateTournamentVM)
- Testable in isolation (mock device ID, auth states)
- Clearer separation of auth concerns

### Candidate 4: TournamentSettingsService
**Lines to Extract:** ~100
**Effort:** 2-3 days
**Complexity:** Medium

**Responsibilities:**
- Settings dialog management
- Settings CRUD operations
- Tournament configuration updates

**Benefits:**
- Isolates admin/creator operations
- Reusable settings logic
- Clearer permission boundaries

## Extraction Roadmap

### Recommended Sequence

**Week 1:** UserIdentityService
- Low risk, high reusability
- Clear boundaries
- Good starting point

**Week 2:** TournamentSettingsService
- Low risk, admin-focused
- Clear separation

**Weeks 3-4:** ParticipantManagementService
- High value, complex
- Isolates async complexity
- Most impactful extraction

**Weeks 5-6:** ScoringRoundService
- High value, complex
- Completes major extractions

**Week 7:** Integration & Testing
- Ensure services work together
- Update test suite
- Performance validation

### Alternative: Incremental Approach

If full 7-week effort is too much:

**Minimal Viable Extraction (Weeks 1-2):**
- Extract UserIdentityService only (2 days, ~130 lines)
- Extract TournamentSettingsService only (3 days, ~100 lines)
- Result: 16% reduction, 4-5 days effort

**Benefit:** Quick wins, reusable services, lower risk

### Expected Outcome

**Final State:**
- TournamentDetailsViewModel: ~600-650 lines (55% reduction)
- 4 new services: ~810 lines total
- Test coverage: ~1,100 new test lines
- Net gain: Better testability, clearer responsibilities

## Lessons from LiveScoringViewModel

LiveScoringViewModel underwent similar extraction:
- **Before:** 2,808 lines
- **After:** 1,500 lines (47% reduction)
- **Services Extracted:** 5 (TournamentSyncService, ScoreConflictResolutionService, etc.)

**What Worked:**
- Incremental extraction (5 services over time)
- Starting with smallest responsibility
- Comprehensive test coverage for each service
- Clear StateFlow ownership (service owns, ViewModel observes)

**What to Avoid:**
- Extracting too much at once (increases risk)
- Circular dependencies between services
- Ownership confusion (StateFlows in both ViewModel and service)

**Apply to TournamentDetailsViewModel:**
- Start with UserIdentityService (smallest, clearest)
- Test each extraction independently
- Clear ownership boundaries
- Incremental approach (can stop after 1-2 if needed)

## Success Criteria

### Extraction Metrics
- ✅ TournamentDetailsViewModel reduced to <700 lines (50%+ reduction)
- ✅ All extracted services <300 lines
- ✅ All methods <50 lines
- ✅ Cyclomatic complexity <10 per method

### Quality Metrics
- ✅ Test coverage maintained or improved (>80%)
- ✅ No behavioral regressions
- ✅ Performance maintained or improved
- ✅ No god classes in extracted services

## References

- **Analysis Source:** Agent 2 TournamentDetailsViewModel Extraction Analysis (2025-11-15)
- **File Location:** `app/src/main/java/com/archeryapprentice/ui/tournament/TournamentDetailsViewModel.kt:1-1421`
- **Test File:** `app/src/test/java/com/archeryapprentice/ui/tournament/TournamentDetailsViewModelTest.kt` (2,841 lines)
- **Related Screen:** `TournamentDetailsScreen.kt` (1,725 lines - UI)

## Related

- [[god-classes|God Class Index]]
- [[round-view-model-refactoring-plan|RoundViewModel Refactoring]]
- [[live-scoring-vm-analysis|LiveScoringViewModel Analysis]]
- [[service-extraction-pattern|Service Extraction Pattern]]
- [[mvvm-patterns|MVVM Patterns]]

## Tags

#god-class #viewmodel #refactoring #tournament #architecture #technical-debt
