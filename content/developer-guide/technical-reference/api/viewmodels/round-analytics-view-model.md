---
title: RoundAnalyticsViewModel API Reference
tags:
  - api
  - viewmodel
  - analytics
  - statistics
  - mvvm
created: 2025-11-01
---

# RoundAnalyticsViewModel API Reference

Complete API reference for the RoundAnalyticsViewModel - managing analytics and statistics UI state.

---

## Overview

**File:** `ui/viewmodels/RoundAnalyticsViewModel.kt`
**Lines:** 605 lines
**Status:** ✅ Production | 📝 Needs comprehensive documentation

### Purpose

RoundAnalyticsViewModel manages UI state for round analytics and performance statistics, providing:
- Score statistics and aggregations
- Performance trends over time
- Equipment correlation analysis
- Distribution charts and graphs
- Comparative analytics
- Historical performance tracking

---

## UI State

```kotlin
data class AnalyticsUiState(
    val roundId: Long?,
    val isLoading: Boolean = false,
    val error: String? = null,

    // Basic stats
    val totalScore: Int = 0,
    val averagePerEnd: Double = 0.0,
    val averagePerArrow: Double = 0.0,
    val xCount: Int = 0,
    val xCountPercentage: Double = 0.0,

    // Distribution
    val scoreDistribution: Map<Int, Int> = emptyMap(),
    val endScores: List<Int> = emptyList(),

    // Trends
    val performanceTrend: TrendDirection = TrendDirection.STABLE,
    val consistencyScore: Double = 0.0,

    // Equipment
    val bowSetup: BowSetup? = null,
    val equipmentPerformance: EquipmentPerformanceStats? = null,

    // Comparisons
    val personalBest: Int? = null,
    val averageComparison: Double = 0.0  // vs user average
)
```

---

## Key Methods

### 1. Load Analytics

```kotlin
fun loadAnalytics(roundId: Long)
```

**Purpose:** Loads comprehensive analytics for a round

**Example:**
```kotlin
class RoundAnalyticsScreen(viewModel: RoundAnalyticsViewModel) {
    LaunchedEffect(roundId) {
        viewModel.loadAnalytics(roundId)
    }

    val state by viewModel.uiState.collectAsState()

    if (state.isLoading) {
        LoadingIndicator()
    } else {
        AnalyticsContent(state)
    }
}
```

### 2. Refresh Analytics

```kotlin
fun refreshAnalytics()
```

**Purpose:** Refreshes analytics data

**Example:**
```kotlin
PullToRefresh(
    onRefresh = { viewModel.refreshAnalytics() }
) {
    AnalyticsContent()
}
```

---

## Analytics Displays

### Score Distribution Chart

```kotlin
@Composable
fun ScoreDistributionChart(
    distribution: Map<Int, Int>,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        distribution.toSortedMap(reverseOrder()).forEach { (score, count) ->
            Row {
                Text("$score", modifier = Modifier.width(24.dp))
                LinearProgressIndicator(
                    progress = count / distribution.values.max().toFloat(),
                    modifier = Modifier.weight(1f)
                )
                Text("$count", modifier = Modifier.width(32.dp))
            }
        }
    }
}
```

### End Scores Trend Line

```kotlin
@Composable
fun EndScoresTrendChart(
    endScores: List<Int>,
    modifier: Modifier = Modifier
) {
    val average = endScores.average()

    Canvas(modifier = modifier.fillMaxWidth().height(200.dp)) {
        // Draw average line
        drawLine(
            color = Color.Gray,
            start = Offset(0f, size.height / 2),
            end = Offset(size.width, size.height / 2),
            strokeWidth = 2.dp.toPx()
        )

        // Draw end scores as connected points
        val points = endScores.mapIndexed { index, score ->
            val x = (index / endScores.size.toFloat()) * size.width
            val y = size.height * (1 - (score / 60f))  // Normalize to 0-60
            Offset(x, y)
        }

        points.zipWithNext().forEach { (p1, p2) ->
            drawLine(
                color = Color.Blue,
                start = p1,
                end = p2,
                strokeWidth = 3.dp.toPx()
            )
        }

        // Draw points
        points.forEach { point ->
            drawCircle(
                color = Color.Blue,
                radius = 4.dp.toPx(),
                center = point
            )
        }
    }
}
```

---

## Usage Examples

### Complete Analytics Screen

```kotlin
@Composable
fun RoundAnalyticsScreen(
    roundId: Long,
    viewModel: RoundAnalyticsViewModel = viewModel()
) {
    LaunchedEffect(roundId) {
        viewModel.loadAnalytics(roundId)
    }

    val state by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Analytics") })
        }
    ) { padding ->
        if (state.isLoading) {
            LoadingIndicator()
        } else {
            LazyColumn(modifier = Modifier.padding(padding)) {
                // Summary stats
                item {
                    StatsCard(
                        totalScore = state.totalScore,
                        averagePerEnd = state.averagePerEnd,
                        averagePerArrow = state.averagePerArrow,
                        xCount = state.xCount
                    )
                }

                // Score distribution
                item {
                    Card {
                        Text("Score Distribution", style = MaterialTheme.typography.h6)
                        ScoreDistributionChart(state.scoreDistribution)
                    }
                }

                // End scores trend
                item {
                    Card {
                        Text("End Scores", style = MaterialTheme.typography.h6)
                        EndScoresTrendChart(state.endScores)
                    }
                }

                // Equipment performance
                state.equipmentPerformance?.let { equipPerf ->
                    item {
                        EquipmentPerformanceCard(equipPerf)
                    }
                }

                // Comparison
                state.personalBest?.let { pb ->
                    item {
                        ComparisonCard(
                            currentScore = state.totalScore,
                            personalBest = pb,
                            averageComparison = state.averageComparison
                        )
                    }
                }
            }
        }
    }
}
```

---

## Testing

### Unit Test Example

```kotlin
class RoundAnalyticsViewModelTest {
    private lateinit var viewModel: RoundAnalyticsViewModel
    private lateinit var mockRepository: RoundRepository
    private lateinit var mockStatsService: StatisticsCalculationService

    @Before
    fun setup() {
        mockRepository = mockk()
        mockStatsService = mockk()
        viewModel = RoundAnalyticsViewModel(mockRepository, mockStatsService)
    }

    @Test
    fun `loadAnalytics updates state with statistics`() = runTest {
        // Arrange
        val roundId = 123L
        val endScores = List(10) { EndScore(totalScore = 54 + it) }

        coEvery { mockRepository.getEndScoresForRound(roundId) } returns
            Result.success(endScores)
        every { mockStatsService.calculateRoundTotal(endScores) } returns 545
        every { mockStatsService.calculateRoundAverage(endScores) } returns 54.5

        // Act
        viewModel.loadAnalytics(roundId)
        advanceUntilIdle()

        // Assert
        val state = viewModel.uiState.value
        assertEquals(545, state.totalScore)
        assertEquals(54.5, state.averagePerEnd, 0.01)
        assertFalse(state.isLoading)
    }
}
```

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/mvvm-patterns|MVVM Patterns]]
- [[../../../../architecture/scoring-view-model-architecture|Scoring VM Architecture]]

**Related Components:**
- [[../services/statistics-calculation-service|StatisticsCalculationService]]
- [[../repositories/round-repository|RoundRepository]]
- [[round-view-model|RoundViewModel]]

**Flows:**
- [[../../../flows/analytics-flow|Analytics Flow]] (Coming soon)

---

**Status:** ✅ Production | 📝 Needs comprehensive documentation
**Lines:** 605 lines
**Last Updated:** 2025-11-01
