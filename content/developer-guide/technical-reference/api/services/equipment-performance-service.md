---
title: EquipmentPerformanceService API Reference
tags:
  - api
  - service
  - equipment
  - analytics
  - business-logic
created: 2025-11-01
---

# EquipmentPerformanceService API Reference

Complete API reference for the EquipmentPerformanceService - analyzing equipment effectiveness and performance correlation.

---

## Overview

**File:** `domain/services/EquipmentPerformanceService.kt`
**Type:** Business Logic Service
**Status:** ✅ Production | 📝 Needs comprehensive documentation

### Purpose

EquipmentPerformanceService analyzes the correlation between equipment configurations and shooting performance, providing:
- Equipment-score correlation analysis
- Performance comparison between setups
- Equipment effectiveness metrics
- Component impact analysis
- Recommendation engine for equipment changes

---

## API Methods

### 1. Equipment Performance Analysis

#### Get Equipment Performance

```kotlin
fun getEquipmentPerformance(
    equipmentId: Long,
    rounds: List<Round>
): EquipmentPerformanceStats
```

**Purpose:** Analyzes performance with specific equipment

**Returns:**
```kotlin
data class EquipmentPerformanceStats(
    val roundsCount: Int,
    val averageScore: Double,
    val bestScore: Int,
    val worstScore: Int,
    val xCountAverage: Double,
    val consistency: Double,          // 0.0 to 1.0
    val lastUsed: Long?,
    val totalArrows: Int,
    val scoreImprovement: Double      // % vs first rounds
)
```

**Example:**
```kotlin
val bowSetup = repository.getBowSetup(setupId).getOrThrow()
val rounds = repository.getRoundsByEquipment(setupId).getOrThrow()
val performance = service.getEquipmentPerformance(setupId, rounds)

println("Performance with ${bowSetup.name}:")
println("  Rounds: ${performance.roundsCount}")
println("  Average: ${"%.1f".format(performance.averageScore)}")
println("  Best: ${performance.bestScore}")
println("  Consistency: ${"%.2f".format(performance.consistency)}")
println("  Improvement: ${performance.scoreImprovement:+.1f}%")
```

---

### 2. Equipment Comparison

#### Compare Equipment Setups

```kotlin
fun compareEquipmentSetups(
    setup1Id: Long,
    setup2Id: Long,
    rounds1: List<Round>,
    rounds2: List<Round>
): EquipmentComparison
```

**Purpose:** Compares performance between two equipment configurations

**Returns:**
```kotlin
data class EquipmentComparison(
    val setup1: BowSetup,
    val setup2: BowSetup,
    val setup1Stats: EquipmentPerformanceStats,
    val setup2Stats: EquipmentPerformanceStats,
    val scoreDifference: Double,
    val consistencyDifference: Double,
    val xCountDifference: Double,
    val betterSetup: Long?,           // ID of better performing setup
    val confidence: Double,            // 0.0 to 1.0 based on sample size
    val recommendation: String
)
```

**Example:**
```kotlin
val comparison = service.compareEquipmentSetups(
    oldBowId,
    newBowId,
    oldRounds,
    newRounds
)

println("Old bow: ${comparison.setup1.name}")
println("  Average: ${comparison.setup1Stats.averageScore}")

println("New bow: ${comparison.setup2.name}")
println("  Average: ${comparison.setup2Stats.averageScore}")

println("Difference: ${comparison.scoreDifference:+.1f}")
println("Better setup: ${comparison.betterSetup}")
println("Confidence: ${"%.1f".format(comparison.confidence * 100)}%")
println("Recommendation: ${comparison.recommendation}")

// Output:
// Old bow: Practice Bow
//   Average: 532.5
// New bow: Competition Bow
//   Average: 548.2
// Difference: +15.7
// Better setup: 2
// Confidence: 85.0%
// Recommendation: New bow shows significant improvement. Continue using.
```

---

### 3. Component Impact Analysis

#### Analyze Component Change Impact

```kotlin
fun analyzeComponentChange(
    beforeRounds: List<Round>,
    afterRounds: List<Round>,
    component: EquipmentComponent
): ComponentChangeImpact
```

**Purpose:** Analyzes impact of changing a specific component (sight, stabilizer, etc.)

**Returns:**
```kotlin
data class ComponentChangeImpact(
    val component: EquipmentComponent,
    val beforeAverage: Double,
    val afterAverage: Double,
    val scoreChange: Double,
    val consistencyChange: Double,
    val xCountChange: Double,
    val impactLevel: ImpactLevel,     // HIGH, MEDIUM, LOW, NONE
    val recommendation: String
)

enum class ImpactLevel {
    HIGH,      // > 5% change
    MEDIUM,    // 2-5% change
    LOW,       // 0.5-2% change
    NONE       // < 0.5% change
}
```

**Example:**
```kotlin
// Changed sight from old to new
val beforeRounds = repository.getRoundsByDateRange(
    startDate = changeDate - 30.days,
    endDate = changeDate
).getOrThrow()

val afterRounds = repository.getRoundsByDateRange(
    startDate = changeDate,
    endDate = changeDate + 30.days
).getOrThrow()

val impact = service.analyzeComponentChange(
    beforeRounds,
    afterRounds,
    EquipmentComponent.SIGHT
)

println("Sight change impact:")
println("  Before: ${impact.beforeAverage}")
println("  After: ${impact.afterAverage}")
println("  Change: ${impact.scoreChange:+.1f}")
println("  Impact: ${impact.impactLevel}")
println("  ${impact.recommendation}")

// Output:
// Sight change impact:
//   Before: 532.5
//   After: 548.2
//   Change: +15.7
//   Impact: HIGH
//   Significant improvement observed. New sight is effective.
```

---

### 4. Equipment Recommendations

#### Get Equipment Recommendations

```kotlin
fun getEquipmentRecommendations(
    currentSetup: BowSetup,
    userHistory: List<Round>
): EquipmentRecommendations
```

**Purpose:** Generates recommendations for equipment changes

**Returns:**
```kotlin
data class EquipmentRecommendations(
    val currentPerformance: EquipmentPerformanceStats,
    val recommendations: List<Recommendation>,
    val strengths: List<String>,
    val weaknesses: List<String>
)

data class Recommendation(
    val component: EquipmentComponent,
    val priority: Priority,           // HIGH, MEDIUM, LOW
    val reason: String,
    val potentialImprovement: Double  // Estimated % improvement
)
```

**Example:**
```kotlin
val setup = repository.getActiveBowSetup().getOrThrow()!!
val history = repository.getRecentRounds(userId, 20).getOrThrow()
val recommendations = service.getEquipmentRecommendations(setup, history)

println("Current performance: ${recommendations.currentPerformance.averageScore}")
println("\nStrengths:")
recommendations.strengths.forEach { println("  ✓ $it") }

println("\nRecommendations:")
recommendations.recommendations
    .sortedByDescending { it.priority }
    .forEach { rec ->
        println("  ${rec.priority}: ${rec.component}")
        println("    ${rec.reason}")
        println("    Potential: +${"%.1f".format(rec.potentialImprovement)}%")
    }

// Output:
// Current performance: 532.5
//
// Strengths:
//   ✓ Consistent X-count (75%)
//   ✓ Stable end-to-end performance
//
// Recommendations:
//   HIGH: STABILIZER
//     Consistency declining in windy conditions
//     Potential: +3.5%
//   MEDIUM: SIGHT
//     Vertical grouping inconsistent at 70m
//     Potential: +2.0%
```

---

## Usage Examples

### Equipment Change Tracking

```kotlin
class EquipmentChangeTracker(
    private val service: EquipmentPerformanceService,
    private val repository: RoundRepository
) {
    suspend fun trackComponentChange(
        component: EquipmentComponent,
        changeDate: Long
    ) {
        val before = repository.getRoundsByDateRange(
            changeDate - 30.days.inWholeMilliseconds,
            changeDate
        ).getOrThrow()

        val after = repository.getRoundsByDateRange(
            changeDate,
            changeDate + 30.days.inWholeMilliseconds
        ).getOrThrow()

        if (after.size >= 5) {  // Enough data
            val impact = service.analyzeComponentChange(before, after, component)

            // Log result
            println("Component: ${impact.component}")
            println("Impact: ${impact.impactLevel}")
            println("Change: ${impact.scoreChange:+.1f}")

            // Notify user
            if (impact.impactLevel == ImpactLevel.HIGH) {
                notifyUser("${component} change had significant impact!")
            }
        }
    }
}
```

### Equipment Recommendation UI

```kotlin
@Composable
fun EquipmentRecommendationsScreen(
    service: EquipmentPerformanceService,
    setup: BowSetup,
    history: List<Round>
) {
    val recommendations = remember(setup, history) {
        service.getEquipmentRecommendations(setup, history)
    }

    LazyColumn {
        // Current performance
        item {
            PerformanceCard(recommendations.currentPerformance)
        }

        // Strengths
        items(recommendations.strengths) { strength ->
            StrengthItem(text = strength)
        }

        // Recommendations
        items(recommendations.recommendations) { rec ->
            RecommendationCard(
                component = rec.component,
                priority = rec.priority,
                reason = rec.reason,
                improvement = rec.potentialImprovement
            )
        }
    }
}
```

---

## Testing

```kotlin
class EquipmentPerformanceServiceTest {
    private lateinit var service: EquipmentPerformanceService

    @Before
    fun setup() {
        service = EquipmentPerformanceService()
    }

    @Test
    fun `compareEquipmentSetups identifies better setup`() {
        val rounds1 = List(10) { Round(finalScore = 530 + it) }
        val rounds2 = List(10) { Round(finalScore = 545 + it) }

        val comparison = service.compareEquipmentSetups(
            1L, 2L, rounds1, rounds2
        )

        assertEquals(2L, comparison.betterSetup)
        assertTrue(comparison.scoreDifference > 10.0)
    }

    @Test
    fun `analyzeComponentChange detects high impact`() {
        val before = List(10) { Round(finalScore = 530) }
        val after = List(10) { Round(finalScore = 550) }

        val impact = service.analyzeComponentChange(
            before, after, EquipmentComponent.SIGHT
        )

        assertEquals(ImpactLevel.HIGH, impact.impactLevel)
        assertTrue(impact.scoreChange > 15.0)
    }
}
```

---

## Best Practices

### 1. Require Sufficient Data

```kotlin
fun getEquipmentPerformance(
    equipmentId: Long,
    rounds: List<Round>
): EquipmentPerformanceStats {
    require(rounds.size >= 3) {
        "Need at least 3 rounds for reliable statistics"
    }
    // ... calculation
}
```

### 2. Include Confidence Levels

```kotlin
data class EquipmentComparison(
    // ... other fields
    val confidence: Double,  // Based on sample size
    val minRoundsRecommended: Int = 10
)

fun calculateConfidence(sampleSize: Int): Double {
    return minOf(sampleSize / 10.0, 1.0)  // Max confidence at 10+ rounds
}
```

### 3. Provide Context with Recommendations

```kotlin
data class Recommendation(
    val component: EquipmentComponent,
    val reason: String,  // Why this recommendation
    val evidence: String,  // What data supports it
    val potentialImprovement: Double
)
```

---

## Related Documentation

**Related Services:**
- [[statistics-calculation-service|StatisticsCalculationService]]

**Related Components:**
- [[../repositories/bow-setup-repository|BowSetupRepository]]
- [[../viewmodels/round-analytics-view-model|RoundAnalyticsViewModel]]

**Flows:**
- [[../../../flows/equipment-management-end-to-end-flow|Equipment Management Flow]]

---

**Status:** ✅ Production | 📝 Needs comprehensive documentation
**Last Updated:** 2025-11-01
