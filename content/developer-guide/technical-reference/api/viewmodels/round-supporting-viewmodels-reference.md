---
title: Round Supporting ViewModels Reference
tags:
  - api
  - viewmodel
  - round
  - scoring
  - display
created: 2025-11-01
---

# Round Supporting ViewModels Reference

Reference for ViewModels that support round functionality.

---

## Overview

These ViewModels were extracted from the original RoundViewModel (which was 3,000+ lines) to follow single responsibility principle.

**ViewModels Covered:**
- RoundScoringViewModel
- RoundDisplayViewModel
- RoundNavigationViewModel
- SettingsViewModel
- StatisticsViewModel

---

## RoundScoringViewModel

**File:** `ui/viewmodels/RoundScoringViewModel.kt`
**Lines:** 187 lines
**Purpose:** Scoring-specific operations separate from LiveScoringViewModel

### UI State

```kotlin
data class RoundScoringUiState(
    val roundId: Long? = null,
    val currentScore: Int = 0,
    val runningTotal: Int = 0,
    val averagePerEnd: Double = 0.0
)
```

### Key Methods

```kotlin
// Calculate running totals
fun calculateRunningTotal(roundId: Long)

// Get score statistics
fun getScoreStatistics(roundId: Long)

// Get end-by-end breakdown
fun getEndBreakdown(roundId: Long)
```

### Usage Example

```kotlin
@Composable
fun ScoringStatsPanel(
    roundId: Long,
    viewModel: RoundScoringViewModel = viewModel()
) {
    val state by viewModel.uiState.collectAsState()

    LaunchedEffect(roundId) {
        viewModel.calculateRunningTotal(roundId)
    }

    Column {
        Text("Current Total: ${state.runningTotal}")
        Text("Average/End: ${"%.1f".format(state.averagePerEnd)}")
    }
}
```

---

## RoundDisplayViewModel

**File:** `ui/viewmodels/RoundDisplayViewModel.kt`
**Lines:** 216 lines
**Purpose:** Round data presentation and formatting

### UI State

```kotlin
data class RoundDisplayUiState(
    val round: Round? = null,
    val formattedScore: String = "",
    val formattedDate: String = "",
    val participantRankings: List<ParticipantRanking> = emptyList()
)
```

### Key Methods

```kotlin
// Format round for display
fun formatRoundDisplay(round: Round)

// Get participant rankings
fun getRankings(roundId: Long)

// Format score with max
fun formatScore(score: Int, maxScore: Int): String  // "540/600"
```

### Usage Example

```kotlin
@Composable
fun RoundSummaryCard(
    round: Round,
    viewModel: RoundDisplayViewModel = viewModel()
) {
    val state by viewModel.uiState.collectAsState()

    LaunchedEffect(round.id) {
        viewModel.formatRoundDisplay(round)
        viewModel.getRankings(round.id)
    }

    Card {
        Text(state.formattedScore)
        Text(state.formattedDate)

        // Rankings
        state.participantRankings.forEach { ranking ->
            RankingRow(ranking)
        }
    }
}
```

---

## RoundNavigationViewModel

**File:** `ui/viewmodels/RoundNavigationViewModel.kt`
**Lines:** 192 lines
**Purpose:** Navigation state and transitions for round screens

### UI State

```kotlin
data class RoundNavigationUiState(
    val currentScreen: RoundScreen = RoundScreen.OVERVIEW,
    val canNavigateBack: Boolean = false,
    val navigationHistory: List<RoundScreen> = emptyList()
)

enum class RoundScreen {
    OVERVIEW,
    SCORING,
    ANALYTICS,
    EQUIPMENT,
    PARTICIPANTS
}
```

### Key Methods

```kotlin
// Navigate to screen
fun navigateTo(screen: RoundScreen)

// Navigate back
fun navigateBack()

// Reset to overview
fun resetNavigation()
```

### Usage Example

```kotlin
@Composable
fun RoundScreenHost(
    roundId: Long,
    navViewModel: RoundNavigationViewModel = viewModel()
) {
    val navState by navViewModel.uiState.collectAsState()

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = navState.currentScreen == RoundScreen.OVERVIEW,
                    onClick = { navViewModel.navigateTo(RoundScreen.OVERVIEW) },
                    icon = { Icon(Icons.Default.Home, "Overview") }
                )
                // ... other items
            }
        }
    ) {
        when (navState.currentScreen) {
            RoundScreen.OVERVIEW -> RoundOverviewScreen(roundId)
            RoundScreen.SCORING -> LiveScoringScreen(roundId)
            RoundScreen.ANALYTICS -> RoundAnalyticsScreen(roundId)
            // ...
        }
    }
}
```

---

## SettingsViewModel

**File:** `ui/viewmodels/SettingsViewModel.kt`
**Purpose:** App settings management

### UI State

```kotlin
data class SettingsUiState(
    val theme: Theme = Theme.SYSTEM,
    val units: Units = Units.METRIC,
    val enableNotifications: Boolean = true,
    val autoSync: Boolean = true
)
```

### Key Methods

```kotlin
fun setTheme(theme: Theme)
fun setUnits(units: Units)
fun toggleNotifications()
fun toggleAutoSync()
```

---

## StatisticsViewModel

**File:** `ui/viewmodels/StatisticsViewModel.kt`
**Purpose:** Global statistics and insights across all rounds

### UI State

```kotlin
data class StatisticsUiState(
    val totalRounds: Int = 0,
    val totalArrows: Int = 0,
    val lifetimeAverage: Double = 0.0,
    val personalBest: Int = 0,
    val trends: List<TrendData> = emptyList()
)
```

### Key Methods

```kotlin
fun loadLifetimeStatistics()
fun loadTrends(period: TimePeriod)
fun getPersonalBests()
```

### Usage Example

```kotlin
@Composable
fun StatisticsScreen(
    viewModel: StatisticsViewModel = viewModel()
) {
    val state by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadLifetimeStatistics()
    }

    Column {
        StatCard("Total Rounds", state.totalRounds.toString())
        StatCard("Lifetime Average", "%.1f".format(state.lifetimeAverage))
        StatCard("Personal Best", state.personalBest.toString())

        TrendChart(trends = state.trends)
    }
}
```

---

## Common Patterns

### All ViewModels Follow:

1. **StateFlow for UI State**
```kotlin
private val _uiState = MutableStateFlow(UiState())
val uiState: StateFlow<UiState> = _uiState.asStateFlow()
```

2. **Repository Injection**
```kotlin
class MyViewModel(
    private val repository: Repository
) : ViewModel()
```

3. **Coroutine Usage**
```kotlin
fun loadData() {
    viewModelScope.launch {
        repository.getData()
    }
}
```

---

## Related Documentation

- [[round-view-model|RoundViewModel]] - Main round ViewModel
- [[live-scoring-view-model|LiveScoringViewModel]] - Active scoring
- [[round-analytics-view-model|RoundAnalyticsViewModel]] - Analytics
- [[../../../../architecture/round-view-model-refactoring-plan|Refactoring History]]

---

**Status:** ✅ All ViewModels in production
**Pattern:** Extracted from RoundViewModel for single responsibility
**Last Updated:** 2025-11-01
