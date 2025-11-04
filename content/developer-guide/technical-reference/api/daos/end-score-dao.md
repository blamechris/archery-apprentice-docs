---
title: EndScoreDao API Reference
tags:
  - api
  - dao
  - room
  - scoring
  - end-score
created: 2025-11-01
---

# EndScoreDao API Reference

Complete API reference for the EndScoreDao - Room database access object for end score entities.

---

## Overview

**File:** `data/dao/EndScoreDao.kt`
**Type:** Room DAO interface
**Status:** ✅ Production

### Purpose

EndScoreDao provides type-safe database access for end score entities. It handles:
- End score CRUD operations
- Round-end relationships
- Arrow score queries
- End totals calculation

---

## Core Operations

### CRUD Methods

```kotlin
@Dao
interface EndScoreDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEndScore(endScore: EndScore): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEndScores(endScores: List<EndScore>): List<Long>

    @Query("SELECT * FROM end_scores WHERE id = :endScoreId")
    suspend fun getEndScoreById(endScoreId: Long): EndScore?

    @Update
    suspend fun updateEndScore(endScore: EndScore)

    @Delete
    suspend fun deleteEndScore(endScore: EndScore)
}
```

### Round Relationship Queries

```kotlin
@Query("SELECT * FROM end_scores WHERE roundId = :roundId ORDER BY endNumber ASC")
suspend fun getEndScoresForRound(roundId: Long): List<EndScore>

@Query("SELECT * FROM end_scores WHERE roundId = :roundId ORDER BY endNumber ASC")
fun observeEndScoresForRound(roundId: Long): Flow<List<EndScore>>

@Query("SELECT * FROM end_scores WHERE roundId = :roundId AND endNumber = :endNumber")
suspend fun getEndScoreByNumber(roundId: Long, endNumber: Int): EndScore?
```

### Aggregation Queries

```kotlin
@Query("SELECT SUM(totalScore) FROM end_scores WHERE roundId = :roundId")
suspend fun getRoundTotalScore(roundId: Long): Int?

@Query("SELECT SUM(xCount) FROM end_scores WHERE roundId = :roundId")
suspend fun getRoundTotalXCount(roundId: Long): Int?

@Query("SELECT COUNT(*) FROM end_scores WHERE roundId = :roundId")
suspend fun getEndCountForRound(roundId: Long): Int
```

---

## With Arrow Scores

### End with Arrows

```kotlin
data class EndScoreWithArrows(
    @Embedded val endScore: EndScore,
    @Relation(
        parentColumn = "id",
        entityColumn = "endScoreId"
    )
    val arrows: List<ArrowScore>
)

@Transaction
@Query("SELECT * FROM end_scores WHERE id = :endScoreId")
suspend fun getEndScoreWithArrows(endScoreId: Long): EndScoreWithArrows?

@Transaction
@Query("SELECT * FROM end_scores WHERE roundId = :roundId ORDER BY endNumber ASC")
suspend fun getEndScoresWithArrowsForRound(roundId: Long): List<EndScoreWithArrows>
```

---

## Usage Examples

### Recording End Score

```kotlin
suspend fun recordEndScore(roundId: Long, endNumber: Int, arrows: List<Int>) {
    val endScore = EndScore(
        roundId = roundId,
        endNumber = endNumber,
        totalScore = arrows.sum(),
        xCount = arrows.count { it == 10 }
    )

    val endScoreId = dao.insertEndScore(endScore)

    val arrowScores = arrows.mapIndexed { index, score ->
        ArrowScore(
            endScoreId = endScoreId,
            arrowNumber = index + 1,
            score = score,
            isX = score == 10
        )
    }

    arrowDao.insertArrowScores(arrowScores)
}
```

### Observing Round Progress

```kotlin
@Composable
fun RoundProgressDisplay(roundId: Long, dao: EndScoreDao) {
    val endScores by dao.observeEndScoresForRound(roundId)
        .collectAsState(initial = emptyList())

    Text("Ends completed: ${endScores.size}")
    Text("Total score: ${endScores.sumOf { it.totalScore }}")
    Text("X-count: ${endScores.sumOf { it.xCount }}")
}
```

---

## Performance Note

⚠️ **N+1 Query Pattern:** Avoid loading ends in loops

```kotlin
// BAD: N+1 queries
val rounds = roundDao.getAllRounds()
rounds.forEach { round ->
    val ends = endDao.getEndScoresForRound(round.id)  // N queries
}

// GOOD: Use JOIN query
@Transaction
@Query("""
    SELECT r.*,
           COUNT(es.id) as endCount,
           SUM(es.totalScore) as totalScore
    FROM rounds r
    LEFT JOIN end_scores es ON r.id = es.roundId
    GROUP BY r.id
""")
suspend fun getRoundsWithEndSummary(): List<RoundWithEndSummary>
```

---

## Testing

```kotlin
@Test
fun `getEndScoresForRound returns ends in order`() = runTest {
    val roundId = 1L

    dao.insertEndScore(EndScore(roundId = roundId, endNumber = 3, ...))
    dao.insertEndScore(EndScore(roundId = roundId, endNumber = 1, ...))
    dao.insertEndScore(EndScore(roundId = roundId, endNumber = 2, ...))

    val ends = dao.getEndScoresForRound(roundId)

    assertEquals(3, ends.size)
    assertEquals(1, ends[0].endNumber)
    assertEquals(2, ends[1].endNumber)
    assertEquals(3, ends[2].endNumber)
}
```

---

## Related Documentation

- [[../repositories/round-repository|RoundRepository]]
- [[round-dao|RoundDao]]
- [[arrow-score-dao|ArrowScoreDao]]
- [[../services/end-completion-service|EndCompletionService]]

---

**Status:** ✅ Production
**Last Updated:** 2025-11-01
