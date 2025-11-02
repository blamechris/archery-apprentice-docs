---
title: Equipment DAOs Reference
tags:
  - api
  - dao
  - room
  - equipment
created: 2025-11-01
---

# Equipment DAOs Reference

Consolidated reference for all equipment configuration DAOs.

---

## Overview

Equipment DAOs provide database access for bow components, following a consistent Room pattern.

**DAOs Covered (9):**
- ArrowSetupDao
- RestConfigurationDao
- PlungerConfigurationDao
- TabConfigurationDao
- ReleaseAidConfigurationDao
- ClkrConfigurationDao (Clicker)
- StringConfigurationDao
- LimbsConfigurationDao
- RiserConfigurationDao

**Already Documented:**
- BowSetupDao
- SightConfigurationDao
- StabilizerConfigurationDao

---

## Common DAO Pattern

All equipment DAOs follow this structure:

```kotlin
@Dao
interface EquipmentDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: Entity): Long

    @Query("SELECT * FROM table_name WHERE id = :id")
    suspend fun getById(id: Long): Entity?

    @Query("SELECT * FROM table_name WHERE bowSetupId = :setupId")
    suspend fun getForBowSetup(setupId: Long): Entity?

    @Query("SELECT * FROM table_name")
    fun observeAll(): Flow<List<Entity>>

    @Update
    suspend fun update(entity: Entity)

    @Delete
    suspend fun delete(entity: Entity)
}
```

---

## ArrowSetupDao

**File:** `data/dao/ArrowSetupDao.kt`
**Table:** `arrow_setups`
**Migration:** Week 4

### Schema

```kotlin
@Entity(tableName = "arrow_setups")
data class ArrowSetup(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val manufacturer: String,
    val model: String,
    val spine: String,        // e.g., "500", "340"
    val length: Double,       // inches
    val pointWeight: Int,     // grains
    val vanes: String,
    val nock: String,
    val isActive: Boolean = false
)
```

### Key Methods

```kotlin
@Query("SELECT * FROM arrow_setups WHERE isActive = 1 LIMIT 1")
suspend fun getActiveArrowSetup(): ArrowSetup?

@Query("UPDATE arrow_setups SET isActive = 0")
suspend fun deactivateAll()
```

---

## RestConfigurationDao

**File:** `data/dao/RestConfigurationDao.kt`
**Table:** `rest_configurations`
**Migration:** Week 6

### Schema

```kotlin
@Entity(tableName = "rest_configurations")
data class RestConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val verticalPosition: Double,
    val horizontalPosition: Double,
    val notes: String? = null
)
```

---

## PlungerConfigurationDao

**File:** `data/dao/PlungerConfigurationDao.kt`
**Table:** `plunger_configurations`
**Migration:** Week 8

### Schema

```kotlin
@Entity(tableName = "plunger_configurations")
data class PlungerConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val tension: Double,       // clicks or turns
    val position: Double,      // mm from riser
    val notes: String? = null
)
```

---

## Tab & Release Aid Configuration DAOs

### TabConfigurationDao

**Migration:** Week 9
**Purpose:** Finger tab settings (recurve bows)

```kotlin
@Entity(tableName = "tab_configurations")
data class TabConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val size: String,
    val thickness: Double,
    val material: String
)
```

### ReleaseAidConfigurationDao

**Migration:** Week 10
**Purpose:** Release aid settings (compound bows)

```kotlin
@Entity(tableName = "release_aid_configurations")
data class ReleaseAidConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val type: String,          // "Thumb", "Wrist", "Handheld"
    val sensitivity: Double,
    val travelDistance: Double
)
```

---

## Bow Component DAOs

### ClkrConfigurationDao (Clicker)

**Migration:** Week 11
**Purpose:** Clicker settings (recurve bows)

```kotlin
@Entity(tableName = "clkr_configurations")
data class ClkrConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val clickerLength: Double,  // mm
    val clickerThickness: Double,
    val position: String        // "Above", "Below"
)
```

### StringConfigurationDao

**Migration:** Week 11
**Purpose:** Bowstring configuration

```kotlin
@Entity(tableName = "string_configurations")
data class StringConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val material: String,       // "Dyneema", "FastFlight", etc.
    val strandCount: Int,
    val servingType: String,
    val length: Double,         // inches
    val twists: Int,
    val dateInstalled: Long
)
```

### LimbsConfigurationDao

**Migration:** Week 11
**Purpose:** Bow limb settings

```kotlin
@Entity(tableName = "limbs_configurations")
data class LimbsConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val length: Int,            // inches
    val poundage: Double,
    val tiller: Double?,        // mm difference top/bottom
    val dateInstalled: Long
)
```

### RiserConfigurationDao

**Migration:** Week 11
**Purpose:** Bow riser configuration

```kotlin
@Entity(tableName = "riser_configurations")
data class RiserConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val length: Int,            // inches (e.g., 25")
    val material: String,       // "Aluminum", "Carbon", etc.
    val gripType: String,
    val weight: Double?         // grams
)
```

---

## Usage Examples

### Creating Equipment Configuration

```kotlin
// Create arrow setup
val arrows = ArrowSetup(
    name = "Competition Arrows",
    manufacturer = "Easton",
    model = "X10",
    spine = "470",
    length = 28.5,
    pointWeight = 110,
    vanes = "Spin Wing",
    nock = "G-Nock"
)

val arrowId = arrowSetupDao.insert(arrows)

// Link to bow
val rest = RestConfiguration(
    bowSetupId = bowId,
    manufacturer = "Shibuya",
    model = "Ultima Rest II",
    verticalPosition = 2.5,
    horizontalPosition = 0.0
)

restDao.insert(rest)
```

### Querying Equipment for Bow Setup

```kotlin
suspend fun getBowWithAllComponents(setupId: Long): CompleteSetup {
    return CompleteSetup(
        bow = bowSetupDao.getById(setupId),
        sight = sightDao.getForBowSetup(setupId),
        rest = restDao.getForBowSetup(setupId),
        stabilizer = stabilizerDao.getForBowSetup(setupId),
        plunger = plungerDao.getForBowSetup(setupId),
        string = stringDao.getForBowSetup(setupId),
        limbs = limbsDao.getForBowSetup(setupId),
        riser = riserDao.getForBowSetup(setupId)
    )
}
```

---

## Migration Timeline

| Week | DAOs Migrated | Status |
|------|---------------|--------|
| Week 4 | ArrowSetupDao | ✅ Complete |
| Week 6 | RestConfigurationDao | ✅ Complete |
| Week 7 | StabilizerConfigurationDao | ✅ Complete |
| Week 8 | PlungerConfigurationDao | ✅ Complete |
| Week 9 | TabConfigurationDao | ✅ Complete |
| Week 10 | ReleaseAidConfigurationDao | ✅ Complete |
| Week 11 | 4 Component DAOs | ✅ Complete |

**Total:** 15 equipment-related DAOs migrated over 10 weeks

---

## Testing

All equipment DAOs have comprehensive integration tests:

```kotlin
@Test
fun insertAndRetrieveConfiguration() = runTest {
    val config = RestConfiguration(
        bowSetupId = 1L,
        manufacturer = "Test",
        model = "Model",
        verticalPosition = 2.5,
        horizontalPosition = 0.0
    )

    val id = dao.insert(config)
    val retrieved = dao.getById(id)

    assertNotNull(retrieved)
    assertEquals(config.manufacturer, retrieved?.manufacturer)
}
```

---

## Related Documentation

- [[bow-setup-dao|BowSetupDao]]
- [[sight-configuration-dao|SightConfigurationDao]]
- [[stabilizer-configuration-dao|StabilizerConfigurationDao]]
- [[../../../../architecture/database-migration-status|Migration Timeline]]
- [[../repositories/bow-setup-repository|BowSetupRepository]]

---

**Status:** ✅ All 9 DAOs migrated and in production
**Pattern:** Consistent Room DAO with bow setup foreign key
**Test Coverage:** Comprehensive integration tests
**Last Updated:** 2025-11-01
