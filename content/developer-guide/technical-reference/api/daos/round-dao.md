---
title: RoundDao API Reference
tags:
  - api
  - dao
  - room
  - database
  - round
  - critical
created: 2025-11-01
---

# RoundDao API Reference

Complete API reference for the RoundDao - the Room database access object for round entity operations.

---

## Overview

**File:** `data/dao/RoundDao.kt`
**Type:** Room DAO interface
**Status:** ✅ Production | ✅ Migrated (Week 2)
**Test Coverage:** 172 comprehensive tests

### Purpose

RoundDao provides type-safe database access for round entities using Room. It:
- Defines database queries using annotations
- Provides CRUD operations for rounds
- Enables reactive data streams (Flow)
- Supports complex JOIN queries
- Implements transaction support

### Migration Status

**Migrated:** Week 2 (Early migration)
**Schema Migrations:** Migrations 1-5
**Test Coverage:** 172 DAO tests (comprehensive)

**See:** [[../../../../architecture/database-migration-status|Migration Timeline]]

---

## Interface Definition

```kotlin
@Dao
interface RoundDao {
    // Create operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRound(round: Round): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRounds(rounds: List<Round>): List<Long>

    // Read operations
    @Query("SELECT * FROM rounds WHERE id = :roundId")
    suspend fun getRoundById(roundId: Long): Round?

    @Query("SELECT * FROM rounds ORDER BY date DESC")
    suspend fun getAllRounds(): List<Round>

    @Query("SELECT * FROM rounds WHERE status = :status ORDER BY date DESC")
    suspend fun getRoundsByStatus(status: String): List<Round>

    // Update operations
    @Update
    suspend fun updateRound(round: Round)

    @Update
    suspend fun updateRounds(rounds: List<Round>)

    // Delete operations
    @Delete
    suspend fun deleteRound(round: Round)

    @Query("DELETE FROM rounds WHERE id = :roundId")
    suspend fun deleteRoundById(roundId: Long)

    // Reactive queries
    @Query("SELECT * FROM rounds WHERE id = :roundId")
    fun observeRoundById(roundId: Long): Flow<Round?>

    @Query("SELECT * FROM rounds ORDER BY date DESC")
    fun observeAllRounds(): Flow<List<Round>>

    @Query("SELECT * FROM rounds WHERE status = :status ORDER BY date DESC")
    fun observeRoundsByStatus(status: String): Flow<List<Round>>

    // Complex queries with relationships
    @Transaction
    @Query("SELECT * FROM rounds WHERE id = :roundId")
    suspend fun getRoundWithEnds(roundId: Long): RoundWithEnds?

    @Transaction
    @Query("SELECT * FROM rounds ORDER BY date DESC")
    suspend fun getAllRoundsWithEnds(): List<RoundWithEnds>
}
```

---

## Core Operations

### 1. Basic CRUD

#### Insert Round

```kotlin
@Insert(onConflict = OnConflictStrategy.REPLACE)
suspend fun insertRound(round: Round): Long
```

**Returns:** Primary key of inserted round

**Conflict Strategy:** REPLACE - Updates existing round if ID matches

**Example:**
```kotlin
val round = Round(
    name = "Practice Round",
    distance = 18,
    targetFace = "122cm",
    endsCount = 10,
    arrowsPerEnd = 6,
    status = RoundStatus.ACTIVE.name,
    date = System.currentTimeMillis()
)

val roundId = roundDao.insertRound(round)
println("Created round with ID: $roundId")
```

#### Get Round by ID

```kotlin
@Query("SELECT * FROM rounds WHERE id = :roundId")
suspend fun getRoundById(roundId: Long): Round?
```

**Returns:** Round if found, null otherwise

**Example:**
```kotlin
val round = roundDao.getRoundById(123L)
if (round != null) {
    println("Found round: ${round.name}")
} else {
    println("Round not found")
}
```

#### Update Round

```kotlin
@Update
suspend fun updateRound(round: Round)
```

**Updates:** All fields of the round

**Example:**
```kotlin
val round = roundDao.getRoundById(123L) ?: return
val updated = round.copy(
    status = RoundStatus.COMPLETED.name,
    finalScore = 540,
    completedAt = System.currentTimeMillis()
)
roundDao.updateRound(updated)
```

#### Delete Round

```kotlin
@Delete
suspend fun deleteRound(round: Round)

@Query("DELETE FROM rounds WHERE id = :roundId")
suspend fun deleteRoundById(roundId: Long)
```

**Example:**
```kotlin
// Option 1: Delete by entity
val round = roundDao.getRoundById(123L)
if (round != null) {
    roundDao.deleteRound(round)
}

// Option 2: Delete by ID (preferred)
roundDao.deleteRoundById(123L)
```

---

### 2. Status Queries

#### Get Rounds by Status

```kotlin
@Query("SELECT * FROM rounds WHERE status = :status ORDER BY date DESC")
suspend fun getRoundsByStatus(status: String): List<Round>
```

**Example:**
```kotlin
// Get all active rounds
val activeRounds = roundDao.getRoundsByStatus(RoundStatus.ACTIVE.name)
println("Active rounds: ${activeRounds.size}")

// Get completed rounds
val completedRounds = roundDao.getRoundsByStatus(RoundStatus.COMPLETED.name)
```

#### Observe Rounds by Status (Reactive)

```kotlin
@Query("SELECT * FROM rounds WHERE status = :status ORDER BY date DESC")
fun observeRoundsByStatus(status: String): Flow<List<Round>>
```

**Example:**
```kotlin
@Composable
fun ActiveRoundsScreen(dao: RoundDao) {
    val activeRounds by dao
        .observeRoundsByStatus(RoundStatus.ACTIVE.name)
        .collectAsState(initial = emptyList())

    LazyColumn {
        items(activeRounds) { round ->
            RoundListItem(round = round)
        }
    }
}
```

---

### 3. Relationship Queries

#### Get Round with End Scores

```kotlin
@Transaction
@Query("SELECT * FROM rounds WHERE id = :roundId")
suspend fun getRoundWithEnds(roundId: Long): RoundWithEnds?
```

**Returns:** RoundWithEnds data class containing round and all related end scores

**Example:**
```kotlin
data class RoundWithEnds(
    @Embedded val round: Round,
    @Relation(
        parentColumn = "id",
        entityColumn = "roundId"
    )
    val endScores: List<EndScore>
)

// Usage
val roundWithEnds = roundDao.getRoundWithEnds(123L)
if (roundWithEnds != null) {
    println("Round: ${roundWithEnds.round.name}")
    println("Ends: ${roundWithEnds.endScores.size}")
    println("Total: ${roundWithEnds.endScores.sumOf { it.totalScore }}")
}
```

#### Get All Rounds with Ends

```kotlin
@Transaction
@Query("SELECT * FROM rounds ORDER BY date DESC")
suspend fun getAllRoundsWithEnds(): List<RoundWithEnds>
```

**Performance Note:** Use sparingly - can be expensive for large datasets

**Better Alternative:**
```kotlin
// Instead of loading all relationships, use summary query
@Query("""
    SELECT r.*,
           COUNT(DISTINCT es.id) as endCount,
           SUM(es.totalScore) as totalScore
    FROM rounds r
    LEFT JOIN end_scores es ON r.id = es.roundId
    GROUP BY r.id
    ORDER BY r.date DESC
""")
suspend fun getRoundsWithSummary(): List<RoundSummary>
```

---

### 4. Advanced Queries

#### Date Range Query

```kotlin
@Query("""
    SELECT * FROM rounds
    WHERE date >= :startDate AND date <= :endDate
    ORDER BY date DESC
""")
suspend fun getRoundsByDateRange(
    startDate: Long,
    endDate: Long
): List<Round>
```

**Example:**
```kotlin
val thirtyDaysAgo = System.currentTimeMillis() - (30 * 24 * 60 * 60 * 1000L)
val now = System.currentTimeMillis()

val recentRounds = roundDao.getRoundsByDateRange(thirtyDaysAgo, now)
println("Rounds in last 30 days: ${recentRounds.size}")
```

#### Participant Filter Query

```kotlin
@Query("""
    SELECT r.* FROM rounds r
    INNER JOIN round_participants rp ON r.id = rp.roundId
    WHERE rp.participantId = :participantId
    ORDER BY r.date DESC
""")
suspend fun getRoundsByParticipant(participantId: Long): List<Round>
```

#### Search Query

```kotlin
@Query("""
    SELECT * FROM rounds
    WHERE name LIKE '%' || :query || '%'
       OR targetFace LIKE '%' || :query || '%'
    ORDER BY date DESC
""")
suspend fun searchRounds(query: String): List<Round>
```

**Example:**
```kotlin
val searchResults = roundDao.searchRounds("WA 1440")
println("Found ${searchResults.size} matching rounds")
```

---

## Reactive Data Streams

### Observing Single Round

```kotlin
@Query("SELECT * FROM rounds WHERE id = :roundId")
fun observeRoundById(roundId: Long): Flow<Round?>
```

**Example:**
```kotlin
class RoundViewModel(
    private val dao: RoundDao,
    private val roundId: Long
) : ViewModel() {
    val round: StateFlow<Round?> = dao
        .observeRoundById(roundId)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = null
        )
}

@Composable
fun RoundScreen(viewModel: RoundViewModel) {
    val round by viewModel.round.collectAsState()

    round?.let {
        Text("Round: ${it.name}")
        Text("Score: ${it.finalScore}")
    }
}
```

### Observing Multiple Rounds

```kotlin
@Query("SELECT * FROM rounds ORDER BY date DESC")
fun observeAllRounds(): Flow<List<Round>>
```

**Example:**
```kotlin
@Composable
fun RoundListScreen(dao: RoundDao) {
    val rounds by dao
        .observeAllRounds()
        .collectAsState(initial = emptyList())

    LazyColumn {
        items(rounds) { round ->
            RoundCard(
                round = round,
                onClick = { /* Navigate */ }
            )
        }
    }
}
```

---

## Transaction Support

### Using @Transaction for Consistency

```kotlin
@Dao
interface RoundDao {
    @Transaction
    suspend fun createRoundWithEnds(
        round: Round,
        endsCount: Int
    ) {
        val roundId = insertRound(round)

        val endScores = List(endsCount) { endNumber ->
            EndScore(
                roundId = roundId,
                endNumber = endNumber + 1,
                totalScore = 0,
                xCount = 0
            )
        }

        insertEndScores(endScores)
    }

    @Insert
    suspend fun insertEndScores(endScores: List<EndScore>): List<Long>
}
```

**Benefits:**
- Atomic operations (all or nothing)
- Data consistency
- Rollback on error

---

## Query Optimization

### Indexing

```kotlin
@Entity(
    tableName = "rounds",
    indices = [
        Index(value = ["status"]),
        Index(value = ["date"]),
        Index(value = ["status", "date"])  // Composite index
    ]
)
data class Round(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val status: String,
    val date: Long,
    // ... other fields
)
```

**Why Indexes Matter:**
```kotlin
// Without index: Full table scan (O(n))
// With index: Binary search (O(log n))

@Query("SELECT * FROM rounds WHERE status = :status ORDER BY date DESC")
suspend fun getRoundsByStatus(status: String): List<Round>
```

### Avoiding N+1 Queries

**Problem:**
```kotlin
// BAD: N+1 queries
val rounds = roundDao.getAllRounds()  // 1 query
rounds.forEach { round ->
    val ends = endDao.getEndsForRound(round.id)  // N queries
}
```

**Solution:**
```kotlin
// GOOD: Single query with JOIN
@Transaction
@Query("""
    SELECT r.*,
           COUNT(es.id) as endCount
    FROM rounds r
    LEFT JOIN end_scores es ON r.id = es.roundId
    GROUP BY r.id
""")
suspend fun getRoundsWithEndCount(): List<RoundWithEndCount>
```

---

## Testing

### Integration Test Pattern

```kotlin
@RunWith(AndroidJUnit4::class)
class RoundDaoTest {
    private lateinit var database: AppDatabase
    private lateinit var dao: RoundDao

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(
            context,
            AppDatabase::class.java
        ).build()
        dao = database.roundDao()
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun insertAndRetrieveRound() = runTest {
        // Arrange
        val round = Round(
            name = "Test Round",
            distance = 18,
            targetFace = "122cm",
            endsCount = 10,
            arrowsPerEnd = 6,
            status = RoundStatus.ACTIVE.name,
            date = System.currentTimeMillis()
        )

        // Act
        val id = dao.insertRound(round)
        val retrieved = dao.getRoundById(id)

        // Assert
        assertNotNull(retrieved)
        assertEquals(round.name, retrieved?.name)
        assertEquals(round.distance, retrieved?.distance)
    }

    @Test
    fun updateRoundChangesFields() = runTest {
        // Arrange
        val round = Round(name = "Original", distance = 18, ...)
        val id = dao.insertRound(round)

        // Act
        val updated = round.copy(
            id = id,
            name = "Updated",
            status = RoundStatus.COMPLETED.name
        )
        dao.updateRound(updated)

        // Assert
        val retrieved = dao.getRoundById(id)
        assertEquals("Updated", retrieved?.name)
        assertEquals(RoundStatus.COMPLETED.name, retrieved?.status)
    }

    @Test
    fun deleteRoundRemovesFromDatabase() = runTest {
        // Arrange
        val round = Round(...)
        val id = dao.insertRound(round)

        // Act
        dao.deleteRoundById(id)

        // Assert
        val retrieved = dao.getRoundById(id)
        assertNull(retrieved)
    }

    @Test
    fun observeRoundsEmitsUpdates() = runTest {
        val rounds = mutableListOf<List<Round>>()

        val job = launch {
            dao.observeAllRounds().collect {
                rounds.add(it)
            }
        }

        // Insert rounds
        dao.insertRound(Round(name = "Round 1", ...))
        dao.insertRound(Round(name = "Round 2", ...))

        advanceUntilIdle()
        job.cancel()

        // Should have 3 emissions: initial empty + 2 inserts
        assertEquals(3, rounds.size)
        assertEquals(0, rounds[0].size)
        assertEquals(1, rounds[1].size)
        assertEquals(2, rounds[2].size)
    }
}
```

---

## Why 0% Coverage is Normal

Room DAOs show **0% code coverage** in reports, but this is **expected and normal**.

### Why This Happens

1. **DAOs are interfaces** with `@Query` annotations
2. **Room generates implementation** classes at compile time (`*_Impl`)
3. **Tests interact with DAO interface**, not generated code
4. **Coverage tools measure interface**, which has no executable code

### Your DAO Tests ARE Valuable

✅ **Verify database operations** work correctly
✅ **Test complex query logic** and relationships
✅ **Ensure data integrity** and foreign key constraints
✅ **Provide regression protection** for schema changes

**See:** [[../../../../testing/test-coverage-guide#why-dao-coverage-is-0-this-is-normal|Coverage Guide]]

---

## Best Practices

### 1. Use Suspend Functions

```kotlin
// GOOD: Suspend for async operations
@Insert
suspend fun insertRound(round: Round): Long

// BAD: Blocking main thread
@Insert
fun insertRound(round: Round): Long
```

### 2. Use Flow for Observation

```kotlin
// GOOD: Reactive updates
@Query("SELECT * FROM rounds")
fun observeRounds(): Flow<List<Round>>

// BAD: One-time query (use only when needed)
@Query("SELECT * FROM rounds")
suspend fun getRounds(): List<Round>
```

### 3. Use @Transaction for Multi-Step Operations

```kotlin
@Transaction
suspend fun complexOperation() {
    step1()
    step2()
    step3()
    // All or nothing - rolls back on exception
}
```

### 4. Handle Null Results

```kotlin
// GOOD: Nullable return type
@Query("SELECT * FROM rounds WHERE id = :id")
suspend fun getRoundById(id: Long): Round?

// Usage
val round = dao.getRoundById(id) ?: return
```

### 5. Use Conflict Strategy Appropriately

```kotlin
// Replace existing on conflict
@Insert(onConflict = OnConflictStrategy.REPLACE)
suspend fun insertRound(round: Round): Long

// Ignore conflicts (keep existing)
@Insert(onConflict = OnConflictStrategy.IGNORE)
suspend fun insertRound(round: Round): Long

// Abort on conflict (throw exception)
@Insert(onConflict = OnConflictStrategy.ABORT)
suspend fun insertRound(round: Round): Long
```

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/room-database-entity-mapping|Entity Mapping]]
- [[../../../../architecture/database-migration-status|Migration Status]]
- [[../../../../architecture/system-architecture#data-layer|Data Layer]]

**Related Components:**
- [[../repositories/round-repository|RoundRepository]] - Repository layer
- [[round|Round Entity]] - Database entity
- [[end-score-dao|EndScoreDao]] - Related DAO

**Testing:**
- [[../../../../testing/adapter-migration-guide|DAO Testing Guide]]
- [[../../../../testing/test-coverage-guide|Coverage Guide]]

---

## Contributing

When modifying RoundDao:

1. **Add tests** - Integration tests for all queries
2. **Use indexes** - For frequently queried columns
3. **Avoid N+1** - Use JOIN queries for relationships
4. **Document queries** - Complex SQL needs comments
5. **Test migrations** - Schema changes require migration tests

---

**Status:** ✅ Production | ✅ Migrated Week 2
**Test Coverage:** 172 comprehensive tests
**Schema Version:** 27
**Last Updated:** 2025-11-01
