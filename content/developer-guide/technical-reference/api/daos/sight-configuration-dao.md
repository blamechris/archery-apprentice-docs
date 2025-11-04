---
title: SightConfigurationDao API Reference
tags:
  - api
  - dao
  - equipment
  - sight
created: 2025-11-01
---

# SightConfigurationDao API Reference

Room DAO for sight configuration entities.

---

## Overview

**File:** `data/dao/SightConfigurationDao.kt`
**Type:** Room DAO interface
**Status:** ✅ Production | ✅ Migrated (Week 5)

### Purpose

Database access for sight configurations:
- Sight CRUD operations
- Bow setup relationships
- Distance marks storage
- Sight history

---

## Core Operations

```kotlin
@Dao
interface SightConfigurationDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSight(sight: SightConfiguration): Long

    @Query("SELECT * FROM sight_configurations WHERE id = :id")
    suspend fun getSightById(id: Long): SightConfiguration?

    @Query("SELECT * FROM sight_configurations WHERE bowSetupId = :setupId")
    suspend fun getSightForBowSetup(setupId: Long): SightConfiguration?

    @Update
    suspend fun updateSight(sight: SightConfiguration)

    @Delete
    suspend fun deleteSight(sight: SightConfiguration)
}
```

---

## Distance Marks

Sight configurations store distance marks as JSON:

```kotlin
@Entity(tableName = "sight_configurations")
data class SightConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,
    val manufacturer: String,
    val model: String,
    val aperture: Double,  // in mm
    @TypeConverters(DistanceMarksConverter::class)
    val distanceMarks: Map<Int, Double>  // distance -> mark value
)

// Example:
val sight = SightConfiguration(
    bowSetupId = 1L,
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
```

---

## Usage Example

```kotlin
@Composable
fun SightMarksDisplay(setupId: Long, dao: SightConfigurationDao) {
    val sight by remember {
        dao.getSightForBowSetup(setupId)
    }.collectAsState(initial = null)

    sight?.distanceMarks?.forEach { (distance, mark) ->
        Text("${distance}m: $mark")
    }
}
```

---

## Related Documentation

- [[../repositories/bow-setup-repository|BowSetupRepository]]
- [[bow-setup-dao|BowSetupDao]]
- [[../../../../architecture/database-migration-status|Equipment Migration (Week 5)]]

---

**Status:** ✅ Production | ✅ Migrated Week 5
**Last Updated:** 2025-11-01
