---
title: Equipment ViewModels Reference
tags:
  - api
  - viewmodel
  - equipment
  - bow
  - arrows
created: 2025-11-01
---

# Equipment ViewModels Reference

Consolidated reference for all equipment configuration ViewModels.

---

## Overview

Equipment ViewModels follow a consistent pattern for managing bow, arrow, and component configurations.

**Total Equipment ViewModels:** 12
- BowSetupViewModel
- ArrowSetupViewModel
- SightConfigurationViewModel
- RestConfigurationViewModel
- StabilizerConfigurationViewModel
- PlungerConfigurationViewModel
- TabConfigurationViewModel
- ReleaseAidConfigurationViewModel
- ClkrConfigurationViewModel
- StringConfigurationViewModel
- LimbsConfigurationViewModel
- RiserConfigurationViewModel

---

## Common Pattern

All equipment ViewModels share this structure:

```kotlin
class EquipmentViewModel(
    private val repository: EquipmentRepository
) : ViewModel() {

    // State
    private val _uiState = MutableStateFlow(EquipmentUiState())
    val uiState: StateFlow<EquipmentUiState> = _uiState.asStateFlow()

    // List all setups
    fun loadSetups()

    // Get active setup
    fun loadActiveSetup()

    // Create new setup
    fun createSetup(setup: Setup)

    // Update existing
    fun updateSetup(setup: Setup)

    // Set as active
    fun setActive(id: Long)

    // Delete setup
    fun deleteSetup(id: Long)
}
```

---

## BowSetupViewModel

**File:** `ui/equipment/viewmodels/BowSetupViewModel.kt`

**UI State:**
```kotlin
data class BowSetupUiState(
    val setups: List<BowSetup> = emptyList(),
    val activeSetup: BowSetup? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)
```

**Key Methods:**
```kotlin
fun loadBowSetups()
fun loadActiveSetup()
fun createBowSetup(name: String, manufacturer: String, model: String)
fun setActiveBow(setupId: Long)
fun deleteBowSetup(setupId: Long)
```

---

## ArrowSetupViewModel

**File:** `ui/equipment/viewmodels/ArrowSetupViewModel.kt`

**UI State:**
```kotlin
data class ArrowSetupUiState(
    val setups: List<ArrowSetup> = emptyList(),
    val activeSetup: ArrowSetup? = null,
    val isLoading: Boolean = false
)
```

**Key Methods:**
```kotlin
fun loadArrowSetups()
fun createArrowSetup(
    name: String,
    spine: String,
    length: Double,
    pointWeight: Int
)
fun setActiveArrows(setupId: Long)
```

---

## Component Configuration ViewModels

### SightConfigurationViewModel

**Manages:** Sight settings and distance marks

```kotlin
data class SightConfigurationUiState(
    val configuration: SightConfiguration? = null,
    val distanceMarks: Map<Int, Double> = emptyMap()
)

fun loadSightConfiguration(bowSetupId: Long)
fun updateSightMarks(distance: Int, markValue: Double)
fun saveSightConfiguration(config: SightConfiguration)
```

### StabilizerConfigurationViewModel

**Manages:** Stabilizer rod lengths and weights

```kotlin
data class StabilizerConfigurationUiState(
    val configuration: StabilizerConfiguration? = null
)

fun updateFrontRod(length: Double, weight: Double)
fun updateSideRods(length: Double, weight: Double)
fun saveConfiguration()
```

### RestConfigurationViewModel

**Manages:** Arrow rest position

```kotlin
fun updateRestPosition(vertical: Double, horizontal: Double)
```

### PlungerConfigurationViewModel

**Manages:** Plunger/button tension

```kotlin
fun updatePlungerTension(tension: Double)
fun updatePlungerPosition(position: Double)
```

---

## Usage Example

```kotlin
@Composable
fun BowSetupScreen(
    viewModel: BowSetupViewModel = viewModel()
) {
    val state by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadBowSetups()
    }

    LazyColumn {
        items(state.setups) { setup ->
            BowSetupCard(
                setup = setup,
                isActive = setup.id == state.activeSetup?.id,
                onSetActive = { viewModel.setActiveBow(setup.id) },
                onDelete = { viewModel.deleteBowSetup(setup.id) }
            )
        }
    }

    FloatingActionButton(
        onClick = { /* Show create dialog */ }
    ) {
        Icon(Icons.Default.Add, "Add")
    }
}
```

---

## Related Documentation

- [[../repositories/bow-setup-repository|BowSetupRepository]]
- [[../repositories/arrow-setup-repository|ArrowSetupRepository]]
- [[../daos/bow-setup-dao|BowSetupDao]]
- [[../../flows/equipment-management-end-to-end-flow|Equipment Management Flow]]

---

**Status:** ✅ All 12 equipment ViewModels in production
**Pattern:** Consistent CRUD + Active management
**Last Updated:** 2025-11-01
