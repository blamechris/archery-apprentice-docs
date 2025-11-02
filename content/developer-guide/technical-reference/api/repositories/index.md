---
title: Repositories API Reference
tags:
  - api
  - repositories
  - data-layer
  - room
created: 2025-11-01
---

# Repositories API Reference

Complete reference for all Repository interfaces and implementations in Archery Apprentice.

---

## Overview

Repositories provide an abstraction layer over data sources (Room database, Firebase, etc.). They:
- Abstract data source implementation details
- Provide reactive data streams (Flow)
- Handle data mapping between layers
- Implement business data operations
- Support offline-first architecture

**Total Repositories:** 17

---

## Repository Pattern

### Interface Pattern

```kotlin
interface Repository {
    suspend fun create(entity: Entity): Result<Id>
    suspend fun update(entity: Entity): Result<Unit>
    suspend fun delete(id: Id): Result<Unit>
    suspend fun getById(id: Id): Result<Entity>
    fun observeAll(): Flow<List<Entity>>
}
```

### Implementation Pattern

```kotlin
class RepositoryImpl(
    private val dao: Dao
) : Repository {
    override suspend fun create(entity: Entity): Result<Id> =
        try {
            val id = dao.insert(entity)
            Result.success(id)
        } catch (e: Exception) {
            Result.failure(e)
        }

    override fun observeAll(): Flow<List<Entity>> =
        dao.observeAll()
}
```

---

## Core Repositories

### RoundRepository
**Purpose:** Round lifecycle and scoring data management

**Status:** 🚧 Needs comprehensive documentation
**File:** `data/repository/impl/RoundRepository.kt` (1,443 lines)
**Documentation:** [[round-repository|Full API Reference →]]

**Key Operations:**
- Round CRUD operations
- End score management
- Arrow score tracking
- Round completion
- Historical data queries
- Multi-participant support

**Critical Issues:**
- ⚠️ **God class**: 1,443 lines
- ⚠️ **N+1 query pattern**: Performance issue
- **Recommendation**: Split into focused repositories

**Used extensively in:**
- [[../../../flows/scoring-flow|Scoring Flow]]
- [[../../../flows/round-lifecycle-flow|Round Lifecycle]]

---

## Equipment Repositories

### BowSetupRepository
**Purpose:** Bow configuration management

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/BowSetupRepository.kt`
**Documentation:** [[bow-setup-repository|Full API Reference →]]

**Key Operations:**
- Bow setup CRUD
- Active bow management
- Setup history
- Equipment correlation

**Used in:** [[../../../flows/equipment-management-end-to-end-flow|Equipment Flow]]

---

### ArrowSetupRepository
**Purpose:** Arrow configuration management

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/ArrowSetupRepository.kt`

---

### SightConfigurationRepository
**Purpose:** Sight settings management

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/SightConfigurationRepository.kt`

---

### RestConfigurationRepository
**Purpose:** Arrow rest configuration

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/RestConfigurationRepository.kt`

---

### StabilizerConfigurationRepository
**Purpose:** Stabilizer setup management

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/StabilizerConfigurationRepository.kt`

---

### PlungerConfigurationRepository
**Purpose:** Plunger/button configuration

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/PlungerConfigurationRepository.kt`

---

### TabConfigurationRepository
**Purpose:** Finger tab settings

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/TabConfigurationRepository.kt`

---

### ReleaseAidConfigurationRepository
**Purpose:** Release aid configuration

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/ReleaseAidConfigurationRepository.kt`

---

### ClkrConfigurationRepository
**Purpose:** Clicker settings

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/ClkrConfigurationRepository.kt`

---

### StringConfigurationRepository
**Purpose:** Bowstring configuration

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/StringConfigurationRepository.kt`

---

### LimbsConfigurationRepository
**Purpose:** Bow limb settings

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/LimbsConfigurationRepository.kt`

---

### RiserConfigurationRepository
**Purpose:** Bow riser configuration

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/RiserConfigurationRepository.kt`

---

## Analytics Repositories

### StatisticsRepository
**Purpose:** Performance statistics and analytics

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/StatisticsRepository.kt`

**Key Operations:**
- Score aggregation
- Performance trends
- Equipment correlation
- Session analytics

---

## Tournament Repositories

### TournamentRepository (Interface)
**Purpose:** Tournament data operations abstraction

**Status:** 🚧 Needs comprehensive documentation
**File:** `data/repository/TournamentRepository.kt` (395 lines, 51 methods)

**Critical Issues:**
- ⚠️ **God interface**: 51 methods (3.4x too many)
- **Recommendation**: Split into 4 focused repositories

---

### OfflineTournamentRepository
**Purpose:** Local tournament storage (Room)

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/OfflineTournamentRepository.kt` (908 lines)

---

### FirebaseTournamentRepository
**Purpose:** Cloud tournament sync (Firebase Firestore)

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/FirebaseTournamentRepository.kt` (1,707 lines)

**Critical Issues:**
- ⚠️ **God class**: 1,707 lines (4.3x too large)
- **Recommendation**: Extract to focused repositories

---

### HybridTournamentRepository
**Purpose:** Offline-first tournament with cloud sync

**Status:** 📝 Needs documentation
**File:** `data/repository/impl/HybridTournamentRepository.kt` (1,506 lines)

**Key Features:**
- Offline-first architecture
- Automatic background sync
- Network connectivity monitoring
- Smart caching with TTL
- Conflict resolution

**Used in:** [[../../../flows/data-sync-flow|Data Sync Flow]]

---

## Repository God Classes

### Critical Issues

**Total Repository Code:** 5,959 lines across tournament repositories

**Problem:**
- TournamentRepository interface: 395 lines, 51 methods
- FirebaseTournamentRepository: 1,707 lines
- HybridTournamentRepository: 1,506 lines
- RoundRepository: 1,443 lines

**Industry Standard:**
- Good repository: 200-400 lines, 10-15 methods

**Recommended Refactoring:**

Split TournamentRepository into:
1. **TournamentCrudRepository** (~300 lines)
   - Basic CRUD operations
   - Tournament lifecycle
2. **TournamentSyncRepository** (~400 lines)
   - Firebase sync
   - Conflict resolution
3. **TournamentScoreRepository** (~500 lines)
   - Score submission
   - Leaderboard management
4. **TournamentAnalyticsRepository** (~200 lines)
   - Statistics
   - Performance tracking

**See:** [[../../../../internal/project-tracking/checkpoint-findings#critical-5-repository-god-classes|Checkpoint Findings]]

---

## Offline-First Pattern

### Hybrid Repository Approach

```kotlin
class HybridRepository(
    private val localRepo: LocalRepository,
    private val remoteRepo: RemoteRepository
) : Repository {
    override suspend fun getData(): Result<Data> {
        // 1. Return local data immediately
        val local = localRepo.getData()

        // 2. Sync with remote in background
        coroutineScope.launch {
            if (isNetworkAvailable) {
                val remote = remoteRepo.getData()
                if (remote.isSuccess) {
                    localRepo.update(remote.getOrThrow())
                }
            }
        }

        return local
    }
}
```

### Benefits:
- ✅ Immediate UI response
- ✅ Works offline
- ✅ Automatic sync
- ✅ Network failure resilient

---

## Result Pattern

All repositories use Result<T> for error handling:

```kotlin
suspend fun operation(): Result<Data> = try {
    val data = dao.fetchData()
    Result.success(data)
} catch (e: Exception) {
    LogConfig.e("Repository", "Operation failed", e)
    Result.failure(e)
}
```

### Usage:

```kotlin
val result = repository.operation()
result.fold(
    onSuccess = { data -> /* Handle success */ },
    onFailure = { error -> /* Handle error */ }
)

// Or
val data = result.getOrElse { defaultValue }
```

---

## Flow Pattern

Repositories expose reactive data streams:

```kotlin
fun observeData(): Flow<List<Data>> =
    dao.observeData()
        .map { entities -> entities.map { it.toDomain() } }
        .catch { e ->
            LogConfig.e("Repository", "Flow error", e)
            emit(emptyList())
        }
```

### Collection:

```kotlin
@Composable
fun MyScreen(repository: Repository) {
    val data by repository.observeData()
        .collectAsState(initial = emptyList())

    // Use data
}
```

---

## Testing Repositories

### Unit Test with Mock DAO

```kotlin
@Test
fun `getData returns success when DAO succeeds`() = runTest {
    val mockDao = mockk<Dao>()
    every { mockDao.fetchData() } returns testData

    val repository = RepositoryImpl(mockDao)
    val result = repository.getData()

    assertTrue(result.isSuccess)
    assertEquals(testData, result.getOrNull())
}
```

### Integration Test with Room

```kotlin
@Test
fun `repository persists data correctly`() = runTest {
    val database = Room.inMemoryDatabaseBuilder(
        context,
        AppDatabase::class.java
    ).build()

    val repository = RepositoryImpl(database.dao())

    repository.create(testEntity)
    val result = repository.getById(testEntity.id)

    assertEquals(testEntity, result.getOrNull())
}
```

---

## Performance Considerations

### N+1 Query Problem

**Problem:** `RoundRepository.kt:98-102` exhibits N+1 pattern

```kotlin
// BAD: N+1 queries
fun getRoundWithDetails(roundId: Int): RoundWithDetails {
    val round = dao.getRound(roundId)  // 1 query
    val ends = round.ends.map { end ->
        dao.getArrowsForEnd(end.id)     // N queries
    }
}
```

**Solution:** Use JOIN query

```kotlin
// GOOD: Single query with JOIN
@Query("""
    SELECT es.*, COUNT(ars.id) as arrowCount
    FROM end_scores es
    LEFT JOIN arrow_scores ars ON es.id = ars.endScoreId
    WHERE es.roundId = :roundId
    GROUP BY es.id
""")
suspend fun getEndScoresSummaryForRound(roundId: Int): List<EndScoreSummary>
```

**Impact:**
- 30-end round: 31 queries → 1 query
- Expected improvement: 30-60x query reduction

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/system-architecture|System Architecture]]
- [[../../../../architecture/room-database-entity-mapping|Entity Mapping]]
- [[../../../../internal/project-tracking/checkpoint-findings|Repository God Classes]]

**Flows:**
- [[../../../flows/data-sync-flow|Data Sync Flow]]
- [[../../../flows/scoring-flow|Scoring Flow]]

**Testing:**
- [[../../../../testing/adapter-migration-guide|DAO Testing]]

---

## Contributing

Help us document the remaining repositories!

**Priority Documentation Needed:**
1. RoundRepository (most critical)
2. BowSetupRepository (equipment)
3. Tournament repositories (hybrid architecture)
4. Equipment-specific repositories (11 remaining)

**Template:** [[../index#contributing-to-api-docs|API Documentation Template]]

---

**Status:** 3/17 Repositories documented (18%)
**Last Updated:** 2025-11-01
**Known Issues:** 4 god class repositories identified
