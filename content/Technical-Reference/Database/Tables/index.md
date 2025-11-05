---
title: "Database Tables"
description: "Complete table schemas and relationships"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - database
  - tables
  - schema
  - sql
---

[Home](/) > [Technical Reference](../../) > [Database](../) > Tables

---

# Database Tables

Complete SQL schema reference for all 26 tables in Archery Apprentice database. This document provides CREATE TABLE statements, column definitions, indexes, and foreign key constraints.

## Overview

**Database Name:** `ArcheryKmpDatabase`
**Version:** 35
**ORM:** RoomKMP
**Total Tables:** 26

### Table Categories

| Category | Tables | Purpose |
|----------|--------|---------|
| **Equipment** | 13 | Bow components and configurations |
| **Scoring** | 3 | Rounds, ends, and arrow scores |
| **Tournament** | 3 | Tournament management |
| **Analytics** | 2 | Performance caching |
| **Settings** | 1 | User preferences |
| **Junction** | 4 | Many-to-many relationships |

---

## Equipment Tables (13)

### Riser Table

Central bow body component.

```sql
CREATE TABLE Riser (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    length TEXT,
    material TEXT
);

CREATE INDEX idx_riser_brand ON Riser(brand);
CREATE INDEX idx_riser_model ON Riser(model);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Model identifier (required)
- `length` - Riser length (e.g., "25 inches")
- `material` - Construction material (e.g., "Carbon", "Aluminum")

**Relationships:**
- Referenced by: `BowSetup.riserId`

---

### Limbs Table

Bow limbs that store and release energy.

```sql
CREATE TABLE Limbs (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    poundage TEXT,
    limbLength TEXT
);

CREATE INDEX idx_limbs_brand ON Limbs(brand);
CREATE INDEX idx_limbs_poundage ON Limbs(poundage);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Model identifier (required)
- `poundage` - Draw weight (e.g., "38 lbs", "42#")
- `limbLength` - Limb size (e.g., "Long", "Medium", "Short")

**Relationships:**
- Referenced by: `BowSetup.limbsId`

---

### BowString Table

Bowstring connecting the limbs.

```sql
CREATE TABLE BowString (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    strandCount INTEGER,
    servingMaterial TEXT
);

CREATE INDEX idx_bowstring_brand ON BowString(brand);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - String type (required)
- `strandCount` - Number of strands (e.g., 16, 18, 20)
- `servingMaterial` - Center serving material

**Relationships:**
- Referenced by: `BowSetup.bowStringId`

---

### Sight Table

Aiming device.

```sql
CREATE TABLE Sight (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    material TEXT
);

CREATE INDEX idx_sight_brand ON Sight(brand);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Model identifier (required)
- `material` - Construction material

**Relationships:**
- Referenced by: `BowSetup.sightId`, `SightMark.sightId`

---

### SightMark Table

Distance-specific sight settings.

```sql
CREATE TABLE SightMark (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    sightId INTEGER NOT NULL,
    distance TEXT NOT NULL,
    markValue TEXT NOT NULL,
    notes TEXT,
    FOREIGN KEY (sightId) REFERENCES Sight(id) ON DELETE CASCADE
);

CREATE INDEX idx_sight_mark_sight_id ON SightMark(sightId);
CREATE INDEX idx_sight_mark_distance ON SightMark(distance);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `sightId` - Foreign key to Sight (required, cascade delete)
- `distance` - Shooting distance (required, e.g., "50 meters")
- `markValue` - Sight setting (required, e.g., "5.2")
- `notes` - Additional notes (optional)

**Relationships:**
- Parent: `Sight` (CASCADE DELETE)

---

### Stabilizer Table

Vibration reduction and balance component.

```sql
CREATE TABLE Stabilizer (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    length TEXT,
    weight TEXT,
    straightnessRating TEXT
);

CREATE INDEX idx_stabilizer_brand ON Stabilizer(brand);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Model identifier (required)
- `length` - Stabilizer length (e.g., "30 inches")
- `weight` - Total weight (e.g., "8 oz")
- `straightnessRating` - Tolerance (e.g., "+/- 0.001")

**Relationships:**
- Referenced by: `BowSetup.stabilizerId`

---

### Weight Table

Additional balance weights.

```sql
CREATE TABLE Weight (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    ounces REAL
);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Weight description (required)
- `ounces` - Weight in ounces

**Relationships:**
- Referenced by: `BowSetup.weightId`

---

### Plunger Table

Pressure button for arrow tuning.

```sql
CREATE TABLE Plunger (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    adjustment TEXT
);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Model identifier (required)
- `adjustment` - Adjustment type (e.g., "Micro-adjust")

**Relationships:**
- Referenced by: `BowSetup.plungerId`

---

### Rest Table

Arrow support component.

```sql
CREATE TABLE Rest (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    type TEXT
);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Model identifier (required)
- `type` - Rest type (e.g., "Magnetic", "Flipper", "Blade")

**Relationships:**
- Referenced by: `BowSetup.restId`

---

### Arrow Table

Complete arrow specifications.

```sql
CREATE TABLE Arrow (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    spine TEXT,
    length TEXT,
    weight TEXT,
    diameter TEXT,
    arrowPoint TEXT,  -- JSON: {"brand", "model", "weight"}
    arrowNock TEXT    -- JSON: {"brand", "model", "size"}
);

CREATE INDEX idx_arrow_brand ON Arrow(brand);
CREATE INDEX idx_arrow_spine ON Arrow(spine);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Arrow manufacturer (required)
- `model` - Arrow model (required)
- `spine` - Stiffness rating (e.g., "500", "600")
- `length` - Shaft length
- `weight` - Total arrow weight
- `diameter` - Shaft diameter
- `arrowPoint` - JSON object with point details
- `arrowNock` - JSON object with nock details

**Relationships:**
- Referenced by: `BowSetup.arrowId`

---

### Accessory Table

Generic equipment items.

```sql
CREATE TABLE Accessory (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    type TEXT
);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `brand` - Manufacturer name (required)
- `model` - Model/type (required)
- `type` - Category (e.g., "Tab", "Chest Guard", "Quiver")

**Relationships:**
- Referenced by: `BowSetup.accessoryId`

---

### BowSetup Table

Complete equipment configuration.

```sql
CREATE TABLE BowSetup (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    isActive INTEGER NOT NULL DEFAULT 1,
    riserId INTEGER,
    limbsId INTEGER,
    sightId INTEGER,
    stabilizerId INTEGER,
    plungerId INTEGER,
    restId INTEGER,
    bowStringId INTEGER,
    arrowId INTEGER,
    weightId INTEGER,
    accessoryId INTEGER,
    FOREIGN KEY (riserId) REFERENCES Riser(id) ON DELETE SET NULL,
    FOREIGN KEY (limbsId) REFERENCES Limbs(id) ON DELETE SET NULL,
    FOREIGN KEY (sightId) REFERENCES Sight(id) ON DELETE SET NULL,
    FOREIGN KEY (stabilizerId) REFERENCES Stabilizer(id) ON DELETE SET NULL,
    FOREIGN KEY (plungerId) REFERENCES Plunger(id) ON DELETE SET NULL,
    FOREIGN KEY (restId) REFERENCES Rest(id) ON DELETE SET NULL,
    FOREIGN KEY (bowStringId) REFERENCES BowString(id) ON DELETE SET NULL,
    FOREIGN KEY (arrowId) REFERENCES Arrow(id) ON DELETE SET NULL,
    FOREIGN KEY (weightId) REFERENCES Weight(id) ON DELETE SET NULL,
    FOREIGN KEY (accessoryId) REFERENCES Accessory(id) ON DELETE SET NULL
);

CREATE INDEX idx_bowsetup_active ON BowSetup(isActive);
CREATE INDEX idx_bowsetup_version ON BowSetup(version);
CREATE INDEX idx_bowsetup_riser_id ON BowSetup(riserId);
CREATE INDEX idx_bowsetup_limbs_id ON BowSetup(limbsId);
CREATE INDEX idx_bowsetup_sight_id ON BowSetup(sightId);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `name` - Setup name (required)
- `description` - Setup notes
- `version` - Version number (auto-increments on change)
- `isActive` - Soft delete flag (1 = active, 0 = deleted)
- `riserId` - Foreign key to Riser (nullable)
- `limbsId` - Foreign key to Limbs (nullable)
- `sightId` - Foreign key to Sight (nullable)
- `stabilizerId` - Foreign key to Stabilizer (nullable)
- `plungerId` - Foreign key to Plunger (nullable)
- `restId` - Foreign key to Rest (nullable)
- `bowStringId` - Foreign key to BowString (nullable)
- `arrowId` - Foreign key to Arrow (nullable)
- `weightId` - Foreign key to Weight (nullable)
- `accessoryId` - Foreign key to Accessory (nullable)

**Relationships:**
- Parents: All equipment tables (SET NULL on delete)
- Referenced by: `Round.bowSetupId`

---

### BowSetupEquipment Table

Junction table for flexible equipment relationships (future use).

```sql
CREATE TABLE BowSetupEquipment (
    setupId INTEGER NOT NULL,
    equipmentId INTEGER NOT NULL,
    equipmentType TEXT NOT NULL,
    PRIMARY KEY (setupId, equipmentId, equipmentType)
);
```

**Columns:**
- `setupId` - BowSetup ID
- `equipmentId` - Generic equipment ID
- `equipmentType` - Type identifier (e.g., "RISER", "LIMBS")

**Note:** Currently not actively used. Preserved for potential future features.

---

## Scoring Tables (3)

### Round Table

Complete scoring session.

```sql
CREATE TABLE Round (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    roundName TEXT NOT NULL,
    numEnds INTEGER NOT NULL,
    numArrows INTEGER NOT NULL,
    distance TEXT NOT NULL,
    targetSize TEXT NOT NULL,
    scoringSystem TEXT NOT NULL,
    targetRings TEXT,  -- JSON array (legacy)
    ringValues TEXT,   -- JSON map (legacy)
    bowSetupId INTEGER,
    bowSetupVersion INTEGER,
    status TEXT NOT NULL DEFAULT 'PLANNED',
    participants TEXT,  -- JSON array
    participantTheme TEXT NOT NULL DEFAULT 'SINGLE_USER',
    tournamentId TEXT,
    tournamentRoundNumber INTEGER,
    isLocal INTEGER NOT NULL DEFAULT 1,
    syncStatus TEXT,
    createdAt INTEGER NOT NULL,
    startedAt INTEGER,
    completedAt INTEGER,
    lastModifiedAt INTEGER NOT NULL,
    totalScore INTEGER NOT NULL DEFAULT 0,
    maxPossibleScore INTEGER NOT NULL DEFAULT 0,
    accuracy REAL NOT NULL DEFAULT 0.0,
    FOREIGN KEY (bowSetupId) REFERENCES BowSetup(id) ON DELETE SET NULL
);

CREATE INDEX idx_round_bowsetup_id ON Round(bowSetupId);
CREATE INDEX idx_round_tournament_id ON Round(tournamentId);
CREATE INDEX idx_round_status ON Round(status);
CREATE INDEX idx_round_status_created ON Round(status, createdAt);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `roundName` - User-defined name (required)
- `numEnds` - Total ends in round (required)
- `numArrows` - Arrows per end (required)
- `distance` - Shooting distance (required)
- `targetSize` - Target face size (required)
- `scoringSystem` - Scoring method (required)
- `targetRings` - Legacy ring definition (JSON)
- `ringValues` - Legacy ring values (JSON)
- `bowSetupId` - Foreign key to BowSetup
- `bowSetupVersion` - Equipment version snapshot
- `status` - Round state (PLANNED, IN_PROGRESS, PAUSED, COMPLETED, CANCELLED)
- `participants` - JSON array of SessionParticipant
- `participantTheme` - SINGLE_USER or MULTI_PARTICIPANT
- `tournamentId` - Tournament identifier
- `tournamentRoundNumber` - Round number in tournament
- `isLocal` - Local (1) vs remote (0) tournament
- `syncStatus` - Sync state for remote tournaments
- `createdAt` - Creation timestamp (epoch milliseconds, required)
- `startedAt` - Start timestamp (epoch milliseconds)
- `completedAt` - Completion timestamp (epoch milliseconds)
- `lastModifiedAt` - Last update timestamp (epoch milliseconds, required)
- `totalScore` - Sum of all arrow scores (cached)
- `maxPossibleScore` - Theoretical maximum (cached)
- `accuracy` - Score as percentage (cached)

**Relationships:**
- Parent: `BowSetup` (SET NULL on delete)
- Referenced by: `EndScore.roundId`, `ArrowScore.roundId`

---

### EndScore Table

Group of arrows shot before retrieving.

```sql
CREATE TABLE EndScore (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    roundId INTEGER NOT NULL,
    endNumber INTEGER NOT NULL,
    totalScore INTEGER NOT NULL DEFAULT 0,
    isComplete INTEGER NOT NULL DEFAULT 0,
    participantId TEXT,
    FOREIGN KEY (roundId) REFERENCES Round(id) ON DELETE CASCADE
);

CREATE INDEX idx_end_score_round_id ON EndScore(roundId);
CREATE INDEX idx_end_score_participant_id ON EndScore(participantId);
CREATE UNIQUE INDEX idx_end_score_unique ON EndScore(roundId, endNumber, participantId);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `roundId` - Foreign key to Round (required, cascade delete)
- `endNumber` - 1-based end sequence (required)
- `totalScore` - Sum of arrow scores (cached)
- `isComplete` - All arrows entered (1 = yes, 0 = no)
- `participantId` - Session participant ID (for multi-participant)

**Relationships:**
- Parent: `Round` (CASCADE DELETE)
- Referenced by: `ArrowScore.endScoreId`

---

### ArrowScore Table

Individual arrow shot with optional coordinate tracking.

```sql
CREATE TABLE ArrowScore (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    endScoreId INTEGER NOT NULL,
    roundId INTEGER NOT NULL,
    arrowNumber INTEGER NOT NULL,
    scoreValue INTEGER NOT NULL,
    isXRing INTEGER NOT NULL DEFAULT 0,
    targetX REAL,
    targetY REAL,
    centerX REAL,
    centerY REAL,
    ringNumber INTEGER,
    clockPosition INTEGER,
    bowSetupId INTEGER,
    bowSetupVersion INTEGER,
    participantId TEXT,
    inputMethod TEXT NOT NULL DEFAULT 'MANUAL',
    FOREIGN KEY (endScoreId) REFERENCES EndScore(id) ON DELETE CASCADE,
    FOREIGN KEY (roundId) REFERENCES Round(id) ON DELETE CASCADE,
    FOREIGN KEY (bowSetupId) REFERENCES BowSetup(id) ON DELETE SET NULL
);

CREATE INDEX idx_arrow_score_round_id ON ArrowScore(roundId);
CREATE INDEX idx_arrow_score_end_score_id ON ArrowScore(endScoreId);
CREATE INDEX idx_arrow_score_participant_id ON ArrowScore(participantId);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `endScoreId` - Foreign key to EndScore (required, cascade delete)
- `roundId` - Foreign key to Round (required, cascade delete, denormalized)
- `arrowNumber` - 1-based arrow sequence within end (required)
- `scoreValue` - Arrow score (required, 0-10 for 10-ring)
- `isXRing` - Inner 10 hit (1 = yes, 0 = no)
- `targetX` - Horizontal coordinate (for grouping analysis)
- `targetY` - Vertical coordinate (for grouping analysis)
- `centerX` - Target center X (normalization)
- `centerY` - Target center Y (normalization)
- `ringNumber` - Scored ring (alternative to scoreValue)
- `clockPosition` - Arrow position (1-12, like clock face)
- `bowSetupId` - Foreign key to BowSetup
- `bowSetupVersion` - Equipment version snapshot
- `participantId` - Session participant ID
- `inputMethod` - Entry method (MANUAL, TARGET_FACE, QUICK_ENTRY)

**Relationships:**
- Parents: `EndScore` (CASCADE DELETE), `Round` (CASCADE DELETE), `BowSetup` (SET NULL)
- Referenced by: `ArrowEquipmentSnapshot.arrowScoreId`

---

## Tournament Tables (3)

### TournamentEntity Table

Tournament metadata and configuration.

```sql
CREATE TABLE TournamentEntity (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    location TEXT,
    organizerId TEXT,
    createdBy TEXT,
    creatorEmail TEXT,
    status TEXT NOT NULL DEFAULT 'OPEN',
    numEnds INTEGER NOT NULL,
    numArrows INTEGER NOT NULL,
    distance TEXT NOT NULL,
    targetSize TEXT NOT NULL,
    scoringSystem TEXT NOT NULL,
    totalRounds INTEGER,
    startTime INTEGER,
    endTime INTEGER,
    createdAt INTEGER NOT NULL,
    isPublic INTEGER NOT NULL DEFAULT 1,
    joinCode TEXT,
    maxParticipants INTEGER,
    requireApproval INTEGER NOT NULL DEFAULT 0,
    allowSpectators INTEGER NOT NULL DEFAULT 1,
    useSettingsDisplayNames INTEGER NOT NULL DEFAULT 1,
    currentRound INTEGER NOT NULL DEFAULT 1,
    topScore INTEGER,
    averageScore REAL,
    totalParticipants INTEGER NOT NULL DEFAULT 0,
    isLocal INTEGER NOT NULL DEFAULT 1,
    needsSync INTEGER NOT NULL DEFAULT 0,
    lastSyncedAt INTEGER,
    eliminationRounds INTEGER,
    advancementCriteria TEXT,
    tiebreakingRules TEXT,
    customRules TEXT,
    registrationDeadline INTEGER,
    roundDeadlines TEXT  -- JSON map
);

CREATE INDEX idx_tournament_status ON TournamentEntity(status);
CREATE INDEX idx_tournament_organizer ON TournamentEntity(organizerId);
CREATE INDEX idx_tournament_created ON TournamentEntity(createdAt);
```

**Columns:** (36 fields)
- `id` - String primary key (UUID or custom)
- `name` - Tournament name (required)
- `description` - Details
- `location` - Venue
- `organizerId` - Creator user ID
- `createdBy` - Creator username
- `creatorEmail` - Contact email
- `status` - Tournament state (OPEN, IN_PROGRESS, COMPLETED, CANCELLED)
- `numEnds`, `numArrows`, `distance`, `targetSize`, `scoringSystem` - Round format (required)
- `totalRounds` - Number of rounds
- `startTime`, `endTime` - Tournament schedule (epoch milliseconds)
- `createdAt` - Creation timestamp (required)
- `isPublic` - Public (1) vs private (0)
- `joinCode` - Access code
- `maxParticipants` - Participant limit
- `requireApproval` - Require approval to join (1 = yes, 0 = no)
- `allowSpectators` - Allow spectators (1 = yes, 0 = no)
- `useSettingsDisplayNames` - Use Settings usernames (1 = yes, 0 = no)
- `currentRound` - Active round number
- `topScore`, `averageScore`, `totalParticipants` - Leaderboard cache
- `isLocal` - Local (1) vs remote (0)
- `needsSync` - Has unsynced changes (1 = yes, 0 = no)
- `lastSyncedAt` - Last sync timestamp
- `eliminationRounds`, `advancementCriteria`, `tiebreakingRules`, `customRules` - Tournament rules
- `registrationDeadline` - Registration cutoff
- `roundDeadlines` - Per-round deadlines (JSON)

**Relationships:**
- Referenced by: `TournamentParticipant.tournamentId`

---

### TournamentParticipant Table

Participant progress and ranking.

```sql
CREATE TABLE TournamentParticipant (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    tournamentId TEXT NOT NULL,
    userId TEXT NOT NULL,
    displayName TEXT NOT NULL,
    currentRound INTEGER NOT NULL DEFAULT 0,
    totalScore INTEGER NOT NULL DEFAULT 0,
    ranking INTEGER,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    registeredAt INTEGER NOT NULL,
    lastRoundSubmitted INTEGER,
    FOREIGN KEY (tournamentId) REFERENCES TournamentEntity(id) ON DELETE CASCADE
);

CREATE INDEX idx_tournament_participant_tournament_id ON TournamentParticipant(tournamentId);
CREATE INDEX idx_tournament_participant_user_id ON TournamentParticipant(userId);
CREATE INDEX idx_tournament_participant_ranking ON TournamentParticipant(ranking);
CREATE UNIQUE INDEX idx_tournament_participant_unique ON TournamentParticipant(tournamentId, userId);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `tournamentId` - Foreign key to TournamentEntity (required, cascade delete)
- `userId` - Participant user ID (required)
- `displayName` - Display name (required)
- `currentRound` - Latest round completed
- `totalScore` - Aggregate score
- `ranking` - Leaderboard position
- `status` - Participation status (ACTIVE, WITHDRAWN, DISQUALIFIED, COMPLETED)
- `registeredAt` - Registration timestamp (required)
- `lastRoundSubmitted` - Last activity timestamp

**Relationships:**
- Parent: `TournamentEntity` (CASCADE DELETE)

---

### TournamentScoreCache Table

Offline score caching for sync.

```sql
CREATE TABLE TournamentScoreCache (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    tournamentId TEXT NOT NULL,
    participantId TEXT NOT NULL,
    roundNumber INTEGER NOT NULL,
    scores TEXT NOT NULL,  -- JSON array of integers
    lastUpdated INTEGER NOT NULL,
    syncStatus TEXT NOT NULL DEFAULT 'PENDING'
);

CREATE INDEX idx_tournament_score_cache_tournament_id ON TournamentScoreCache(tournamentId);
CREATE INDEX idx_tournament_score_cache_sync_status ON TournamentScoreCache(syncStatus);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `tournamentId` - Tournament reference (required)
- `participantId` - Participant user ID (required)
- `roundNumber` - Round number (required)
- `scores` - JSON array of arrow scores (required)
- `lastUpdated` - Last modification timestamp (required)
- `syncStatus` - Sync state (PENDING, SYNCED, FAILED)

**Relationships:**
- No formal foreign keys (standalone caching)

---

## Analytics Tables (2)

### EquipmentStatsCache Table

Pre-calculated performance metrics.

```sql
CREATE TABLE EquipmentStatsCache (
    setupId INTEGER NOT NULL,
    distance TEXT NOT NULL,
    totalRounds INTEGER NOT NULL DEFAULT 0,
    averageScore REAL NOT NULL DEFAULT 0.0,
    accuracy REAL NOT NULL DEFAULT 0.0,
    ringDistribution TEXT,  -- JSON map: {10: count, 9: count, ...}
    lastUpdated INTEGER NOT NULL,
    PRIMARY KEY (setupId, distance)
);

CREATE INDEX idx_stats_cache_setup_id ON EquipmentStatsCache(setupId);
CREATE INDEX idx_stats_cache_distance ON EquipmentStatsCache(distance);
```

**Columns:**
- `setupId` - BowSetup ID (composite primary key)
- `distance` - Shooting distance (composite primary key)
- `totalRounds` - Number of completed rounds
- `averageScore` - Mean score across rounds
- `accuracy` - Average accuracy percentage
- `ringDistribution` - JSON map of arrows per ring
- `lastUpdated` - Cache timestamp (required)

**Relationships:**
- Logical parent: `BowSetup` (no formal FK to preserve cache if setup deleted)

---

### ArrowEquipmentSnapshot Table

Historical equipment configurations.

```sql
CREATE TABLE ArrowEquipmentSnapshot (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    arrowScoreId INTEGER NOT NULL,
    bowSetupSnapshot TEXT NOT NULL,  -- Complete BowSetup JSON
    FOREIGN KEY (arrowScoreId) REFERENCES ArrowScore(id) ON DELETE CASCADE
);

CREATE INDEX idx_snapshot_arrow_id ON ArrowEquipmentSnapshot(arrowScoreId);
CREATE UNIQUE INDEX idx_snapshot_unique ON ArrowEquipmentSnapshot(arrowScoreId);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `arrowScoreId` - Foreign key to ArrowScore (required, cascade delete)
- `bowSetupSnapshot` - Complete equipment configuration as JSON (required)

**Relationships:**
- Parent: `ArrowScore` (CASCADE DELETE, one-to-one)

---

## Settings Table (1)

### Settings Table

User preferences and app configuration.

```sql
CREATE TABLE Settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    userName TEXT,
    preferredDistance TEXT,
    preferredTargetSize TEXT,
    theme TEXT,
    measurementSystem TEXT
);
```

**Columns:**
- `id` - Auto-incrementing primary key
- `userName` - User display name
- `preferredDistance` - Default distance for new rounds
- `preferredTargetSize` - Default target size
- `theme` - UI theme preference
- `measurementSystem` - Metric vs Imperial

**Note:** Typically single row database (id = 1).

---

## Foreign Key Summary

### CASCADE DELETE

When parent deleted, children automatically deleted:

```
TournamentEntity → TournamentParticipant
Sight → SightMark
Round → EndScore → ArrowScore
ArrowScore → ArrowEquipmentSnapshot
```

### SET NULL

When parent deleted, child foreign key set to NULL:

```
BowSetup ← Round (Round.bowSetupId becomes NULL)
BowSetup ← ArrowScore (ArrowScore.bowSetupId becomes NULL)
All Equipment → BowSetup (BowSetup foreign keys become NULL)
```

---

## Index Strategy

### Performance Indexes

**Frequent JOINs:**
```sql
-- Equipment lookups
CREATE INDEX idx_bowsetup_riser_id ON BowSetup(riserId);
CREATE INDEX idx_bowsetup_limbs_id ON BowSetup(limbsId);

-- Scoring hierarchy
CREATE INDEX idx_end_score_round_id ON EndScore(roundId);
CREATE INDEX idx_arrow_score_round_id ON ArrowScore(roundId);
CREATE INDEX idx_arrow_score_end_score_id ON ArrowScore(endScoreId);
```

**Filtering & Sorting:**
```sql
-- Round queries
CREATE INDEX idx_round_status ON Round(status);
CREATE INDEX idx_round_status_created ON Round(status, createdAt);

-- BowSetup filtering
CREATE INDEX idx_bowsetup_active ON BowSetup(isActive);

-- Tournament queries
CREATE INDEX idx_tournament_status ON TournamentEntity(status);
CREATE INDEX idx_tournament_participant_ranking ON TournamentParticipant(ranking);
```

**Unique Constraints:**
```sql
-- Prevent duplicate entries
CREATE UNIQUE INDEX idx_end_score_unique ON EndScore(roundId, endNumber, participantId);
CREATE UNIQUE INDEX idx_tournament_participant_unique ON TournamentParticipant(tournamentId, userId);
CREATE UNIQUE INDEX idx_snapshot_unique ON ArrowEquipmentSnapshot(arrowScoreId);
```

---

## Data Types

### SQLite Type Mapping

| Column Type | SQLite Storage | Kotlin Type | Example |
|-------------|----------------|-------------|---------|
| INTEGER | INTEGER | Long, Int | `id`, `numEnds` |
| TEXT | TEXT | String | `name`, `brand` |
| REAL | REAL | Double | `accuracy`, `targetX` |
| BLOB | BLOB | ByteArray | (not used) |

### JSON Storage

Stored as TEXT, converted via type converters:

```sql
-- JSON arrays
participants TEXT  -- List<SessionParticipant>
scores TEXT        -- List<Int>
targetRings TEXT   -- List<Int>

-- JSON objects
ringValues TEXT         -- Map<Int, Int>
ringDistribution TEXT   -- Map<Int, Int>
roundDeadlines TEXT     -- Map<Int, Instant>
arrowPoint TEXT         -- ArrowPoint object
arrowNock TEXT          -- ArrowNock object
bowSetupSnapshot TEXT   -- Complete BowSetup object
```

### Timestamp Storage

Stored as INTEGER (epoch milliseconds):

```sql
createdAt INTEGER        -- kotlinx.datetime.Instant
startedAt INTEGER
completedAt INTEGER
lastModifiedAt INTEGER
registeredAt INTEGER
```

---

## Migration Considerations

### Schema Evolution

**Adding Columns:**
```sql
ALTER TABLE Round ADD COLUMN newField TEXT;
```

**Adding Indexes:**
```sql
CREATE INDEX idx_new_index ON Round(newField);
```

**Cannot Do (requires migration):**
- Rename columns
- Change column types
- Add NOT NULL without default
- Remove columns (create new table, copy data)

### Migration Best Practices

1. **Always increment database version**
2. **Test migrations with existing data**
3. **Provide default values for new columns**
4. **Preserve data with CREATE TABLE AS SELECT for complex changes**
5. **Update corresponding DAO queries**

---

## Related Documentation

**Database:**
- [Database Overview](../) - Architecture and design
- [Data Models](../../Data-Models/) - Entity documentation
- [Migrations](../Migrations/) - Migration history

**Development:**
- [Database Best Practices](../../../developer-guide/guides/best-practices/) - Query optimization
- [Testing Database](../../../developer-guide/testing/) - Testing strategies

---

## Quick Reference

### Table Count by Category

| Category | Count | Tables |
|----------|-------|--------|
| Equipment | 13 | Riser, Limbs, BowString, Sight, SightMark, Stabilizer, Weight, Plunger, Rest, Arrow, Accessory, BowSetup, BowSetupEquipment |
| Scoring | 3 | Round, EndScore, ArrowScore |
| Tournament | 3 | TournamentEntity, TournamentParticipant, TournamentScoreCache |
| Analytics | 2 | EquipmentStatsCache, ArrowEquipmentSnapshot |
| Settings | 1 | Settings |
| **Total** | **26** | |

### Foreign Key Cascade Summary

**CASCADE DELETE:** TournamentEntity → TournamentParticipant, Sight → SightMark, Round → EndScore → ArrowScore, ArrowScore → ArrowEquipmentSnapshot

**SET NULL:** BowSetup ← Round, Equipment → BowSetup

### Primary Index Patterns

- All tables have INTEGER PRIMARY KEY AUTOINCREMENT (except TournamentEntity uses TEXT, EquipmentStatsCache uses composite)
- Foreign keys indexed for JOIN performance
- Status fields indexed for filtering
- Composite indexes for common query patterns

---

**Database Version:** 35
**Last Schema Update:** Week 13-14 (KMP Migration)
**ORM:** RoomKMP 1.0.0
