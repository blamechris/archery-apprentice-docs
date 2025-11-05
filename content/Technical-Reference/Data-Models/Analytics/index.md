---
title: "Analytics Data Models"
description: "Analytics and statistics data structures"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - data-models
  - analytics
  - statistics
  - performance
  - caching
---

[Home](/) > [Technical Reference](../../) > [Data Models](../) > Analytics

---

# Analytics Data Models

Complete reference for analytics and statistics entities in Archery Apprentice. These models cache performance metrics and preserve historical equipment snapshots for accurate performance tracking and comparisons.

## Overview

**Total Analytics Entities:** 2 (EquipmentStatsCache, ArrowEquipmentSnapshot)
**Location:** `shared:database` module
**Package:** `com.archeryapprentice.database.entities.analytics`

### Purpose

**Performance Optimization:**
- Pre-calculate expensive aggregations
- Avoid repeated queries across scoring data
- Enable fast equipment comparisons

**Historical Accuracy:**
- Preserve exact equipment configurations at time of shooting
- Enable accurate "then vs now" comparisons
- Track equipment changes over time

### Entity Categories

| Entity | Purpose | Lifecycle |
|--------|---------|-----------|
| **EquipmentStatsCache** | Cached performance metrics per equipment | Updated after round completion |
| **ArrowEquipmentSnapshot** | Historical equipment snapshots per arrow | Created once, never modified |

---

## EquipmentStatsCache Entity

Pre-calculated performance metrics for equipment at specific distances, avoiding expensive real-time aggregations.

**File:** `EquipmentStatsCacheEntity.kt`
**Table:** `EquipmentStatsCache`

### Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **setupId** | Long | Primary key (FK to BowSetup) | `5` |
| **distance** | String | Shooting distance for these stats | `"50 meters"`, `"30 yards"` |
| **totalRounds** | Int | Number of completed rounds | `15`, `42` |
| **averageScore** | Double | Mean score across all rounds | `285.5`, `312.8` |
| **accuracy** | Double | Average accuracy percentage | `79.3`, `86.7` |
| **ringDistribution** | Map<Int, Int> | Arrows per ring (JSON) | `{10: 45, 9: 98, 8: 67, ...}` |
| **lastUpdated** | Instant | Cache timestamp | For cache invalidation |

### Composite Primary Key

The primary key is a combination of `(setupId, distance)`, allowing separate stats per equipment per distance.

**Why?**
- Equipment performs differently at different distances
- 50m stats ≠ 70m stats for same equipment
- Separate caches enable distance-specific comparisons

### Ring Distribution

**Format:**
```kotlin
ringDistribution = mapOf(
    10 to 45,   // 45 arrows in the 10 ring
    9 to 98,    // 98 arrows in the 9 ring
    8 to 67,    // 67 arrows in the 8 ring
    7 to 54,
    6 to 32,
    5 to 18,
    4 to 9,
    3 to 3,
    2 to 1,
    1 to 0,
    0 to 3      // 3 misses
)
```

**Purpose:**
- Visualize shot distribution (pie chart, bar graph)
- Identify scoring patterns
- Compare equipment performance profiles

### Usage Example

```kotlin
val statsCache = EquipmentStatsCacheEntity(
    setupId = 5L,
    distance = "50 meters",
    totalRounds = 25,
    averageScore = 312.4,
    accuracy = 86.8,  // 86.8% of maximum possible
    ringDistribution = mapOf(
        10 to 120,
        9 to 230,
        8 to 180,
        7 to 95,
        6 to 50,
        5 to 15,
        4 to 5,
        3 to 2,
        2 to 1,
        1 to 0,
        0 to 2
    ),
    lastUpdated = Clock.System.now()
)
```

### Cache Update Strategy

**When to Update:**
1. After completing a round
2. When equipment version changes (create new cache entry)
3. On user-requested stats refresh

**Update Logic:**
```kotlin
suspend fun updateEquipmentStatsCache(setupId: Long, distance: String) {
    // 1. Get all completed rounds for this setup and distance
    val rounds = roundDao.getCompletedRounds(
        setupId = setupId,
        distance = distance,
        status = RoundStatus.COMPLETED
    )

    // 2. Calculate aggregates
    val totalRounds = rounds.size
    val averageScore = rounds.map { it.totalScore }.average()
    val averageAccuracy = rounds.map { it.accuracy }.average()

    // 3. Calculate ring distribution
    val allArrows = arrowScoreDao.getArrowsForRounds(rounds.map { it.id })
    val ringDistribution = allArrows
        .groupBy { it.scoreValue }
        .mapValues { it.value.size }

    // 4. Update or insert cache
    val cache = EquipmentStatsCacheEntity(
        setupId = setupId,
        distance = distance,
        totalRounds = totalRounds,
        averageScore = averageScore,
        accuracy = averageAccuracy,
        ringDistribution = ringDistribution,
        lastUpdated = Clock.System.now()
    )

    statsCacheDao.upsert(cache)
}
```

### Cache Invalidation

**When to Invalidate:**
- Equipment version changes (new cache entry needed)
- Round deleted or status changed from COMPLETED
- Manual user request

**Invalidation Strategy:**
```kotlin
// Don't delete old cache - create new entry for new version
// Old cache preserved for historical comparisons

suspend fun onEquipmentVersionChange(oldSetupId: Long, newSetupId: Long) {
    // Old cache (setupId = 5, version 1) remains
    // New cache (setupId = 5, version 2) will be created as rounds complete
}
```

### Queries

**Get stats for equipment at distance:**
```kotlin
@Query("""
    SELECT * FROM EquipmentStatsCache
    WHERE setupId = :setupId AND distance = :distance
""")
suspend fun getStats(setupId: Long, distance: String): EquipmentStatsCacheEntity?
```

**Get all stats for equipment (all distances):**
```kotlin
@Query("""
    SELECT * FROM EquipmentStatsCache
    WHERE setupId = :setupId
    ORDER BY distance ASC
""")
suspend fun getAllStatsForSetup(setupId: Long): List<EquipmentStatsCacheEntity>
```

**Compare equipment at same distance:**
```kotlin
@Query("""
    SELECT * FROM EquipmentStatsCache
    WHERE distance = :distance
    ORDER BY averageScore DESC
""")
suspend fun compareEquipmentAtDistance(distance: String): List<EquipmentStatsCacheEntity>
```

### Type Converter

```kotlin
// Map<Int, Int> ↔ JSON String
@TypeConverter
fun fromRingDistribution(map: Map<Int, Int>): String =
    Json.encodeToString(map)

@TypeConverter
fun toRingDistribution(value: String): Map<Int, Int> =
    Json.decodeFromString(value)
```

---

## ArrowEquipmentSnapshot Entity

Historical snapshot of equipment configuration at the time an arrow was shot. Enables accurate "what equipment was I using when I shot this arrow?" queries.

**File:** `ArrowEquipmentSnapshotEntity.kt`
**Table:** `ArrowEquipmentSnapshot`

### Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **id** | Long | Primary key, auto-increment | `1`, `2`, `3` |
| **arrowScoreId** | Long | Foreign key → ArrowScore(id) | `12345` |
| **bowSetupSnapshot** | String | Complete BowSetup JSON | See below |

### BowSetup Snapshot

**Format:**
Full BowSetup entity serialized to JSON, including all referenced equipment.

**Example:**
```json
{
  "id": 5,
  "name": "Competition Setup",
  "version": 3,
  "isActive": true,
  "riser": {
    "id": 1,
    "brand": "Hoyt",
    "model": "Formula X",
    "length": "25 inches",
    "material": "Carbon"
  },
  "limbs": {
    "id": 2,
    "brand": "Hoyt",
    "model": "Formula X-Act",
    "poundage": "38 lbs",
    "limbLength": "Long"
  },
  "sight": {
    "id": 3,
    "brand": "Shibuya",
    "model": "Ultima RC II"
  },
  "stabilizer": {
    "id": 4,
    "brand": "Doinker",
    "model": "Platinum",
    "length": "30 inches"
  }
  // ... all other equipment
}
```

### Purpose

**Historical Accuracy:**
1. Equipment changes after shooting don't affect historical data
2. Can always see exact configuration used for any arrow
3. Enables retroactive equipment performance analysis

**Use Cases:**
- "What limbs was I using when I shot this 10?"
- "Compare arrows shot with setup v1 vs v2"
- "Analyze performance before and after equipment change"

### Usage Example

```kotlin
// When scoring an arrow
suspend fun scoreArrow(arrow: ArrowScoreEntity, bowSetup: BowSetupEntity) {
    // 1. Insert arrow score
    val arrowId = arrowScoreDao.insert(arrow)

    // 2. Create equipment snapshot
    val completeSetup = getCompleteSetup(bowSetup.id)  // Includes all equipment
    val snapshot = ArrowEquipmentSnapshotEntity(
        arrowScoreId = arrowId,
        bowSetupSnapshot = Json.encodeToString(completeSetup)
    )
    snapshotDao.insert(snapshot)
}
```

### Queries

**Get snapshot for arrow:**
```kotlin
@Query("""
    SELECT * FROM ArrowEquipmentSnapshot
    WHERE arrowScoreId = :arrowScoreId
""")
suspend fun getSnapshotForArrow(arrowScoreId: Long): ArrowEquipmentSnapshotEntity?
```

**Get arrows with specific equipment component:**
```kotlin
// Find all arrows shot with specific riser
// (Requires JSON parsing or full-text search)
@Query("""
    SELECT * FROM ArrowEquipmentSnapshot
    WHERE bowSetupSnapshot LIKE '%"riser":{"id":' || :riserId || '%'
""")
suspend fun findArrowsWithRiser(riserId: Long): List<ArrowEquipmentSnapshotEntity>
```

**Get snapshot with arrow data:**
```kotlin
data class ArrowWithSnapshot(
    val arrow: ArrowScoreEntity,
    val snapshot: ArrowEquipmentSnapshotEntity?
)

@Transaction
@Query("""
    SELECT a.*, s.*
    FROM ArrowScore a
    LEFT JOIN ArrowEquipmentSnapshot s ON s.arrowScoreId = a.id
    WHERE a.id = :arrowId
""")
suspend fun getArrowWithSnapshot(arrowId: Long): ArrowWithSnapshot
```

### Snapshot Creation Strategy

**Option 1: Snapshot Every Arrow** (Current approach)
- Pros: Complete historical accuracy
- Cons: Storage overhead for frequent equipment

**Option 2: Snapshot on Equipment Change**
- Pros: Reduced storage
- Cons: More complex to reconstruct arrow-time equipment

**Option 3: Snapshot per Round**
- Pros: Balance of accuracy and storage
- Cons: Assumes no mid-round equipment changes

**Recommendation:** Option 1 (snapshot every arrow) for maximum accuracy, or Option 3 (snapshot per round) for practical balance.

### Type Converter

```kotlin
// BowSetupSnapshot (complex object) ↔ JSON String
@TypeConverter
fun fromBowSetupSnapshot(snapshot: BowSetupSnapshot): String =
    Json.encodeToString(snapshot)

@TypeConverter
fun toBowSetupSnapshot(value: String): BowSetupSnapshot =
    Json.decodeFromString(value)
```

---

## Relationships

### EquipmentStatsCache Relationships

**Parent:** BowSetup (Many-to-One via setupId)
- No formal FK constraint (to preserve cache if setup deleted)
- Logical relationship: cache belongs to setup

**Data Sources:**
- Round entities (via Round.bowSetupId)
- ArrowScore entities (via ArrowScore.roundId)

**Update Triggers:**
- Round completion (Round.status → COMPLETED)
- Round deletion (remove from aggregation)

### ArrowEquipmentSnapshot Relationships

**Parent:** ArrowScore (One-to-One)
- Foreign Key: `ArrowEquipmentSnapshot.arrowScoreId → ArrowScore.id`
- Cascade: ON DELETE CASCADE (deleting arrow deletes snapshot)

**Data Source:**
- BowSetup entity at time of arrow scoring
- All referenced equipment entities (Riser, Limbs, etc.)

---

## Analytics Workflows

### Workflow 1: Equipment Performance Over Time

**Goal:** Track how a bow setup performs as archer improves.

```kotlin
suspend fun getEquipmentPerformanceOverTime(setupId: Long, distance: String): List<PerformancePoint> {
    // Get all completed rounds chronologically
    val rounds = roundDao.getCompletedRoundsChronological(setupId, distance)

    return rounds.map { round ->
        PerformancePoint(
            date = round.completedAt,
            score = round.totalScore,
            accuracy = round.accuracy
        )
    }
}

// Visualize as line chart: time → score
```

### Workflow 2: Compare Equipment Versions

**Goal:** Did the new limbs improve performance?

```kotlin
suspend fun compareEquipmentVersions(setupId: Long, version1: Int, version2: Int, distance: String) {
    // Get cached stats for each version
    val stats1 = statsCacheDao.getStats(setupId, version1, distance)
    val stats2 = statsCacheDao.getStats(setupId, version2, distance)

    return VersionComparison(
        version1 = VersionStats(
            version = version1,
            averageScore = stats1.averageScore,
            accuracy = stats1.accuracy,
            roundCount = stats1.totalRounds
        ),
        version2 = VersionStats(
            version = version2,
            averageScore = stats2.averageScore,
            accuracy = stats2.accuracy,
            roundCount = stats2.totalRounds
        ),
        improvement = stats2.averageScore - stats1.averageScore
    )
}
```

### Workflow 3: Ring Distribution Analysis

**Goal:** Visualize where arrows are landing.

```kotlin
suspend fun getRingDistributionChart(setupId: Long, distance: String): PieChartData {
    val stats = statsCacheDao.getStats(setupId, distance)

    return PieChartData(
        slices = stats.ringDistribution.map { (ring, count) ->
            PieSlice(
                label = if (ring == 0) "Miss" else "$ring-ring",
                value = count,
                color = getRingColor(ring)
            )
        }
    )
}
```

### Workflow 4: Advanced Shot Grouping (with Coordinates)

**Goal:** Analyze shot grouping for arrows with coordinate data.

**Requirements:**
- Arrows scored with Target Face method
- ArrowScore.targetX and targetY populated

```kotlin
suspend fun calculateGroupingMetrics(roundId: Long): GroupingMetrics {
    val arrows = arrowScoreDao.getArrowsWithCoordinates(roundId)

    // Calculate centroid (group center)
    val centerX = arrows.map { it.targetX ?: 0.0 }.average()
    val centerY = arrows.map { it.targetY ?: 0.0 }.average()

    // Calculate radial standard deviation
    val radialSD = arrows.map { arrow ->
        val dx = (arrow.targetX ?: 0.0) - centerX
        val dy = (arrow.targetY ?: 0.0) - centerY
        sqrt(dx * dx + dy * dy)
    }.standardDeviation()

    // Calculate eccentricity (how "stretched" the group is)
    val eccentricity = calculateEccentricity(arrows)

    // Calculate bias (directional tendency)
    val bias = calculateBias(centerX, centerY)

    return GroupingMetrics(
        centerX = centerX,
        centerY = centerY,
        radialSD = radialSD,
        eccentricity = eccentricity,
        bias = bias
    )
}
```

**Eccentricity:**
- 0 = perfect circle
- 1 = perfectly linear group
- Indicates consistency in one dimension vs another

**Radial SD:**
- Standard deviation of arrow distances from group center
- Lower = tighter group
- Units: normalized to target size

**Bias:**
- Directional tendency (e.g., "consistently left")
- Calculated as angle from center to group centroid
- Example: 90° = high, 180° = left, 270° = low, 0° = right

### Workflow 5: Fatigue Analysis

**Goal:** Detect performance drop-off during round.

```kotlin
suspend fun analyzeFatigue(roundId: Long): FatigueAnalysis {
    val ends = endScoreDao.getEndScores(roundId)

    // Compare first third vs last third of round
    val firstThird = ends.take(ends.size / 3)
    val lastThird = ends.takeLast(ends.size / 3)

    val avgFirst = firstThird.map { it.totalScore }.average()
    val avgLast = lastThird.map { it.totalScore }.average()

    val fatigueDrop = avgFirst - avgLast
    val fatiguePercent = (fatigueDrop / avgFirst) * 100

    return FatigueAnalysis(
        firstThirdAvg = avgFirst,
        lastThirdAvg = avgLast,
        drop = fatigueDrop,
        dropPercent = fatiguePercent,
        hasFatigue = fatiguePercent > 5.0  // > 5% drop indicates fatigue
    )
}
```

---

## Cache Management

### Cache Size Considerations

**EquipmentStatsCache:**
- Size: ~500 bytes per entry
- Entries: (# setups) × (# distances practiced)
- Example: 10 setups × 5 distances = 50 entries ≈ 25 KB
- **Conclusion:** Negligible storage impact

**ArrowEquipmentSnapshot:**
- Size: ~2-5 KB per snapshot
- Entries: # arrows scored (potentially tens of thousands)
- Example: 1,000 rounds × 72 arrows = 72,000 snapshots ≈ 144-360 MB
- **Consideration:** Can grow large over time

### Snapshot Optimization Strategies

**Strategy 1: Differential Snapshots**
- Only store equipment that changed since last snapshot
- Reference previous snapshot ID for unchanged equipment
- Reduces redundancy

**Strategy 2: Compression**
- Compress JSON before storage
- Use gzip or similar
- Reduces storage by ~60-80%

**Strategy 3: Sampling**
- Snapshot first arrow of each end
- Reconstruct others by assuming no mid-end changes
- 6x storage reduction (6-arrow ends)

**Strategy 4: Periodic Cleanup**
- Archive old snapshots (e.g., > 2 years)
- Keep aggregated stats, discard snapshots
- Balances history preservation with storage

**Recommendation:** Start with full snapshots, implement compression if storage becomes issue.

---

## Performance Optimization

### Index Strategy

```sql
-- EquipmentStatsCache
CREATE INDEX idx_stats_cache_setup_id ON EquipmentStatsCache(setupId);
CREATE INDEX idx_stats_cache_distance ON EquipmentStatsCache(distance);
CREATE INDEX idx_stats_cache_composite ON EquipmentStatsCache(setupId, distance);

-- ArrowEquipmentSnapshot
CREATE INDEX idx_snapshot_arrow_id ON ArrowEquipmentSnapshot(arrowScoreId);
```

### Query Optimization

**Good: Use cached stats**
```kotlin
// Fast: Pre-calculated
val avgScore = statsCacheDao.getStats(setupId, distance).averageScore
```

**Bad: Real-time aggregation**
```kotlin
// Slow: Aggregates all arrows every time
val avgScore = roundDao.getRoundsForSetup(setupId)
    .filter { it.distance == distance }
    .map { it.totalScore }
    .average()
```

### Cache Warming

**Preload cache on app start:**
```kotlin
suspend fun warmStatsCache() {
    val activeSetups = bowSetupDao.getActiveSetups()
    val commonDistances = listOf("30m", "50m", "70m")

    activeSetups.forEach { setup ->
        commonDistances.forEach { distance ->
            if (!statsCacheDao.exists(setup.id, distance)) {
                updateEquipmentStatsCache(setup.id, distance)
            }
        }
    }
}
```

---

## Related Entities

**Scoring:**
- [Round](../Scoring/#round-entity) - Data source for stats cache
- [ArrowScore](../Scoring/#arrowscore-entity) - Linked to equipment snapshots

**Equipment:**
- [BowSetup](../Equipment/#bowsetup-entity) - Referenced in stats cache and snapshots

---

## Developer Guidelines

### Best Practices

**1. Update Cache After Round Completion**
```kotlin
// Good: Update cache when round completes
suspend fun completeRound(roundId: Long) {
    val round = roundDao.getById(roundId)
    roundDao.updateStatus(roundId, RoundStatus.COMPLETED)

    // Update cache
    round.bowSetupId?.let { setupId ->
        updateEquipmentStatsCache(setupId, round.distance)
    }
}

// Bad: Forget to update cache
roundDao.updateStatus(roundId, RoundStatus.COMPLETED)
// Stats now stale!
```

**2. Handle Missing Cache Gracefully**
```kotlin
// Good: Fallback to real-time calculation
suspend fun getAverageScore(setupId: Long, distance: String): Double {
    val cached = statsCacheDao.getStats(setupId, distance)
    return cached?.averageScore ?: calculateAverageScoreLive(setupId, distance)
}

// Bad: Crash on missing cache
val avgScore = statsCacheDao.getStats(setupId, distance).averageScore  // NPE if null
```

**3. Snapshot Strategically**
```kotlin
// Good: Snapshot per round (efficient)
suspend fun scoreRound(round: RoundEntity, bowSetup: BowSetupEntity) {
    val setupSnapshot = createSnapshot(bowSetup)

    round.arrows.forEach { arrow ->
        arrowScoreDao.insert(arrow)
        // All arrows in round reference same snapshot (via roundId)
    }
}

// Alternative: Snapshot per arrow (maximum accuracy, more storage)
```

**4. Clean Up Old Snapshots**
```kotlin
// Periodic cleanup of very old snapshots
suspend fun cleanupOldSnapshots(olderThanDays: Int = 730) {  // 2 years
    val cutoffDate = Clock.System.now().minus(olderThanDays.days)

    val oldArrows = arrowScoreDao.getArrowsOlderThan(cutoffDate)
    oldArrows.forEach { arrow ->
        snapshotDao.delete(arrow.id)
    }
}
```

### Common Queries

**Get equipment performance summary:**
```kotlin
data class EquipmentSummary(
    val setupId: Long,
    val setupName: String,
    val totalRounds: Int,
    val averageScore: Double,
    val bestScore: Int,
    val recentTrend: String  // "Improving", "Declining", "Stable"
)

suspend fun getEquipmentSummary(setupId: Long, distance: String): EquipmentSummary {
    val stats = statsCacheDao.getStats(setupId, distance)
    val rounds = roundDao.getCompletedRounds(setupId, distance)
    val recentRounds = rounds.takeLast(10)

    val trend = calculateTrend(recentRounds.map { it.totalScore })

    return EquipmentSummary(
        setupId = setupId,
        setupName = bowSetupDao.getById(setupId).name,
        totalRounds = stats.totalRounds,
        averageScore = stats.averageScore,
        bestScore = rounds.maxOf { it.totalScore },
        recentTrend = trend
    )
}
```

**Compare multiple setups:**
```kotlin
suspend fun compareSetups(
    setupIds: List<Long>,
    distance: String
): List<SetupComparison> {
    return setupIds.map { setupId ->
        val stats = statsCacheDao.getStats(setupId, distance)
        val setup = bowSetupDao.getById(setupId)

        SetupComparison(
            setupId = setupId,
            setupName = setup.name,
            averageScore = stats?.averageScore ?: 0.0,
            accuracy = stats?.accuracy ?: 0.0,
            roundCount = stats?.totalRounds ?: 0
        )
    }.sortedByDescending { it.averageScore }
}
```

---

## Related Documentation

**Database:**
- [Database Overview](../../Database/) - Full database architecture
- [Database Tables](../../Database/Tables/) - Table schemas

**Other Data Models:**
- [Scoring Models](../Scoring/) - Round and arrow data sources
- [Equipment Models](../Equipment/) - BowSetup referenced in caches

**User Guides:**
- [Analytics Features](../../../user-guide/features/Analytics/) - User-facing analytics

---

## Quick Reference

| Entity | Purpose | Size | Update Frequency |
|--------|---------|------|------------------|
| **EquipmentStatsCache** | Pre-calculated performance metrics | ~500 bytes | After round completion |
| **ArrowEquipmentSnapshot** | Historical equipment configurations | ~2-5 KB | Once per arrow (or per round) |

**EquipmentStatsCache Fields:**
- `setupId` + `distance` (composite key)
- `totalRounds`, `averageScore`, `accuracy`
- `ringDistribution` (Map<Int, Int>)
- `lastUpdated`

**ArrowEquipmentSnapshot Fields:**
- `id`, `arrowScoreId`
- `bowSetupSnapshot` (JSON string)

**Key Metrics:**
- **Accuracy** - Score as percentage of maximum
- **Ring Distribution** - Arrows per ring (10, 9, 8, ...)
- **Eccentricity** - Group shape (0 = circle, 1 = line)
- **Radial SD** - Group tightness
- **Bias** - Directional tendency
- **Fatigue Drop** - Performance decline during round

**Cache Management:**
- Update cache on round completion
- Invalidate on equipment version change
- Consider compression for snapshots
- Periodic cleanup of old snapshots (>2 years)

---

**Navigation:**
- **Previous:** [Tournament Data Models](../Tournament/)
- **Next:** [Database Tables](../../Database/Tables/)
