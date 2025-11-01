---
title: Equipment Repositories Reference
tags:
  - api
  - repository
  - equipment
  - bow
  - configuration
created: 2025-11-01
---

# Equipment Repositories Reference

Consolidated reference for equipment configuration repositories.

---

## Overview

Equipment repositories provide data access for bow components and configurations, following a consistent pattern with offline-first architecture.

**Repositories Covered (9):**
- SightConfigurationRepository
- RestConfigurationRepository
- StabilizerConfigurationRepository
- PlungerConfigurationRepository
- TabConfigurationRepository
- ReleaseAidConfigurationRepository
- ClkrConfigurationRepository
- StringConfigurationRepository
- LimbsConfigurationRepository

**Already Documented:**
- BowSetupRepository
- ArrowSetupRepository
- RiserConfigurationRepository

---

## Common Repository Pattern

All equipment repositories follow this structure:

```kotlin
class EquipmentConfigurationRepository(
    private val dao: EquipmentConfigurationDao
) {
    // Get configuration for bow setup
    suspend fun getForBowSetup(setupId: Long): Result<Configuration?>

    // Save configuration
    suspend fun save(config: Configuration): Result<Long>

    // Update configuration
    suspend fun update(config: Configuration): Result<Unit>

    // Delete configuration
    suspend fun delete(config: Configuration): Result<Unit>

    // Observe configuration changes
    fun observeForBowSetup(setupId: Long): Flow<Configuration?>
}
```

---

## SightConfigurationRepository

**File:** `data/repositories/SightConfigurationRepository.kt`
**Purpose:** Sight settings with distance marks

### API

```kotlin
class SightConfigurationRepository(
    private val dao: SightConfigurationDao
) {
    // CRUD operations
    suspend fun getForBowSetup(setupId: Long): Result<SightConfiguration?>
    suspend fun save(config: SightConfiguration): Result<Long>
    suspend fun update(config: SightConfiguration): Result<Unit>
    suspend fun delete(config: SightConfiguration): Result<Unit>

    // Distance marks
    suspend fun getDistanceMarks(sightId: Long): Result<Map<Int, Double>>
    suspend fun updateDistanceMark(sightId: Long, distance: Int, mark: Double): Result<Unit>
    suspend fun deleteDistanceMark(sightId: Long, distance: Int): Result<Unit>

    // Observe changes
    fun observeForBowSetup(setupId: Long): Flow<SightConfiguration?>
}
```

### Usage Example

```kotlin
// Create sight configuration
val sightConfig = SightConfiguration(
    bowSetupId = bowId,
    manufacturer = "Shibuya",
    model = "Ultima RC II",
    scopeMagnification = 4.0,
    apertureDiameter = 0.5,
    notes = "Competition sight"
)

val sightId = sightRepository.save(sightConfig)
    .getOrThrow()

// Add distance marks
sightRepository.updateDistanceMark(sightId, 18, 6.5)  // 18m @ 6.5
sightRepository.updateDistanceMark(sightId, 30, 4.2)  // 30m @ 4.2
sightRepository.updateDistanceMark(sightId, 50, 2.1)  // 50m @ 2.1

// Retrieve with marks
val config = sightRepository.getForBowSetup(bowId).getOrNull()
val marks = sightRepository.getDistanceMarks(sightId).getOrNull()
```

---

## RestConfigurationRepository

**File:** `data/repositories/RestConfigurationRepository.kt`
**Purpose:** Arrow rest position settings

### API

```kotlin
class RestConfigurationRepository(
    private val dao: RestConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<RestConfiguration?>
    suspend fun save(config: RestConfiguration): Result<Long>
    suspend fun update(config: RestConfiguration): Result<Unit>
    suspend fun delete(config: RestConfiguration): Result<Unit>

    // Position adjustments
    suspend fun updatePosition(
        configId: Long,
        vertical: Double,
        horizontal: Double
    ): Result<Unit>

    fun observeForBowSetup(setupId: Long): Flow<RestConfiguration?>
}
```

### Usage Example

```kotlin
val restConfig = RestConfiguration(
    bowSetupId = bowId,
    manufacturer = "Shibuya",
    model = "Ultima Rest II",
    verticalPosition = 2.5,
    horizontalPosition = 0.0,
    notes = "Center shot"
)

restRepository.save(restConfig)

// Adjust position
restRepository.updatePosition(
    configId = restId,
    vertical = 2.6,     // +0.1mm up
    horizontal = -0.2   // 0.2mm left
)
```

---

## StabilizerConfigurationRepository

**File:** `data/repositories/StabilizerConfigurationRepository.kt`
**Purpose:** Stabilizer rod configuration

### API

```kotlin
class StabilizerConfigurationRepository(
    private val dao: StabilizerConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<StabilizerConfiguration?>
    suspend fun save(config: StabilizerConfiguration): Result<Long>
    suspend fun update(config: StabilizerConfiguration): Result<Unit>
    suspend fun delete(config: StabilizerConfiguration): Result<Unit>

    // Rod configuration
    suspend fun updateFrontRod(
        configId: Long,
        length: Double,
        weight: Double
    ): Result<Unit>

    suspend fun updateSideRods(
        configId: Long,
        length: Double,
        weight: Double
    ): Result<Unit>

    fun observeForBowSetup(setupId: Long): Flow<StabilizerConfiguration?>
}
```

### Usage Example

```kotlin
val stabConfig = StabilizerConfiguration(
    bowSetupId = bowId,
    manufacturer = "Doinker",
    frontRodLength = 30.0,      // inches
    frontRodWeight = 12.0,      // oz
    sideRodLength = 12.0,       // inches
    sideRodWeight = 8.0,        // oz
    vBarAngle = 45.0            // degrees
)

stabRepository.save(stabConfig)

// Experiment with front rod
stabRepository.updateFrontRod(
    configId = stabId,
    length = 32.0,
    weight = 14.0
)
```

---

## PlungerConfigurationRepository

**File:** `data/repositories/PlungerConfigurationRepository.kt`
**Purpose:** Plunger/button settings

### API

```kotlin
class PlungerConfigurationRepository(
    private val dao: PlungerConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<PlungerConfiguration?>
    suspend fun save(config: PlungerConfiguration): Result<Long>
    suspend fun update(config: PlungerConfiguration): Result<Unit>
    suspend fun delete(config: PlungerConfiguration): Result<Unit>

    // Tension and position
    suspend fun adjustTension(configId: Long, tension: Double): Result<Unit>
    suspend fun adjustPosition(configId: Long, position: Double): Result<Unit>

    fun observeForBowSetup(setupId: Long): Flow<PlungerConfiguration?>
}
```

### Usage Example

```kotlin
val plungerConfig = PlungerConfiguration(
    bowSetupId = bowId,
    manufacturer = "Beiter",
    model = "Plunger",
    tension = 3.5,       // clicks
    position = 1.5,      // mm from riser
    notes = "Medium-stiff spring"
)

plungerRepository.save(plungerConfig)

// Fine-tune
plungerRepository.adjustTension(plungerId, 3.75)
plungerRepository.adjustPosition(plungerId, 1.6)
```

---

## Release Mechanism Repositories

### TabConfigurationRepository

**File:** `data/repositories/TabConfigurationRepository.kt`
**Purpose:** Finger tab settings (recurve)

```kotlin
class TabConfigurationRepository(
    private val dao: TabConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<TabConfiguration?>
    suspend fun save(config: TabConfiguration): Result<Long>
    suspend fun update(config: TabConfiguration): Result<Unit>
    suspend fun delete(config: TabConfiguration): Result<Unit>

    fun observeForBowSetup(setupId: Long): Flow<TabConfiguration?>
}
```

**Usage:**
```kotlin
val tabConfig = TabConfiguration(
    bowSetupId = bowId,
    manufacturer = "AAE",
    model = "Elite Tab",
    size = "Medium",
    thickness = 3.5,      // mm
    material = "Cordovan"
)

tabRepository.save(tabConfig)
```

### ReleaseAidConfigurationRepository

**File:** `data/repositories/ReleaseAidConfigurationRepository.kt`
**Purpose:** Release aid settings (compound)

```kotlin
class ReleaseAidConfigurationRepository(
    private val dao: ReleaseAidConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<ReleaseAidConfiguration?>
    suspend fun save(config: ReleaseAidConfiguration): Result<Long>
    suspend fun update(config: ReleaseAidConfiguration): Result<Unit>
    suspend fun delete(config: ReleaseAidConfiguration): Result<Unit>

    // Release settings
    suspend fun adjustSensitivity(configId: Long, sensitivity: Double): Result<Unit>
    suspend fun adjustTravel(configId: Long, travel: Double): Result<Unit>

    fun observeForBowSetup(setupId: Long): Flow<ReleaseAidConfiguration?>
}
```

**Usage:**
```kotlin
val releaseConfig = ReleaseAidConfiguration(
    bowSetupId = bowId,
    manufacturer = "Scott",
    model = "Halo Pro",
    type = "Thumb",
    sensitivity = 2.5,
    travelDistance = 0.75
)

releaseRepository.save(releaseConfig)
```

---

## Bow Component Repositories

### ClkrConfigurationRepository (Clicker)

**File:** `data/repositories/ClkrConfigurationRepository.kt`
**Purpose:** Clicker settings (recurve)

```kotlin
class ClkrConfigurationRepository(
    private val dao: ClkrConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<ClkrConfiguration?>
    suspend fun save(config: ClkrConfiguration): Result<Long>
    suspend fun update(config: ClkrConfiguration): Result<Unit>
    suspend fun delete(config: ClkrConfiguration): Result<Unit>

    // Length adjustment
    suspend fun adjustClickerLength(configId: Long, length: Double): Result<Unit>

    fun observeForBowSetup(setupId: Long): Flow<ClkrConfiguration?>
}
```

**Usage:**
```kotlin
val clickerConfig = ClkrConfiguration(
    bowSetupId = bowId,
    manufacturer = "Beiter",
    model = "Clicker",
    clickerLength = 28.5,        // mm
    clickerThickness = 0.20,     // mm
    position = "Above"
)

clickerRepository.save(clickerConfig)

// Adjust for new arrows
clickerRepository.adjustClickerLength(clickerId, 28.75)
```

### StringConfigurationRepository

**File:** `data/repositories/StringConfigurationRepository.kt`
**Purpose:** Bowstring configuration

```kotlin
class StringConfigurationRepository(
    private val dao: StringConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<StringConfiguration?>
    suspend fun save(config: StringConfiguration): Result<Long>
    suspend fun update(config: StringConfiguration): Result<Unit>
    suspend fun delete(config: StringConfiguration): Result<Unit>

    // String maintenance
    suspend fun recordStringChange(
        bowSetupId: Long,
        config: StringConfiguration
    ): Result<Long>

    suspend fun getStringHistory(bowSetupId: Long): Result<List<StringConfiguration>>

    fun observeForBowSetup(setupId: Long): Flow<StringConfiguration?>
}
```

**Usage:**
```kotlin
val stringConfig = StringConfiguration(
    bowSetupId = bowId,
    manufacturer = "BCY",
    material = "X99",
    strandCount = 18,
    servingType = "Halo",
    length = 68.5,              // inches
    twists = 20,
    dateInstalled = System.currentTimeMillis()
)

stringRepository.recordStringChange(bowId, stringConfig)

// Track string history
val history = stringRepository.getStringHistory(bowId).getOrNull()
// Shows progression over time
```

### LimbsConfigurationRepository

**File:** `data/repositories/LimbsConfigurationRepository.kt`
**Purpose:** Bow limb settings

```kotlin
class LimbsConfigurationRepository(
    private val dao: LimbsConfigurationDao
) {
    suspend fun getForBowSetup(setupId: Long): Result<LimbsConfiguration?>
    suspend fun save(config: LimbsConfiguration): Result<Long>
    suspend fun update(config: LimbsConfiguration): Result<Unit>
    suspend fun delete(config: LimbsConfiguration): Result<Unit>

    // Limb adjustments
    suspend fun adjustTiller(configId: Long, tiller: Double): Result<Unit>
    suspend fun recordLimbChange(
        bowSetupId: Long,
        config: LimbsConfiguration
    ): Result<Long>

    fun observeForBowSetup(setupId: Long): Flow<LimbsConfiguration?>
}
```

**Usage:**
```kotlin
val limbsConfig = LimbsConfiguration(
    bowSetupId = bowId,
    manufacturer = "Win&Win",
    model = "Winex",
    length = 68,                // inches
    poundage = 38.0,            // lbs
    tiller = 0.5,               // mm (top - bottom)
    dateInstalled = System.currentTimeMillis()
)

limbsRepository.save(limbsConfig)

// Adjust tiller
limbsRepository.adjustTiller(limbsId, 0.75)
```

---

## Complete Equipment Setup Example

```kotlin
suspend fun createCompleteEquipmentSetup(bowSetupId: Long) {
    // Bow components
    val sight = SightConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "Shibuya",
        model = "Ultima RC II",
        scopeMagnification = 4.0,
        apertureDiameter = 0.5
    )
    sightRepository.save(sight)

    val rest = RestConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "Shibuya",
        model = "Ultima Rest II",
        verticalPosition = 2.5,
        horizontalPosition = 0.0
    )
    restRepository.save(rest)

    val stabilizer = StabilizerConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "Doinker",
        frontRodLength = 30.0,
        frontRodWeight = 12.0,
        sideRodLength = 12.0,
        sideRodWeight = 8.0,
        vBarAngle = 45.0
    )
    stabilizerRepository.save(stabilizer)

    val plunger = PlungerConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "Beiter",
        model = "Plunger",
        tension = 3.5,
        position = 1.5
    )
    plungerRepository.save(plunger)

    val tab = TabConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "AAE",
        model = "Elite Tab",
        size = "Medium",
        thickness = 3.5,
        material = "Cordovan"
    )
    tabRepository.save(tab)

    val clicker = ClkrConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "Beiter",
        model = "Clicker",
        clickerLength = 28.5,
        clickerThickness = 0.20,
        position = "Above"
    )
    clickerRepository.save(clicker)

    val string = StringConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "BCY",
        material = "X99",
        strandCount = 18,
        servingType = "Halo",
        length = 68.5,
        twists = 20,
        dateInstalled = System.currentTimeMillis()
    )
    stringRepository.save(string)

    val limbs = LimbsConfiguration(
        bowSetupId = bowSetupId,
        manufacturer = "Win&Win",
        model = "Winex",
        length = 68,
        poundage = 38.0,
        tiller = 0.5,
        dateInstalled = System.currentTimeMillis()
    )
    limbsRepository.save(limbs)
}
```

---

## Querying Complete Equipment

```kotlin
data class CompleteEquipmentSetup(
    val bowSetup: BowSetup,
    val sight: SightConfiguration?,
    val rest: RestConfiguration?,
    val stabilizer: StabilizerConfiguration?,
    val plunger: PlungerConfiguration?,
    val tab: TabConfiguration?,
    val clicker: ClkrConfiguration?,
    val string: StringConfiguration?,
    val limbs: LimbsConfiguration?
)

suspend fun getCompleteSetup(bowSetupId: Long): Result<CompleteEquipmentSetup> {
    return runCatching {
        CompleteEquipmentSetup(
            bowSetup = bowSetupRepository.getById(bowSetupId).getOrThrow(),
            sight = sightRepository.getForBowSetup(bowSetupId).getOrNull(),
            rest = restRepository.getForBowSetup(bowSetupId).getOrNull(),
            stabilizer = stabilizerRepository.getForBowSetup(bowSetupId).getOrNull(),
            plunger = plungerRepository.getForBowSetup(bowSetupId).getOrNull(),
            tab = tabRepository.getForBowSetup(bowSetupId).getOrNull(),
            clicker = clickerRepository.getForBowSetup(bowSetupId).getOrNull(),
            string = stringRepository.getForBowSetup(bowSetupId).getOrNull(),
            limbs = limbsRepository.getForBowSetup(bowSetupId).getOrNull()
        )
    }
}
```

---

## Reactive Updates

All equipment repositories support reactive updates via Flow:

```kotlin
@Composable
fun EquipmentConfigScreen(
    bowSetupId: Long,
    sightRepository: SightConfigurationRepository,
    restRepository: RestConfigurationRepository
    // ... other repositories
) {
    val sightConfig by sightRepository
        .observeForBowSetup(bowSetupId)
        .collectAsState(initial = null)

    val restConfig by restRepository
        .observeForBowSetup(bowSetupId)
        .collectAsState(initial = null)

    // UI automatically updates when configurations change
    Column {
        sightConfig?.let { sight ->
            SightConfigCard(sight)
        }

        restConfig?.let { rest ->
            RestConfigCard(rest)
        }
    }
}
```

---

## Best Practices

### 1. Configuration Consistency

```kotlin
// GOOD: Create all components for a bow setup
suspend fun setupNewBow(bowId: Long) {
    // Create all essential configurations
    createSightConfiguration(bowId)
    createRestConfiguration(bowId)
    createStabilizerConfiguration(bowId)
}

// BAD: Partial configuration
suspend fun setupNewBow(bowId: Long) {
    createSightConfiguration(bowId)
    // Missing other essential components
}
```

### 2. Error Handling

```kotlin
// GOOD: Handle missing configurations gracefully
val sight = sightRepository.getForBowSetup(bowId)
    .getOrNull()

if (sight == null) {
    showPrompt("Add sight configuration?")
} else {
    displaySightSettings(sight)
}

// BAD: Assume configuration exists
val sight = sightRepository.getForBowSetup(bowId)
    .getOrThrow()  // May crash if not configured
```

### 3. Atomic Updates

```kotlin
// GOOD: Transaction for related changes
suspend fun updateBowSetup(
    bowId: Long,
    sightAdjustment: Double,
    restAdjustment: Double
) {
    database.withTransaction {
        sightRepository.adjustPosition(sightId, sightAdjustment)
        restRepository.updatePosition(restId, 0.0, restAdjustment)
    }
}
```

---

## Related Documentation

- [[bow-setup-repository|BowSetupRepository]]
- [[arrow-setup-repository|ArrowSetupRepository]]
- [[../daos/equipment-daos-reference|Equipment DAOs Reference]]
- [[../viewmodels/equipment-viewmodels-reference|Equipment ViewModels Reference]]
- [[../../flows/equipment-management-end-to-end-flow|Equipment Management Flow]]

---

**Status:** ✅ All 9 equipment repositories in production
**Pattern:** Consistent CRUD with bow setup foreign key
**Offline-First:** All operations local-first with optional sync
**Last Updated:** 2025-11-01
