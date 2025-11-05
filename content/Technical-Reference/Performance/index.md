---
title: "Performance Guidelines"
description: "Performance optimization techniques and benchmarking"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - performance
  - optimization
  - benchmarking
  - best-practices
---

[Home](/) > [Technical Reference](../) > Performance

---

# Performance Guidelines

Consolidated reference for performance optimization techniques, benchmarking strategies, and best practices used throughout Archery Apprentice.

## Overview

Performance is critical for a smooth user experience. Archery Apprentice employs various optimization strategies across database queries, UI rendering, network operations, and memory management.

**Performance Categories:**

1. **Database Optimization** - Indexes, query optimization, N+1 prevention
2. **Memory Management** - Caching strategies, leak prevention
3. **UI Performance** - Compose recomposition optimization, state management
4. **Network Optimization** - Efficient Firebase sync, exponential backoff
5. **Benchmarking & Monitoring** - Performance testing and profiling

**Related Documentation:**

- [Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/) - Caching and network optimization
- [System Flows](../Flows/System-Flows/) - State management and coroutine patterns
- [Database Tables](../Database/Tables/) - Database schema with indexes
- [System Architecture](../../developer-guide/architecture/system-architecture/) - Technical debt and performance priorities

---

## Database Optimization

Performance optimizations for Room database queries, indexes, and data access patterns.

### Strategic Indexing

**Overview:**

Indexes dramatically improve query performance for frequently filtered and sorted columns. All performance-critical queries in Archery Apprentice use indexed columns.

**Index Strategy:**

| Table               | Indexed Columns                     | Query Pattern                                    |
|---------------------|-------------------------------------|--------------------------------------------------|
| Round               | `status`, `createdAt`, `bowSetupId` | Filter by status, sort by date, join to equipment|
| End                 | `roundId`, `endNumber`              | Fetch ends for round, sort by end number         |
| Arrow               | `endId`, `arrowNumber`              | Fetch arrows for end, sort by arrow number       |
| BowSetup            | `id`, `name`                        | Lookup by ID, search by name                     |
| TournamentParticipant | `tournamentId`, `userId`          | Fetch participants for tournament, by user       |

**Index Creation:**

```sql
-- Round table indexes
CREATE INDEX idx_round_status ON Round(status);
CREATE INDEX idx_round_created_at ON Round(createdAt);
CREATE INDEX idx_round_status_created ON Round(status, createdAt); -- Composite for filtering + sorting
CREATE INDEX idx_round_bowsetup_id ON Round(bowSetupId);

-- End table indexes
CREATE INDEX idx_end_round_id ON End(roundId);

-- Arrow table indexes
CREATE INDEX idx_arrow_end_id ON Arrow(endId);

-- TournamentParticipant table indexes
CREATE INDEX idx_tournament_participant_tournament_id ON TournamentParticipant(tournamentId);
CREATE INDEX idx_tournament_participant_user_id ON TournamentParticipant(userId);
```

**Why Composite Indexes:**

Composite index `idx_round_status_created` enables efficient queries like:

```sql
SELECT * FROM Round
WHERE status = 'COMPLETED'
ORDER BY createdAt DESC
LIMIT 50;
```

Without the composite index, the database would:
1. Filter by status using `idx_round_status`
2. Sort ALL matched rows by createdAt (expensive!)
3. Take top 50

With the composite index, the database:
1. Use composite index to find status='COMPLETED' AND already sorted by createdAt
2. Take top 50 (no separate sort needed!)

**Index Tradeoff:**

- **Benefit:** Faster queries (especially for large tables)
- **Cost:** Slower inserts/updates (indexes must be updated), more disk space
- **Recommendation:** Index heavily queried columns, avoid indexing rarely queried columns

**See Also:**
- [Database Tables](../Database/Tables/) - Complete schema with all indexes
- [Database Migrations](../Database/Migrations/) - Index creation migrations

---

### Query Optimization

**N+1 Query Prevention:**

Avoid the N+1 query anti-pattern where you fetch N items, then fetch related data for each item individually.

**Bad Example (N+1):**

```kotlin
// Fetch all rounds (1 query)
val rounds = roundDao.getAllRounds()

// For each round, fetch equipment (N queries!)
rounds.forEach { round ->
    val equipment = bowSetupDao.getById(round.bowSetupId) // N separate queries
    println("${round.name} with ${equipment.name}")
}
```

**Good Example (JOIN):**

```kotlin
// Single query with JOIN
@Query("""
    SELECT Round.*, BowSetup.name as equipmentName
    FROM Round
    LEFT JOIN BowSetup ON Round.bowSetupId = BowSetup.id
    WHERE Round.status = :status
""")
fun getRoundsWithEquipment(status: RoundStatus): Flow<List<RoundWithEquipment>>
```

**Good Example (Relation):**

```kotlin
// Room loads related data efficiently with @Relation
data class RoundWithEnds(
    @Embedded val round: Round,
    @Relation(
        parentColumn = "id",
        entityColumn = "roundId"
    )
    val ends: List<End>
)

@Query("SELECT * FROM Round WHERE id = :roundId")
fun getRoundWithEnds(roundId: Long): Flow<RoundWithEnds>
```

**Pagination:**

For large result sets, use pagination to avoid loading all data at once:

```kotlin
@Query("SELECT * FROM Round WHERE status = :status ORDER BY createdAt DESC LIMIT :limit OFFSET :offset")
fun getRoundsPaginated(status: RoundStatus, limit: Int, offset: Int): List<Round>

// Usage: Load 50 rounds at a time
val page1 = roundDao.getRoundsPaginated(RoundStatus.COMPLETED, limit = 50, offset = 0)
val page2 = roundDao.getRoundsPaginated(RoundStatus.COMPLETED, limit = 50, offset = 50)
```

**Query Profiling:**

Use Android Studio's Database Inspector to profile queries:

1. Open Database Inspector (View > Tool Windows > Database Inspector)
2. Run app and execute query
3. Check "Query Execution Time" column
4. Optimize slow queries (> 100ms)

**See Also:**
- [Round Lifecycle Flow](../../developer-guide/technical-reference/flows/round-lifecycle-flow/) - Pagination examples
- [Database Tables](../Database/Tables/) - Schema with foreign keys for efficient JOINs

---

### Pre-Calculated Statistics

**Overview:**

Statistics are pre-calculated and stored in the database rather than computed on-the-fly.

**Strategy:**

```
End Completed → Calculate End Stats → Store in End table →
Round Completed → Calculate Round Stats → Store in Round table →
View Analytics → Read Pre-Calculated Stats (Fast!)
```

**Pre-Calculated Fields:**

| Entity | Pre-Calculated Fields                                  |
|--------|--------------------------------------------------------|
| End    | `totalScore`, `averageScore`, `maxScore`, `minScore`, `xCount` |
| Round  | `totalScore`, `averageScore`, `consistency`, `maxEnd`, `minEnd`, `totalXCount` |

**Why Pre-Calculate:**

- **Fast Reads:** No computation needed when viewing round history or analytics
- **Simple Queries:** Sorting by average score is a simple indexed column lookup
- **Trade-off:** Slightly slower writes (calculate on end/round completion), but writes are infrequent

**Example:**

```kotlin
// Calculate and store end statistics
suspend fun completeEnd(end: End) {
    val arrows = arrowDao.getArrowsForEnd(end.id)
    val stats = calculateEndStats(arrows)

    // Store pre-calculated stats in End table
    endDao.update(end.copy(
        totalScore = stats.total,
        averageScore = stats.average,
        maxScore = stats.max,
        minScore = stats.min,
        xCount = stats.xCount
    ))
}

// Read pre-calculated stats (no computation!)
val rounds = roundDao.getAllRounds() // Already has totalScore, averageScore, etc.
```

**See Also:**
- [Scoring Flow](../../developer-guide/technical-reference/flows/scoring-flow/) - Statistics calculation implementation

---

## Memory Management

Strategies for efficient memory usage and leak prevention.

### Caching Strategy

**TTL-Based Caching:**

Archery Apprentice uses Time-To-Live (TTL) caching to reduce database queries and network calls while ensuring data freshness.

**Cache Layers:**

1. **In-Memory Cache** (ViewModel/Repository level)
   - Fastest access
   - Survives configuration changes (ViewModel scope)
   - Cleared when ViewModel destroyed

2. **Room Database** (Local persistent cache)
   - Persists across app restarts
   - Offline-first source of truth
   - Never cleared automatically

3. **Firebase Cache** (Remote data cache)
   - TTL-based invalidation
   - Shared across devices (if authenticated)
   - Cleared on TTL expiration

**TTL Strategy:**

| Data Type              | TTL      | Rationale                                         |
|------------------------|----------|---------------------------------------------------|
| Tournament Leaderboard | 5 min    | Balance real-time updates vs network load         |
| Equipment Stats        | 5 min    | Infrequently changing, expensive to recalculate   |
| Historical Rounds      | 1 week   | Immutable after completion, safe to cache long-term |
| Active Round State     | No cache | Always reflect latest state, no staleness tolerated |
| Settings               | No cache | Single-row, StateFlow updates immediately         |

**Implementation:**

```kotlin
class TournamentScoreCacheService {
    private val cache = mutableMapOf<String, CachedLeaderboard>()
    private val TTL = 5.minutes

    suspend fun getLeaderboard(tournamentId: String): List<Score> {
        val cached = cache[tournamentId]
        if (cached != null && !cached.isExpired()) {
            return cached.data // Cache hit!
        }

        // Cache miss: fetch from source
        val fresh = firebaseRepository.getLeaderboard(tournamentId)
        cache[tournamentId] = CachedLeaderboard(fresh, Clock.System.now())
        return fresh
    }

    fun invalidate(tournamentId: String) {
        cache.remove(tournamentId)
    }

    private fun CachedLeaderboard.isExpired(): Boolean {
        return (Clock.System.now() - timestamp) > TTL
    }
}

data class CachedLeaderboard(
    val data: List<Score>,
    val timestamp: Instant
)
```

**Cache Invalidation:**

- **Explicit:** After mutations (insert, update, delete) - `cache.invalidate(key)`
- **Time-Based:** TTL expiration - checked on every access
- **Event-Based:** Firebase listeners trigger invalidation when remote data changes

**Memory Considerations:**

- In-memory caches are cleared when ViewModel destroyed (no long-term memory leaks)
- Large datasets (historical rounds) use database caching (not in-memory)
- Firebase listeners are removed when ViewModel cleared (no listener leaks)

**See Also:**
- [Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/) - Comprehensive caching documentation
- [System Flows - Caching Strategy](../Flows/System-Flows/#caching-strategy) - Cache implementation patterns

---

### Memory Leak Prevention

**Lifecycle-Aware Components:**

All long-running operations are scoped to appropriate lifecycles:

```kotlin
// ✅ GOOD: viewModelScope automatically cancelled when ViewModel cleared
class SomeViewModel : ViewModel() {
    fun loadData() {
        viewModelScope.launch {
            val data = repository.fetchData()
            _state.value = data
        }
    }

    override fun onCleared() {
        // viewModelScope coroutines automatically cancelled
    }
}

// ❌ BAD: GlobalScope never cancelled (memory leak!)
class SomeViewModel : ViewModel() {
    fun loadData() {
        GlobalScope.launch { // NEVER USE GlobalScope!
            val data = repository.fetchData()
            _state.value = data // ViewModel might be destroyed, but coroutine still running
        }
    }
}
```

**Firebase Listener Cleanup:**

```kotlin
fun observeTournamentScores(tournamentId: String): Flow<List<Score>> {
    return callbackFlow {
        val listener = firestore
            .collection("tournaments")
            .document(tournamentId)
            .collection("scores")
            .addSnapshotListener { snapshot, error ->
                // Listener callback
                trySend(snapshot?.toObjects(Score::class.java) ?: emptyList())
            }

        // CRITICAL: Remove listener when Flow cancelled
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

**Common Leak Sources:**

1. **GlobalScope** - Never use, use viewModelScope instead
2. **Unremoved Listeners** - Firebase, Room, network callbacks must be removed
3. **Static References** - Avoid storing ViewModel/Context in static fields
4. **Background Threads** - Must be cancelled when no longer needed

**Leak Detection:**

- Use LeakCanary (already integrated in debug builds)
- Monitor memory usage in Android Studio Profiler
- Check for retained objects after ViewModel cleared

---

## UI Performance

Optimization strategies for Jetpack Compose recomposition and UI responsiveness.

### Recomposition Optimization

**Overview:**

Jetpack Compose recomposes UI when state changes. Excessive recomposition causes lag and jank.

**State Hoisting:**

Hoist state to lowest common ancestor to minimize recomposition scope:

```kotlin
// ✅ GOOD: State hoisted to lowest common ancestor
@Composable
fun ScoringScreen(viewModel: ScoringViewModel) {
    val currentScore by viewModel.currentScore.collectAsState()

    Column {
        ScoreDisplay(score = currentScore) // Only recomposes when currentScore changes
        ArrowButtons(onArrowScored = { viewModel.scoreArrow(it) }) // Never recomposes
    }
}

// ❌ BAD: Entire screen recomposes on any state change
@Composable
fun ScoringScreen(viewModel: ScoringViewModel) {
    val allState by viewModel.state.collectAsState() // Entire state object

    Column {
        ScoreDisplay(score = allState.currentScore) // Recomposes even when other fields change!
        ArrowButtons(onArrowScored = { viewModel.scoreArrow(it) }) // Also recomposes unnecessarily!
    }
}
```

**StateFlow Optimization:**

Use StateFlow operators to reduce unnecessary emissions:

```kotlin
// Only emit when value actually changes
val distinctScore = scoreFlow
    .distinctUntilChanged()
    .stateIn(viewModelScope, WhileSubscribed(5000), 0)

// Combine multiple flows efficiently
val combinedState = combine(
    roundFlow,
    equipmentFlow,
    participantsFlow
) { round, equipment, participants ->
    ScoringScreenState(round, equipment, participants)
}.stateIn(viewModelScope, WhileSubscribed(5000), ScoringScreenState.Loading)
```

**State Sharing Strategy:**

```kotlin
// WhileSubscribed(5000) - Most common, stops upstream 5s after last subscriber
val state = flow.stateIn(viewModelScope, WhileSubscribed(5000), initialValue)

// Eagerly - Start immediately, never stop (use sparingly, potential memory leak)
val state = flow.stateIn(viewModelScope, Eagerly, initialValue)

// Lazily - Start when first subscriber, never stop
val state = flow.stateIn(viewModelScope, Lazily, initialValue)
```

**Immutable State:**

Always use immutable state objects to enable Compose's smart recomposition:

```kotlin
// ✅ GOOD: Immutable data class
data class ScoringState(
    val currentEnd: Int,
    val arrowsScored: Int,
    val totalScore: Int
)

// Compose can efficiently detect changes
_state.value = state.copy(arrowsScored = arrowsScored + 1)

// ❌ BAD: Mutable properties
class ScoringState {
    var currentEnd: Int = 0
    var arrowsScored: Int = 0
    var totalScore: Int = 0
}

// Compose can't detect changes, recomposes entire tree!
state.arrowsScored += 1
_state.value = state // Same object reference, Compose thinks nothing changed!
```

**See Also:**
- [System Flows - State Management](../Flows/System-Flows/#state-management-flows) - StateFlow patterns
- Jetpack Compose Performance documentation

---

### Lazy Loading

**LazyColumn/LazyRow:**

Use lazy lists for large datasets to avoid loading all items at once:

```kotlin
@Composable
fun HistoricalRoundsScreen(rounds: List<Round>) {
    LazyColumn {
        items(rounds) { round ->
            RoundListItem(round = round)
        }
    }
}

// Compose only renders visible items + small buffer
// 1000 rounds? No problem, only ~15 items rendered at once
```

**Pagination:**

```kotlin
@Composable
fun HistoricalRoundsScreen(viewModel: HistoricalRoundsViewModel) {
    val rounds by viewModel.rounds.collectAsState()

    LazyColumn {
        items(rounds) { round ->
            RoundListItem(round = round)
        }

        // Load more when reaching end
        item {
            LaunchedEffect(Unit) {
                viewModel.loadMore()
            }
        }
    }
}
```

---

## Network Optimization

Strategies for efficient Firebase sync and network usage.

### Exponential Backoff Retry

**Overview:**

Network failures are handled with exponential backoff retry to avoid overwhelming Firebase servers while still retrying transient failures.

**Algorithm:**

```
Attempt 1: Immediate
Attempt 2: Wait 1s, retry
Attempt 3: Wait 2s, retry
Attempt 4: Wait 4s, retry
Attempt 5: Wait 8s, retry
Attempt 6: Wait 16s, give up
```

**Implementation:**

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
            delay(delay)
            delay *= 2 // Exponential backoff
        }
    }
}
```

**Why Exponential:**

- **Linear Backoff (1s, 2s, 3s, 4s):** Too aggressive, spams server during sustained outages
- **Exponential Backoff (1s, 2s, 4s, 8s):** Gives server time to recover, reduces load
- **Max Delay:** Cap at 16s to avoid indefinite waits

**See Also:**
- [Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/) - Retry implementation with exponential backoff

---

### Batch Operations

**Overview:**

Batch Firebase operations reduce network round-trips for initial data loading.

**Example:**

```kotlin
// ❌ BAD: N network requests
suspend fun loadTournamentData(tournamentId: String) {
    val tournament = firestore.collection("tournaments").document(tournamentId).get()
    val participants = firestore.collection("tournaments").document(tournamentId).collection("participants").get()
    val scores = firestore.collection("tournaments").document(tournamentId).collection("scores").get()
}

// ✅ GOOD: 1 network request with batched reads
suspend fun loadTournamentData(tournamentId: String) {
    val batch = firestore.batch()
    val tournamentRef = firestore.collection("tournaments").document(tournamentId)
    val participantsRef = tournamentRef.collection("participants")
    val scoresRef = tournamentRef.collection("scores")

    // Firestore batches these into fewer network requests
    val results = firestore.runTransaction { transaction ->
        listOf(
            transaction.get(tournamentRef),
            transaction.get(participantsRef),
            transaction.get(scoresRef)
        )
    }
}
```

---

### Query Filtering

**Overview:**

Use Firebase query filters to reduce data transfer and processing.

**Example:**

```kotlin
// ❌ BAD: Fetch all scores, filter in app
val allScores = firestore.collection("tournaments/$tournamentId/scores").get()
val recentScores = allScores.filter { it.updatedAt > recentTimestamp }

// ✅ GOOD: Filter on server, transfer only needed data
val recentScores = firestore
    .collection("tournaments/$tournamentId/scores")
    .whereGreaterThan("updatedAt", recentTimestamp)
    .get()
```

---

## Benchmarking & Monitoring

Tools and strategies for measuring and tracking performance.

### Performance Testing

**Database Query Benchmarking:**

```kotlin
@Test
fun benchmark_getRoundsQuery() {
    val startTime = System.currentTimeMillis()

    val rounds = runBlocking {
        roundDao.getRounds(RoundStatus.COMPLETED, limit = 50)
    }

    val duration = System.currentTimeMillis() - startTime
    println("Query took ${duration}ms")

    // Assert performance SLA
    assert(duration < 100) { "Query took ${duration}ms, expected < 100ms" }
}
```

**UI Performance Profiling:**

Use Android Studio Profiler:

1. Run app in Profile mode
2. Navigate to slow screen
3. Check "Rendering" profiler
4. Look for janky frames (> 16ms per frame)
5. Identify slow composables in flame graph

**Firebase Performance Monitoring:**

```kotlin
// Track custom traces
val trace = Firebase.performance.newTrace("load_tournament")
trace.start()

try {
    val tournament = firebaseRepository.loadTournament(id)
    trace.putMetric("tournament_size", tournament.participants.size.toLong())
} finally {
    trace.stop()
}
```

---

### Performance Metrics

**Target Performance SLAs:**

| Operation                | Target     | Rationale                                      |
|--------------------------|------------|------------------------------------------------|
| Database Query           | < 100ms    | User expects instant data loading              |
| Screen Load              | < 500ms    | From tap to visible content                    |
| Frame Rendering          | < 16ms     | 60 FPS (1000ms / 60 frames = 16.67ms/frame)   |
| Firebase Sync (initial)  | < 2s       | Acceptable wait for network operation          |
| Firebase Sync (delta)    | < 500ms    | Real-time feel for leaderboard updates         |

**Monitoring:**

- Use Firebase Performance Monitoring for network metrics
- Use Android Studio Profiler for CPU/memory/rendering metrics
- Use LeakCanary for memory leak detection
- Use Database Inspector for query profiling

---

## Best Practices Summary

Consolidated list of performance best practices:

### Database

- ✅ Index frequently queried columns (status, createdAt, foreign keys)
- ✅ Use composite indexes for filter + sort queries
- ✅ Use JOINs or @Relation to prevent N+1 queries
- ✅ Paginate large result sets (50-100 items per page)
- ✅ Pre-calculate statistics, store in database
- ❌ Avoid SELECT * when only a few columns needed
- ❌ Avoid N+1 queries (fetch related data in single query)

### Memory

- ✅ Use TTL-based caching (5 min for frequently changing data)
- ✅ Use viewModelScope for coroutines (automatically cancelled)
- ✅ Remove Firebase listeners in awaitClose { }
- ✅ Use LeakCanary to detect memory leaks
- ❌ Never use GlobalScope (memory leak risk)
- ❌ Avoid static references to ViewModel/Context

### UI

- ✅ Use StateFlow with distinctUntilChanged()
- ✅ Hoist state to lowest common ancestor
- ✅ Use immutable state objects (data class)
- ✅ Use LazyColumn/LazyRow for large lists
- ✅ Use WhileSubscribed(5000) for StateFlow sharing
- ❌ Avoid mutable state properties (causes excessive recomposition)
- ❌ Avoid hoisting all state to root (causes entire tree recomposition)

### Network

- ✅ Use offline-first architecture (local DB as source of truth)
- ✅ Use exponential backoff retry (1s, 2s, 4s, 8s, 16s)
- ✅ Use Firebase query filters (reduce data transfer)
- ✅ Use batch operations for initial data loading
- ✅ Use TTL caching (5 min for leaderboards)
- ❌ Avoid polling (use Firebase listeners instead)
- ❌ Avoid fetching all data when only subset needed

---

## Related Documentation

- **[Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/)** - Caching, retry, and network optimization
- **[System Flows](../Flows/System-Flows/)** - State management and coroutine patterns
- **[Database Tables](../Database/Tables/)** - Complete schema with indexes
- **[Database Migrations](../Database/Migrations/)** - Index creation and optimization
- **[System Architecture](../../developer-guide/architecture/system-architecture/)** - Technical debt and performance priorities

---

**Last Updated:** 2025-11-04
**Performance SLAs:** Database < 100ms, Screen Load < 500ms, Frame Rendering < 16ms
