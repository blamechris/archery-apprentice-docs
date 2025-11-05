---
title: "Code Examples"
description: "Common patterns, feature implementations, and test examples"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - code-examples
  - patterns
  - best-practices
  - snippets
---

[Home](/) > [Technical Reference](../) > Code Examples

---

# Code Examples

Practical code examples for common tasks and patterns used throughout Archery Apprentice.

## Overview

This guide provides copy-paste-ready code examples for implementing common patterns in Archery Apprentice. All examples are extracted from the actual codebase and follow established conventions.

**Example Categories:**

1. **Repository Pattern** - Data access layer implementations
2. **ViewModel Pattern** - State management and business logic
3. **Compose UI** - Common UI patterns and components
4. **Coroutines** - Async operations and flow patterns
5. **Firebase Integration** - Cloud sync and real-time listeners
6. **Testing** - Unit and integration test examples

**Related Documentation:**

- [System Flows](../Flows/System-Flows/) - State management and coroutine patterns
- [Integration Flows](../Flows/Integration-Flows/) - Firebase integration patterns
- [Performance Guidelines](../Performance/) - Optimization techniques
- [MVVM Patterns](../../developer-guide/architecture/mvvm-patterns/) - Architecture overview

---

## Repository Pattern Examples

Data access layer implementations following the Repository pattern.

### Basic Repository with Flow

**Pattern:** Repository exposes Flow<T> from DAO, automatically updates UI on database changes.

```kotlin
class RoundRepository(
    private val roundDao: RoundDao
) {
    // Expose Flow from DAO - UI observes and recomposes automatically
    fun observeRounds(status: RoundStatus): Flow<List<Round>> {
        return roundDao.observeRounds(status)
    }

    // Write operation returns Result type for error handling
    suspend fun saveRound(round: Round): SaveResult {
        return try {
            roundDao.insert(round)
            SaveResult.Success
        } catch (e: Exception) {
            SaveResult.Error(e.message)
        }
    }

    // Read operation (one-shot, not reactive)
    suspend fun getRound(id: Long): Round? {
        return roundDao.getById(id)
    }
}

// SaveResult sealed class for consistent error handling
sealed class SaveResult {
    object Success : SaveResult()
    data class Error(val message: String?) : SaveResult()
}
```

**Usage in ViewModel:**

```kotlin
class RoundViewModel(
    private val repository: RoundRepository
) : ViewModel() {
    // Convert Flow to StateFlow for Compose
    val rounds = repository.observeRounds(RoundStatus.COMPLETED)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun saveRound(round: Round) = viewModelScope.launch {
        when (val result = repository.saveRound(round)) {
            is SaveResult.Success -> _message.value = "Round saved"
            is SaveResult.Error -> _error.value = result.message
        }
    }
}
```

**See Also:**
- [Round Lifecycle Flow](../../developer-guide/technical-reference/flows/round-lifecycle-flow/) - Complete repository implementation
- [Database Tables](../Database/Tables/) - DAO definitions

---

### Hybrid Repository (Local + Firebase)

**Pattern:** Offline-first repository with Firebase sync for tournament data.

```kotlin
class HybridTournamentRepository(
    private val localDao: TournamentDao,
    private val firebaseRepo: FirebaseTournamentRepository,
    private val cacheService: TournamentScoreCacheService
) {
    // Read: Cache → Local DB → Firebase (if network available)
    suspend fun getTournament(id: String): Tournament {
        // 1. Check in-memory cache
        cacheService.get(id)?.let { return it }

        // 2. Check local database
        val local = localDao.getTournament(id)
        if (local != null && !local.isStale()) {
            cacheService.put(id, local)
            return local
        }

        // 3. Fetch from Firebase (if network available)
        if (networkAvailable) {
            val remote = firebaseRepo.getTournament(id)
            localDao.insert(remote) // Update local DB
            cacheService.put(id, remote)
            return remote
        }

        // 4. Offline mode: return stale local data or throw
        return local ?: throw OfflineException("No cached data available")
    }

    // Write: Local DB (immediate) → Firebase (async with retry)
    suspend fun submitScore(score: Score) {
        // Update local DB first (source of truth)
        localDao.insertScore(score)

        // Sync to Firebase asynchronously (doesn't block UI)
        viewModelScope.launch {
            submitScoreWithRetry(score, maxRetries = 5)
        }
    }

    private suspend fun submitScoreWithRetry(score: Score, maxRetries: Int): Result {
        var attempt = 0
        var delay = 1000L

        while (attempt < maxRetries) {
            try {
                firebaseRepo.submitScore(score)
                return Result.Success
            } catch (e: IOException) {
                attempt++
                if (attempt >= maxRetries) return Result.Failure(e)
                delay(delay)
                delay *= 2 // Exponential backoff: 1s, 2s, 4s, 8s, 16s
            }
        }
    }
}
```

**See Also:**
- [Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/) - Complete hybrid repository implementation
- [Integration Flows](../Flows/Integration-Flows/) - Firebase integration patterns

---

## ViewModel Pattern Examples

State management and business logic patterns.

### Basic ViewModel with StateFlow

**Pattern:** ViewModel exposes immutable StateFlow<T> for UI observation.

```kotlin
class ScoringViewModel(
    private val repository: RoundRepository
) : ViewModel() {
    // Private mutable state (internal only)
    private val _state = MutableStateFlow<ScoringState>(ScoringState.Loading)

    // Public immutable state (exposed to UI)
    val state: StateFlow<ScoringState> = _state.asStateFlow()

    // Load data on init
    init {
        loadRoundData()
    }

    fun loadRoundData() = viewModelScope.launch {
        _state.value = ScoringState.Loading

        try {
            val round = repository.getRound(roundId)
            _state.value = ScoringState.Success(round)
        } catch (e: Exception) {
            _state.value = ScoringState.Error(e.message)
        }
    }

    fun scoreArrow(score: Int) {
        val currentState = _state.value
        if (currentState is ScoringState.Success) {
            _state.value = currentState.copy(
                arrowsScored = currentState.arrowsScored + 1,
                currentScore = currentState.currentScore + score
            )
        }
    }
}

// Sealed class for UI state
sealed class ScoringState {
    object Loading : ScoringState()
    data class Success(
        val round: Round,
        val arrowsScored: Int = 0,
        val currentScore: Int = 0
    ) : ScoringState()
    data class Error(val message: String?) : ScoringState()
}
```

**Usage in Compose:**

```kotlin
@Composable
fun ScoringScreen(viewModel: ScoringViewModel = viewModel()) {
    val state by viewModel.state.collectAsState()

    when (val currentState = state) {
        is ScoringState.Loading -> LoadingIndicator()
        is ScoringState.Success -> ScoringContent(
            round = currentState.round,
            score = currentState.currentScore,
            onArrowScored = { score -> viewModel.scoreArrow(score) }
        )
        is ScoringState.Error -> ErrorMessage(currentState.message)
    }
}
```

**See Also:**
- [Scoring Flow](../../developer-guide/technical-reference/flows/scoring-flow/) - Complete scoring ViewModel
- [System Flows - State Management](../Flows/System-Flows/#state-management-flows) - StateFlow patterns

---

### Combined StateFlows

**Pattern:** Combine multiple StateFlows into one derived state.

```kotlin
class RoundDetailViewModel(
    roundRepository: RoundRepository,
    equipmentRepository: BowSetupRepository,
    statsRepository: StatsRepository
) : ViewModel() {
    // Combine three separate flows into one composite state
    val screenState = combine(
        roundRepository.observeRound(roundId),
        equipmentRepository.observeBowSetup(bowSetupId),
        statsRepository.observeRoundStats(roundId)
    ) { round, equipment, stats ->
        RoundDetailScreenState(
            round = round,
            equipment = equipment,
            stats = stats
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = RoundDetailScreenState.Loading
    )
}

data class RoundDetailScreenState(
    val round: Round,
    val equipment: BowSetup,
    val stats: RoundStats
) {
    companion object {
        val Loading = RoundDetailScreenState(
            round = Round.EMPTY,
            equipment = BowSetup.EMPTY,
            stats = RoundStats.EMPTY
        )
    }
}
```

**See Also:**
- [System Flows - State Composition](../Flows/System-Flows/#state-composition-and-derivation) - StateFlow combination patterns

---

## Compose UI Examples

Common UI patterns and components.

### Observing StateFlow in Compose

**Pattern:** Collect StateFlow as State in Compose, automatically recompose on changes.

```kotlin
@Composable
fun RoundListScreen(viewModel: RoundListViewModel = viewModel()) {
    // Collect StateFlow as State
    val rounds by viewModel.rounds.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    Column {
        if (isLoading) {
            CircularProgressIndicator()
        }

        LazyColumn {
            items(rounds) { round ->
                RoundListItem(
                    round = round,
                    onClick = { viewModel.navigateToRound(round.id) }
                )
            }
        }
    }
}
```

---

### LazyColumn with Pagination

**Pattern:** Lazy list with infinite scrolling pagination.

```kotlin
@Composable
fun HistoricalRoundsScreen(viewModel: HistoricalRoundsViewModel = viewModel()) {
    val rounds by viewModel.rounds.collectAsState()
    val hasMore by viewModel.hasMore.collectAsState()

    LazyColumn {
        items(rounds) { round ->
            RoundListItem(round = round)
        }

        // Load more when reaching end
        if (hasMore) {
            item {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }

                LaunchedEffect(Unit) {
                    viewModel.loadMore()
                }
            }
        }
    }
}
```

**ViewModel Implementation:**

```kotlin
class HistoricalRoundsViewModel(
    private val repository: RoundRepository
) : ViewModel() {
    private val _rounds = MutableStateFlow<List<Round>>(emptyList())
    val rounds: StateFlow<List<Round>> = _rounds.asStateFlow()

    private val _hasMore = MutableStateFlow(true)
    val hasMore: StateFlow<Boolean> = _hasMore.asStateFlow()

    private var currentPage = 0
    private val pageSize = 50

    init {
        loadMore()
    }

    fun loadMore() = viewModelScope.launch {
        val newRounds = repository.getRoundsPaginated(
            status = RoundStatus.COMPLETED,
            limit = pageSize,
            offset = currentPage * pageSize
        )

        _rounds.value = _rounds.value + newRounds
        _hasMore.value = newRounds.size == pageSize
        currentPage++
    }
}
```

**See Also:**
- [Round Lifecycle Flow](../../developer-guide/technical-reference/flows/round-lifecycle-flow/) - Pagination implementation

---

### State Hoisting for Performance

**Pattern:** Hoist state to lowest common ancestor to minimize recomposition.

```kotlin
// ✅ GOOD: State hoisted to lowest ancestor
@Composable
fun ScoringScreen(viewModel: ScoringViewModel) {
    val currentScore by viewModel.currentScore.collectAsState()
    val endNumber by viewModel.endNumber.collectAsState()

    Column {
        // Only recomposes when currentScore changes
        ScoreDisplay(score = currentScore)

        // Only recomposes when endNumber changes
        EndProgress(endNumber = endNumber)

        // Never recomposes (no state dependency)
        ArrowButtons(onArrowScored = { viewModel.scoreArrow(it) })
    }
}

// ❌ BAD: All state in one object causes entire tree recomposition
@Composable
fun ScoringScreen(viewModel: ScoringViewModel) {
    val state by viewModel.state.collectAsState()

    Column {
        // Recomposes even when currentScore unchanged!
        ScoreDisplay(score = state.currentScore)

        // Recomposes even when endNumber unchanged!
        EndProgress(endNumber = state.endNumber)

        // Recomposes unnecessarily!
        ArrowButtons(onArrowScored = { viewModel.scoreArrow(it) })
    }
}
```

**See Also:**
- [Performance Guidelines - Recomposition Optimization](../Performance/#recomposition-optimization)

---

## Coroutine Examples

Async operations and Flow patterns.

### Basic Coroutine Launch

**Pattern:** Launch coroutine in viewModelScope for async operations.

```kotlin
class SomeViewModel : ViewModel() {
    fun loadData() = viewModelScope.launch {
        try {
            val data = repository.fetchData() // Suspend function
            _state.value = UiState.Success(data)
        } catch (e: Exception) {
            _error.value = e.message
        }
    }
}
```

---

### Parallel Async Operations

**Pattern:** Run multiple async operations in parallel.

```kotlin
fun loadTournamentData(tournamentId: String) = viewModelScope.launch {
    try {
        // Run three operations in parallel
        val tournament = async { tournamentRepo.getTournament(tournamentId) }
        val participants = async { participantRepo.getParticipants(tournamentId) }
        val scores = async { scoreRepo.getScores(tournamentId) }

        // Wait for all results
        val tournamentData = TournamentData(
            tournament = tournament.await(),
            participants = participants.await(),
            scores = scores.await()
        )

        _state.value = UiState.Success(tournamentData)
    } catch (e: Exception) {
        _error.value = e.message
    }
}
```

---

### Flow Transformation

**Pattern:** Transform Flow values with operators.

```kotlin
class RoundStatsViewModel(
    roundRepository: RoundRepository
) : ViewModel() {
    val roundStats = roundRepository.observeRound(roundId)
        .map { round ->
            // Transform Round to RoundStats
            RoundStats(
                average = round.totalScore / round.numArrows,
                consistency = calculateConsistency(round.ends),
                maxEnd = round.ends.maxOf { it.total }
            )
        }
        .distinctUntilChanged() // Only emit when stats actually change
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = RoundStats.EMPTY
        )
}
```

---

## Firebase Integration Examples

Cloud sync and real-time listeners.

### Firebase Real-Time Listener

**Pattern:** Observe Firebase collection with real-time updates.

```kotlin
fun observeTournamentScores(tournamentId: String): Flow<List<Score>> {
    return callbackFlow {
        val listener = firestore
            .collection("tournaments")
            .document(tournamentId)
            .collection("scores")
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error) // Close flow on error
                    return@addSnapshotListener
                }

                val scores = snapshot?.documents?.mapNotNull { doc ->
                    doc.toObject(Score::class.java)
                } ?: emptyList()

                trySend(scores) // Emit to flow
            }

        // CRITICAL: Remove listener when flow cancelled
        awaitClose { listener.remove() }
    }
}

// Usage in ViewModel (automatically cleaned up)
fun observeScores(tournamentId: String) {
    observeTournamentScores(tournamentId)
        .onEach { scores -> _scores.value = scores }
        .launchIn(viewModelScope) // Cancelled when ViewModel cleared
}
```

**See Also:**
- [Integration Flows - Real-Time Listeners](../Flows/Integration-Flows/#real-time-firebase-listeners)
- [Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/) - Complete Firebase integration

---

### Exponential Backoff Retry

**Pattern:** Retry failed network operations with exponential backoff.

```kotlin
suspend fun submitScoreWithRetry(score: Score, maxRetries: Int = 5): Result {
    var attempt = 0
    var delay = 1000L // Start with 1 second

    while (attempt < maxRetries) {
        try {
            firebaseRepository.submitScore(score)
            return Result.Success
        } catch (e: IOException) {
            attempt++
            if (attempt >= maxRetries) {
                return Result.Failure(e)
            }
            Log.w("Retry", "Attempt $attempt failed, retrying in ${delay}ms")
            delay(delay)
            delay *= 2 // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        }
    }

    return Result.Failure(Exception("All retries exhausted"))
}
```

**See Also:**
- [Performance Guidelines - Exponential Backoff](../Performance/#exponential-backoff-retry)
- [Integration Flows](../Flows/Integration-Flows/) - Network optimization

---

## Testing Examples

Unit and integration test patterns.

### Repository Unit Test

**Pattern:** Test repository with fake DAO.

```kotlin
@RunWith(JUnit4::class)
class RoundRepositoryTest {
    private lateinit var repository: RoundRepository
    private lateinit var fakeDao: FakeRoundDao

    @Before
    fun setup() {
        fakeDao = FakeRoundDao()
        repository = RoundRepository(fakeDao)
    }

    @Test
    fun `saveRound should insert round into database`() = runTest {
        val round = Round(id = 1, roundName = "Test Round")

        val result = repository.saveRound(round)

        assertEquals(SaveResult.Success, result)
        assertEquals(1, fakeDao.rounds.size)
        assertEquals(round, fakeDao.rounds[0])
    }

    @Test
    fun `getRounds should return rounds with status`() = runTest {
        // Given
        fakeDao.rounds.add(Round(id = 1, status = RoundStatus.COMPLETED))
        fakeDao.rounds.add(Round(id = 2, status = RoundStatus.IN_PROGRESS))

        // When
        val completed = repository.getRounds(RoundStatus.COMPLETED).first()

        // Then
        assertEquals(1, completed.size)
        assertEquals(RoundStatus.COMPLETED, completed[0].status)
    }
}

// Fake DAO for testing
class FakeRoundDao : RoundDao {
    val rounds = mutableListOf<Round>()

    override suspend fun insert(round: Round): Long {
        rounds.add(round)
        return round.id
    }

    override fun observeRounds(status: RoundStatus): Flow<List<Round>> {
        return flowOf(rounds.filter { it.status == status })
    }
}
```

---

### ViewModel Unit Test

**Pattern:** Test ViewModel with fake repository.

```kotlin
@RunWith(JUnit4::class)
class ScoringViewModelTest {
    private lateinit var viewModel: ScoringViewModel
    private lateinit var fakeRepository: FakeRoundRepository

    // Test coroutine dispatcher
    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeRoundRepository()
        viewModel = ScoringViewModel(fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `scoreArrow should update state with new score`() = runTest {
        // Given
        viewModel._state.value = ScoringState.Success(
            round = Round.EMPTY,
            arrowsScored = 0,
            currentScore = 0
        )

        // When
        viewModel.scoreArrow(10)

        // Then
        val state = viewModel.state.value as ScoringState.Success
        assertEquals(1, state.arrowsScored)
        assertEquals(10, state.currentScore)
    }

    @Test
    fun `loadRoundData should update state to Loading then Success`() = runTest {
        // Given
        val round = Round(id = 1, roundName = "Test Round")
        fakeRepository.rounds[1] = round

        // When
        viewModel.loadRoundData()

        // Then
        assertEquals(ScoringState.Success(round), viewModel.state.value)
    }
}
```

---

### Database Migration Test

**Pattern:** Test database migrations with MigrationTestHelper.

```kotlin
@RunWith(AndroidJUnit4::class)
class MigrationTest {
    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        ArcheryKmpDatabase::class.java
    )

    @Test
    fun migrate35to36_addsNewFieldColumn() {
        // Create database at version 35
        val db = helper.createDatabase("test_db", 35).apply {
            execSQL("INSERT INTO Round (id, roundName, status) VALUES (1, 'Test', 'COMPLETED')")
            close()
        }

        // Run migration to version 36
        helper.runMigrationsAndValidate("test_db", 36, true, MIGRATION_35_36)

        // Verify migration result
        val migratedDb = helper.getMigratableDatabase("test_db", 36)
        val cursor = migratedDb.query("SELECT * FROM Round WHERE id = 1")

        cursor.moveToFirst()
        val newField = cursor.getString(cursor.getColumnIndex("newField"))
        assertEquals("default", newField)

        cursor.close()
    }
}
```

**See Also:**
- [Database Migrations](../Database/Migrations/) - Migration examples and best practices

---

## Common Antipatterns to Avoid

Patterns to avoid and their replacements.

### Antipattern: GlobalScope

```kotlin
// ❌ BAD: GlobalScope never cancelled (memory leak)
class SomeViewModel : ViewModel() {
    fun loadData() {
        GlobalScope.launch {
            val data = repository.fetchData()
            _state.value = data // ViewModel might be destroyed!
        }
    }
}

// ✅ GOOD: viewModelScope automatically cancelled
class SomeViewModel : ViewModel() {
    fun loadData() = viewModelScope.launch {
        val data = repository.fetchData()
        _state.value = data
    }
}
```

---

### Antipattern: Mutable State in UI

```kotlin
// ❌ BAD: Mutable state properties (Compose can't detect changes)
class ScoringState {
    var currentScore: Int = 0
}

state.currentScore += 10
_state.value = state // Same object, Compose recomposes entire tree!

// ✅ GOOD: Immutable data class (efficient change detection)
data class ScoringState(
    val currentScore: Int = 0
)

_state.value = state.copy(currentScore = state.currentScore + 10)
```

---

### Antipattern: N+1 Queries

```kotlin
// ❌ BAD: N+1 queries (one query per round)
val rounds = roundDao.getAllRounds() // 1 query
rounds.forEach { round ->
    val equipment = bowSetupDao.getById(round.bowSetupId) // N queries!
}

// ✅ GOOD: Single query with JOIN
@Query("""
    SELECT Round.*, BowSetup.name as equipmentName
    FROM Round
    LEFT JOIN BowSetup ON Round.bowSetupId = BowSetup.id
""")
fun getRoundsWithEquipment(): Flow<List<RoundWithEquipment>>
```

---

## Quick Reference

Common patterns at a glance:

### Repository
- Expose `Flow<T>` from DAO
- Use `suspend` functions for writes
- Return `SaveResult` for error handling

### ViewModel
- Use `viewModelScope.launch` for coroutines
- Expose `StateFlow<T>` to UI
- Use immutable data classes for state

### Compose UI
- Collect StateFlow with `collectAsState()`
- Use `LazyColumn` for large lists
- Hoist state to lowest common ancestor

### Coroutines
- Use `viewModelScope` (not GlobalScope)
- Use `async/await` for parallel operations
- Remove listeners in `awaitClose { }`

### Testing
- Use fake implementations for dependencies
- Use `UnconfinedTestDispatcher` for coroutines
- Test state transitions, not implementation

---

## Related Documentation

- **[System Flows](../Flows/System-Flows/)** - State management and coroutine patterns
- **[Integration Flows](../Flows/Integration-Flows/)** - Firebase integration patterns
- **[Performance Guidelines](../Performance/)** - Optimization techniques
- **[MVVM Patterns](../../developer-guide/architecture/mvvm-patterns/)** - Architecture overview
- **[Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/)** - Complete Firebase implementation

---

**Last Updated:** 2025-11-04
**Pattern Count:** 15+ common patterns with examples
