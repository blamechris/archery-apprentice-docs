---
title: BowSetupDao API Reference
tags:
  - api
  - dao
  - room
  - equipment
  - bow
created: 2025-11-01
---

# BowSetupDao API Reference

Complete API reference for the BowSetupDao - Room database access object for bow setup entities.

---

## Overview

**File:** `data/dao/BowSetupDao.kt`
**Type:** Room DAO interface
**Status:** ✅ Production | ✅ Migrated (Week 3)

### Purpose

BowSetupDao provides type-safe database access for bow setup entities using Room. It handles:
- Bow setup CRUD operations
- Active bow queries
- Equipment component relationships
- Setup history tracking

---

## Core Operations

### CRUD Methods

```kotlin
@Dao
interface BowSetupDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBowSetup(setup: BowSetup): Long

    @Query("SELECT * FROM bow_setups WHERE id = :setupId")
    suspend fun getBowSetupById(setupId: Long): BowSetup?

    @Update
    suspend fun updateBowSetup(setup: BowSetup)

    @Delete
    suspend fun deleteBowSetup(setup: BowSetup)
}
```

### Active Bow Queries

```kotlin
@Query("SELECT * FROM bow_setups WHERE isActive = 1 LIMIT 1")
suspend fun getActiveBowSetup(): BowSetup?

@Query("SELECT * FROM bow_setups WHERE isActive = 1")
fun observeActiveBowSetup(): Flow<BowSetup?>

@Query("UPDATE bow_setups SET isActive = 0")
suspend fun deactivateAllBowSetups()
```

### List Queries

```kotlin
@Query("SELECT * FROM bow_setups ORDER BY name ASC")
suspend fun getAllBowSetups(): List<BowSetup>

@Query("SELECT * FROM bow_setups ORDER BY name ASC")
fun observeAllBowSetups(): Flow<List<BowSetup>>

@Query("SELECT * FROM bow_setups WHERE bowType = :type ORDER BY name ASC")
suspend fun getBowSetupsByType(type: String): List<BowSetup>
```

---

## Relationship Queries

### Bow Setup with Components

```kotlin
data class BowSetupWithComponents(
    @Embedded val bowSetup: BowSetup,
    @Relation(
        parentColumn = "id",
        entityColumn = "bowSetupId"
    )
    val sightConfig: SightConfiguration?,
    @Relation(
        parentColumn = "id",
        entityColumn = "bowSetupId"
    )
    val restConfig: RestConfiguration?,
    @Relation(
        parentColumn = "id",
        entityColumn = "bowSetupId"
    )
    val stabilizerConfig: StabilizerConfiguration?
)

@Transaction
@Query("SELECT * FROM bow_setups WHERE id = :setupId")
suspend fun getBowSetupWithComponents(setupId: Long): BowSetupWithComponents?
```

---

## Usage Examples

### Setting Active Bow

```kotlin
suspend fun setActiveBow(setupId: Long) {
    // Deactivate all bows
    bowSetupDao.deactivateAllBowSetups()

    // Activate selected bow
    val setup = bowSetupDao.getBowSetupById(setupId) ?: return
    val activated = setup.copy(isActive = true)
    bowSetupDao.updateBowSetup(activated)
}
```

### Reactive Active Bow

```kotlin
@Composable
fun ActiveBowDisplay(dao: BowSetupDao) {
    val activeBow by dao.observeActiveBowSetup()
        .collectAsState(initial = null)

    activeBow?.let { bow ->
        Text("Active: ${bow.name}")
        Text("${bow.manufacturer} ${bow.model}")
    }
}
```

---

## Testing

```kotlin
@Test
fun `getActiveBowSetup returns active bow`() = runTest {
    val bow1 = BowSetup(name = "Bow 1", isActive = false, ...)
    val bow2 = BowSetup(name = "Bow 2", isActive = true, ...)

    dao.insertBowSetup(bow1)
    dao.insertBowSetup(bow2)

    val active = dao.getActiveBowSetup()

    assertNotNull(active)
    assertEquals("Bow 2", active?.name)
}
```

---

## Related Documentation

- [[../repositories/bow-setup-repository|BowSetupRepository]]
- [[../../../../architecture/database-migration-status|Equipment Migration (Week 3)]]
- [[../../../flows/equipment-management-end-to-end-flow|Equipment Flow]]

---

**Status:** ✅ Production | ✅ Migrated Week 3
**Last Updated:** 2025-11-01
