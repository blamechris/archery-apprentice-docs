---
title: StabilizerConfigurationDao API Reference
tags:
  - api
  - dao
  - equipment
  - stabilizer
created: 2025-11-01
---

# StabilizerConfigurationDao API Reference

Room DAO for stabilizer configuration entities.

---

## Overview

**File:** `data/dao/StabilizerConfigurationDao.kt`
**Type:** Room DAO interface
**Status:** ✅ Production | ✅ Migrated (Week 7)

### Purpose

Database access for stabilizer configurations:
- Stabilizer CRUD operations
- Bow setup relationships
- Rod lengths and weights
- Configuration history

---

## Core Operations

```kotlin
@Dao
interface StabilizerConfigurationDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertStabilizer(stab: StabilizerConfiguration): Long

    @Query("SELECT * FROM stabilizer_configurations WHERE id = :id")
    suspend fun getStabilizerById(id: Long): StabilizerConfiguration?

    @Query("SELECT * FROM stabilizer_configurations WHERE bowSetupId = :setupId")
    suspend fun getStabilizerForBowSetup(setupId: Long): StabilizerConfiguration?

    @Update
    suspend fun updateStabilizer(stab: StabilizerConfiguration)

    @Delete
    suspend fun deleteStabilizer(stab: StabilizerConfiguration)
}
```

---

## Entity Model

```kotlin
@Entity(tableName = "stabilizer_configurations")
data class StabilizerConfiguration(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val bowSetupId: Long,

    // Front rod
    val frontLength: Double,  // in inches
    val frontWeight: Double,  // in ounces

    // Side rods
    val sideRodLength: Double,
    val sideRodWeight: Double,
    val sideRodAngle: Double = 45.0,  // degrees

    // V-bar
    val vBarAngle: Double = 45.0,

    // Notes
    val notes: String? = null
)
```

---

## Usage Example

```kotlin
val stabilizer = StabilizerConfiguration(
    bowSetupId = 1L,
    frontLength = 30.0,  // 30" front rod
    frontWeight = 8.0,   // 8oz
    sideRodLength = 12.0, // 12" side rods
    sideRodWeight = 4.0,  // 4oz each
    notes = "Olympic setup for outdoor 70m"
)

dao.insertStabilizer(stabilizer)
```

---

## Related Documentation

- [[../repositories/bow-setup-repository|BowSetupRepository]]
- [[bow-setup-dao|BowSetupDao]]
- [[../../../../architecture/database-migration-status|Equipment Migration (Week 7)]]

---

**Status:** ✅ Production | ✅ Migrated Week 7
**Last Updated:** 2025-11-01
