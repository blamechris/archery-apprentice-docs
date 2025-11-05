---
title: "Scoring Data Models"
description: "Scoring-related data structures and entities"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - data-models
  - scoring
  - entities
  - round
  - arrows
---

[Home](/) > [Technical Reference](../../) > [Data Models](../) > Scoring

---

# Scoring Data Models

Complete reference for scoring-related entities in Archery Apprentice. These models track rounds, ends, and individual arrow scores with full support for multi-participant sessions, equipment versioning, and tournament integration.

## Overview

**Core Entities:** 3 (Round, EndScore, ArrowScore)
**Relationships:** Cascading one-to-many (Round → EndScore → ArrowScore)
**Location:** `shared:database` module
**Package:** `com.archeryapprentice.database.entities.scoring`

### Entity Hierarchy

```
Round (scoring session)
  └── EndScore (group of arrows)
        └── ArrowScore (individual arrow)
```

**Cascading Deletes:**
- Deleting a Round deletes all associated EndScores and ArrowScores
- Data integrity preserved through foreign key constraints
- Historical equipment snapshots maintained separately

---

## Round Entity

The Round entity represents a complete scoring session, from creation through completion or cancellation.

**File:** `RoundEntity.kt`
**Table:** `Round`
**Total Fields:** 25

### Field Categories

#### 1. Basic Configuration (5 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **id** | Long | Primary key, auto-increment | `1`, `2`, `3` |
| **roundName** | String | User-defined round name | `"Practice - May 15"` |
| **numEnds** | Int | Total ends in round | `6`, `10`, `12` |
| **numArrows** | Int | Arrows per end | `3`, `6` |
| **distance** | Distance | Shooting distance | `"50 meters"`, `"30 yards"` |

**Usage:**
```kotlin
val round = RoundEntity(
    roundName = "Competition Prep",
    numEnds = 6,
    numArrows = 6,
    distance = Distance.fromString("70 meters"),
    targetSize = TargetSize.fromString("122cm")
)
```

#### 2. Target Configuration (2 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **targetSize** | TargetSize | Target face size | `"122cm"`, `"80cm"`, `"40cm"` |
| **scoringSystem** | ScoringSystem | Ring scoring system | `10-ring`, `6-ring`, `5-zone` |

**Supported Scoring Systems:**
- `10-ring` - Standard Olympic recurve (10, 9, 8, 7, 6, 5, 4, 3, 2, 1, miss)
- `6-ring` - NFAA field archery (6, 5, 4, 3, 2, 1, miss)
- `5-zone` - Simplified practice (5, 4, 3, 2, 1, miss)
- `X-ring compound` - Compound bow scoring with smaller X-ring

#### 3. Legacy Scoring Fields (2 fields)

| Field | Type | Description | Status |
|-------|------|-------------|--------|
| **targetRings** | List<Int>? | Legacy ring definition | Deprecated, use scoringSystem |
| **ringValues** | Map<Int, Int>? | Legacy ring values | Deprecated, use scoringSystem |

**Note:** These fields are preserved for backward compatibility but scoringSystem is preferred.

#### 4. Equipment Tracking (2 fields)

| Field | Type | Description | Purpose |
|-------|------|-------------|---------|
| **bowSetupId** | Long? | Foreign key to BowSetup | Links round to equipment configuration |
| **bowSetupVersion** | Int? | Equipment version snapshot | Tracks exact equipment version used |

**Equipment Versioning:**
- `bowSetupId` references BowSetup entity
- `bowSetupVersion` preserves exact configuration at time of round
- If equipment changes later, round still references original version
- Enables accurate equipment performance analytics

**Example:**
```kotlin
// Round created with BowSetup id=5, version=3
round.bowSetupId = 5L
round.bowSetupVersion = 3

// Later, if BowSetup changes to version 4, this round still references version 3
// Ensures historical accuracy
```

#### 5. Status Management (1 field)

| Field | Type | Description | Allowed Values |
|-------|------|-------------|----------------|
| **status** | RoundStatus | Current round state | PLANNED, IN_PROGRESS, PAUSED, COMPLETED, CANCELLED |

**Status Workflow:**

```
PLANNED → IN_PROGRESS → COMPLETED
            ↓
          PAUSED → (resume) → IN_PROGRESS
            ↓
        CANCELLED
```

**Status Definitions:**
- **PLANNED** - Round created but not started, no scores entered yet
- **IN_PROGRESS** - Active scoring session, currently entering scores
- **PAUSED** - Temporarily stopped, can be resumed later
- **COMPLETED** - All ends scored, final statistics available
- **CANCELLED** - Invalid/abandoned round, excluded from statistics

#### 6. Multi-Participant Support (2 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **participants** | List<SessionParticipant> | List of participants (JSON) | `[{"id":"user1","name":"John"},{"id":"guest1","name":"Sarah"}]` |
| **participantTheme** | ParticipantTheme | Single or multi mode | `SINGLE_USER`, `MULTI_PARTICIPANT` |

**SessionParticipant Structure:**
```kotlin
data class SessionParticipant(
    val id: String,           // Unique participant ID
    val name: String,         // Display name
    val isGuest: Boolean,     // True if guest archer
    val bowSetupId: Long?     // Optional equipment reference
)
```

**Multi-Participant Rules:**
- Maximum 4 participants (1 user + 3 guests)
- Each participant gets separate scores and statistics
- Guests auto-generate temporary bow setups
- Participant theme determines UI mode

#### 7. Tournament Integration (4 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **tournamentId** | String? | Tournament identifier | `"spring-tourney-2025"` |
| **tournamentRoundNumber** | Int? | Round number in tournament | `1`, `2`, `3` |
| **isLocal** | Boolean | Local vs remote tournament | `true` (offline), `false` (online) |
| **syncStatus** | SyncStatus? | Sync state for remote tournaments | `SYNCED`, `PENDING`, `FAILED` |

**Tournament Types:**
- **Local:** Offline tournament, no sync required
- **Remote:** Online tournament, requires sync with server
- **Hybrid:** Local creation with optional remote sync

#### 8. Timestamps (4 fields)

| Field | Type | Description | Purpose |
|-------|------|-------------|---------|
| **createdAt** | Instant | Round creation time | Sorting, history tracking |
| **startedAt** | Instant? | When scoring began | Performance tracking |
| **completedAt** | Instant? | When round finished | Duration calculation |
| **lastModifiedAt** | Instant | Last update time | Sync conflict resolution |

**Timestamp Behavior:**
- `createdAt` set on entity creation
- `startedAt` set when status → IN_PROGRESS
- `completedAt` set when status → COMPLETED
- `lastModifiedAt` updates on any field change

#### 9. Statistics Cache (3 fields)

| Field | Type | Description | Calculation |
|-------|------|-------------|-------------|
| **totalScore** | Int | Sum of all arrow scores | Cached for performance |
| **maxPossibleScore** | Int | Theoretical maximum | `numEnds × numArrows × maxRingValue` |
| **accuracy** | Double | Score as percentage | `(totalScore / maxPossibleScore) × 100` |

**Why Cache?**
- Avoids expensive database aggregations
- Real-time statistics during scoring
- Quick round comparisons

### Complete Round Example

```kotlin
val practiceRound = RoundEntity(
    id = 1L,
    roundName = "Morning Practice - 50m",
    numEnds = 6,
    numArrows = 6,
    distance = Distance.fromString("50 meters"),
    targetSize = TargetSize.fromString("122cm"),
    scoringSystem = ScoringSystem.TEN_RING,
    bowSetupId = 5L,
    bowSetupVersion = 3,
    status = RoundStatus.IN_PROGRESS,
    participants = listOf(
        SessionParticipant(
            id = "user123",
            name = "Chris",
            isGuest = false,
            bowSetupId = 5L
        )
    ),
    participantTheme = ParticipantTheme.SINGLE_USER,
    tournamentId = null,
    isLocal = true,
    createdAt = Clock.System.now(),
    startedAt = Clock.System.now(),
    lastModifiedAt = Clock.System.now(),
    totalScore = 0,
    maxPossibleScore = 360, // 6 ends × 6 arrows × 10
    accuracy = 0.0
)
```

---

## EndScore Entity

The EndScore entity groups arrow scores into ends (sets of arrows shot before retrieving).

**File:** `EndScoreEntity.kt`
**Table:** `EndScore`
**Total Fields:** 6

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| **id** | Long | Primary key, auto-increment | Unique end identifier |
| **roundId** | Long | Foreign key → Round(id), CASCADE DELETE | Parent round |
| **endNumber** | Int | 1-based index | End sequence (1, 2, 3...) |
| **totalScore** | Int | Sum of arrows | Cached end total |
| **isComplete** | Boolean | All arrows entered? | `true` when all arrows scored |
| **participantId** | String? | Session participant ID | For multi-participant rounds |

### Relationships

**Parent:** Round (Many-to-One)
- `endNumber` is unique within a round
- Deleting a Round cascades to EndScores
- Foreign key: `EndScore.roundId → Round.id`

**Children:** ArrowScore (One-to-Many)
- Each EndScore has multiple ArrowScores
- Number of arrows = Round.numArrows
- Deleting EndScore cascades to ArrowScores

### Indexes

```sql
CREATE INDEX idx_end_score_round_id ON EndScore(roundId);
CREATE INDEX idx_end_score_participant_id ON EndScore(participantId);
```

**Why These Indexes?**
- `roundId` - Frequent JOINs to get all ends for a round
- `participantId` - Multi-participant scoring queries

### Usage Example

```kotlin
// Create an end for round 1, end number 1
val end1 = EndScoreEntity(
    roundId = 1L,
    endNumber = 1,
    totalScore = 56,        // Sum of 6 arrows
    isComplete = true,      // All arrows entered
    participantId = "user123"
)

// Query all ends for a round
@Query("SELECT * FROM EndScore WHERE roundId = :roundId ORDER BY endNumber ASC")
suspend fun getEndScoresForRound(roundId: Long): List<EndScoreEntity>
```

### Multi-Participant Behavior

In multi-participant rounds:
- Each participant gets separate EndScore entries
- Same endNumber, different participantId
- Example: End 1 has 4 EndScore rows (one per participant)

```kotlin
// Round with 2 participants
val participant1End1 = EndScoreEntity(
    roundId = 1L,
    endNumber = 1,
    participantId = "user123",
    totalScore = 56
)

val participant2End1 = EndScoreEntity(
    roundId = 1L,
    endNumber = 1,
    participantId = "guest1",
    totalScore = 52
)
```

---

## ArrowScore Entity

The ArrowScore entity represents a single arrow shot, with optional coordinate tracking for grouping analysis.

**File:** `ArrowScoreEntity.kt`
**Table:** `ArrowScore`
**Total Fields:** 16

### Field Categories

#### 1. Identity & Relationships (4 fields)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| **id** | Long | Primary key, auto-increment | Unique arrow identifier |
| **endScoreId** | Long | Foreign key → EndScore(id), CASCADE DELETE | Parent end |
| **roundId** | Long | Foreign key → Round(id), CASCADE DELETE | Parent round (denormalized) |
| **arrowNumber** | Int | 1-based index | Arrow sequence within end (1, 2, 3...) |

**Why Denormalize roundId?**
- Faster queries for round-level arrow analysis
- Avoids JOIN through EndScore
- Trade-off: Slight data duplication for performance

#### 2. Score Data (2 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **scoreValue** | Int | Arrow score | `10`, `9`, `8`, `7`, `6`, `5`, `4`, `3`, `2`, `1`, `0` (miss) |
| **isXRing** | Boolean | Inner 10 hit? | `true` for X-ring 10s, `false` otherwise |

**X-Ring Rules:**
- Only applicable when `scoreValue = 10`
- Used for tie-breaking in competitions
- Compound X-ring smaller than recurve X-ring
- All X's are 10s, but not all 10s are X's

#### 3. Coordinate Data (6 fields)

| Field | Type | Description | Purpose |
|-------|------|-------------|---------|
| **targetX** | Double? | Horizontal coordinate | Shot grouping analysis |
| **targetY** | Double? | Vertical coordinate | Shot grouping analysis |
| **centerX** | Double? | Target center X | Normalize to different target sizes |
| **centerY** | Double? | Target center Y | Normalize to different target sizes |
| **ringNumber** | Int? | Scored ring (0-10) | Alternative to scoreValue |
| **clockPosition** | Int? | Arrow position (1-12) | Directional analysis (like clock face) |

**Coordinate System:**
- Origin (0, 0) at target center
- Positive X = right, Negative X = left
- Positive Y = up, Negative Y = down
- Units: Normalized to target size

**When Coordinates Are Captured:**
- Target Face scoring method: All coordinates filled
- Manual entry: Coordinates null
- Quick entry: Coordinates null

**Advanced Analytics Enabled:**
- **Eccentricity** - How "stretched" the shot group is (0 = perfect circle, 1 = line)
- **Radial SD** - Standard deviation of arrows from group center
- **Bias** - Directional tendency (e.g., consistently left)
- **Clock Position** - Visualize patterns (e.g., 3 o'clock = right)

#### 4. Equipment Tracking (2 fields)

| Field | Type | Description | Purpose |
|-------|------|-------------|---------|
| **bowSetupId** | Long? | Equipment used | Track equipment per arrow (if changed mid-round) |
| **bowSetupVersion** | Int? | Equipment version | Historical accuracy |

**Why Track Per Arrow?**
- Theoretically supports mid-round equipment changes
- Currently: All arrows in round use same equipment
- Future-proofing for advanced scenarios

#### 5. Metadata (2 fields)

| Field | Type | Description | Values |
|-------|------|-------------|--------|
| **participantId** | String? | Who shot this arrow | `"user123"`, `"guest1"`, `"guest2"` |
| **inputMethod** | InputMethod | How score was entered | `MANUAL`, `TARGET_FACE`, `QUICK_ENTRY` |

**InputMethod Impact:**
- `TARGET_FACE` - Coordinates captured
- `MANUAL` - Coordinates null
- `QUICK_ENTRY` - Coordinates null, minimal validation

### Complete ArrowScore Example

```kotlin
// Target Face scoring - full coordinates
val arrowWithCoords = ArrowScoreEntity(
    id = 1L,
    endScoreId = 1L,
    roundId = 1L,
    arrowNumber = 1,
    scoreValue = 10,
    isXRing = true,
    targetX = 2.5,
    targetY = -1.2,
    centerX = 0.0,
    centerY = 0.0,
    ringNumber = 10,
    clockPosition = 2,  // 2 o'clock position
    bowSetupId = 5L,
    bowSetupVersion = 3,
    participantId = "user123",
    inputMethod = InputMethod.TARGET_FACE
)

// Manual entry - no coordinates
val manualArrow = ArrowScoreEntity(
    id = 2L,
    endScoreId = 1L,
    roundId = 1L,
    arrowNumber = 2,
    scoreValue = 9,
    isXRing = false,
    targetX = null,
    targetY = null,
    centerX = null,
    centerY = null,
    ringNumber = null,
    clockPosition = null,
    bowSetupId = 5L,
    bowSetupVersion = 3,
    participantId = "user123",
    inputMethod = InputMethod.MANUAL
)
```

### Indexes

```sql
CREATE INDEX idx_arrow_score_round_id ON ArrowScore(roundId);
CREATE INDEX idx_arrow_score_end_score_id ON ArrowScore(endScoreId);
CREATE INDEX idx_arrow_score_participant_id ON ArrowScore(participantId);
```

---

## Relationships & Cascades

### Round → EndScore → ArrowScore

**Cascade Behavior:**

```sql
-- Foreign Keys
EndScore.roundId → Round.id (ON DELETE CASCADE)
ArrowScore.endScoreId → EndScore.id (ON DELETE CASCADE)
ArrowScore.roundId → Round.id (ON DELETE CASCADE)

-- Effect
DELETE FROM Round WHERE id = 1;
-- Also deletes:
-- - All EndScore rows where roundId = 1
-- - All ArrowScore rows where roundId = 1 OR endScoreId IN (endScores from round 1)
```

**Data Integrity:**
- Deleting a Round removes all associated data
- No orphaned EndScores or ArrowScores
- Historical equipment snapshots preserved separately (ArrowEquipmentSnapshot table)

### Equipment References

**Round.bowSetupId → BowSetup.id:**
- Foreign key with `ON DELETE SET NULL`
- If BowSetup deleted, Round.bowSetupId becomes null
- Round still valid, just unlinked from equipment
- Equipment snapshots still preserved

**ArrowScore.bowSetupId → BowSetup.id:**
- Same behavior as Round
- Allows per-arrow equipment tracking (future feature)

---

## Status Workflow

### Round Status Transitions

```
┌─────────┐
│ PLANNED │  (Round created, no scores yet)
└────┬────┘
     │ startRound()
     ↓
┌──────────────┐
│ IN_PROGRESS  │  (Active scoring)
└──┬───────┬───┘
   │       │
   │       ├─ pauseRound() → ┌────────┐
   │       │                  │ PAUSED │
   │       │                  └───┬────┘
   │       │                      │ resumeRound()
   │       │                      ↓
   │       │                  (back to IN_PROGRESS)
   │       │
   │       └─ completeRound() → ┌───────────┐
   │                             │ COMPLETED │
   │                             └───────────┘
   │
   └─ cancelRound() → ┌───────────┐
                       │ CANCELLED │
                       └───────────┘
```

**Status Rules:**
1. **PLANNED → IN_PROGRESS:** First arrow entered or explicit start
2. **IN_PROGRESS → PAUSED:** User pauses mid-round
3. **PAUSED → IN_PROGRESS:** User resumes
4. **IN_PROGRESS → COMPLETED:** All ends scored
5. **Any → CANCELLED:** User abandons round

**Statistics Inclusion:**
- `COMPLETED` rounds: Included in all statistics
- `CANCELLED` rounds: Excluded from statistics
- `PLANNED`, `IN_PROGRESS`, `PAUSED`: Not yet finalized

---

## Multi-Participant Scoring

### Data Model

**Round Level:**
```kotlin
val multiRound = RoundEntity(
    participants = listOf(
        SessionParticipant("user123", "Chris", isGuest = false, bowSetupId = 5L),
        SessionParticipant("guest1", "Sarah", isGuest = true, bowSetupId = 100L),
        SessionParticipant("guest2", "Mike", isGuest = true, bowSetupId = 101L)
    ),
    participantTheme = ParticipantTheme.MULTI_PARTICIPANT
)
```

**EndScore Level:**
```kotlin
// End 1 has 3 EndScore entries (one per participant)
val chrisEnd1 = EndScoreEntity(roundId = 1L, endNumber = 1, participantId = "user123", totalScore = 56)
val sarahEnd1 = EndScoreEntity(roundId = 1L, endNumber = 1, participantId = "guest1", totalScore = 54)
val mikeEnd1 = EndScoreEntity(roundId = 1L, endNumber = 1, participantId = "guest2", totalScore = 52)
```

**ArrowScore Level:**
```kotlin
// Each participant's end has 6 arrows
val chrisArrow1 = ArrowScoreEntity(endScoreId = 1L, arrowNumber = 1, participantId = "user123", scoreValue = 10)
val sarahArrow1 = ArrowScoreEntity(endScoreId = 2L, arrowNumber = 1, participantId = "guest1", scoreValue = 9)
val mikeArrow1 = ArrowScoreEntity(endScoreId = 3L, arrowNumber = 1, participantId = "guest2", scoreValue = 9)
```

### Queries for Multi-Participant

**Get all scores for one participant:**
```kotlin
@Query("""
    SELECT * FROM ArrowScore
    WHERE roundId = :roundId AND participantId = :participantId
    ORDER BY endScoreId, arrowNumber
""")
suspend fun getArrowScoresForParticipant(roundId: Long, participantId: String): List<ArrowScoreEntity>
```

**Get leaderboard:**
```kotlin
@Query("""
    SELECT participantId, SUM(scoreValue) as totalScore
    FROM ArrowScore
    WHERE roundId = :roundId
    GROUP BY participantId
    ORDER BY totalScore DESC
""")
suspend fun getLeaderboard(roundId: Long): List<ParticipantScore>
```

---

## Equipment Versioning

### Why Version Tracking?

Rounds reference exact equipment configuration at time of scoring:
- BowSetup changes create new versions
- Rounds store `bowSetupVersion` to track exact config
- Enables accurate historical comparisons

### Example Scenario

```kotlin
// Week 1: Create bow setup (version 1)
val mySetup = BowSetup(id = 5L, version = 1, riserId = 1L, limbsId = 2L)

// Shoot round 1
val round1 = Round(bowSetupId = 5L, bowSetupVersion = 1)

// Week 2: Change limbs (version 2)
mySetup.copy(version = 2, limbsId = 3L)  // New limbs

// Shoot round 2
val round2 = Round(bowSetupId = 5L, bowSetupVersion = 2)

// Analysis: Compare performance
// Round 1: Setup v1 (old limbs) - Average 8.5
// Round 2: Setup v2 (new limbs) - Average 9.1
// Conclusion: New limbs improved performance!
```

---

## Type Converters

Scoring entities use type converters for complex types:

```kotlin
// Distance
@TypeConverter
fun fromDistance(distance: Distance): String = distance.toString()

@TypeConverter
fun toDistance(value: String): Distance = Distance.fromString(value)

// ScoringSystem
@TypeConverter
fun fromScoringSystem(system: ScoringSystem): String = system.name

@TypeConverter
fun toScoringSystem(value: String): ScoringSystem = ScoringSystem.valueOf(value)

// SessionParticipant List
@TypeConverter
fun fromParticipantList(participants: List<SessionParticipant>): String =
    Json.encodeToString(participants)

@TypeConverter
fun toParticipantList(value: String): List<SessionParticipant> =
    Json.decodeFromString(value)

// RoundStatus
@TypeConverter
fun fromRoundStatus(status: RoundStatus): String = status.name

@TypeConverter
fun toRoundStatus(value: String): RoundStatus = RoundStatus.valueOf(value)
```

---

## Related Entities

**Equipment:**
- [BowSetup](../Equipment/#bowsetup) - Equipment configuration referenced by rounds
- [ArrowEquipmentSnapshot](../Analytics/#arrowequipmentsnapshot) - Historical equipment snapshots

**Tournament:**
- [TournamentEntity](../Tournament/#tournamententity) - Tournament data referenced by tournamentId
- [TournamentScoreCache](../Tournament/#tournamentscoreCache) - Offline score caching

**Analytics:**
- [EquipmentStatsCache](../Analytics/#equipmentstatscache) - Cached performance metrics

---

## Developer Guidelines

### Creating a Round

```kotlin
// 1. Create Round entity
val round = RoundEntity(
    roundName = "Practice",
    numEnds = 6,
    numArrows = 6,
    distance = Distance.fromString("50 meters"),
    targetSize = TargetSize.fromString("122cm"),
    scoringSystem = ScoringSystem.TEN_RING,
    bowSetupId = userBowSetupId,
    bowSetupVersion = currentSetupVersion,
    status = RoundStatus.PLANNED,
    participants = listOf(currentUser),
    participantTheme = ParticipantTheme.SINGLE_USER,
    createdAt = Clock.System.now(),
    lastModifiedAt = Clock.System.now()
)

// 2. Insert into database
val roundId = roundDao.insert(round)

// 3. Start scoring (status → IN_PROGRESS)
roundDao.updateStatus(roundId, RoundStatus.IN_PROGRESS)
```

### Scoring an End

```kotlin
database.withTransaction {
    // 1. Create EndScore
    val endScore = EndScoreEntity(
        roundId = roundId,
        endNumber = currentEndNumber,
        totalScore = 0,  // Will update after arrows
        isComplete = false,
        participantId = currentParticipantId
    )
    val endScoreId = endScoreDao.insert(endScore)

    // 2. Insert arrow scores
    val arrows = listOf(10, 9, 9, 8, 7, 6).mapIndexed { index, score ->
        ArrowScoreEntity(
            endScoreId = endScoreId,
            roundId = roundId,
            arrowNumber = index + 1,
            scoreValue = score,
            isXRing = (score == 10 && index == 0),  // First arrow is X
            participantId = currentParticipantId,
            inputMethod = InputMethod.MANUAL
        )
    }
    arrowScoreDao.insertAll(arrows)

    // 3. Update EndScore total
    val endTotal = arrows.sumOf { it.scoreValue }
    endScoreDao.updateTotal(endScoreId, endTotal, isComplete = true)

    // 4. Update Round running total
    val newRoundTotal = roundDao.getRoundTotal(roundId) + endTotal
    roundDao.updateTotal(roundId, newRoundTotal)
}
```

### Completing a Round

```kotlin
// 1. Verify all ends scored
val expectedEnds = round.numEnds
val scoredEnds = endScoreDao.getCompletedEndCount(roundId)
require(scoredEnds == expectedEnds) { "Not all ends scored" }

// 2. Calculate final statistics
val totalScore = arrowScoreDao.getTotalScore(roundId)
val maxPossible = round.numEnds * round.numArrows * 10  // Assuming 10-ring
val accuracy = (totalScore.toDouble() / maxPossible) * 100

// 3. Update round
roundDao.updateCompletion(
    roundId = roundId,
    status = RoundStatus.COMPLETED,
    totalScore = totalScore,
    accuracy = accuracy,
    completedAt = Clock.System.now()
)
```

---

## Query Examples

### Get Round with All Data

```kotlin
@Query("""
    SELECT * FROM Round
    WHERE id = :roundId
""")
suspend fun getRound(roundId: Long): RoundEntity

@Query("""
    SELECT * FROM EndScore
    WHERE roundId = :roundId
    ORDER BY endNumber ASC
""")
suspend fun getEndScores(roundId: Long): List<EndScoreEntity>

@Query("""
    SELECT * FROM ArrowScore
    WHERE roundId = :roundId
    ORDER BY endScoreId, arrowNumber ASC
""")
suspend fun getArrowScores(roundId: Long): List<ArrowScoreEntity>
```

### Get Active Rounds

```kotlin
@Query("""
    SELECT * FROM Round
    WHERE status IN ('IN_PROGRESS', 'PAUSED')
    ORDER BY lastModifiedAt DESC
""")
suspend fun getActiveRounds(): List<RoundEntity>
```

### Get Completed Rounds for Equipment

```kotlin
@Query("""
    SELECT * FROM Round
    WHERE bowSetupId = :setupId
    AND status = 'COMPLETED'
    ORDER BY completedAt DESC
""")
suspend fun getCompletedRoundsForSetup(setupId: Long): List<RoundEntity>
```

### Calculate Statistics

```kotlin
@Query("""
    SELECT AVG(scoreValue) as avgScore,
           SUM(CASE WHEN isXRing = 1 THEN 1 ELSE 0 END) as xCount
    FROM ArrowScore
    WHERE roundId = :roundId
""")
suspend fun getRoundStats(roundId: Long): RoundStats
```

---

## Related Documentation

**Database:**
- [Database Overview](../../Database/) - Full database architecture
- [Database Tables](../../Database/Tables/) - Table schemas
- [Migrations](../../Database/Migrations/) - Migration history

**Other Data Models:**
- [Equipment Models](../Equipment/) - BowSetup and equipment entities
- [Tournament Models](../Tournament/) - Tournament integration
- [Analytics Models](../Analytics/) - Statistics and caching

**Developer Guides:**
- [Scoring Best Practices](../../../developer-guide/guides/best-practices/) - Query optimization
- [Testing Scoring](../../../developer-guide/testing/) - Unit and integration tests

---

## Quick Reference

| Entity | Fields | Purpose | Cascade |
|--------|--------|---------|---------|
| **Round** | 25 | Complete scoring session | Parent → deletes EndScores and ArrowScores |
| **EndScore** | 6 | Group of arrows (one end) | Child of Round, parent of ArrowScores |
| **ArrowScore** | 16 | Individual arrow shot | Child of EndScore and Round |

**Key Relationships:**
- Round 1 → Many EndScore
- EndScore 1 → Many ArrowScore
- Round → Equipment (BowSetup) via bowSetupId

**Status Flow:**
`PLANNED → IN_PROGRESS → PAUSED → IN_PROGRESS → COMPLETED`
(or CANCELLED at any point)

**Multi-Participant:**
- Max 4 participants per round
- Separate EndScore and ArrowScore rows per participant
- Leaderboard via GROUP BY participantId

---

**Next:** [Equipment Data Models](../Equipment/) - BowSetup and equipment entities
