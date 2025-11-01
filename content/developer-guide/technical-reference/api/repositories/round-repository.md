---
title: RoundRepository API Reference
tags:
  - api
  - repository
  - round
  - scoring
  - critical
created: 2025-11-01
---

# RoundRepository API Reference

Complete API reference for the RoundRepository - the central repository managing round lifecycle, scoring, and historical data.

---

## Overview

**File:** `data/repository/impl/RoundRepository.kt`
**Lines:** 1,443 (⚠️ God class - 3.6x recommended size)
**Interface:** `RoundRepository`
**Status:** ✅ Production | 🚧 Needs refactoring

### Purpose

RoundRepository is the primary data access layer for round management, handling:
- Round CRUD operations
- End score management
- Arrow score tracking
- Round completion and status
- Historical data queries
- Multi-participant support

### Critical Status

⚠️ **God Class Warning:** This repository has grown to 1,443 lines and handles too many responsibilities. Recommended refactoring into:
1. **RoundCrudRepository** (~400 lines) - Basic CRUD
2. **RoundScoringRepository** (~500 lines) - Score management
3. **RoundHistoryRepository** (~300 lines) - Historical queries
4. **RoundAnalyticsRepository** (~200 lines) - Statistics

**See:** [[../../../../internal/project-tracking/checkpoint-findings#critical-5-repository-god-classes|Checkpoint Findings]]

---

## Key Responsibilities

### 1. Round Lifecycle Management

```kotlin
// Create new round
suspend fun createRound(round: Round): Result<Long>

// Update round metadata
suspend fun updateRound(round: Round): Result<Unit>

// Delete round and all related data
suspend fun deleteRound(roundId: Long): Result<Unit>

// Get round by ID
suspend fun getRoundById(roundId: Long): Result<Round?>

// Get round with all related data
suspend fun getRoundWithEnds(roundId: Long): Result<RoundWithEnds?>
```

### 2. Round Status Management

```kotlin
// Update round status
suspend fun updateRoundStatus(
    roundId: Long,
    status: RoundStatus
): Result<Unit>

// Complete round
suspend fun completeRound(roundId: Long): Result<Unit>

// Archive round
suspend fun archiveRound(roundId: Long): Result<Unit>

// Observe rounds by status
fun observeRoundsByStatus(status: RoundStatus): Flow<List<Round>>
```

### 3. End Score Management

```kotlin
// Create end score
suspend fun createEndScore(endScore: EndScore): Result<Long>

// Update end score
suspend fun updateEndScore(endScore: EndScore): Result<Unit>

// Get end scores for round
suspend fun getEndScoresForRound(roundId: Long): Result<List<EndScore>>

// Get end score by number
suspend fun getEndScoreByNumber(
    roundId: Long,
    endNumber: Int
): Result<EndScore?>

// Delete end score
suspend fun deleteEndScore(endScoreId: Long): Result<Unit>
```

### 4. Arrow Score Management

```kotlin
// Create arrow scores
suspend fun createArrowScores(arrows: List<ArrowScore>): Result<List<Long>>

// Update arrow score
suspend fun updateArrowScore(arrow: ArrowScore): Result<Unit>

// Get arrows for end
suspend fun getArrowsForEnd(endScoreId: Long): Result<List<ArrowScore>>

// Delete arrow scores
suspend fun deleteArrowScores(endScoreId: Long): Result<Unit>
```

### 5. Historical Queries

```kotlin
// Get recent rounds
suspend fun getRecentRounds(limit: Int = 10): Result<List<Round>>

// Get rounds by date range
suspend fun getRoundsByDateRange(
    startDate: Long,
    endDate: Long
): Result<List<Round>>

// Get rounds by participant
suspend fun getRoundsByParticipant(
    participantId: Long
): Result<List<Round>>

// Search rounds
suspend fun searchRounds(query: String): Result<List<Round>>
```

### 6. Multi-Participant Support

```kotlin
// Add participant to round
suspend fun addParticipant(
    roundId: Long,
    participantId: Long
): Result<Unit>

// Remove participant from round
suspend fun removeParticipant(
    roundId: Long,
    participantId: Long
): Result<Unit>

// Get participants for round
suspend fun getParticipantsForRound(
    roundId: Long
): Result<List<Participant>>

// Get round scores by participant
suspend fun getRoundScoresByParticipant(
    roundId: Long
): Result<Map<Long, Int>>
```

---

## Performance Issues

### ⚠️ N+1 Query Problem

**Location:** `RoundRepository.kt:98-102`

**Problem:**
```kotlin
// BAD: Fetches rounds, then queries each round individually
suspend fun getRoundsWithDetails(): List<RoundWithDetails> {
    val rounds = dao.getAllRounds()  // 1 query
    return rounds.map { round ->
        val ends = getEndScoresForRound(round.id)  // N queries
        RoundWithDetails(round, ends.getOrNull() ?: emptyList())
    }
}
```

**Impact:**
- 30-round list: 31 database queries
- Significant performance degradation
- UI lag on round list screen

**Solution:**
```kotlin
// GOOD: Single query with JOIN
@Transaction
@Query("""
    SELECT r.*,
           COUNT(DISTINCT es.id) as endCount,
           COUNT(DISTINCT ars.id) as arrowCount,
           SUM(ars.score) as totalScore
    FROM rounds r
    LEFT JOIN end_scores es ON r.id = es.roundId
    LEFT JOIN arrow_scores ars ON es.id = ars.endScoreId
    GROUP BY r.id
    ORDER BY r.date DESC
""")
suspend fun getRoundsWithStats(): List<RoundWithStats>
```

**Expected Improvement:** 30-60x query reduction

---

## Usage Examples

### Creating a Complete Round

```kotlin
class CreateRoundUseCase(
    private val repository: RoundRepository
) {
    suspend fun execute(
        roundConfig: RoundConfig,
        participants: List<Participant>
    ): Result<Long> {
        // 1. Create round
        val round = Round(
            name = roundConfig.name,
            distance = roundConfig.distance,
            targetFace = roundConfig.targetFace,
            endsCount = roundConfig.endsCount,
            arrowsPerEnd = roundConfig.arrowsPerEnd,
            status = RoundStatus.ACTIVE
        )

        val roundId = repository.createRound(round)
            .getOrElse { return Result.failure(it) }

        // 2. Add participants
        participants.forEach { participant ->
            repository.addParticipant(roundId, participant.id)
                .getOrElse { return Result.failure(it) }
        }

        // 3. Initialize end scores
        repeat(roundConfig.endsCount) { endNumber ->
            val endScore = EndScore(
                roundId = roundId,
                endNumber = endNumber + 1,
                totalScore = 0,
                xCount = 0
            )
            repository.createEndScore(endScore)
                .getOrElse { return Result.failure(it) }
        }

        return Result.success(roundId)
    }
}
```

### Recording Arrow Scores

```kotlin
suspend fun recordEndScore(
    roundId: Long,
    endNumber: Int,
    arrows: List<Int>
) {
    // 1. Get or create end score
    val endScore = repository.getEndScoreByNumber(roundId, endNumber)
        .getOrNull()
        ?: EndScore(
            roundId = roundId,
            endNumber = endNumber,
            totalScore = 0,
            xCount = 0
        )

    val endScoreId = if (endScore.id == 0L) {
        repository.createEndScore(endScore).getOrThrow()
    } else {
        endScore.id
    }

    // 2. Create arrow scores
    val arrowScores = arrows.mapIndexed { index, score ->
        ArrowScore(
            endScoreId = endScoreId,
            arrowNumber = index + 1,
            score = score,
            isX = score == 10 // Simplified
        )
    }

    repository.createArrowScores(arrowScores).getOrThrow()

    // 3. Update end totals
    val updatedEnd = endScore.copy(
        totalScore = arrows.sum(),
        xCount = arrows.count { it == 10 }
    )

    repository.updateEndScore(updatedEnd).getOrThrow()
}
```

### Completing a Round

```kotlin
suspend fun completeRound(roundId: Long) {
    // 1. Verify all ends are scored
    val round = repository.getRoundById(roundId).getOrThrow()
        ?: throw IllegalStateException("Round not found")

    val endScores = repository.getEndScoresForRound(roundId).getOrThrow()

    if (endScores.size < round.endsCount) {
        throw IllegalStateException(
            "Cannot complete round: ${endScores.size}/${round.endsCount} ends scored"
        )
    }

    // 2. Calculate final score
    val totalScore = endScores.sumOf { it.totalScore }
    val totalXCount = endScores.sumOf { it.xCount }

    // 3. Update round status
    val completedRound = round.copy(
        status = RoundStatus.COMPLETED,
        finalScore = totalScore,
        xCount = totalXCount,
        completedAt = System.currentTimeMillis()
    )

    repository.updateRound(completedRound).getOrThrow()
}
```

### Querying Historical Data

```kotlin
suspend fun getRecentPerformance(participantId: Long) {
    // Get last 10 rounds for participant
    val rounds = repository.getRoundsByParticipant(participantId)
        .getOrThrow()
        .sortedByDescending { it.date }
        .take(10)

    // Calculate average performance
    val averageScore = rounds
        .filter { it.status == RoundStatus.COMPLETED }
        .map { it.finalScore }
        .average()

    println("Last 10 rounds average: $averageScore")
}
```

---

## Reactive Data Streams

### Observing Active Rounds

```kotlin
@Composable
fun ActiveRoundsScreen(repository: RoundRepository) {
    val activeRounds by repository
        .observeRoundsByStatus(RoundStatus.ACTIVE)
        .collectAsState(initial = emptyList())

    LazyColumn {
        items(activeRounds) { round ->
            RoundCard(round = round)
        }
    }
}
```

### Real-time Round Updates

```kotlin
class RoundViewModel(
    private val repository: RoundRepository,
    private val roundId: Long
) : ViewModel() {
    val round: StateFlow<Round?> = repository
        .observeRoundById(roundId)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = null
        )

    val endScores: StateFlow<List<EndScore>> = repository
        .observeEndScoresForRound(roundId)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )
}
```

---

## Testing

### Unit Test Example

```kotlin
@Test
fun `createRound returns success with valid round`() = runTest {
    val mockDao = mockk<RoundDao>()
    coEvery { mockDao.insertRound(any()) } returns 1L

    val repository = RoundRepositoryImpl(mockDao)
    val round = Round(
        name = "Practice Round",
        distance = 18,
        endsCount = 10
    )

    val result = repository.createRound(round)

    assertTrue(result.isSuccess)
    assertEquals(1L, result.getOrNull())
    coVerify { mockDao.insertRound(round) }
}
```

### Integration Test Example

```kotlin
@Test
fun `round lifecycle persists correctly`() = runTest {
    val database = Room.inMemoryDatabaseBuilder(
        context,
        AppDatabase::class.java
    ).build()

    val repository = RoundRepositoryImpl(database.roundDao())

    // Create
    val roundId = repository.createRound(testRound).getOrThrow()

    // Read
    val retrieved = repository.getRoundById(roundId).getOrThrow()
    assertEquals(testRound.name, retrieved?.name)

    // Update
    val updated = retrieved!!.copy(status = RoundStatus.COMPLETED)
    repository.updateRound(updated).getOrThrow()

    val completed = repository.getRoundById(roundId).getOrThrow()
    assertEquals(RoundStatus.COMPLETED, completed?.status)

    // Delete
    repository.deleteRound(roundId).getOrThrow()
    val deleted = repository.getRoundById(roundId).getOrThrow()
    assertNull(deleted)
}
```

---

## Known Issues

### 1. God Class (Critical)

**Issue:** 1,443 lines, too many responsibilities
**Impact:** Difficult to maintain, test, and understand
**Priority:** High
**Recommendation:** Split into 4 focused repositories

### 2. N+1 Query Pattern (High)

**Issue:** Multiple database queries in loops
**Impact:** Performance degradation on list screens
**Priority:** High
**Recommendation:** Use JOIN queries with @Transaction

### 3. Missing Transaction Support

**Issue:** Complex operations not wrapped in transactions
**Impact:** Data inconsistency risk
**Priority:** Medium
**Recommendation:** Add @Transaction annotations

### 4. Error Handling Inconsistency

**Issue:** Some methods throw, others return Result<T>
**Impact:** Unpredictable error handling
**Priority:** Medium
**Recommendation:** Standardize on Result<T> pattern

---

## Migration Notes

### Database Migrations

RoundRepository has been through 27 schema migrations:

| Migration | Week | Changes |
|-----------|------|---------|
| 1-5 | Week 2 | Initial round schema |
| 6-10 | Week 3 | Multi-participant support |
| 11-15 | Week 5 | End score enhancements |
| 16-20 | Week 7 | Arrow score tracking |
| 21-27 | Week 9-11 | Performance optimizations |

**See:** [[../../../../architecture/database-migration-status|Migration Timeline]]

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/system-architecture#data-layer|Data Layer Architecture]]
- [[../../../../architecture/room-database-entity-mapping|Entity Mapping]]
- [[../../../../internal/project-tracking/checkpoint-findings|Repository God Classes]]

**Flows:**
- [[../../../flows/scoring-flow|Scoring Flow]]
- [[../../../flows/round-lifecycle-flow|Round Lifecycle Flow]]

**Related Components:**
- [[../daos/round-dao|RoundDao]] - Database access
- [[../services/round-lifecycle-service|RoundLifecycleService]] - Business logic
- [[../viewmodels/round-view-model|RoundViewModel]] - UI state

**Testing:**
- [[../../../../testing/adapter-migration-guide|DAO Testing Guide]]
- [[../../../../testing/test-quality-standards|Testing Standards]]

---

## Contributing

When modifying RoundRepository:

1. **Consider refactoring first** - This class is too large
2. **Add tests** - Maintain test coverage
3. **Use Result<T>** - Consistent error handling
4. **Avoid N+1 queries** - Use JOIN queries
5. **Document breaking changes** - Update migration guide

---

**Status:** ✅ Production | 🚧 Needs refactoring
**Priority:** Critical - Most used repository
**Test Coverage:** 172 DAO tests (comprehensive)
**Last Updated:** 2025-11-01
