---
title: StatisticsCalculationService API Reference
tags:
  - api
  - service
  - analytics
  - statistics
  - business-logic
created: 2025-11-01
---

# StatisticsCalculationService API Reference

Complete API reference for the StatisticsCalculationService - the analytics engine for performance statistics and score calculations.

---

## Overview

**File:** `domain/services/StatisticsCalculationService.kt`
**Type:** Business Logic Service
**Status:** ✅ Production | 📝 Needs comprehensive documentation

### Purpose

StatisticsCalculationService encapsulates all statistical calculations and analytics for rounds, providing:
- Score aggregation and totals
- Average calculations
- Performance trends
- Equipment correlation analysis
- Session analytics
- Distribution analysis

### Key Responsibilities

1. **Score Aggregation** - Total scores, averages, maximums
2. **Performance Metrics** - Trends, consistency, improvement
3. **Equipment Analytics** - Performance by setup
4. **Distribution Analysis** - Arrow value frequency
5. **Session Statistics** - Per-session metrics

---

## API Methods

### 1. Round Statistics

#### Calculate Round Total

```kotlin
fun calculateRoundTotal(endScores: List<EndScore>): Int
```

**Purpose:** Calculates total score for a round from end scores

**Parameters:**
- `endScores` - List of end scores for the round

**Returns:** Total score across all ends

**Example:**
```kotlin
val endScores = repository.getEndScoresForRound(roundId).getOrThrow()
val totalScore = service.calculateRoundTotal(endScores)
println("Round total: $totalScore")
```

**Implementation:**
```kotlin
fun calculateRoundTotal(endScores: List<EndScore>): Int =
    endScores.sumOf { it.totalScore }
```

#### Calculate Round Average

```kotlin
fun calculateRoundAverage(endScores: List<EndScore>): Double
```

**Purpose:** Calculates average score per end

**Returns:** Average end score, or 0.0 if no ends

**Example:**
```kotlin
val average = service.calculateRoundAverage(endScores)
println("Average per end: ${"%.2f".format(average)}")
```

**Implementation:**
```kotlin
fun calculateRoundAverage(endScores: List<EndScore>): Double {
    if (endScores.isEmpty()) return 0.0
    return endScores.map { it.totalScore }.average()
}
```

#### Calculate Arrow Average

```kotlin
fun calculateArrowAverage(arrowScores: List<ArrowScore>): Double
```

**Purpose:** Calculates average score per arrow

**Example:**
```kotlin
val arrowScores = repository.getArrowScoresForRound(roundId).getOrThrow()
val arrowAverage = service.calculateArrowAverage(arrowScores)
println("Average per arrow: ${"%.2f".format(arrowAverage)}")
```

---

### 2. X-Count and 10-Count Statistics

#### Calculate Total X-Count

```kotlin
fun calculateTotalXCount(endScores: List<EndScore>): Int
```

**Purpose:** Counts total X-ring hits across all ends

**Example:**
```kotlin
val xCount = service.calculateTotalXCount(endScores)
println("Total X-ring hits: $xCount")
```

#### Calculate X-Count Percentage

```kotlin
fun calculateXCountPercentage(
    xCount: Int,
    totalArrows: Int
): Double
```

**Purpose:** Calculates percentage of arrows in X-ring

**Returns:** Percentage (0.0 to 100.0)

**Example:**
```kotlin
val xCount = 45
val totalArrows = 60
val percentage = service.calculateXCountPercentage(xCount, totalArrows)
println("X-ring percentage: ${"%.1f".format(percentage)}%")
// Output: "X-ring percentage: 75.0%"
```

**Implementation:**
```kotlin
fun calculateXCountPercentage(xCount: Int, totalArrows: Int): Double {
    if (totalArrows == 0) return 0.0
    return (xCount.toDouble() / totalArrows) * 100.0
}
```

---

### 3. Performance Trends

#### Calculate Performance Trend

```kotlin
fun calculatePerformanceTrend(
    rounds: List<Round>
): PerformanceTrend
```

**Purpose:** Analyzes performance trend over multiple rounds

**Returns:** PerformanceTrend with direction and percentage change

**Example:**
```kotlin
data class PerformanceTrend(
    val direction: TrendDirection,  // IMPROVING, DECLINING, STABLE
    val percentageChange: Double,   // e.g., +5.2%
    val confidence: Double          // 0.0 to 1.0
)

val recentRounds = repository.getRecentRounds(10).getOrThrow()
val trend = service.calculatePerformanceTrend(recentRounds)

when (trend.direction) {
    TrendDirection.IMPROVING ->
        println("Performance improving by ${trend.percentageChange}%")
    TrendDirection.DECLINING ->
        println("Performance declining by ${trend.percentageChange}%")
    TrendDirection.STABLE ->
        println("Performance is stable")
}
```

**Algorithm:**
```kotlin
fun calculatePerformanceTrend(rounds: List<Round>): PerformanceTrend {
    if (rounds.size < 3) {
        return PerformanceTrend(TrendDirection.STABLE, 0.0, 0.0)
    }

    val scores = rounds.map { it.finalScore }
    val recent = scores.take(scores.size / 2).average()
    val older = scores.drop(scores.size / 2).average()

    val change = ((recent - older) / older) * 100.0

    val direction = when {
        change > 2.0 -> TrendDirection.IMPROVING
        change < -2.0 -> TrendDirection.DECLINING
        else -> TrendDirection.STABLE
    }

    val confidence = minOf(rounds.size / 10.0, 1.0)

    return PerformanceTrend(direction, change, confidence)
}
```

#### Calculate Consistency Score

```kotlin
fun calculateConsistencyScore(endScores: List<EndScore>): Double
```

**Purpose:** Measures shooting consistency (0.0 = random, 1.0 = perfect)

**Returns:** Consistency score based on standard deviation

**Example:**
```kotlin
val consistency = service.calculateConsistencyScore(endScores)
println("Consistency: ${"%.2f".format(consistency)}")
// 0.95 = Very consistent
// 0.75 = Moderately consistent
// 0.50 = Inconsistent
```

**Implementation:**
```kotlin
fun calculateConsistencyScore(endScores: List<EndScore>): Double {
    if (endScores.size < 2) return 1.0

    val scores = endScores.map { it.totalScore.toDouble() }
    val mean = scores.average()
    val variance = scores.map { (it - mean).pow(2) }.average()
    val stdDev = sqrt(variance)

    // Normalize: lower stdDev = higher consistency
    val maxStdDev = mean  // Maximum expected deviation
    return 1.0 - (stdDev / maxStdDev).coerceIn(0.0, 1.0)
}
```

---

### 4. Score Distribution

#### Calculate Score Distribution

```kotlin
fun calculateScoreDistribution(
    arrowScores: List<ArrowScore>
): Map<Int, Int>
```

**Purpose:** Counts frequency of each arrow value

**Returns:** Map of score value to count

**Example:**
```kotlin
val arrows = repository.getArrowScoresForRound(roundId).getOrThrow()
val distribution = service.calculateScoreDistribution(arrows)

distribution.forEach { (score, count) ->
    println("Score $score: $count arrows")
}

// Output:
// Score 10: 25 arrows
// Score 9: 18 arrows
// Score 8: 12 arrows
// Score 7: 5 arrows
```

**Visualization:**
```kotlin
fun printDistributionChart(distribution: Map<Int, Int>) {
    distribution.toSortedMap(reverseOrder()).forEach { (score, count) ->
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

### 5. Equipment Correlation

#### Calculate Equipment Performance

```kotlin
fun calculateEquipmentPerformance(
    rounds: List<Round>,
    equipmentSetup: EquipmentSetup
): EquipmentPerformance
```

**Purpose:** Analyzes performance with specific equipment

**Returns:** Performance metrics for given equipment setup

**Example:**
```kotlin
data class EquipmentPerformance(
    val averageScore: Double,
    val roundsCount: Int,
    val xCountPercentage: Double,
    val consistency: Double,
    val comparedToOverall: Double  // e.g., +3.5% better
)

val setup = repository.getBowSetup(setupId).getOrThrow()
val rounds = repository.getRoundsByEquipment(setupId).getOrThrow()
val performance = service.calculateEquipmentPerformance(rounds, setup)

println("With ${setup.name}:")
println("  Average: ${performance.averageScore}")
println("  X-count: ${"%.1f".format(performance.xCountPercentage)}%")
println("  Consistency: ${"%.2f".format(performance.consistency)}")
println("  vs Overall: ${performance.comparedToOverall:+.1f}%")
```

---

### 6. Session Analytics

#### Calculate Session Statistics

```kotlin
fun calculateSessionStatistics(
    rounds: List<Round>,
    sessionDate: LocalDate
): SessionStatistics
```

**Purpose:** Aggregates statistics for a practice session

**Returns:** Comprehensive session metrics

**Example:**
```kotlin
data class SessionStatistics(
    val totalRounds: Int,
    val totalArrows: Int,
    val averageScore: Double,
    val highestRound: Int,
    val lowestRound: Int,
    val xCountTotal: Int,
    val duration: Duration,
    val improvement: Double  // vs previous session
)

val today = LocalDate.now()
val todayRounds = repository.getRoundsByDate(today).getOrThrow()
val stats = service.calculateSessionStatistics(todayRounds, today)

println("Session Summary for $today:")
println("  Rounds: ${stats.totalRounds}")
println("  Arrows: ${stats.totalArrows}")
println("  Average: ${"%.1f".format(stats.averageScore)}")
println("  Best: ${stats.highestRound}")
println("  X-count: ${stats.xCountTotal}")
```

---

### 7. Comparative Analytics

#### Compare Performance Periods

```kotlin
fun comparePerformancePeriods(
    period1: List<Round>,
    period2: List<Round>
): PerformanceComparison
```

**Purpose:** Compares performance between two time periods

**Example:**
```kotlin
data class PerformanceComparison(
    val averageChange: Double,       // Percentage change
    val consistencyChange: Double,   // Consistency improvement
    val xCountChange: Double,        // X-count change
    val trend: String                // "Improving", "Declining", "Stable"
)

val thisMonth = repository.getRoundsInMonth(currentMonth).getOrThrow()
val lastMonth = repository.getRoundsInMonth(previousMonth).getOrThrow()
val comparison = service.comparePerformancePeriods(thisMonth, lastMonth)

println("Month-over-month performance:")
println("  Average: ${comparison.averageChange:+.1f}%")
println("  Consistency: ${comparison.consistencyChange:+.2f}")
println("  X-count: ${comparison.xCountChange:+.1f}%")
println("  Trend: ${comparison.trend}")
```

---

## Complex Use Cases

### Personal Best Detection

```kotlin
suspend fun findPersonalBests(userId: Long): PersonalBests {
    val allRounds = repository.getAllRoundsForUser(userId).getOrThrow()

    return PersonalBests(
        highestRoundScore = allRounds.maxByOrNull { it.finalScore },
        highestEndScore = findHighestEndScore(allRounds),
        mostXCount = allRounds.maxByOrNull { it.xCount },
        bestConsistency = findMostConsistentRound(allRounds),
        longestStreak = findLongestPerfectEndStreak(allRounds)
    )
}

private fun findMostConsistentRound(rounds: List<Round>): Round? {
    return rounds.maxByOrNull { round ->
        val endScores = getEndScoresForRound(round.id)
        service.calculateConsistencyScore(endScores)
    }
}
```

### Goal Progress Tracking

```kotlin
suspend fun calculateGoalProgress(
    userId: Long,
    goal: PerformanceGoal
): GoalProgress {
    val recentRounds = repository.getRecentRounds(userId, 10).getOrThrow()
    val currentAverage = service.calculateRoundAverage(
        recentRounds.flatMap { getEndScoresForRound(it.id) }
    )

    val progress = ((currentAverage - goal.baseline) /
                   (goal.target - goal.baseline)) * 100.0

    return GoalProgress(
        current = currentAverage,
        target = goal.target,
        progressPercentage = progress.coerceIn(0.0, 100.0),
        onTrack = progress >= goal.expectedProgressByNow()
    )
}
```

---

## Testing

### Unit Test Examples

```kotlin
class StatisticsCalculationServiceTest {
    private lateinit var service: StatisticsCalculationService

    @Before
    fun setup() {
        service = StatisticsCalculationService()
    }

    @Test
    fun `calculateRoundTotal sums all end scores`() {
        val endScores = listOf(
            EndScore(totalScore = 54),
            EndScore(totalScore = 56),
            EndScore(totalScore = 58)
        )

        val total = service.calculateRoundTotal(endScores)

        assertEquals(168, total)
    }

    @Test
    fun `calculateRoundAverage returns correct average`() {
        val endScores = listOf(
            EndScore(totalScore = 50),
            EndScore(totalScore = 60),
            EndScore(totalScore = 55)
        )

        val average = service.calculateRoundAverage(endScores)

        assertEquals(55.0, average, 0.01)
    }

    @Test
    fun `calculateRoundAverage returns zero for empty list`() {
        val average = service.calculateRoundAverage(emptyList())
        assertEquals(0.0, average, 0.01)
    }

    @Test
    fun `calculateXCountPercentage returns correct percentage`() {
        val percentage = service.calculateXCountPercentage(
            xCount = 45,
            totalArrows = 60
        )

        assertEquals(75.0, percentage, 0.01)
    }

    @Test
    fun `calculateConsistencyScore returns 1_0 for identical scores`() {
        val endScores = List(10) { EndScore(totalScore = 60) }
        val consistency = service.calculateConsistencyScore(endScores)

        assertEquals(1.0, consistency, 0.01)
    }

    @Test
    fun `calculateScoreDistribution counts correctly`() {
        val arrows = listOf(
            ArrowScore(score = 10),
            ArrowScore(score = 10),
            ArrowScore(score = 9),
            ArrowScore(score = 10),
            ArrowScore(score = 8)
        )

        val distribution = service.calculateScoreDistribution(arrows)

        assertEquals(3, distribution[10])
        assertEquals(1, distribution[9])
        assertEquals(1, distribution[8])
    }
}
```

---

## Best Practices

### 1. Handle Edge Cases

```kotlin
// GOOD: Defensive programming
fun calculateAverage(scores: List<Int>): Double {
    if (scores.isEmpty()) return 0.0
    return scores.average()
}

// BAD: Can crash with empty list
fun calculateAverage(scores: List<Int>): Double {
    return scores.average()  // Throws if empty
}
```

### 2. Use Appropriate Number Types

```kotlin
// GOOD: Use Double for percentages and averages
fun calculatePercentage(part: Int, total: Int): Double {
    return (part.toDouble() / total) * 100.0
}

// BAD: Integer division loses precision
fun calculatePercentage(part: Int, total: Int): Int {
    return (part / total) * 100  // Always 0 if part < total
}
```

### 3. Document Statistical Methods

```kotlin
/**
 * Calculates standard deviation of end scores.
 *
 * Uses sample standard deviation formula:
 * σ = sqrt(Σ(xi - μ)² / (n - 1))
 *
 * @param scores List of end scores
 * @return Standard deviation, or 0.0 if < 2 samples
 */
fun calculateStandardDeviation(scores: List<Double>): Double
```

### 4. Provide Context with Statistics

```kotlin
data class StatisticWithContext(
    val value: Double,
    val label: String,
    val comparisonToAverage: Double,
    val percentile: Int,
    val trend: TrendDirection
)
```

---

## Performance Considerations

### Caching Calculations

```kotlin
class StatisticsCalculationService {
    private val cache = LruCache<String, Any>(maxSize = 50)

    fun calculateRoundStatistics(roundId: Long): RoundStatistics {
        val cacheKey = "round_stats_$roundId"

        return cache.get(cacheKey) as? RoundStatistics
            ?: computeRoundStatistics(roundId).also { stats ->
                cache.put(cacheKey, stats)
            }
    }
}
```

### Efficient Distribution Calculation

```kotlin
// GOOD: Single pass
fun calculateScoreDistribution(arrows: List<ArrowScore>): Map<Int, Int> {
    return arrows.groupingBy { it.score }.eachCount()
}

// BAD: Multiple iterations
fun calculateScoreDistribution(arrows: List<ArrowScore>): Map<Int, Int> {
    val distribution = mutableMapOf<Int, Int>()
    (0..10).forEach { score ->
        distribution[score] = arrows.count { it.score == score }
    }
    return distribution
}
```

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/service-architecture|Service Architecture]]
- [[../../../../architecture/system-architecture#domain-layer|Domain Layer]]

**Related Services:**
- [[progress-calculation-service|ProgressCalculationService]]
- [[equipment-performance-service|EquipmentPerformanceService]]

**Related Components:**
- [[../viewmodels/round-analytics-view-model|RoundAnalyticsViewModel]]
- [[../repositories/round-repository|RoundRepository]]

**Flows:**
- [[../../../flows/analytics-flow|Analytics Flow]] (Coming soon)

---

## Contributing

When modifying StatisticsCalculationService:

1. **Add tests** - Unit tests for all calculations
2. **Validate inputs** - Handle edge cases (empty lists, division by zero)
3. **Document formulas** - Statistical methods need clear documentation
4. **Consider precision** - Use appropriate number types (Double vs Int)
5. **Cache results** - Expensive calculations should be cached

---

**Status:** ✅ Production | 📝 Needs comprehensive documentation
**Test Coverage:** Unit tests for core calculations
**Last Updated:** 2025-11-01
