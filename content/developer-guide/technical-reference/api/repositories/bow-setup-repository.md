---
title: BowSetupRepository API Reference
tags:
  - api
  - repository
  - equipment
  - bow
created: 2025-11-01
---

# BowSetupRepository API Reference

Complete API reference for the BowSetupRepository - managing bow configuration and equipment setup data.

---

## Overview

**File:** `data/repository/impl/BowSetupRepository.kt`
**Interface:** `BowSetupRepository`
**Status:** ✅ Production | ✅ Migrated (Week 3)

### Purpose

BowSetupRepository provides data access for bow configurations, handling:
- Bow setup CRUD operations
- Active bow management
- Setup history tracking
- Equipment correlation with performance
- Component configuration (sight, rest, stabilizer, etc.)

### Migration Status

**Migrated:** Week 3 (Equipment migration phase)
**Test Coverage:** Integration tests via repository layer

---

## Key Responsibilities

### 1. Bow Setup CRUD

#### Create Bow Setup

```kotlin
suspend fun createBowSetup(setup: BowSetup): Result<Long>
```

**Purpose:** Creates a new bow configuration

**Example:**
```kotlin
val bowSetup = BowSetup(
    name = "Competition Recurve",
    bowType = BowType.RECURVE,
    manufacturer = "Hoyt",
    model = "Formula X",
    drawWeight = 38.0,
    drawLength = 28.5,
    isActive = true,
    notes = "Olympic setup for outdoor 70m"
)

val setupId = repository.createBowSetup(bowSetup).getOrThrow()
println("Created bow setup: $setupId")
```

#### Get Bow Setup

```kotlin
suspend fun getBowSetup(setupId: Long): Result<BowSetup?>
```

**Purpose:** Retrieves a specific bow setup

**Example:**
```kotlin
val setup = repository.getBowSetup(setupId).getOrNull()
setup?.let {
    println("Bow: ${it.manufacturer} ${it.model}")
    println("Draw Weight: ${it.drawWeight}#")
}
```

#### Update Bow Setup

```kotlin
suspend fun updateBowSetup(setup: BowSetup): Result<Unit>
```

**Purpose:** Updates bow configuration

**Example:**
```kotlin
val setup = repository.getBowSetup(setupId).getOrThrow()!!
val updated = setup.copy(
    drawWeight = 40.0,  // Increased poundage
    notes = "Increased weight for indoor season"
)
repository.updateBowSetup(updated).getOrThrow()
```

#### Delete Bow Setup

```kotlin
suspend fun deleteBowSetup(setupId: Long): Result<Unit>
```

**Purpose:** Deletes a bow configuration

**Note:** May fail if setup is used in historical rounds

**Example:**
```kotlin
val result = repository.deleteBowSetup(setupId)
result.fold(
    onSuccess = { println("Setup deleted") },
    onFailure = { error ->
        when (error) {
            is SetupInUseException ->
                showError("Cannot delete: used in ${error.roundCount} rounds")
            else ->
                showError(error.message)
        }
    }
)
```

---

### 2. Active Bow Management

#### Get Active Bow Setup

```kotlin
suspend fun getActiveBowSetup(): Result<BowSetup?>
```

**Purpose:** Retrieves the currently active bow setup

**Example:**
```kotlin
val activeBow = repository.getActiveBowSetup().getOrNull()
if (activeBow != null) {
    println("Current bow: ${activeBow.name}")
} else {
    println("No active bow configured")
    promptUserToSelectBow()
}
```

#### Set Active Bow

```kotlin
suspend fun setActiveBowSetup(setupId: Long): Result<Unit>
```

**Purpose:** Marks a bow setup as active (deactivates others)

**Business Rule:** Only one bow can be active at a time

**Example:**
```kotlin
// Switch to competition bow
repository.setActiveBowSetup(competitionBowId).getOrThrow()

// Start new round with active bow
val activeBow = repository.getActiveBowSetup().getOrThrow()!!
startNewRound(bowSetupId = activeBow.id)
```

**Implementation Pattern:**
```kotlin
suspend fun setActiveBowSetup(setupId: Long): Result<Unit> = try {
    // Deactivate all bows
    val allBows = getAllBowSetups().getOrThrow()
    allBows.forEach { bow ->
        if (bow.isActive) {
            updateBowSetup(bow.copy(isActive = false))
        }
    }

    // Activate selected bow
    val selectedBow = getBowSetup(setupId).getOrThrow()
        ?: return Result.failure(BowNotFoundException(setupId))

    updateBowSetup(selectedBow.copy(isActive = true))

    Result.success(Unit)
} catch (e: Exception) {
    Result.failure(e)
}
```

---

### 3. Bow Setup History

#### Get All Bow Setups

```kotlin
suspend fun getAllBowSetups(): Result<List<BowSetup>>
```

**Purpose:** Retrieves all bow configurations

**Example:**
```kotlin
val allBows = repository.getAllBowSetups().getOrThrow()
allBows.forEach { bow ->
    val status = if (bow.isActive) "[ACTIVE]" else ""
    println("${bow.name} $status - ${bow.manufacturer} ${bow.model}")
}
```

#### Get Bow Setups by Type

```kotlin
suspend fun getBowSetupsByType(type: BowType): Result<List<BowSetup>>
```

**Purpose:** Filters bows by type (RECURVE, COMPOUND, BAREBOW)

**Example:**
```kotlin
enum class BowType {
    RECURVE,
    COMPOUND,
    BAREBOW,
    LONGBOW
}

val recurveBows = repository.getBowSetupsByType(BowType.RECURVE)
    .getOrThrow()
```

---

### 4. Equipment Component Relationships

#### Get Bow Setup with Components

```kotlin
suspend fun getBowSetupWithComponents(setupId: Long): Result<BowSetupComplete?>
```

**Purpose:** Retrieves bow with all associated components

**Returns:** Complete bow configuration including:
- Sight configuration
- Arrow rest settings
- Stabilizer setup
- Plunger configuration
- String configuration
- Limb settings
- Riser details

**Example:**
```kotlin
data class BowSetupComplete(
    val bowSetup: BowSetup,
    val sightConfig: SightConfiguration?,
    val restConfig: RestConfiguration?,
    val stabilizerConfig: StabilizerConfiguration?,
    val plungerConfig: PlungerConfiguration?,
    val stringConfig: StringConfiguration?,
    val limbsConfig: LimbsConfiguration?,
    val riserConfig: RiserConfiguration?
)

val complete = repository.getBowSetupWithComponents(setupId).getOrThrow()
complete?.let {
    println("Bow: ${it.bowSetup.name}")
    it.sightConfig?.let { sight ->
        println("Sight: ${sight.manufacturer} ${sight.model}")
    }
    it.stabilizerConfig?.let { stab ->
        println("Stabilizer: ${stab.frontLength}\" front, ${stab.sideRodLength}\" sides")
    }
}
```

---

### 5. Performance Correlation

#### Get Bow Setup Performance

```kotlin
suspend fun getBowSetupPerformance(setupId: Long): Result<BowPerformanceStats>
```

**Purpose:** Retrieves performance statistics for a bow setup

**Example:**
```kotlin
data class BowPerformanceStats(
    val roundsCount: Int,
    val averageScore: Double,
    val bestScore: Int,
    val xCountAverage: Double,
    val consistency: Double,
    val lastUsed: Long?
)

val stats = repository.getBowSetupPerformance(setupId).getOrThrow()
println("Performance with this bow:")
println("  Rounds: ${stats.roundsCount}")
println("  Average: ${"%.1f".format(stats.averageScore)}")
println("  Best: ${stats.bestScore}")
println("  Consistency: ${"%.2f".format(stats.consistency)}")
```

#### Compare Bow Setups

```kotlin
suspend fun compareBowSetups(
    setupId1: Long,
    setupId2: Long
): Result<BowComparison>
```

**Purpose:** Compares performance between two bow setups

**Example:**
```kotlin
data class BowComparison(
    val bow1: BowSetup,
    val bow2: BowSetup,
    val bow1Stats: BowPerformanceStats,
    val bow2Stats: BowPerformanceStats,
    val scoreDifference: Double,
    val betterBow: Long?  // ID of better performing bow
)

val comparison = repository.compareBowSetups(
    oldBowId,
    newBowId
).getOrThrow()

println("Old bow average: ${comparison.bow1Stats.averageScore}")
println("New bow average: ${comparison.bow2Stats.averageScore}")
println("Difference: ${comparison.scoreDifference:+.1f}")
```

---

## Reactive Data Streams

### Observing Active Bow

```kotlin
fun observeActiveBowSetup(): Flow<BowSetup?>
```

**Purpose:** Reactive stream of active bow changes

**Example:**
```kotlin
@Composable
fun BowSelectionScreen(repository: BowSetupRepository) {
    val activeBow by repository.observeActiveBowSetup()
        .collectAsState(initial = null)

    activeBow?.let { bow ->
        BowCard(
            bow = bow,
            modifier = Modifier.border(2.dp, Color.Green)
        )
    }
}
```

### Observing All Bows

```kotlin
fun observeAllBowSetups(): Flow<List<BowSetup>>
```

**Example:**
```kotlin
class EquipmentViewModel(
    private val repository: BowSetupRepository
) : ViewModel() {
    val bows: StateFlow<List<BowSetup>> = repository
        .observeAllBowSetups()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )
}
```

---

## Equipment Management Flow

### Complete Bow Setup Workflow

```kotlin
class BowSetupWorkflow(
    private val repository: BowSetupRepository
) {
    suspend fun setupNewBow(): Long {
        // 1. Create base bow setup
        val bowSetup = BowSetup(
            name = "New Competition Bow",
            bowType = BowType.RECURVE,
            manufacturer = "Hoyt",
            model = "Formula X",
            drawWeight = 38.0,
            drawLength = 28.5
        )
        val bowId = repository.createBowSetup(bowSetup).getOrThrow()

        // 2. Add sight configuration
        val sight = SightConfiguration(
            bowSetupId = bowId,
            manufacturer = "Shibuya",
            model = "Ultima RC II",
            aperture = 0.5,
            distanceMarks = mapOf(
                18 to 6.5,
                30 to 5.2,
                50 to 3.8,
                70 to 2.1
            )
        )
        repository.addSightConfiguration(sight)

        // 3. Add stabilizer setup
        val stabilizer = StabilizerConfiguration(
            bowSetupId = bowId,
            frontLength = 30.0,
            frontWeight = 8.0,
            sideRodLength = 12.0,
            sideRodWeight = 4.0
        )
        repository.addStabilizerConfiguration(stabilizer)

        // 4. Add arrow rest
        val rest = RestConfiguration(
            bowSetupId = bowId,
            manufacturer = "Shibuya",
            model = "Ultima Rest II",
            verticalPosition = 2.5,
            horizontalPosition = 0.0
        )
        repository.addRestConfiguration(rest)

        // 5. Set as active bow
        repository.setActiveBowSetup(bowId)

        return bowId
    }
}
```

---

## Testing

### Unit Test Example

```kotlin
@Test
fun `setActiveBowSetup deactivates other bows`() = runTest {
    // Arrange
    val bow1Id = repository.createBowSetup(
        BowSetup(name = "Bow 1", isActive = true, ...)
    ).getOrThrow()

    val bow2Id = repository.createBowSetup(
        BowSetup(name = "Bow 2", isActive = false, ...)
    ).getOrThrow()

    // Act
    repository.setActiveBowSetup(bow2Id).getOrThrow()

    // Assert
    val bow1 = repository.getBowSetup(bow1Id).getOrThrow()
    val bow2 = repository.getBowSetup(bow2Id).getOrThrow()

    assertFalse(bow1!!.isActive)
    assertTrue(bow2!!.isActive)
}
```

### Integration Test Example

```kotlin
@Test
fun `getBowSetupWithComponents includes all configurations`() = runTest {
    // Arrange
    val bowId = repository.createBowSetup(testBow).getOrThrow()
    repository.addSightConfiguration(testSight.copy(bowSetupId = bowId))
    repository.addStabilizerConfiguration(testStab.copy(bowSetupId = bowId))
    repository.addRestConfiguration(testRest.copy(bowSetupId = bowId))

    // Act
    val complete = repository.getBowSetupWithComponents(bowId).getOrThrow()

    // Assert
    assertNotNull(complete)
    assertNotNull(complete!!.sightConfig)
    assertNotNull(complete.stabilizerConfig)
    assertNotNull(complete.restConfig)
}
```

---

## Best Practices

### 1. Enforce Single Active Bow

```kotlin
// GOOD: Atomically switch active bow
suspend fun setActiveBowSetup(setupId: Long): Result<Unit>

// BAD: Manual management risks multiple active bows
suspend fun markBowActive(setupId: Long, isActive: Boolean)
```

### 2. Use Complete Object for Display

```kotlin
// GOOD: Single query with all data
val complete = repository.getBowSetupWithComponents(setupId)

// BAD: Multiple queries
val bow = repository.getBowSetup(setupId)
val sight = repository.getSightForBow(setupId)
val rest = repository.getRestForBow(setupId)
// ...
```

### 3. Track Equipment Changes

```kotlin
data class BowSetup(
    val id: Long = 0,
    val name: String,
    // ... other fields
    val createdAt: Long = System.currentTimeMillis(),
    val modifiedAt: Long = System.currentTimeMillis(),
    val versionNumber: Int = 1  // Track configuration changes
)
```

---

## Related Documentation

**Architecture:**
- [[../../../../architecture/system-architecture#data-layer|Data Layer Architecture]]
- [[../../../../architecture/database-migration-status|Equipment Migration Timeline]]

**Flows:**
- [[../../../flows/equipment-management-end-to-end-flow|Equipment Management Flow]]

**Related Components:**
- [[../daos/bow-setup-dao|BowSetupDao]] - Database access
- [[../viewmodels/bow-setup-view-model|BowSetupViewModel]] - UI state
- [[../services/equipment-performance-service|EquipmentPerformanceService]] - Analytics

**Related Repositories:**
- [[arrow-setup-repository|ArrowSetupRepository]]
- [[sight-configuration-repository|SightConfigurationRepository]]
- [[stabilizer-configuration-repository|StabilizerConfigurationRepository]]

---

## Contributing

When modifying BowSetupRepository:

1. **Maintain single active bow** - Only one bow can be active
2. **Add tests** - Equipment changes need test coverage
3. **Track history** - Preserve configuration changes
4. **Document components** - Complex equipment needs documentation
5. **Consider performance** - Use joins for complete object queries

---

**Status:** ✅ Production | ✅ Migrated Week 3
**Test Coverage:** Integration tests via repository layer
**Last Updated:** 2025-11-01
