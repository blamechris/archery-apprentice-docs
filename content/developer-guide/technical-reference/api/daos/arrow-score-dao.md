---
title: ArrowScoreDao API Reference
tags:
  - api
  - dao
  - room
  - scoring
  - arrow-score
created: 2025-11-01
---

# ArrowScoreDao API Reference

Complete API reference for the ArrowScoreDao - Room database access object for individual arrow score entities.

---

## Overview

**File:** `data/dao/ArrowScoreDao.kt`
**Type:** Room DAO interface
**Status:** ✅ Production

### Purpose

ArrowScoreDao provides type-safe database access for individual arrow scores. It handles:
- Arrow score CRUD operations
- End-arrow relationships
- X-ring tracking
- Score distribution queries

---

## Core Operations

### CRUD Methods

```kotlin
@Dao
interface ArrowScoreDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertArrowScore(arrow: ArrowScore): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertArrowScores(arrows: List<ArrowScore>): List<Long>

    @Query("SELECT * FROM arrow_scores WHERE id = :arrowId")
    suspend fun getArrowScoreById(arrowId: Long): ArrowScore?

    @Update
    suspend fun updateArrowScore(arrow: ArrowScore)

    @Delete
    suspend fun deleteArrowScore(arrow: ArrowScore)

    @Query("DELETE FROM arrow_scores WHERE endScoreId = :endScoreId")
    suspend fun deleteArrowScoresForEnd(endScoreId: Long)
}
```

### End Relationship Queries

```kotlin
@Query("SELECT * FROM arrow_scores WHERE endScoreId = :endScoreId ORDER BY arrowNumber ASC")
suspend fun getArrowScoresForEnd(endScoreId: Long): List<ArrowScore>

@Query("SELECT * FROM arrow_scores WHERE endScoreId = :endScoreId ORDER BY arrowNumber ASC")
fun observeArrowScoresForEnd(endScoreId: Long): Flow<List<ArrowScore>>

@Query("""
    SELECT ars.* FROM arrow_scores ars
    INNER JOIN end_scores es ON ars.endScoreId = es.id
    WHERE es.roundId = :roundId
    ORDER BY es.endNumber, ars.arrowNumber
""")
suspend fun getArrowScoresForRound(roundId: Long): List<ArrowScore>
```

### X-Ring Queries

```kotlin
@Query("SELECT COUNT(*) FROM arrow_scores WHERE endScoreId = :endScoreId AND isX = 1")
suspend fun getXCountForEnd(endScoreId: Long): Int

@Query("""
    SELECT COUNT(*) FROM arrow_scores ars
    INNER JOIN end_scores es ON ars.endScoreId = es.id
    WHERE es.roundId = :roundId AND ars.isX = 1
""")
suspend fun getXCountForRound(roundId: Long): Int
```

### Distribution Queries

```kotlin
@Query("""
    SELECT score, COUNT(*) as count
    FROM arrow_scores
    WHERE endScoreId IN (
        SELECT id FROM end_scores WHERE roundId = :roundId
    )
    GROUP BY score
    ORDER BY score DESC
""")
suspend fun getScoreDistributionForRound(roundId: Long): Map<Int, Int>
```

---

## Usage Examples

### Recording Arrow Scores

```kotlin
suspend fun recordArrows(endScoreId: Long, scores: List<Int>) {
    val arrows = scores.mapIndexed { index, score ->
        ArrowScore(
            endScoreId = endScoreId,
            arrowNumber = index + 1,
            score = score,
            isX = (score == 10)  // Simplified - actual logic checks inner 10
        )
    }

    dao.insertArrowScores(arrows)

    // Update end score totals
    val totalScore = scores.sum()
    val xCount = scores.count { it == 10 }

    endScoreDao.updateEndScore(
        endScore.copy(
            totalScore = totalScore,
            xCount = xCount
        )
    )
}
```

### Reactive Arrow Display

```kotlin
@Composable
fun ArrowScoreDisplay(endScoreId: Long, dao: ArrowScoreDao) {
    val arrows by dao.observeArrowScoresForEnd(endScoreId)
        .collectAsState(initial = emptyList())

    Row {
        arrows.forEach { arrow ->
            ArrowValueChip(
                value = arrow.score,
                isX = arrow.isX
            )
        }
    }
}
```

### Score Distribution Chart

```kotlin
suspend fun displayDistribution(roundId: Long) {
    val distribution = dao.getScoreDistributionForRound(roundId)

    distribution.forEach { (score, count) ->
        val bar = "█".repeat(count)
        println("$score │ $bar $count")
    }
}

// Output:
// 10 │ █████████████████████████ 25
//  9 │ ██████████████████ 18
//  8 │ ████████████ 12
//  7 │ █████ 5
```

---

## Testing

```kotlin
@Test
fun `getArrowScoresForEnd returns arrows in order`() = runTest {
    val endScoreId = 1L

    dao.insertArrowScore(ArrowScore(endScoreId, arrowNumber = 3, score = 8))
    dao.insertArrowScore(ArrowScore(endScoreId, arrowNumber = 1, score = 10))
    dao.insertArrowScore(ArrowScore(endScoreId, arrowNumber = 2, score = 9))

    val arrows = dao.getArrowScoresForEnd(endScoreId)

    assertEquals(3, arrows.size)
    assertEquals(1, arrows[0].arrowNumber)
    assertEquals(2, arrows[1].arrowNumber)
    assertEquals(3, arrows[2].arrowNumber)
}

@Test
fun `getXCountForEnd counts correctly`() = runTest {
    val endScoreId = 1L

    dao.insertArrowScores(listOf(
        ArrowScore(endScoreId, 1, 10, isX = true),
        ArrowScore(endScoreId, 2, 10, isX = true),
        ArrowScore(endScoreId, 3, 9, isX = false),
        ArrowScore(endScoreId, 4, 10, isX = false)  // 10 but not X
    ))

    val xCount = dao.getXCountForEnd(endScoreId)

    assertEquals(2, xCount)
}
```

---

## Best Practices

### 1. Batch Insert for Performance

```kotlin
// GOOD: Single batch insert
val arrows = (1..6).map { ArrowScore(endScoreId, it, scores[it-1]) }
dao.insertArrowScores(arrows)

// BAD: Multiple individual inserts
scores.forEachIndexed { index, score ->
    dao.insertArrowScore(ArrowScore(endScoreId, index + 1, score))
}
```

### 2. Use Cascade Delete

```kotlin
@Entity(
    tableName = "arrow_scores",
    foreignKeys = [
        ForeignKey(
            entity = EndScore::class,
            parentColumns = ["id"],
            childColumns = ["endScoreId"],
            onDelete = ForeignKey.CASCADE  // Delete arrows when end deleted
        )
    ]
)
data class ArrowScore(...)
```

---

## Related Documentation

- [[end-score-dao|EndScoreDao]]
- [[../services/end-completion-service|EndCompletionService]]
- [[../../../flows/scoring-flow|Scoring Flow]]

---

**Status:** ✅ Production
**Last Updated:** 2025-11-01
