---
title: RoundViewModel API Reference
tags:
  - api
  - viewmodel
  - round
  - mvvm
  - critical
created: 2025-11-01
---

# RoundViewModel API Reference

Complete API reference for the RoundViewModel - managing round lifecycle and coordination.

---

## Overview

**File:** `ui/viewmodels/RoundViewModel.kt`
**Lines:** 2,079 lines
**Status:** ✅ Production | ✅ Successfully Refactored

### Purpose

RoundViewModel manages round lifecycle, coordination, and overall state. It handles:
- Round creation and setup
- Round status management
- Participant coordination
- Round completion
- Historical data access
- Round deletion and archiving

### Refactoring History

**Original:** 3,000+ lines (included all round functionality)
**Current:** 2,079 lines
**Extracted:** 8 specialized ViewModels

**Extraction Result:** Successfully split into focused ViewModels:
- RoundScoringViewModel
- RoundManagementViewModel
- RoundCreationViewModel
- RoundDisplayViewModel
- RoundNavigationViewModel
- RoundAnalyticsViewModel

**See:** [[../../../../architecture/round-view-model-audit|Audit Report]] | [[../../../../architecture/round-view-model-refactoring-plan|Refactoring Plan]]

---

## UI State

```kotlin
data class RoundUiState(
    val roundId: Long? = null,
    val round: Round? = null,
    val status: RoundStatus = RoundStatus.PLANNED,

    // Participants
    val participants: List<Participant> = emptyList(),

    // Progress
    val endsCompleted: Int = 0,
    val endsTotal: Int = 0,

    // Scoring summary
    val totalScore: Int = 0,
    val xCount: Int = 0,

    // Equipment
    val activeBowSetup: BowSetup? = null,

    // UI flags
    val isLoading: Boolean = false,
    val error: String? = null
)
```

---

## Key Methods

### Round Lifecycle

```kotlin
// Load round data
fun loadRound(roundId: Long)

// Start round
fun startRound()

// Complete round
fun completeRound()

// Delete round
fun deleteRound()
```

### Participants

```kotlin
// Add participant
fun addParticipant(participantId: Long)

// Remove participant
fun removeParticipant(participantId: Long)

// Get participant scores
fun getParticipantScores(): Map<Long, Int>
```

---

## Usage Example

```kotlin
@Composable
fun RoundScreen(
    roundId: Long,
    viewModel: RoundViewModel = viewModel()
) {
    LaunchedEffect(roundId) {
        viewModel.loadRound(roundId)
    }

    val state by viewModel.uiState.collectAsState()

    when (state.status) {
        RoundStatus.PLANNED -> RoundSetupView(viewModel)
        RoundStatus.ACTIVE -> LiveScoringView(roundId)
        RoundStatus.COMPLETED -> RoundSummaryView(state)
    }
}
```

---

## Related Documentation

- [[../../../../architecture/round-view-model-audit|Complete Audit]]
- [[../../../../architecture/round-view-model-refactoring-plan|Refactoring Plan]]
- [[live-scoring-view-model|LiveScoringViewModel]]
- [[../repositories/round-repository|RoundRepository]]

---

**Status:** ✅ Production | ✅ Successfully refactored from 3,000+ lines
**Last Updated:** 2025-11-01
