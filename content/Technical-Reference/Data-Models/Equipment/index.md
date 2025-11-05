---
title: "Equipment Data Models"
description: "Equipment-related data structures and entities"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - data-models
  - equipment
  - entities
  - bow-setup
---

[Home](/) > [Technical Reference](../../) > [Data Models](../) > Equipment

---

# Equipment Data Models

Complete reference for all equipment-related entities in Archery Apprentice. These models represent physical archery gear, from individual components like risers and limbs to complete bow configurations.

## Overview

**Total Equipment Entities:** 13
**Location:** `shared:database` module
**Package:** `com.archeryapprentice.database.entities.equipment`

### Entity Categories

| Category | Entities | Purpose |
|----------|----------|---------|
| **Core Bow Components** | Riser, Limbs, BowString | Essential bow structure |
| **Sighting & Aiming** | Sight, SightMark | Aiming equipment and settings |
| **Stabilization** | Stabilizer, Weight | Balance and vibration control |
| **Arrow Rest System** | Plunger, Rest | Arrow support and tuning |
| **Arrows** | Arrow | Complete arrow specifications |
| **Accessories** | Accessory | Generic equipment items |
| **Configuration** | BowSetup, BowSetupEquipment | Complete equipment configurations |

### Design Principles

**1. Component-Based Architecture**
- Each component is a separate entity
- BowSetup aggregates components into configurations
- Reusable components across multiple setups

**2. Versioning**
- BowSetup tracks version changes
- Equipment changes create new versions
- Historical accuracy for performance analysis

**3. Soft Deletes**
- BowSetup uses `isActive` flag instead of hard delete
- Preserves historical data integrity
- Rounds can always reference original equipment

**4. Flexible Relationships**
- One-to-many: Equipment → BowSetup
- Optional foreign keys allow partial configurations
- Junction table (BowSetupEquipment) for future flexibility

---

## Core Bow Components

### Riser Entity

The riser is the central body of the bow, to which limbs and accessories attach.

**File:** `RiserEntity.kt`
**Table:** `Riser`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"Hoyt"`, `"Win&Win"`, `"SF Archery"` |
| **model** | String | Yes | Model name | `"Formula X"`, `"Inno CXT"`, `"Axiom+"` |
| **length** | String? | No | Riser length | `"25 inches"`, `"27 inches"` |
| **material** | String? | No | Construction material | `"Carbon"`, `"Aluminum"`, `"Wood"` |

#### Usage Example

```kotlin
val riser = RiserEntity(
    brand = "Hoyt",
    model = "Formula X",
    length = "25 inches",
    material = "Carbon"
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.riserId`)
**Cascade:** ON DELETE SET NULL (BowSetup.riserId becomes null if Riser deleted)

---

### Limbs Entity

Limbs are the flexible arms of the bow that store and release energy.

**File:** `LimbsEntity.kt`
**Table:** `Limbs`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"Hoyt"`, `"Win&Win"`, `"Border"` |
| **model** | String | Yes | Model name | `"Formula X-Act"`, `"Wiawis NS-G"` |
| **poundage** | String? | No | Draw weight | `"38 lbs"`, `"42 lbs"`, `"36#"` |
| **limbLength** | String? | No | Limb size | `"Long"`, `"Medium"`, `"Short"` |

#### Usage Example

```kotlin
val limbs = LimbsEntity(
    brand = "Hoyt",
    model = "Formula X-Act",
    poundage = "38 lbs",
    limbLength = "Long"
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.limbsId`)
**Cascade:** ON DELETE SET NULL

**Important:** Changing limbs in a BowSetup creates a new version (equipment versioning).

---

### BowString Entity

The bowstring connects the limbs and transfers energy to the arrow.

**File:** `BowStringEntity.kt`
**Table:** `BowString`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"BCY"`, `"Brownell"`, `"Angel"` |
| **model** | String | Yes | String type/model | `"8125G"`, `"X99"`, `"Dyneema"` |
| **strandCount** | Int? | No | Number of strands | `16`, `18`, `20` |
| **servingMaterial** | String? | No | Center serving material | `"BCY 3D"`, `"Halo"` |

#### Usage Example

```kotlin
val bowString = BowStringEntity(
    brand = "BCY",
    model = "8125G",
    strandCount = 18,
    servingMaterial = "BCY 3D"
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.bowStringId`)
**Cascade:** ON DELETE SET NULL

---

## Sighting & Aiming

### Sight Entity

The sight is the aiming device mounted on the riser.

**File:** `SightEntity.kt`
**Table:** `Sight`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"Shibuya"`, `"Axcel"`, `"Sure-Loc"` |
| **model** | String | Yes | Model name | `"Ultima RC II"`, `"Achieve XP"` |
| **material** | String? | No | Construction material | `"Carbon"`, `"Aluminum"` |

#### Usage Example

```kotlin
val sight = SightEntity(
    brand = "Shibuya",
    model = "Ultima RC II",
    material = "Carbon"
)
```

#### Relationships

**Used In:**
- BowSetup (via `BowSetup.sightId`)
- SightMark (via `SightMark.sightId`)

**Cascade:**
- BowSetup: ON DELETE SET NULL
- SightMark: ON DELETE CASCADE

---

### SightMark Entity

SightMark stores distance-specific sight settings for a Sight.

**File:** `SightMarkEntity.kt`
**Table:** `SightMark`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **sightId** | Long | Yes | Foreign key → Sight(id) | `5` |
| **distance** | String | Yes | Shooting distance | `"30 meters"`, `"50 yards"` |
| **markValue** | String | Yes | Sight setting | `"5.2"`, `"7.8"`, `"105 clicks"` |
| **notes** | String? | No | Additional notes | `"Windy conditions"`, `"Indoor"` |

#### Usage Example

```kotlin
// Sight marks for 70m Olympic round
val sightMarks = listOf(
    SightMarkEntity(
        sightId = 5L,
        distance = "70 meters",
        markValue = "2.5",
        notes = "Outdoor, calm wind"
    ),
    SightMarkEntity(
        sightId = 5L,
        distance = "50 meters",
        markValue = "5.8",
        notes = "Outdoor"
    ),
    SightMarkEntity(
        sightId = 5L,
        distance = "30 meters",
        markValue = "9.2",
        notes = "Indoor/outdoor"
    )
)
```

#### Relationships

**Parent:** Sight (Many-to-One)
- Foreign Key: `SightMark.sightId → Sight.id`
- Cascade: ON DELETE CASCADE (deleting Sight deletes all its SightMarks)

#### Queries

```kotlin
// Get all sight marks for a sight
@Query("SELECT * FROM SightMark WHERE sightId = :sightId ORDER BY distance ASC")
suspend fun getSightMarksForSight(sightId: Long): List<SightMarkEntity>

// Find sight mark for specific distance
@Query("SELECT * FROM SightMark WHERE sightId = :sightId AND distance = :distance")
suspend fun getSightMarkForDistance(sightId: Long, distance: String): SightMarkEntity?
```

---

## Stabilization

### Stabilizer Entity

Stabilizers reduce vibration and balance the bow.

**File:** `StabilizerEntity.kt`
**Table:** `Stabilizer`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"Doinker"`, `"Shrewd"`, `"Axcel"` |
| **model** | String | Yes | Model name | `"Platinum"`, `"Atlas"`, `"Achieve"` |
| **length** | String? | No | Stabilizer length | `"30 inches"`, `"12 inches"` |
| **weight** | String? | No | Total weight | `"8 oz"`, `"120 grams"` |
| **straightnessRating** | String? | No | Straightness tolerance | `"+/- 0.001"`, `"0.002"` |

#### Usage Example

```kotlin
val stabilizer = StabilizerEntity(
    brand = "Doinker",
    model = "Platinum",
    length = "30 inches",
    weight = "8 oz",
    straightnessRating = "+/- 0.001"
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.stabilizerId`)
**Cascade:** ON DELETE SET NULL

---

### Weight Entity

Additional balance weights attached to stabilizer or bow.

**File:** `WeightEntity.kt`
**Table:** `Weight`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"Shrewd"`, `"Doinker"`, `"Generic"` |
| **model** | String | Yes | Model/type | `"1 oz weight"`, `"3/4 oz"`, `"2 oz donut"` |
| **ounces** | Double? | No | Weight in ounces | `1.0`, `0.75`, `2.0` |

#### Usage Example

```kotlin
val weight = WeightEntity(
    brand = "Shrewd",
    model = "1 oz weight",
    ounces = 1.0
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.weightId`)
**Cascade:** ON DELETE SET NULL

---

## Arrow Rest System

### Plunger Entity

The plunger (pressure button) fine-tunes arrow flight.

**File:** `PlungerEntity.kt`
**Table:** `Plunger`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"Beiter"`, `"Shibuya"`, `"Avalon"` |
| **model** | String | Yes | Model name | `"DX Plunger"`, `"Dual Click"` |
| **adjustment** | String? | No | Adjustment type | `"Micro-adjust"`, `"Click adjust"` |

#### Usage Example

```kotlin
val plunger = PlungerEntity(
    brand = "Beiter",
    model = "DX Plunger",
    adjustment = "Micro-adjust"
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.plungerId`)
**Cascade:** ON DELETE SET NULL

---

### Rest Entity

The rest supports the arrow before release.

**File:** `RestEntity.kt`
**Table:** `Rest`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"Hoyt"`, `"AAE"`, `"Cavalier"` |
| **model** | String | Yes | Model name | `"Super Rest"`, `"Free Flyte"` |
| **type** | String? | No | Rest type | `"Magnetic"`, `"Flipper"`, `"Blade"` |

#### Usage Example

```kotlin
val rest = RestEntity(
    brand = "Hoyt",
    model = "Super Rest",
    type = "Magnetic"
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.restId`)
**Cascade:** ON DELETE SET NULL

---

## Arrows

### Arrow Entity

Complete arrow specifications including point and nock.

**File:** `ArrowEntity.kt`
**Table:** `Arrow`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Arrow manufacturer | `"Easton"`, `"Carbon Express"`, `"Victory"` |
| **model** | String | Yes | Arrow model | `"X10"`, `"Protour"`, `"VAP"` |
| **spine** | String? | No | Arrow stiffness | `"500"`, `"600"`, `"350"` |
| **length** | String? | No | Shaft length | `"29 inches"`, `"30.5 inches"` |
| **weight** | String? | No | Total arrow weight | `"420 grains"`, `"380 gr"` |
| **diameter** | String? | No | Shaft diameter | `"5.5mm"`, `"4mm"` |
| **arrowPoint** | ArrowPoint? | No | Embedded point data | See ArrowPoint structure |
| **arrowNock** | ArrowNock? | No | Embedded nock data | See ArrowNock structure |

#### Embedded Objects

**ArrowPoint:**
```kotlin
data class ArrowPoint(
    val brand: String,      // e.g., "Easton"
    val model: String,      // e.g., "X10 Point"
    val weight: String      // e.g., "120 grains"
)
```

**ArrowNock:**
```kotlin
data class ArrowNock(
    val brand: String,      // e.g., "Easton"
    val model: String,      // e.g., "G Nock"
    val size: String?       // e.g., "Large", "Small"
)
```

#### Usage Example

```kotlin
val arrow = ArrowEntity(
    brand = "Easton",
    model = "X10",
    spine = "500",
    length = "29.5 inches",
    weight = "420 grains",
    diameter = "5.5mm",
    arrowPoint = ArrowPoint(
        brand = "Easton",
        model = "X10 Point",
        weight = "120 grains"
    ),
    arrowNock = ArrowNock(
        brand = "Easton",
        model = "G Nock",
        size = "Large"
    )
)
```

#### Type Converters

```kotlin
@TypeConverter
fun fromArrowPoint(point: ArrowPoint?): String? =
    point?.let { Json.encodeToString(it) }

@TypeConverter
fun toArrowPoint(value: String?): ArrowPoint? =
    value?.let { Json.decodeFromString(it) }

@TypeConverter
fun fromArrowNock(nock: ArrowNock?): String? =
    nock?.let { Json.encodeToString(it) }

@TypeConverter
fun toArrowNock(value: String?): ArrowNock? =
    value?.let { Json.decodeFromString(it) }
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.arrowId`)
**Cascade:** ON DELETE SET NULL

---

## Accessories

### Accessory Entity

Generic equipment items (tabs, chest guards, quivers, etc.)

**File:** `AccessoryEntity.kt`
**Table:** `Accessory`

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **brand** | String | Yes | Manufacturer | `"AAE"`, `"Beiter"`, `"Easton"` |
| **model** | String | Yes | Model/type | `"Elite Tab"`, `"Chest Guard"`, `"Hip Quiver"` |
| **type** | String? | No | Accessory category | `"Tab"`, `"Chest Guard"`, `"Quiver"`, `"Other"` |

#### Usage Example

```kotlin
val accessory = AccessoryEntity(
    brand = "AAE",
    model = "Elite Tab",
    type = "Tab"
)
```

#### Relationships

**Used In:** BowSetup (via `BowSetup.accessoryId`)
**Cascade:** ON DELETE SET NULL

---

## Bow Configuration

### BowSetup Entity

The BowSetup entity represents a complete equipment configuration, aggregating all components.

**File:** `BowSetupEntity.kt`
**Table:** `BowSetup`
**Total Fields:** 15

#### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **id** | Long | Yes | Primary key, auto-increment | `1`, `2`, `3` |
| **name** | String | Yes | Setup name | `"Competition Setup"`, `"Practice Bow"` |
| **description** | String? | No | Setup notes | `"38# limbs, 30\" stabilizer"` |
| **version** | Int | Yes | Version number (auto-increment) | `1`, `2`, `3` |
| **isActive** | Boolean | Yes | Soft delete flag | `true` (active), `false` (deleted) |
| **riserId** | Long? | No | Foreign key → Riser(id) | `1` |
| **limbsId** | Long? | No | Foreign key → Limbs(id) | `2` |
| **sightId** | Long? | No | Foreign key → Sight(id) | `3` |
| **stabilizerId** | Long? | No | Foreign key → Stabilizer(id) | `4` |
| **plungerId** | Long? | No | Foreign key → Plunger(id) | `5` |
| **restId** | Long? | No | Foreign key → Rest(id) | `6` |
| **bowStringId** | Long? | No | Foreign key → BowString(id) | `7` |
| **arrowId** | Long? | No | Foreign key → Arrow(id) | `8` |
| **weightId** | Long? | No | Foreign key → Weight(id) | `9` |
| **accessoryId** | Long? | No | Foreign key → Accessory(id) | `10` |

#### Versioning Behavior

**Automatic Version Increment:**
- Version starts at 1 when created
- Any equipment change increments version
- Changing limbs: version 1 → 2
- Changing stabilizer: version 2 → 3
- Rounds reference exact version for historical accuracy

**Example:**
```kotlin
// Initial setup (version 1)
val setup = BowSetupEntity(
    name = "My Setup",
    version = 1,
    isActive = true,
    riserId = 1L,
    limbsId = 2L
)

// Change limbs (version 2)
val updatedSetup = setup.copy(
    version = 2,
    limbsId = 3L  // New limbs
)

// Round created with version 2 always references that configuration
```

#### Soft Delete Behavior

**Why Soft Delete?**
- Preserve historical data integrity
- Rounds can always reference original equipment
- Equipment performance history maintained

**How It Works:**
```kotlin
// "Delete" a setup (soft delete)
bowSetupDao.updateActive(setupId, isActive = false)

// Setup still exists in database, but isActive = false
// Won't appear in active equipment lists
// Historical rounds still reference it
```

#### Usage Example

```kotlin
val bowSetup = BowSetupEntity(
    name = "Competition Setup 2025",
    description = "38# Hoyt Formula X, 30\" Doinker stab",
    version = 1,
    isActive = true,
    riserId = 1L,      // Hoyt Formula X riser
    limbsId = 2L,      // Hoyt 38# limbs
    sightId = 3L,      // Shibuya Ultima sight
    stabilizerId = 4L, // Doinker 30" stabilizer
    plungerId = 5L,    // Beiter plunger
    restId = 6L,       // Hoyt Super Rest
    bowStringId = 7L,  // BCY 8125G string
    arrowId = 8L,      // Easton X10 arrows
    weightId = 9L,     // 1oz weights
    accessoryId = 10L  // AAE Elite Tab
)
```

#### Relationships

**Children:** All equipment entities
- Foreign keys to 10 equipment types
- All cascade ON DELETE SET NULL
- Partial configurations allowed (nullable foreign keys)

**Used By:** Round (via `Round.bowSetupId` and `Round.bowSetupVersion`)

#### Queries

```kotlin
// Get active bow setups
@Query("SELECT * FROM BowSetup WHERE isActive = 1 ORDER BY name ASC")
suspend fun getActiveSetups(): List<BowSetupEntity>

// Get all versions of a setup
@Query("SELECT * FROM BowSetup WHERE name = :name ORDER BY version ASC")
suspend fun getSetupVersions(name: String): List<BowSetupEntity>

// Get setup with all equipment (requires JOINs)
@Query("""
    SELECT BowSetup.*, Riser.*, Limbs.*, Sight.*
    FROM BowSetup
    LEFT JOIN Riser ON BowSetup.riserId = Riser.id
    LEFT JOIN Limbs ON BowSetup.limbsId = Limbs.id
    LEFT JOIN Sight ON BowSetup.sightId = Sight.id
    WHERE BowSetup.id = :setupId
""")
suspend fun getSetupWithEquipment(setupId: Long): BowSetupWithEquipment
```

---

### BowSetupEquipment Entity

Junction table for flexible setup-equipment relationships (future use).

**File:** `BowSetupEquipmentEntity.kt`
**Table:** `BowSetupEquipment`

#### Fields

| Field | Type | Description |
|-------|------|-------------|
| **setupId** | Long | Foreign key → BowSetup(id) |
| **equipmentId** | Long | Generic equipment ID |
| **equipmentType** | String | Type of equipment (e.g., "RISER", "LIMBS") |

#### Purpose

Currently not actively used in favor of direct foreign keys in BowSetup. Preserved for potential future features:
- Multiple stabilizers
- Multiple accessories
- Dynamic equipment combinations

---

## Equipment Lifecycle

### Creating Equipment

```kotlin
// 1. Create individual components
val riser = riserDao.insert(RiserEntity(brand = "Hoyt", model = "Formula X", ...))
val limbs = limbsDao.insert(LimbsEntity(brand = "Hoyt", model = "X-Act", ...))
val sight = sightDao.insert(SightEntity(brand = "Shibuya", model = "Ultima", ...))

// 2. Create bow setup
val setup = bowSetupDao.insert(BowSetupEntity(
    name = "My Setup",
    version = 1,
    isActive = true,
    riserId = riser,
    limbsId = limbs,
    sightId = sight
))
```

### Updating Equipment

```kotlin
// Changing equipment creates new version
val currentSetup = bowSetupDao.getById(setupId)
val newVersion = currentSetup.version + 1

bowSetupDao.update(currentSetup.copy(
    version = newVersion,
    limbsId = newLimbsId  // Changed limbs
))

// Old rounds still reference old version
// New rounds will use new version
```

### Deleting Equipment

```kotlin
// Soft delete (preferred)
bowSetupDao.updateActive(setupId, isActive = false)
// Setup hidden from active lists but preserved

// Hard delete component (if not in any setup)
riserDao.delete(riserId)
// Only safe if no BowSetup references it
// Otherwise, BowSetup.riserId will be set to NULL (ON DELETE SET NULL)
```

---

## Equipment Performance Tracking

### Linking Equipment to Rounds

```kotlin
// When creating a round
val round = RoundEntity(
    roundName = "Practice",
    bowSetupId = currentSetup.id,
    bowSetupVersion = currentSetup.version,
    ...
)
```

### Querying Performance by Equipment

```kotlin
// Get all completed rounds for a setup
@Query("""
    SELECT * FROM Round
    WHERE bowSetupId = :setupId
    AND status = 'COMPLETED'
    ORDER BY completedAt DESC
""")
suspend fun getRoundsForSetup(setupId: Long): List<RoundEntity>

// Calculate average score for setup
@Query("""
    SELECT AVG(totalScore) as avgScore
    FROM Round
    WHERE bowSetupId = :setupId
    AND status = 'COMPLETED'
""")
suspend fun getAverageScoreForSetup(setupId: Long): Double
```

### Equipment Version Comparison

```kotlin
// Compare performance across versions
@Query("""
    SELECT version, AVG(totalScore) as avgScore, COUNT(*) as roundCount
    FROM Round
    WHERE bowSetupId = :setupId
    AND status = 'COMPLETED'
    GROUP BY bowSetupVersion
    ORDER BY version ASC
""")
suspend fun getPerformanceByVersion(setupId: Long): List<VersionPerformance>
```

---

## Multi-Participant Guest Setups

### Auto-Generated Guest Setups

When creating multi-participant rounds, temporary setups are auto-generated for guests:

```kotlin
// Round with 2 guests
val round = RoundEntity(
    participants = listOf(
        SessionParticipant("user123", "Chris", isGuest = false, bowSetupId = 5L),
        SessionParticipant("guest1", "Sarah", isGuest = true, bowSetupId = 100L),  // Auto-generated
        SessionParticipant("guest2", "Mike", isGuest = true, bowSetupId = 101L)   // Auto-generated
    )
)

// Guest setups created automatically
val guestSetup1 = BowSetupEntity(
    name = "Guest - Sarah (Temp)",
    version = 1,
    isActive = false,  // Not shown in active lists
    riserId = null,    // Minimal data
    limbsId = null
)
```

**Characteristics:**
- Name includes "Guest - {name} (Temp)"
- `isActive = false` (hidden from main equipment lists)
- Minimal equipment data
- Preserved for historical accuracy
- Don't clutter user's equipment management

---

## Type Converters

Equipment entities use type converters for embedded objects:

```kotlin
// ArrowPoint converter
@TypeConverter
fun fromArrowPoint(point: ArrowPoint?): String? =
    point?.let { Json.encodeToString(it) }

@TypeConverter
fun toArrowPoint(value: String?): ArrowPoint? =
    value?.let { Json.decodeFromString(it) }

// ArrowNock converter
@TypeConverter
fun fromArrowNock(nock: ArrowNock?): String? =
    nock?.let { Json.encodeToString(it) }

@TypeConverter
fun toArrowNock(value: String?): ArrowNock? =
    value?.let { Json.decodeFromString(it) }
```

---

## Indexes

Strategic indexes for performance:

```sql
-- BowSetup indexes
CREATE INDEX idx_bow_setup_active ON BowSetup(isActive);
CREATE INDEX idx_bow_setup_version ON BowSetup(version);

-- Foreign key indexes (for JOINs)
CREATE INDEX idx_bow_setup_riser_id ON BowSetup(riserId);
CREATE INDEX idx_bow_setup_limbs_id ON BowSetup(limbsId);
CREATE INDEX idx_bow_setup_sight_id ON BowSetup(sightId);
-- (and other foreign keys)

-- SightMark indexes
CREATE INDEX idx_sight_mark_sight_id ON SightMark(sightId);
```

---

## Related Entities

**Scoring:**
- [Round](../Scoring/#round-entity) - References BowSetup via bowSetupId
- [ArrowScore](../Scoring/#arrowscore-entity) - Tracks equipment per arrow

**Analytics:**
- [EquipmentStatsCache](../Analytics/#equipmentstatscache) - Cached performance metrics
- [ArrowEquipmentSnapshot](../Analytics/#arrowequipmentsnapshot) - Historical snapshots

---

## Developer Guidelines

### Best Practices

**1. Always Create Components First**
```kotlin
// Good: Create components, then setup
val riserId = riserDao.insert(riser)
val limbsId = limbsDao.insert(limbs)
val setup = BowSetupEntity(riserId = riserId, limbsId = limbsId, ...)

// Bad: Reference non-existent components
val setup = BowSetupEntity(riserId = 999L, ...)  // FK constraint violation
```

**2. Use Versioning for Equipment Changes**
```kotlin
// Good: Increment version on change
val newVersion = currentSetup.version + 1
val updated = currentSetup.copy(version = newVersion, limbsId = newLimbsId)

// Bad: Change equipment without versioning
val updated = currentSetup.copy(limbsId = newLimbsId)  // Version unchanged
```

**3. Soft Delete BowSetups**
```kotlin
// Good: Soft delete
bowSetupDao.updateActive(setupId, false)

// Bad: Hard delete
bowSetupDao.delete(setupId)  // Breaks historical round references
```

**4. Handle Nullable Foreign Keys**
```kotlin
// Good: Check nullability
val riser = setup.riserId?.let { riserDao.getById(it) }

// Bad: Assume non-null
val riser = riserDao.getById(setup.riserId)  // NPE if null
```

### Common Queries

**Get Complete Setup with Equipment:**
```kotlin
data class CompleteSetup(
    val setup: BowSetupEntity,
    val riser: RiserEntity?,
    val limbs: LimbsEntity?,
    val sight: SightEntity?,
    // ... other components
)

@Transaction
@Query("SELECT * FROM BowSetup WHERE id = :setupId")
suspend fun getCompleteSetup(setupId: Long): CompleteSetup
```

**Find Setups Using Specific Component:**
```kotlin
@Query("SELECT * FROM BowSetup WHERE riserId = :riserId AND isActive = 1")
suspend fun getSetupsUsingRiser(riserId: Long): List<BowSetupEntity>
```

---

## Related Documentation

**Database:**
- [Database Overview](../../Database/) - Full database architecture
- [Database Tables](../../Database/Tables/) - Table schemas

**Other Data Models:**
- [Scoring Models](../Scoring/) - Round and arrow data
- [Tournament Models](../Tournament/) - Tournament integration
- [Analytics Models](../Analytics/) - Performance metrics

**User Guides:**
- [Equipment Tasks](../../../user-guide/How-To/Equipment-Tasks/) - User-facing equipment management

---

## Quick Reference

### Equipment Entity Summary

| Entity | Required Fields | Optional Fields | Used In |
|--------|----------------|-----------------|---------|
| **Riser** | brand, model | length, material | BowSetup |
| **Limbs** | brand, model | poundage, limbLength | BowSetup |
| **BowString** | brand, model | strandCount, servingMaterial | BowSetup |
| **Sight** | brand, model | material | BowSetup, SightMark |
| **SightMark** | sightId, distance, markValue | notes | - |
| **Stabilizer** | brand, model | length, weight, straightnessRating | BowSetup |
| **Weight** | brand, model | ounces | BowSetup |
| **Plunger** | brand, model | adjustment | BowSetup |
| **Rest** | brand, model | type | BowSetup |
| **Arrow** | brand, model | spine, length, weight, diameter, arrowPoint, arrowNock | BowSetup |
| **Accessory** | brand, model | type | BowSetup |
| **BowSetup** | name, version, isActive | description, all equipment IDs | Round |

### BowSetup Versioning

**When Version Increments:**
- Any equipment field changes (riserId, limbsId, etc.)
- Description or name changes do NOT increment version

**Why Versioning Matters:**
- Rounds reference exact configuration at time of shooting
- Compare performance before/after equipment changes
- Historical accuracy for analytics

### Soft Delete Workflow

```
Active Setup (isActive = true)
  ↓
User "deletes" setup
  ↓
Soft Delete (isActive = false)
  ↓
Hidden from active lists
  ↓
Still referenced by historical rounds
  ↓
Can be queried if needed
```

---

**Next:** [Tournament Data Models](../Tournament/) - Tournament and participant entities

