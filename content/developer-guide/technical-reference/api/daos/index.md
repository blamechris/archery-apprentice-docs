---
title: DAOs API Reference
tags:
  - api
  - daos
  - room
  - database
created: 2025-11-01
---

# DAOs API Reference

Complete reference for all Data Access Objects (DAOs) in Archery Apprentice.

---

## Overview

DAOs provide type-safe database access using Room. They:
- Define database queries using annotations
- Provide CRUD operations
- Enable reactive data streams (Flow)
- Support transactions
- Implement database operations

**Total DAOs:** 15

---

## DAO Pattern

### Basic DAO

```kotlin
@Dao
interface MyDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: Entity): Long

    @Update
    suspend fun update(entity: Entity)

    @Delete
    suspend fun delete(entity: Entity)

    @Query("SELECT * FROM table_name WHERE id = :id")
    suspend fun getById(id: Long): Entity?

    @Query("SELECT * FROM table_name ORDER BY created_at DESC")
    fun observeAll(): Flow<List<Entity>>
}
```

### Query Patterns

```kotlin
// Simple query
@Query("SELECT * FROM rounds WHERE id = :roundId")
suspend fun getRound(roundId: Long): Round?

// Query with JOIN
@Query("""
    SELECT r.*, COUNT(es.id) as endCount
    FROM rounds r
    LEFT JOIN end_scores es ON r.id = es.roundId
    GROUP BY r.id
""")
suspend fun getRoundsWithEndCount(): List<RoundWithEndCount>

// Query with parameters
@Query("SELECT * FROM rounds WHERE status = :status AND date >= :startDate")
suspend fun getRoundsByStatusAfterDate(
    status: String,
    startDate: Long
): List<Round>

// Reactive query
@Query("SELECT * FROM rounds ORDER BY date DESC")
fun observeRounds(): Flow<List<Round>>
```

---

## Core DAOs

### RoundDao
**Purpose:** Round entity database operations

**Status:** 📝 Needs comprehensive documentation
**File:** `data/dao/RoundDao.kt`
**Documentation:** [[round-dao|Full API Reference →]]

**Key Operations:**
- Round CRUD
- Round with ends queries
- Status filtering
- Date range queries
- Participant filtering

**Key Queries:**
```kotlin
@Query("SELECT * FROM rounds WHERE id = :roundId")
suspend fun getRoundById(roundId: Long): Round?

@Query("SELECT * FROM rounds WHERE status = :status")
fun observeRoundsByStatus(status: String): Flow<List<Round>>

@Transaction
@Query("SELECT * FROM rounds WHERE id = :roundId")
suspend fun getRoundWithEnds(roundId: Long): RoundWithEnds?
```

**Migration Status:** ✅ Migrated Week 2
**Test Coverage:** 172 DAO tests (comprehensive)

---

### EndScoreDao
**Purpose:** End score entity operations

**Status:** 📝 Needs documentation
**File:** `data/dao/EndScoreDao.kt`

**Key Operations:**
- End score CRUD
- Round-end relationships
- Arrow score queries
- End totals calculation

**Performance Note:**
- ⚠️ Watch for N+1 query patterns
- Use JOIN queries for bulk operations

---

### ArrowScoreDao
**Purpose:** Individual arrow score tracking

**Status:** 📝 Needs documentation
**File:** `data/dao/ArrowScoreDao.kt`

**Key Operations:**
- Arrow CRUD
- End-arrow relationships
- X-ring tracking
- Score aggregation

---

## Equipment DAOs

### BowSetupDao
**Purpose:** Bow configuration database operations

**Status:** 📝 Needs documentation
**File:** `data/dao/BowSetupDao.kt`
**Documentation:** [[bow-setup-dao|Full API Reference →]]

**Key Operations:**
- Bow setup CRUD
- Active bow queries
- Equipment history
- Performance tracking

**Migration Status:** ✅ Migrated Week 3

---

### ArrowSetupDao
**Purpose:** Arrow configuration operations

**Status:** 📝 Needs documentation
**File:** `data/dao/ArrowSetupDao.kt`

**Migration Status:** ✅ Migrated Week 4

---

### SightConfigurationDao
**Purpose:** Sight settings database operations

**Status:** 📝 Needs documentation
**File:** `data/dao/SightConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 5

---

### RestConfigurationDao
**Purpose:** Arrow rest configuration

**Status:** 📝 Needs documentation
**File:** `data/dao/RestConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 6

---

### StabilizerConfigurationDao
**Purpose:** Stabilizer setup operations

**Status:** 📝 Needs documentation
**File:** `data/dao/StabilizerConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 7

---

### PlungerConfigurationDao
**Purpose:** Plunger/button configuration

**Status:** 📝 Needs documentation
**File:** `data/dao/PlungerConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 8

---

### TabConfigurationDao
**Purpose:** Finger tab settings

**Status:** 📝 Needs documentation
**File:** `data/dao/TabConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 9

---

### ReleaseAidConfigurationDao
**Purpose:** Release aid configuration

**Status:** 📝 Needs documentation
**File:** `data/dao/ReleaseAidConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 10

---

### ClkrConfigurationDao
**Purpose:** Clicker settings

**Status:** 📝 Needs documentation
**File:** `data/dao/ClkrConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 11

---

### StringConfigurationDao
**Purpose:** Bowstring configuration

**Status:** 📝 Needs documentation
**File:** `data/dao/StringConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 11

---

### LimbsConfigurationDao
**Purpose:** Bow limb settings

**Status:** 📝 Needs documentation
**File:** `data/dao/LimbsConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 11

---

### RiserConfigurationDao
**Purpose:** Bow riser configuration

**Status:** 📝 Needs documentation
**File:** `data/dao/RiserConfigurationDao.kt`

**Migration Status:** ✅ Migrated Week 11

---

## Migration Status

### DAO Migration Timeline

**Week-by-week Equipment DAO Migration:**

| Week | DAOs Migrated | Status |
|------|---------------|--------|
| Week 2 | RoundDao | ✅ Complete |
| Week 3 | BowSetupDao | ✅ Complete |
| Week 4 | ArrowSetupDao | ✅ Complete |
| Week 5 | SightConfigurationDao | ✅ Complete |
| Week 6 | RestConfigurationDao | ✅ Complete |
| Week 7 | StabilizerConfigurationDao | ✅ Complete |
| Week 8 | PlungerConfigurationDao | ✅ Complete |
| Week 9 | TabConfigurationDao | ✅ Complete |
| Week 10 | ReleaseAidConfigurationDao | ✅ Complete |
| Week 11 | 4 Equipment DAOs | ✅ Complete |

**Total Migration:** 15 DAOs, 27 schema migrations

**See:** [[../../../../architecture/database-migration-status|Migration Timeline]]

---

## DAO Coverage & Testing

### Test Coverage

**Total DAO Tests:** 172
- Comprehensive database operation coverage
- Integration tests via repositories
- Schema migration tests

**Why 0% Coverage in Reports?**

Room DAOs show 0% coverage because:
- DAOs are interfaces with `@Query` annotations
- Room generates implementation classes (`*_Impl`) at compile time
- Tests interact with DAO interface, not generated code

**Your DAO tests ARE valuable because they:**
- ✅ Verify database operations work correctly
- ✅ Test complex query logic and relationships
- ✅ Ensure data integrity and foreign key constraints
- ✅ Provide regression protection for schema changes

**See:** [[../../../../testing/test-coverage-guide#why-dao-coverage-is-0-this-is-normal|Coverage Guide]]

---

## Advanced Query Patterns

### JOIN Queries

```kotlin
@Transaction
@Query("""
    SELECT r.*,
           COUNT(DISTINCT es.id) as endCount,
           COUNT(DISTINCT ars.id) as arrowCount,
           SUM(ars.score) as totalScore
    FROM rounds r
    LEFT JOIN end_scores es ON r.id = es.roundId
    LEFT JOIN arrow_scores ars ON es.id = ars.endScoreId
    WHERE r.status = :status
    GROUP BY r.id
    ORDER BY r.date DESC
""")
suspend fun getRoundStatsByStatus(status: String): List<RoundStats>
```

### Subqueries

```kotlin
@Query("""
    SELECT * FROM rounds
    WHERE id IN (
        SELECT DISTINCT roundId
        FROM end_scores
        WHERE totalScore > :minScore
    )
""")
suspend fun getRoundsWithMinScore(minScore: Int): List<Round>
```

### Conditional Queries

```kotlin
@Query("""
    SELECT * FROM rounds
    WHERE (:status IS NULL OR status = :status)
      AND (:startDate IS NULL OR date >= :startDate)
      AND (:endDate IS NULL OR date <= :endDate)
    ORDER BY date DESC
""")
suspend fun getRoundsFiltered(
    status: String?,
    startDate: Long?,
    endDate: Long?
): List<Round>
```

---

## Transaction Support

### Using @Transaction

```kotlin
@Dao
interface MyDao {
    @Transaction
    suspend fun createRoundWithEnds(
        round: Round,
        ends: List<EndScore>
    ) {
        val roundId = insertRound(round)
        ends.forEach { end ->
            end.roundId = roundId
            insertEnd(end)
        }
    }

    @Insert
    suspend fun insertRound(round: Round): Long

    @Insert
    suspend fun insertEnd(end: EndScore): Long
}
```

### Manual Transactions

```kotlin
@Transaction
suspend fun complexOperation() = withTransaction {
    val id1 = dao1.insert(entity1)
    val id2 = dao2.insert(entity2)
    dao3.link(id1, id2)
}
```

---

## Performance Optimization

### N+1 Query Problem

**Problem:** Loading related data in loops

```kotlin
// BAD: N+1 queries
val rounds = roundDao.getAllRounds()  // 1 query
rounds.forEach { round ->
    val ends = endDao.getEndsForRound(round.id)  // N queries
}
```

**Solution:** Use @Transaction and @Relation

```kotlin
// GOOD: Single query with JOIN
data class RoundWithEnds(
    @Embedded val round: Round,
    @Relation(
        parentColumn = "id",
        entityColumn = "roundId"
    )
    val ends: List<EndScore>
)

@Transaction
@Query("SELECT * FROM rounds")
suspend fun getRoundsWithEnds(): List<RoundWithEnds>
```

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
data class Round(...)
```

---

## Testing DAOs

### Integration Test Pattern

```kotlin
@RunWith(AndroidJUnit4::class)
class RoundDaoTest {
    private lateinit var database: AppDatabase
    private lateinit var dao: RoundDao

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
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
        val round = Round(...)
        val id = dao.insert(round)

        val retrieved = dao.getRoundById(id)

        assertEquals(round.name, retrieved?.name)
    }
}
```

### Flow Testing

```kotlin
@Test
fun observeRoundsEmitsUpdates() = runTest {
    val rounds = mutableListOf<List<Round>>()

    val job = launch {
        dao.observeRounds().collect {
            rounds.add(it)
        }
    }

    dao.insert(round1)
    dao.insert(round2)

    advanceUntilIdle()
    job.cancel()

    assertEquals(3, rounds.size)  // Initial empty + 2 inserts
}
```

---

## Room Best Practices

### Use Suspend Functions

```kotlin
// GOOD: Suspend for async operations
@Insert
suspend fun insert(entity: Entity): Long

// BAD: Blocking main thread
@Insert
fun insert(entity: Entity): Long
```

### Use Flow for Observation

```kotlin
// GOOD: Reactive updates
@Query("SELECT * FROM table")
fun observeAll(): Flow<List<Entity>>

// BAD: One-time query
@Query("SELECT * FROM table")
suspend fun getAll(): List<Entity>
```

### Use @Transaction for Multi-Step Operations

```kotlin
@Transaction
suspend fun complexOperation() {
    step1()
    step2()
    step3()
}
```

### Handle Null Results

```kotlin
// GOOD: Nullable return type
@Query("SELECT * FROM table WHERE id = :id")
suspend fun getById(id: Long): Entity?

// Use safely
val entity = dao.getById(id) ?: return
```

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/room-database-entity-mapping|Entity Mapping]]
- [[../../../../architecture/database-migration-status|Migration Status]]
- [[../../../../architecture/system-architecture#data-layer|Data Layer]]

**Testing:**
- [[../../../../testing/adapter-migration-guide|DAO Testing Guide]]
- [[../../../../testing/test-coverage-guide|Coverage Guide]]

**Guides:**
- [[../../../../guides/migration-testing-unit-tests-vs-instrumented-tests|Test Strategy]]

---

## Contributing

Help us document the remaining DAOs!

**Priority Documentation Needed:**
1. RoundDao (most critical)
2. BowSetupDao (equipment)
3. EndScoreDao (scoring)
4. ArrowScoreDao (scoring)
5. Remaining equipment DAOs (11 DAOs)

**Template:** [[../index#contributing-to-api-docs|API Documentation Template]]

---

**Status:** 0/15 DAOs fully documented (0%)
**Migration:** 15/15 DAOs migrated (100%)
**Test Coverage:** 172 comprehensive tests
**Last Updated:** 2025-11-01
