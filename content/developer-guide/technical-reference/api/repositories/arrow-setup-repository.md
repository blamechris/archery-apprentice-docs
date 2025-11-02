---
title: ArrowSetupRepository API Reference
tags:
  - api
  - repository
  - equipment
  - arrows
created: 2025-11-01
---

# ArrowSetupRepository API Reference

Repository for arrow configuration management.

---

## Overview

**File:** `data/repository/impl/ArrowSetupRepository.kt`
**Status:** ✅ Production | ✅ Migrated (Week 4)

### Purpose

Manages arrow configurations:
- Arrow setup CRUD operations
- Active arrow management
- Spine and weight tracking
- Arrow history

---

## Key Methods

```kotlin
// CRUD operations
suspend fun createArrowSetup(setup: ArrowSetup): Result<Long>
suspend fun getArrowSetup(setupId: Long): Result<ArrowSetup?>
suspend fun updateArrowSetup(setup: ArrowSetup): Result<Unit>
suspend fun deleteArrowSetup(setupId: Long): Result<Unit>

// Active arrow management
suspend fun getActiveArrowSetup(): Result<ArrowSetup?>
suspend fun setActiveArrowSetup(setupId: Long): Result<Unit>

// List operations
suspend fun getAllArrowSetups(): Result<List<ArrowSetup>>
fun observeAllArrowSetups(): Flow<List<ArrowSetup>>
```

---

## Entity Model

```kotlin
data class ArrowSetup(
    val id: Long = 0,
    val name: String,
    val manufacturer: String,
    val model: String,

    // Specifications
    val spine: String,  // e.g., "500", "340"
    val length: Double,  // in inches
    val pointWeight: Int, // in grains

    // Components
    val vanes: String,
    val nock: String,
    val insert: String? = null,

    // Active status
    val isActive: Boolean = false,

    // Metadata
    val notes: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)
```

---

## Usage Example

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

val setupId = repository.createArrowSetup(arrows).getOrThrow()

// Set as active
repository.setActiveArrowSetup(setupId)

// Use in round
val activeArrows = repository.getActiveArrowSetup().getOrThrow()
println("Shooting with: ${activeArrows?.name}")
```

---

## Related Documentation

- [[bow-setup-repository|BowSetupRepository]]
- [[../daos/arrow-setup-dao|ArrowSetupDao]]
- [[../../../flows/equipment-management-end-to-end-flow|Equipment Flow]]

---

**Status:** ✅ Production | ✅ Migrated Week 4
**Last Updated:** 2025-11-01
