---
title: "System Flows"
description: "Internal system processes and data flows"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - flows
  - architecture
  - system-design
  - internal-processes
---

[Home](/) > [Technical Reference](../../) > [Flows](../) > System Flows

---

# System Flows

Complete reference for internal system processes, state management, and data flows in Archery Apprentice.

## Overview

System flows describe the internal processes that power the application, from state management and data persistence to background processing and error handling. This guide documents all major system-level workflows.

**Flow Organization:**

Flows are organized by system architectural concern:

1. **State Management** - Reactive state propagation, StateFlow patterns
2. **Data Persistence** - Database operations, caching, versioning
3. **Background Processing** - Async operations, coroutines, sync
4. **Error Handling** - Error propagation, recovery, validation
5. **Lifecycle Management** - Component lifecycles, state preservation

**Related Documentation:**

- [User Flows](../User-Flows/) - User-facing workflows and interactions
- [Integration Flows](../Integration-Flows/) - External service integrations
- [System Architecture](../../../developer-guide/architecture/system-architecture/) - Overall architecture patterns
- [MVVM Patterns](../../../developer-guide/architecture/mvvm-patterns/) - State management architecture

---

## State Management Flows

Flows related to reactive state management and UI updates.

### 1. StateFlow Propagation Pattern

**Status:** ✅ Documented (demonstrated across multiple flows)
**Documentation:** See [Settings Architecture](../../../../developer-guide/technical-reference/flows/settings-architecture/) for canonical example

**Overview:**

All state changes in Archery Apprentice follow a unidirectional data flow pattern using Kotlin StateFlow for reactive updates.

**Flow Pattern:**

```
User Action → ViewModel Method → Repository Update → Database/Cache Write →
StateFlow Emission → UI Observes StateFlow → Recomposition
```

**Key Principles:**

1. **Single Source of Truth** - Database or repository cache is authoritative
2. **Unidirectional Flow** - Data flows from repository → ViewModel → UI
3. **Reactive Updates** - UI observes StateFlow, recomposes automatically
4. **Immutable State** - State objects are immutable, updates create new instances
5. **No Direct Mutation** - UI never mutates state directly, only emits events

**Example: Settings State Propagation**

```
User Changes Measurement System (UI) →
SettingsViewModel.updateMeasurementSystem() →
SettingsRepository.updateSettings() →
SettingsDao.update() (Room database) →
settingsFlow.emit(newSettings) (StateFlow) →
All UI Consumers Observe settingsFlow →
UI Recomposes with New Measurement System
```

**StateFlow vs LiveData:**

- **StateFlow** - Preferred for new code, Kotlin-native, coroutines integration
- **LiveData** - Legacy code only, being migrated to StateFlow
- **Migration Pattern** - Replace LiveData with StateFlow + `.asLiveData()` for compatibility

**Typical StateFlow Declaration:**

```kotlin
class SomeViewModel : ViewModel() {
    private val _state = MutableStateFlow<UiState>(UiState.Loading)
    val state: StateFlow<UiState> = _state.asStateFlow()

    fun updateState(newData: Data) {
        _state.value = UiState.Success(newData)
    }
}
```

**See Also:**
- [Settings Architecture](../../../../developer-guide/technical-reference/flows/settings-architecture/) - Canonical StateFlow example
- [Scoring Flow](../../../../developer-guide/technical-reference/flows/scoring-flow/) - Complex StateFlow with multi-participant state
- [MVVM Patterns](../../../developer-guide/architecture/mvvm-patterns/) - Architecture overview

---

### 2. State Composition and Derivation

**Status:** ⚠️ Partially Documented (scattered across flows)
**Documentation:** Examples in Scoring Flow and Round Lifecycle Flow

**Overview:**

Complex UI state is often derived from multiple StateFlows using `combine()` or computed properties.

**Combination Pattern:**

```kotlin
val combinedState = combine(
    roundFlow,
    equipmentFlow,
    participantsFlow
) { round, equipment, participants ->
    ScoringScreenState(
        round = round,
        equipment = equipment,
        participants = participants
    )
}.stateIn(
    scope = viewModelScope,
    started = SharingStarted.WhileSubscribed(5000),
    initialValue = ScoringScreenState.Loading
)
```

**Key Patterns:**

1. **combine()** - Merge multiple StateFlows into one derived state
2. **map()** - Transform StateFlow values
3. **flatMapLatest()** - Switch to new StateFlow based on upstream value
4. **distinctUntilChanged()** - Only emit when value actually changes
5. **stateIn()** - Convert Flow to StateFlow with lifecycle management

**State Sharing Strategies:**

- **WhileSubscribed(5000)** - Most common, stops upstream after 5 seconds of no subscribers
- **Eagerly** - Start immediately, never stop (use sparingly, memory leak risk)
- **Lazily** - Start when first subscriber collects, never stop

**Example: Scoring Session State Derivation**

```kotlin
val scoringSessionState = combine(
    currentEndFlow,
    arrowScoresFlow,
    tournamentSyncStatusFlow
) { currentEnd, arrows, syncStatus ->
    ScoringSessionState(
        endNumber = currentEnd.number,
        totalArrows = arrows.size,
        isEndComplete = arrows.size == currentEnd.maxArrows,
        syncStatus = syncStatus
    )
}.stateIn(viewModelScope, WhileSubscribed(5000), ScoringSessionState.Initial)
```

**See Also:**
- [Scoring Flow](../../../../developer-guide/technical-reference/flows/scoring-flow/) - Multi-state composition examples
- [Round Lifecycle Flow](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/) - State derivation for round status

---

### 3. State Persistence Across Configuration Changes

**Status:** ✅ Documented (MVVM architecture inherent)
**Documentation:** [MVVM Patterns](../../../developer-guide/architecture/mvvm-patterns/)

**Overview:**

ViewModels survive configuration changes (rotation, dark mode toggle), preserving state automatically.

**Persistence Pattern:**

```
Activity Created → ViewModel Created → State Initialized →
Configuration Change (Rotation) → Activity Destroyed/Recreated →
ViewModel Survives → State Preserved → UI Recomposes with Existing State
```

**What Survives:**

- ViewModel instances (scoped to Activity/Fragment lifecycle)
- StateFlow state (stored in ViewModel)
- Cached data in repositories (in-memory caches)
- Database data (persisted to disk)

**What Doesn't Survive:**

- Activity/Fragment instances (recreated)
- View state (unless saved via SavedStateHandle)
- Non-ViewModel objects (unless explicitly saved)

**SavedStateHandle Pattern:**

For state that must survive process death (e.g., low memory kill):

```kotlin
class SomeViewModel(
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {
    var tempState: String
        get() = savedStateHandle.get<String>("temp_state") ?: ""
        set(value) = savedStateHandle.set("temp_state", value)
}
```

**See Also:**
- [MVVM Patterns](../../../developer-guide/architecture/mvvm-patterns/) - ViewModel lifecycle documentation
- Android ViewModel documentation (survives configuration changes)

---

## Data Persistence Flows

Flows related to database operations, caching, and data versioning.

### 4. Data Persistence Pattern (Repository → DAO → Room)

**Status:** ✅ Fully Documented (demonstrated across all flows)
**Documentation:** See all flow docs, especially [Round Lifecycle Flow](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/)

**Overview:**

All data persistence follows the Repository pattern with Room database as the single source of truth.

**Persistence Flow:**

```
ViewModel → Repository → DAO → Room Database → SQLite
```

**Write Flow:**

```kotlin
// ViewModel
fun saveRound(round: Round) = viewModelScope.launch {
    repository.saveRound(round)
}

// Repository
suspend fun saveRound(round: Round): SaveResult {
    return try {
        dao.insert(round)
        SaveResult.Success
    } catch (e: Exception) {
        SaveResult.Error(e.message)
    }
}

// DAO (Room)
@Insert(onConflict = OnConflictStrategy.REPLACE)
suspend fun insert(round: Round): Long
```

**Read Flow:**

```kotlin
// Repository exposes Flow from DAO
fun observeRounds(): Flow<List<Round>> = dao.getAllRounds()

// ViewModel converts to StateFlow
val rounds = repository.observeRounds()
    .stateIn(viewModelScope, WhileSubscribed(5000), emptyList())

// UI observes StateFlow
val rounds by viewModel.rounds.collectAsState()
```

**Key Patterns:**

1. **Flow-Based Queries** - DAOs return Flow<T>, automatically update on DB changes
2. **Suspend Functions** - All write operations are suspend functions
3. **Transaction Support** - Use `@Transaction` for multi-table operations
4. **Conflict Strategies** - REPLACE, IGNORE, ABORT for insert conflicts
5. **Foreign Key Cascades** - CASCADE DELETE, SET NULL for referential integrity

**SaveResult Pattern:**

Consistent error handling across all repositories:

```kotlin
sealed class SaveResult {
    object Success : SaveResult()
    data class Error(val message: String?) : SaveResult()
}
```

**See Also:**
- [Database Tables](../../Database/Tables/) - Complete schema reference
- [Database Overview](../../Database/) - Room architecture documentation
- [Data Models](../../Data-Models/) - Entity model documentation

---

### 5. Equipment Versioning Flow

**Status:** ✅ Fully Documented (1,949 lines)
**Documentation:** [Equipment Management End-to-End Flow](../../../../developer-guide/technical-reference/flows/equipment-management-end-to-end-flow/)

**Overview:**

Equipment modifications create new versions to preserve historical accuracy for past rounds.

**Versioning Flow:**

```
BowSetup v1 Created → Round 1 Uses v1 Snapshot →
User Edits BowSetup → v2 Created → Round 2 Uses v2 Snapshot →
Round 1 Still References v1 Snapshot (Historical Accuracy Preserved)
```

**Key Mechanisms:**

1. **Version Counter** - `bowSetupVersion` column incremented on modification
2. **Snapshot Embedding** - Round embeds complete equipment snapshot (JSON)
3. **Historical Immutability** - Past rounds never affected by equipment changes
4. **Current Version Tracking** - Latest version used for new rounds

**Versioning Trigger:**

Any equipment modification creates new version:
- Add/remove/edit component
- Change bow type
- Update bow setup name
- Modify component properties

**See Full Documentation:** [Equipment Management End-to-End Flow](../../../../developer-guide/technical-reference/flows/equipment-management-end-to-end-flow/)

---

### 6. Round Status State Machine

**Status:** ✅ Fully Documented (1,168 lines)
**Documentation:** [Round Lifecycle Flow](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/)

**Overview:**

Round lifecycle is governed by a strict state machine with validation at each transition.

**State Machine:**

```
PLANNED → IN_PROGRESS ⇄ PAUSED → COMPLETED
                                → CANCELLED
```

**State Transitions:**

| From         | To          | Trigger                  | Validation                                   |
|--------------|-------------|--------------------------|----------------------------------------------|
| PLANNED      | IN_PROGRESS | User clicks "Start"      | All participants have equipment selected     |
| IN_PROGRESS  | PAUSED      | User clicks "Pause"      | None                                         |
| PAUSED       | IN_PROGRESS | User clicks "Resume"     | None                                         |
| IN_PROGRESS  | COMPLETED   | All ends completed       | All arrows scored, all ends finalized        |
| IN_PROGRESS  | CANCELLED   | User cancels round       | Confirmation prompt                          |
| PLANNED      | CANCELLED   | User deletes draft       | Confirmation prompt                          |

**Invalid Transitions:**

- COMPLETED → Any (completed rounds are immutable)
- CANCELLED → Any (cancelled rounds cannot be resumed)
- PLANNED → PAUSED (can't pause before starting)

**Validation Logic:**

```kotlin
fun canTransitionTo(newStatus: RoundStatus): Boolean {
    return when (currentStatus) {
        PLANNED -> newStatus == IN_PROGRESS || newStatus == CANCELLED
        IN_PROGRESS -> newStatus == PAUSED || newStatus == COMPLETED || newStatus == CANCELLED
        PAUSED -> newStatus == IN_PROGRESS || newStatus == CANCELLED
        COMPLETED, CANCELLED -> false // Terminal states
    }
}
```

**See Full Documentation:** [Round Lifecycle Flow](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/)

---

### 7. Caching Strategy

**Status:** ✅ Fully Documented (1,399 lines)
**Documentation:** [Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/)

**Overview:**

Smart caching with TTL (Time-To-Live) reduces database queries and Firebase network calls.

**Caching Layers:**

1. **In-Memory Cache** - ViewModel/Repository level, short-lived
2. **Room Database** - Local persistent cache, offline-first source of truth
3. **Firebase Cache** - Remote data cache, TTL-based invalidation

**Cache Read Flow:**

```
Request Data → Check In-Memory Cache (valid?) → Check Room Database →
Check Firebase (if network) → Update Caches → Return Data
```

**Cache Write Flow:**

```
Write Data → Update In-Memory Cache → Write to Room Database →
Write to Firebase (Async) → Invalidate Related Caches
```

**TTL Strategy:**

| Data Type               | TTL      | Rationale                                           |
|-------------------------|----------|-----------------------------------------------------|
| Tournament Leaderboard  | 5 min    | Balance real-time updates vs network load           |
| Equipment Stats         | 5 min    | Infrequently changing, expensive to recalculate     |
| Historical Rounds       | 1 week   | Immutable after completion, safe to cache long-term |
| Active Round State      | No cache | Always reflect latest state, no staleness tolerated |
| Settings                | No cache | Single-row, StateFlow updates immediately           |

**Cache Invalidation:**

- **Explicit** - After mutations (insert, update, delete)
- **Time-Based** - TTL expiration (5 minutes, 1 week)
- **Event-Based** - Firebase listeners trigger invalidation

**Example: Tournament Leaderboard Cache**

```kotlin
class TournamentScoreCacheService {
    private val cache = mutableMapOf<String, CachedLeaderboard>()
    private val TTL = 5.minutes

    suspend fun getLeaderboard(tournamentId: String): List<Score> {
        val cached = cache[tournamentId]
        if (cached != null && !cached.isExpired()) {
            return cached.data
        }

        val fresh = firebaseRepository.getLeaderboard(tournamentId)
        cache[tournamentId] = CachedLeaderboard(fresh, Clock.System.now())
        return fresh
    }

    fun invalidate(tournamentId: String) {
        cache.remove(tournamentId)
    }
}
```

**See Full Documentation:** [Data Sync Flow - Caching Strategy](../../../../developer-guide/technical-reference/flows/data-sync-flow/#caching-strategy)

---

## Background Processing Flows

Flows related to asynchronous operations, coroutines, and background sync.

### 8. Coroutine Patterns

**Status:** ✅ Documented (demonstrated across all flows)
**Documentation:** Examples in all flow documentation

**Overview:**

All async operations use Kotlin coroutines with structured concurrency.

**Coroutine Scopes:**

1. **viewModelScope** - Tied to ViewModel lifecycle, most common
2. **lifecycleScope** - Tied to Activity/Fragment lifecycle
3. **GlobalScope** - Avoid! Use viewModelScope instead

**Dispatchers:**

1. **Dispatchers.Main** - UI updates, StateFlow emissions (default for viewModelScope)
2. **Dispatchers.IO** - Database, network, file I/O
3. **Dispatchers.Default** - CPU-intensive computations

**Common Patterns:**

**1. Launch and Forget:**
```kotlin
viewModelScope.launch {
    repository.saveData(data) // Async, non-blocking
}
```

**2. Async with Result:**
```kotlin
viewModelScope.launch {
    val result = withContext(Dispatchers.IO) {
        repository.fetchData()
    }
    _state.value = UiState.Success(result)
}
```

**3. Parallel Operations:**
```kotlin
viewModelScope.launch {
    val deferred1 = async { repository.fetchA() }
    val deferred2 = async { repository.fetchB() }
    val combined = deferred1.await() + deferred2.await()
}
```

**4. Error Handling:**
```kotlin
viewModelScope.launch {
    try {
        repository.riskyOperation()
    } catch (e: Exception) {
        _error.value = e.message
    }
}
```

**See Also:**
- Kotlin Coroutines documentation
- All flow docs for practical coroutine examples

---

### 9. Tournament Sync with Exponential Backoff

**Status:** ✅ Fully Documented (1,399 lines)
**Documentation:** [Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/)

**Overview:**

Async tournament score submission with exponential backoff retry handles transient network failures gracefully.

**Sync Flow:**

```
End Completed → Save to Local DB → Emit Success to UI (Immediate) →
Background: Submit to Firebase (Async) → Network Error? →
Retry 1 (1s delay) → Retry 2 (2s delay) → Retry 3 (4s delay) →
Retry 4 (8s delay) → Retry 5 (16s delay) → Give Up (Log Error)
```

**Exponential Backoff Algorithm:**

```kotlin
suspend fun submitScoreWithRetry(score: Score, maxRetries: Int = 5): Result {
    var attempt = 0
    var delay = 1000L // Start with 1 second

    while (attempt < maxRetries) {
        try {
            firebaseRepository.submitScore(score)
            return Result.Success
        } catch (e: Exception) {
            attempt++
            if (attempt >= maxRetries) {
                return Result.Failure(e)
            }
            delay(delay)
            delay *= 2 // Exponential backoff
        }
    }
}
```

**Key Features:**

1. **Non-Blocking** - User can continue scoring while sync happens in background
2. **Exponential Backoff** - Delays: 1s, 2s, 4s, 8s, 16s (up to 5 retries)
3. **Offline-First** - Local DB updated immediately, Firebase sync happens async
4. **Conflict Detection** - Last-write-wins with timestamp-based conflict resolution
5. **Error Notification** - User notified if sync ultimately fails after all retries

**See Full Documentation:** [Data Sync Flow - Retry Logic](../../../../developer-guide/technical-reference/flows/data-sync-flow/#retry-logic)

---

### 10. Statistics Calculation Flow

**Status:** ✅ Documented (part of Scoring Flow)
**Documentation:** [Scoring Flow - Statistics Calculation](../../../../developer-guide/technical-reference/flows/scoring-flow/#statistics-calculation)

**Overview:**

Statistics aggregated at multiple levels: arrow → end → round → equipment → all-time.

**Calculation Hierarchy:**

```
Arrow Scores → End Statistics (total, average, highs, lows) →
Round Statistics (total, average, consistency, highs, lows) →
Equipment Statistics (average by distance, round count, performance) →
All-Time Statistics (personal bests, trends, comparisons)
```

**End Statistics Calculation:**

```kotlin
fun calculateEndStats(arrows: List<Arrow>): EndStats {
    return EndStats(
        total = arrows.sumOf { it.score },
        average = arrows.map { it.score }.average(),
        max = arrows.maxOf { it.score },
        min = arrows.minOf { it.score },
        xCount = arrows.count { it.score == 10 && it.isX }
    )
}
```

**Round Statistics Calculation:**

```kotlin
fun calculateRoundStats(ends: List<End>): RoundStats {
    val allArrows = ends.flatMap { it.arrows }
    return RoundStats(
        total = ends.sumOf { it.total },
        average = ends.map { it.average }.average(),
        consistency = calculateStandardDeviation(ends.map { it.total }),
        maxEnd = ends.maxOf { it.total },
        minEnd = ends.minOf { it.total },
        xCount = allArrows.count { it.isX }
    )
}
```

**Calculation Trigger:**

- **End Completion** - End statistics calculated and saved
- **Round Completion** - Round statistics calculated and saved
- **On-Demand** - Equipment/all-time statistics calculated when viewed (cached)

**Performance Optimization:**

- End/Round stats pre-calculated and stored (not recomputed)
- Equipment stats cached for 5 minutes
- Database indexes on scoring fields for fast aggregation queries

**See Full Documentation:** [Scoring Flow - Statistics Calculation](../../../../developer-guide/technical-reference/flows/scoring-flow/#statistics-calculation)

---

## Error Handling Flows

Flows related to error propagation, recovery, and user feedback.

### 11. Validation Flow

**Status:** ✅ Documented (demonstrated across flows)
**Documentation:** Examples in Scoring Flow and Round Lifecycle Flow

**Overview:**

Multi-level validation ensures data integrity: UI → ViewModel → Repository → Database.

**Validation Layers:**

1. **UI Validation** - Client-side input validation (TextField, Button enabled/disabled)
2. **ViewModel Validation** - Business logic validation before repository call
3. **Repository Validation** - Pre-database checks, authorization
4. **Database Validation** - Constraints, foreign keys, NOT NULL checks

**Example: End Completion Validation**

```kotlin
// UI Layer - Button enabled only when valid
Button(
    onClick = { viewModel.completeEnd() },
    enabled = allArrowsScored && !isProcessing
)

// ViewModel Layer - Business logic validation
fun completeEnd() {
    if (!allArrowsScored()) {
        _error.value = "All arrows must be scored before completing end"
        return
    }

    viewModelScope.launch {
        val result = repository.completeEnd(currentEnd)
        when (result) {
            is SaveResult.Success -> _state.value = UiState.Success
            is SaveResult.Error -> _error.value = result.message
        }
    }
}

// Repository Layer - Authorization check
suspend fun completeEnd(end: End): SaveResult {
    if (!hasPermission(end.roundId)) {
        return SaveResult.Error("No permission to score in this round")
    }
    return dao.updateEnd(end)
}

// Database Layer - Constraints enforced
@Entity(
    foreignKeys = [ForeignKey(
        entity = Round::class,
        parentColumns = ["id"],
        childColumns = ["roundId"],
        onDelete = CASCADE
    )]
)
data class End(
    @ColumnInfo(name = "roundId") val roundId: Long,
    @ColumnInfo(name = "endNumber") val endNumber: Int
    // Round must exist, otherwise foreign key violation
)
```

**Validation Result Patterns:**

```kotlin
sealed class ValidationResult {
    object Valid : ValidationResult()
    data class Invalid(val errors: List<String>) : ValidationResult()
}
```

**See Also:**
- [Scoring Flow](../../../../developer-guide/technical-reference/flows/scoring-flow/) - End completion validation
- [Round Lifecycle Flow](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/) - Round status validation

---

### 12. Error Propagation and Recovery

**Status:** ⚠️ Partially Documented (scattered across flows)
**Documentation:** Examples in Data Sync Flow

**Overview:**

Errors propagate from lowest layer to UI with appropriate recovery strategies at each level.

**Error Flow:**

```
Database Error → Repository Catches → Returns SaveResult.Error →
ViewModel Handles → Updates Error StateFlow → UI Observes → Shows Error Message
```

**Error Categories:**

1. **Validation Errors** - User input errors, show inline error messages
2. **Database Errors** - Constraint violations, foreign key errors, show toast/snackbar
3. **Network Errors** - Firebase timeouts, connectivity loss, retry automatically
4. **Conflict Errors** - Tournament score conflicts, resolve automatically or notify user
5. **Permission Errors** - Unauthorized operations, show error dialog

**Recovery Strategies:**

| Error Type        | Strategy                                      |
|-------------------|-----------------------------------------------|
| Validation        | Show inline error, disable submit button      |
| Database          | Show error toast, allow user to retry         |
| Network (transient) | Retry with exponential backoff (up to 5 times) |
| Network (persistent) | Show offline mode, queue for later sync       |
| Conflict          | Automatic last-write-wins resolution          |
| Permission        | Show error dialog, navigate back              |

**Example: Network Error with Retry**

```kotlin
suspend fun syncScores() {
    var attempt = 0
    val maxRetries = 5

    while (attempt < maxRetries) {
        try {
            firebaseRepository.syncScores()
            _syncStatus.value = SyncStatus.Success
            return
        } catch (e: IOException) {
            attempt++
            if (attempt >= maxRetries) {
                _syncStatus.value = SyncStatus.Failed(e.message)
                return
            }
            delay(2.0.pow(attempt).toLong() * 1000) // Exponential backoff
        }
    }
}
```

**User-Facing Error Messages:**

- **Validation** - "All arrows must be scored" (specific, actionable)
- **Database** - "Failed to save round. Please try again." (generic, retry)
- **Network** - "Unable to sync scores. Will retry automatically." (informational, automatic recovery)
- **Permission** - "You don't have permission to score in this tournament." (clear, blocking)

**See Also:**
- [Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/) - Network error handling and retry
- [Scoring Flow](../../../../developer-guide/technical-reference/flows/scoring-flow/) - Validation error handling

---

## Lifecycle Management Flows

Flows related to Android component lifecycles and state preservation.

### 13. ViewModel Lifecycle

**Status:** ✅ Documented (MVVM patterns)
**Documentation:** [MVVM Patterns](../../../developer-guide/architecture/mvvm-patterns/)

**Overview:**

ViewModels survive configuration changes and are cleared when Activity/Fragment is finished.

**Lifecycle Flow:**

```
Activity Created → ViewModel Created (via ViewModelProvider) →
Activity Destroyed (Config Change) → ViewModel Survives →
Activity Recreated → ViewModel Reattached →
Activity Finished → ViewModel.onCleared() → Resources Cleaned Up
```

**ViewModel Cleanup:**

```kotlin
class SomeViewModel : ViewModel() {
    private val disposables = CompositeDisposable()

    override fun onCleared() {
        super.onCleared()
        // Clean up resources
        disposables.clear()
        // Cancel coroutines (viewModelScope automatically cancelled)
    }
}
```

**viewModelScope:**

- Automatically cancelled when `onCleared()` is called
- All launched coroutines are cancelled
- No manual cleanup needed for coroutines

**See Full Documentation:** [MVVM Patterns](../../../developer-guide/architecture/mvvm-patterns/)

---

### 14. Navigation Patterns

**Status:** ⚠️ Not Documented (High Priority)
**Planned Documentation:** To be created

**Overview:**

Jetpack Compose Navigation with bottom navigation and deep linking support.

**High-Level Flow (Not Yet Documented):**

1. **Bottom Navigation** - Primary navigation for main sections (Rounds, Equipment, Analytics, Tournaments, Settings)
2. **Back Stack Management** - Standard Android back button behavior, state preserved
3. **Deep Linking** - Direct navigation to specific screens (round detail, equipment detail)
4. **Cross-Feature Navigation** - Equipment → Rounds, Rounds → Analytics, etc.
5. **State Restoration** - Navigation state survives configuration changes

**Key Components (Identified but Not Documented):**

- NavHost setup (Compose Navigation)
- NavGraph definition (navigation routes)
- BottomNavigationBar (tab navigation)
- Deep link handlers (URL schemes)

**Why Not Documented:**

Navigation patterns are complex and span the entire application. This is identified as **High Priority** for future documentation as it's foundational for understanding application structure.

---

## Related Documentation

- **[User Flows](../User-Flows/)** - User-facing workflows and interactions
- **[Integration Flows](../Integration-Flows/)** - External service integrations (Firebase, exports)
- **[System Architecture](../../../developer-guide/architecture/system-architecture/)** - Overall architecture patterns
- **[MVVM Patterns](../../../developer-guide/architecture/mvvm-patterns/)** - State management architecture
- **[Database Overview](../../Database/)** - Data persistence and schemas
- **[Data Models](../../Data-Models/)** - Entity models and relationships

---

## Contributing System Flow Documentation

To add or improve system flow documentation:

1. **Trace the Flow** - Follow code execution from entry to completion
2. **Document State Changes** - Track StateFlow emissions and state transitions
3. **Identify Decision Points** - Where does the system branch based on conditions?
4. **Document Error Paths** - What happens when operations fail?
5. **Add Performance Notes** - Caching, optimization strategies
6. **Cross-Reference** - Link to related flows, architecture, and database docs
7. **Include Code Examples** - Show actual implementation patterns

**System Flow Checklist:**

- [ ] High-level flow diagram (Mermaid)
- [ ] Step-by-step code execution with file paths
- [ ] State transitions and StateFlow emissions
- [ ] Error handling and recovery strategies
- [ ] Performance considerations (caching, optimization)
- [ ] Related flows and components
- [ ] Code examples with file paths and line numbers
- [ ] Testing strategies and examples

---

**Last Updated:** 2025-11-04
**Documentation Coverage:** 10 flows documented (8,647 total lines from related docs), 4 flows planned
