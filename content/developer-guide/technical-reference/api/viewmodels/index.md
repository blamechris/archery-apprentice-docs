---
title: ViewModels API Reference
tags:
  - api
  - viewmodels
  - mvvm
  - state-management
created: 2025-11-01
---

# ViewModels API Reference

Complete reference for all ViewModels in Archery Apprentice.

---

## Overview

ViewModels manage UI state and handle user interactions following the MVVM pattern. They:
- Hold and expose UI state via StateFlow
- Process user actions
- Coordinate with repositories and services
- Survive configuration changes

**Total ViewModels:** 21

---

## Core Scoring ViewModels

### LiveScoringViewModel
**Purpose:** Real-time arrow scoring during active rounds

**Status:** ✅ Documented
**File:** `ui/viewmodels/LiveScoringViewModel.kt` (2,808 lines)
**Documentation:** [[live-scoring-view-model|Full API Reference →]]

**Key Responsibilities:**
- Active end scoring
- Arrow value input
- X-ring tracking
- End completion
- Tournament sync
- Real-time leaderboard

**Critical Analysis:** [[../../../../architecture/live-scoring-vm-analysis|Architecture Analysis]]

---

### RoundViewModel
**Purpose:** Round lifecycle and management

**Status:** ✅ Documented
**File:** `ui/viewmodels/RoundViewModel.kt` (2,079 lines)
**Documentation:** [[round-view-model|Full API Reference →]]

**Key Responsibilities:**
- Round creation
- Round status management
- Participant management
- Round completion
- Historical data access

**Refactoring:** [[../../../../architecture/round-view-model-refactoring-plan|Refactoring Plan]]

---

### RoundScoringViewModel
**Purpose:** Scoring-specific operations

**Status:** 🚧 Partial
**File:** `ui/viewmodels/RoundScoringViewModel.kt` (187 lines)
**Documentation:** Coming soon

---

## Equipment ViewModels

### BowSetupViewModel
**Purpose:** Bow configuration management

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/BowSetupViewModel.kt`

**Key Responsibilities:**
- Bow setup CRUD operations
- Active bow selection
- Setup history tracking

**Used in:** [[../../../../technical-reference/flows/equipment-management-end-to-end-flow|Equipment Flow]]

---

### ArrowSetupViewModel
**Purpose:** Arrow configuration management

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/ArrowSetupViewModel.kt`

---

### SightConfigurationViewModel
**Purpose:** Sight settings management

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/SightConfigurationViewModel.kt`

---

### RestConfigurationViewModel
**Purpose:** Arrow rest configuration

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/RestConfigurationViewModel.kt`

---

### StabilizerConfigurationViewModel
**Purpose:** Stabilizer setup management

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/StabilizerConfigurationViewModel.kt`

---

### PlungerConfigurationViewModel
**Purpose:** Plunger/button configuration

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/PlungerConfigurationViewModel.kt`

---

### TabConfigurationViewModel
**Purpose:** Finger tab settings

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/TabConfigurationViewModel.kt`

---

### ReleaseAidConfigurationViewModel
**Purpose:** Release aid configuration (compound bows)

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/ReleaseAidConfigurationViewModel.kt`

---

### ClkrConfigurationViewModel
**Purpose:** Clicker settings (recurve bows)

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/ClkrConfigurationViewModel.kt`

---

### StringConfigurationViewModel
**Purpose:** Bowstring configuration

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/StringConfigurationViewModel.kt`

---

### LimbsConfigurationViewModel
**Purpose:** Bow limb settings

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/LimbsConfigurationViewModel.kt`

---

### RiserConfigurationViewModel
**Purpose:** Bow riser configuration

**Status:** 📝 Needs documentation
**File:** `ui/equipment/viewmodels/RiserConfigurationViewModel.kt`

---

## Analytics ViewModels

### RoundAnalyticsViewModel
**Purpose:** Round performance analytics

**Status:** 📝 Needs documentation
**File:** `ui/viewmodels/RoundAnalyticsViewModel.kt` (605 lines)

**Key Responsibilities:**
- Score statistics
- Performance trends
- Equipment correlation
- Session analytics

---

### StatisticsViewModel
**Purpose:** Global statistics and insights

**Status:** 📝 Needs documentation
**File:** `ui/viewmodels/StatisticsViewModel.kt`

---

## Management ViewModels

### RoundManagementViewModel
**Purpose:** Round list and filtering

**Status:** 📝 Needs documentation
**File:** `ui/viewmodels/RoundManagementViewModel.kt` (495 lines)

**Key Responsibilities:**
- Round listing
- Search and filter
- Bulk operations
- Round deletion

---

### RoundCreationViewModel
**Purpose:** New round setup

**Status:** 📝 Needs documentation
**File:** `ui/viewmodels/RoundCreationViewModel.kt` (480 lines)

**Key Responsibilities:**
- Round configuration
- Participant setup
- Equipment selection
- Validation

---

## Display & Navigation ViewModels

### RoundDisplayViewModel
**Purpose:** Round data presentation

**Status:** 📝 Needs documentation
**File:** `ui/viewmodels/RoundDisplayViewModel.kt` (216 lines)

---

### RoundNavigationViewModel
**Purpose:** Navigation state management

**Status:** 📝 Needs documentation
**File:** `ui/viewmodels/RoundNavigationViewModel.kt` (192 lines)

---

## Settings ViewModels

### SettingsViewModel
**Purpose:** App settings management

**Status:** 📝 Needs documentation
**File:** `ui/viewmodels/SettingsViewModel.kt`

**Architecture:** [[../../../../architecture/settings-architecture|Settings Architecture]]

---

## ViewModel Patterns

### State Management

All ViewModels follow this pattern:

```kotlin
class MyViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(UiState.initial())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    fun handleAction(action: Action) {
        when (action) {
            // Handle actions
        }
    }
}
```

### UI State

```kotlin
data class UiState(
    val data: Data? = null,
    val isLoading: Boolean = false,
    val error: String? = null
) {
    companion object {
        fun initial() = UiState()
    }
}
```

### Dependency Injection

```kotlin
class MyViewModel(
    private val repository: Repository,
    private val service: Service
) : ViewModel() {
    // Factory pattern used for instantiation
}
```

---

## God Class Warning

### Critical ViewModels Requiring Refactoring

**LiveScoringViewModel (2,808 lines)**
- ⚠️ **Too large**: Violates single responsibility
- **Status**: Active refactoring planned
- **Issue**: Handles 12+ distinct domains
- **Target**: Extract to 5 services (~1,600 lines, 57% reduction)
- **See:** [[../../../../architecture/live-scoring-vm-analysis|Full Analysis]]

**RoundViewModel (2,079 lines)**
- ⚠️ **Large**: Successfully extracted from 3,000+ lines
- **Status**: Stable after extraction
- **History**: Split into 8 ViewModels
- **See:** [[../../../../architecture/round-view-model-audit|Audit Report]]

---

## Testing ViewModels

### Unit Test Pattern

```kotlin
@Test
fun `action updates state correctly`() = runTest {
    val viewModel = MyViewModel(mockRepository)

    viewModel.handleAction(Action.DoSomething)

    val state = viewModel.uiState.value
    assertEquals(expected, state.data)
}
```

### StateFlow Testing

```kotlin
@Test
fun `stateFlow emits correct values`() = runTest {
    val viewModel = MyViewModel(mockRepository)
    val states = mutableListOf<UiState>()

    val job = launch {
        viewModel.uiState.collect { states.add(it) }
    }

    viewModel.performAction()

    job.cancel()
    assertEquals(expectedStates, states)
}
```

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/mvvm-patterns|MVVM Patterns]]
- [[../../../../architecture/system-architecture|System Architecture]]
- [[../../../../architecture/scoring-view-model-architecture|Scoring VM Architecture]]

**Flows:**
- [[../../../flows/scoring-flow|Scoring Flow]]
- [[../../../flows/round-lifecycle-flow|Round Lifecycle]]
- [[../../../flows/equipment-management-end-to-end-flow|Equipment Flow]]

**Testing:**
- [[../../../../testing/test-quality-standards|Testing Standards]]

---

## Contributing

Help us document the remaining ViewModels!

**Priority Documentation Needed:**
1. Equipment ViewModels (11 remaining)
2. Analytics ViewModels
3. Management ViewModels

**Template:** [[../index#contributing-to-api-docs|API Documentation Template]]

---

**Status:** 5/21 ViewModels documented (24%)
**Last Updated:** 2025-11-01
