---
title: Services API Reference
tags:
  - api
  - services
  - business-logic
  - domain-layer
created: 2025-11-01
---

# Services API Reference

Complete reference for all Business Logic Services in Archery Apprentice.

---

## Overview

Services encapsulate complex business logic and coordinate multiple repositories. They:
- Implement domain-specific business rules
- Coordinate multiple data sources
- Perform calculations and transformations
- Keep ViewModels thin
- Enable reusability across ViewModels

**Total Services:** 19 extracted services

---

## Service Pattern

### Basic Service

```kotlin
class MyService(
    private val repository: Repository
) {
    suspend fun performOperation(): Result<Output> {
        val data = repository.getData()
            .getOrElse { return Result.failure(it) }

        // Business logic
        val result = processData(data)

        return Result.success(result)
    }
}
```

### Service with Multiple Repositories

```kotlin
class ComplexService(
    private val repo1: Repository1,
    private val repo2: Repository2
) {
    suspend fun coordinateOperation(): Result<Output> {
        // Coordinate multiple data sources
        val data1 = repo1.getData().getOrElse { return Result.failure(it) }
        val data2 = repo2.getData().getOrElse { return Result.failure(it) }

        // Complex business logic
        val output = combineAndProcess(data1, data2)

        return Result.success(output)
    }
}
```

---

## Core Scoring Services

### EndCompletionService
**Purpose:** End scoring completion and validation

**Status:** ✅ Documented
**File:** `domain/services/EndCompletionService.kt` (400+ lines)
**Documentation:** [[end-completion-service|Full API Reference →]]

**Key Responsibilities:**
- Arrow score validation
- End total calculation
- Database persistence
- Tournament score submission
- Conflict detection
- Statistics updates

**Used in:**
- [[../../../flows/scoring-flow|Scoring Flow]]
- LiveScoringViewModel

**Code Example:**
```kotlin
service.completeEnd(
    roundId = roundId,
    endNumber = endNumber,
    arrowScores = arrows,
    participantId = participantId
)
```

---

### RoundLifecycleService
**Purpose:** Round state transitions and validation

**Status:** 📝 Needs documentation
**File:** `domain/services/RoundLifecycleService.kt`

**Key Responsibilities:**
- Round status management
- State transition validation
- Completion conditions
- Status event propagation

**Used in:** [[../../../flows/round-lifecycle-flow|Round Lifecycle]]

---

## Tournament Services

### TournamentSyncService
**Purpose:** Real-time tournament data synchronization

**Status:** ✅ Documented
**File:** `domain/services/TournamentSyncService.kt` (556 lines)
**Documentation:** [[tournament-sync-service|Full API Reference →]]

**Key Responsibilities:**
- Firebase real-time listeners
- Live leaderboard sync
- Participant progress tracking
- Score submission with retry
- Network status monitoring

**Key Features:**
- 3 concurrent Firebase listeners
- Exponential backoff retry (100ms, 200ms, 400ms)
- Error classification
- StateFlow-based sync status

**Used in:** [[../../../flows/data-sync-flow|Data Sync Flow]]

---

### ScoreConflictResolutionService
**Purpose:** Detect and resolve scoring conflicts in tournaments

**Status:** ✅ Documented
**File:** `domain/services/ScoreConflictResolutionService.kt` (262 lines)
**Documentation:** [[score-conflict-resolution-service|Full API Reference →]]

**Key Responsibilities:**
- Conflict detection (local vs remote)
- Resolution strategy determination
- Version-based conflict resolution
- Timestamp-based tie-breaking
- Manual resolution support

**Conflict Strategies:**
- `LOCAL_WINS` - Keep local score (default)
- `REMOTE_WINS` - Accept remote score
- `HIGHEST_WINS` - Use highest score
- `LATEST_WINS` - Most recent update
- `MANUAL` - Require user intervention

---

### TournamentScoreCacheService
**Purpose:** Smart caching for tournament data

**Status:** 📝 Needs documentation
**File:** `data/services/TournamentScoreCacheService.kt`

**Key Features:**
- Status-aware TTL (completed = indefinite, in-progress = 5min)
- 50-90% reduction in Firebase reads
- 5-10x faster load times
- Automatic cache maintenance

**Cache Strategy:**
| Tournament Status | TTL | Rationale |
|-------------------|-----|-----------|
| COMPLETED | Indefinite | Immutable data |
| IN_PROGRESS | 5 minutes | Balance freshness vs reads |
| PLANNED | 10 minutes | Rarely changes |

---

## Analytics Services

### StatisticsCalculationService
**Purpose:** Performance statistics and analytics

**Status:** 📝 Needs documentation
**File:** `domain/services/StatisticsCalculationService.kt`
**Documentation:** [[statistics-calculation-service|Full API Reference →]]

**Key Responsibilities:**
- Score aggregation
- Average calculations
- Performance trends
- Equipment correlation
- Session analytics

**Used in:** Round analytics screens

---

### ProgressCalculationService
**Purpose:** Round and end progress tracking

**Status:** 📝 Needs documentation
**File:** `domain/services/ProgressCalculationService.kt`

**Key Responsibilities:**
- Ends completed tracking
- Arrows shot counting
- Completion percentage
- Remaining ends calculation

---

## Display Services

### RoundDisplayService
**Purpose:** Round data formatting and presentation

**Status:** 📝 Needs documentation
**File:** `domain/services/RoundDisplayService.kt`

**Key Responsibilities:**
- Round total calculation
- Per-participant totals
- **Multi-participant ranking**
- X-count tie-breaking
- Display formatting

**Ranking Algorithm:**
```kotlin
// Primary: Score (descending)
// Secondary: X count (descending)
sortedWith(
    compareByDescending<ParticipantRankData> { it.score }
        .thenByDescending { it.xCount }
)
```

**See:** [[../../../../internal/technical-notes/multi-participant-ranking-and-tie-breaking|Ranking Algorithm]]

---

## Equipment Services

### EquipmentPerformanceService
**Purpose:** Equipment effectiveness analytics

**Status:** 📝 Needs documentation
**File:** `domain/services/EquipmentPerformanceService.kt`

**Key Responsibilities:**
- Equipment-score correlation
- Performance by setup
- Equipment comparison
- Recommendation engine

---

### EquipmentValidationService
**Purpose:** Equipment configuration validation

**Status:** 📝 Needs documentation
**File:** `domain/services/EquipmentValidationService.kt`

---

## Migration Services

### DatabaseMigrationService
**Purpose:** Room database schema migrations

**Status:** 📝 Needs documentation
**File:** `data/services/DatabaseMigrationService.kt`

**Key Responsibilities:**
- Schema version management
- Migration execution
- Data preservation
- Rollback support

---

## Utility Services

### DateTimeService
**Purpose:** Timestamp and date utilities

**Status:** 📝 Needs documentation
**File:** `domain/services/DateTimeService.kt`

---

### ValidationService
**Purpose:** General data validation

**Status:** 📝 Needs documentation
**File:** `domain/services/ValidationService.kt`

---

### LoggingService
**Purpose:** Centralized logging

**Status:** 📝 Needs documentation
**File:** `domain/services/LoggingService.kt`

---

## Service Extraction History

### Original Architecture

**Problem:** ViewModels contained all business logic (god classes)

**Example: LiveScoringViewModel**
- Original: 2,808 lines with 12 distinct domains
- 66 methods handling everything from UI to database

### Service Extraction Pattern

**Extraction Process:**
1. Identify cohesive business logic domain
2. Create service interface
3. Move logic to service
4. Inject service into ViewModel
5. ViewModel delegates to service

**Benefits:**
- ✅ Testability improved
- ✅ Code reuse enabled
- ✅ ViewModels thinned
- ✅ Single responsibility restored

**See:** [[../../../../architecture/service-architecture|Service Architecture]]

---

## Recommended Extractions

From LiveScoringViewModel analysis:

**Priority Extractions (1,600 lines, 57% reduction):**

1. **TournamentSyncService** (~600 lines) ✅ EXTRACTED
   - Firebase listeners
   - Score submission
   - Conflict handling

2. **ConflictResolutionService** (~400 lines) ✅ EXTRACTED
   - Conflict detection
   - Resolution strategies

3. **EndCompletionService** (~400 lines) ✅ EXTRACTED
   - Score validation
   - End finalization
   - Stats calculation

4. **RoundLifecycleService** (~200 lines) 📝 NEEDED
   - Round status management
   - State transitions
   - Completion logic

5. **ParticipantManagementService** (~200 lines) 📝 NEEDED
   - Participant CRUD
   - Selection management
   - Multi-participant logic

**See:** [[../../../../architecture/live-scoring-vm-analysis|LiveScoringVM Analysis]]

---

## Testing Services

### Unit Test Pattern

```kotlin
@Test
fun `service performs calculation correctly`() = runTest {
    val mockRepo = mockk<Repository>()
    coEvery { mockRepo.getData() } returns Result.success(testData)

    val service = MyService(mockRepo)
    val result = service.performOperation()

    assertTrue(result.isSuccess)
    assertEquals(expectedOutput, result.getOrNull())
}
```

### Mocking Multiple Repositories

```kotlin
@Test
fun `service coordinates multiple repositories`() = runTest {
    val mockRepo1 = mockk<Repository1>()
    val mockRepo2 = mockk<Repository2>()

    coEvery { mockRepo1.getData() } returns Result.success(data1)
    coEvery { mockRepo2.getData() } returns Result.success(data2)

    val service = ComplexService(mockRepo1, mockRepo2)
    val result = service.coordinateOperation()

    assertTrue(result.isSuccess)
    coVerify { mockRepo1.getData() }
    coVerify { mockRepo2.getData() }
}
```

---

## Service Best Practices

### Single Responsibility

Each service should have one clear purpose:
```kotlin
// GOOD: Focused responsibility
class ScoreCalculationService {
    fun calculateTotal(arrows: List<Arrow>): Int
    fun calculateAverage(arrows: List<Arrow>): Double
}

// BAD: Too many responsibilities
class EverythingService {
    fun calculateScore()
    fun syncToFirebase()
    fun validateUser()
    fun sendEmail()
}
```

### Dependency Injection

Services should receive dependencies via constructor:
```kotlin
// GOOD: Testable
class MyService(
    private val repository: Repository
)

// BAD: Hard-coded dependency
class MyService {
    private val repository = RepositoryImpl()
}
```

### Error Handling

Use Result<T> for error propagation:
```kotlin
suspend fun performOperation(): Result<Output> {
    return try {
        val data = repository.getData()
            .getOrElse { return Result.failure(it) }

        val output = process(data)
        Result.success(output)
    } catch (e: Exception) {
        LogConfig.e("Service", "Operation failed", e)
        Result.failure(e)
    }
}
```

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/service-architecture|Service Architecture]]
- [[../../../../architecture/service-migration-flow|Service Extraction Pattern]]
- [[../../../../architecture/live-scoring-vm-analysis|Service Extraction Case Study]]

**Flows:**
- [[../../../flows/scoring-flow|Scoring Flow]]
- [[../../../flows/data-sync-flow|Data Sync Flow]]

**Testing:**
- [[../../../../testing/test-quality-standards|Testing Standards]]

---

## Contributing

Help us document the remaining services!

**Priority Documentation Needed:**
1. StatisticsCalculationService (analytics)
2. RoundLifecycleService (core)
3. EquipmentPerformanceService (equipment)
4. Remaining utility services (13 services)

**Template:** [[../index#contributing-to-api-docs|API Documentation Template]]

---

**Status:** 3/19 Services documented (16%)
**Last Updated:** 2025-11-01
**Extraction Progress:** 3 major services extracted, 2 recommended
