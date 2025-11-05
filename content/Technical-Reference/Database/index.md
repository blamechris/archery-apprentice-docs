---
title: "Database Documentation"
description: "Complete database schemas, tables, and architecture"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - database
  - schema
  - architecture
  - room
---

[Home](/) > [Technical Reference](../) > Database

---

# Database Documentation

Archery Apprentice uses **RoomKMP** for cross-platform database management. This document covers the database architecture, schema design, and migration history.

## Overview

**Database:** `ArcheryKmpDatabase`
**Current Version:** 35
**ORM:** RoomKMP (Kotlin Multiplatform version of Room)
**Total Entities:** 26
**Migration History:** Versions 17→35 (18 migrations preserved)

### Database Location

- **Module:** `shared:database`
- **Package:** `com.archeryapprentice.database`
- **Main Class:** `ArcheryKmpDatabase.kt`
- **Platform:** Android (Room), iOS (SQLite wrapper), JVM (SQLite)

---

## Architecture

### Entity Categories

The database is organized into logical categories:

| Category | Entities | Purpose |
|----------|----------|---------|
| **Equipment** | 13 | Bow components, arrows, accessories |
| **Scoring** | 3 | Rounds, ends, arrow scores |
| **Tournament** | 3 | Tournament management, participants, caching |
| **Statistics** | 2 | Performance cache, equipment snapshots |
| **Settings** | 1 | User preferences |

### Design Principles

**1. Relational Integrity**
- Foreign key constraints enforce relationships
- Cascading deletes where appropriate
- Soft deletes for historical data (e.g., BowSetup uses `isActive`)

**2. Performance Optimization**
- Strategic indexes on frequently queried fields
- Composite indexes for complex queries
- Efficient JOIN operations through proper relationships

**3. Data Versioning**
- BowSetup tracks version changes
- Equipment snapshots preserve historical configurations
- Rounds reference exact equipment versions used

**4. KMP Compatibility**
- All entities work across Android, iOS, JVM
- Platform-specific implementations in `DatabaseBuilder`
- Type converters handle complex data types consistently

---

## Entity Schema

### Equipment Entities (13 Total)

Equipment entities represent physical archery gear:

#### Core Bow Components
1. **Riser** - Central bow body
   - Fields: id, brand, model, length, material
   - Used in: BowSetup

2. **Limbs** - Energy-storing bow arms
   - Fields: id, brand, model, poundage, limbLength
   - Used in: BowSetup

3. **BowString** - Connects limbs
   - Fields: id, brand, model, strandCount, servingMaterial
   - Used in: BowSetup

#### Sighting & Aiming
4. **Sight** - Aiming device
   - Fields: id, brand, model, material
   - Used in: BowSetup, SightMark

5. **SightMark** - Distance-specific sight settings
   - Fields: id, sightId, distance, markValue, notes
   - Foreign Key: sightId → Sight(id)

#### Stabilization
6. **Stabilizer** - Vibration reduction, balance
   - Fields: id, brand, model, length, weight, straightnessRating
   - Used in: BowSetup

7. **Weight** - Additional balance weights
   - Fields: id, brand, model, ounces
   - Used in: BowSetup

#### Arrow Rest System
8. **Plunger** - Fine-tune arrow flight
   - Fields: id, brand, model, adjustment
   - Used in: BowSetup

9. **Rest** - Arrow support
   - Fields: id, brand, model, type
   - Used in: BowSetup

#### Arrows
10. **Arrow** - Complete arrow set
    - Fields: id, brand, model, spine, length, weight, diameter, arrowPoint (embedded), arrowNock (embedded)
    - Embedded Objects: ArrowPoint, ArrowNock
    - Used in: BowSetup

11. **Accessory** - Generic equipment
    - Fields: id, brand, model, type
    - Used in: BowSetup

#### Bow Configuration
12. **BowSetup** - Complete equipment configuration (15 fields)
    - Fields: id, name, description, version, isActive, riserId, limbsId, sightId, stabilizerId, plungerId, restId, bowStringId, arrowId, weightId, accessoryId
    - Foreign Keys: References all equipment types
    - Soft Delete: Uses `isActive` flag
    - Versioning: Auto-increments version on equipment changes

13. **BowSetupEquipment** - Junction table for setup-equipment relationships
    - Fields: setupId, equipmentId, equipmentType
    - Purpose: Flexible many-to-many relationships

### Scoring Entities (3 Total)

Entities for round scoring and session management:

1. **Round** (25 fields)
   - **Basic:** roundName, numEnds, numArrows, distance, targetSize
   - **Scoring:** scoringSystem, targetRings (legacy), ringValues (legacy)
   - **Equipment:** bowSetupId (FK → BowSetup), bowSetupVersion
   - **Status:** PLANNED, IN_PROGRESS, PAUSED, COMPLETED, CANCELLED
   - **Multi-participant:** participants (JSON list), participantTheme
   - **Tournament:** tournamentId, tournamentRoundNumber, isLocal, syncStatus
   - **Timestamps:** createdAt, startedAt, completedAt, lastModifiedAt

2. **EndScore**
   - Fields: id, roundId, endNumber, totalScore, isComplete, participantId
   - Foreign Key: roundId → Round(id), CASCADE DELETE
   - Purpose: Group arrow scores by end

3. **ArrowScore** (16 fields)
   - **Score:** scoreValue, isXRing
   - **Coordinates:** targetX, targetY, centerX, centerY (for grouping analysis)
   - **Position:** ringNumber, clockPosition
   - **Equipment Tracking:** bowSetupId, bowSetupVersion
   - **Metadata:** participantId, inputMethod (MANUAL/TARGET_FACE/QUICK_ENTRY)
   - Foreign Keys: endScoreId → EndScore(id), roundId → Round(id)

### Tournament Entities (3 Total)

Entities for tournament management and offline support:

1. **TournamentEntity** (36 fields)
   - **Metadata:** name, description, location, createdBy, creatorEmail
   - **Status:** OPEN, IN_PROGRESS, COMPLETED, CANCELLED
   - **Round Format:** numEnds, numArrows, distance, targetSize, scoringSystem
   - **Access Control:** isPublic, joinCode, maxParticipants, requireApproval
   - **Settings:** allowSpectators, useSettingsDisplayNames
   - **Sync:** needsSync, lastSyncedAt, isLocal

2. **TournamentParticipantEntity**
   - Fields: id, tournamentId, userId, displayName, currentRound, totalScore, ranking, status
   - Foreign Key: tournamentId → TournamentEntity(id)
   - Purpose: Track participant progress and rankings

3. **TournamentScoreCache**
   - Fields: id, tournamentId, participantId, roundNumber, scores, lastUpdated
   - Purpose: Offline score caching for sync when online

### Statistics & Cache Entities (2 Total)

1. **EquipmentStatsCache**
   - Fields: setupId, distance, totalRounds, averageScore, accuracy, ringDistribution
   - Purpose: Cached performance metrics for equipment

2. **ArrowEquipmentSnapshot**
   - Fields: id, arrowScoreId, bowSetupSnapshot (JSON)
   - Purpose: Historical equipment configuration snapshots

### Settings Entity (1 Total)

1. **Settings**
   - Fields: id, userName, preferredDistance, preferredTargetSize, theme, measurementSystem
   - Purpose: User preferences and app configuration

---

## Relationships

### Equipment → BowSetup
- **Type:** Many-to-One
- **Direction:** Multiple equipment items → One setup can use multiple equipment
- **Foreign Keys:** BowSetup.riserId → Riser.id, BowSetup.limbsId → Limbs.id, etc.
- **Cascade:** ON DELETE SET NULL (preserve historical data)

### BowSetup → Round
- **Type:** One-to-Many
- **Direction:** One setup → Multiple rounds
- **Foreign Key:** Round.bowSetupId → BowSetup.id
- **Versioning:** Round also stores bowSetupVersion to track exact configuration

### Round → EndScore → ArrowScore
- **Type:** One-to-Many (cascading)
- **Direction:** Round → Ends → Arrows
- **Foreign Keys:**
  - EndScore.roundId → Round.id (CASCADE DELETE)
  - ArrowScore.endScoreId → EndScore.id (CASCADE DELETE)
  - ArrowScore.roundId → Round.id (CASCADE DELETE)
- **Effect:** Deleting a round deletes all associated ends and arrow scores

### Tournament → TournamentParticipant
- **Type:** One-to-Many
- **Foreign Key:** TournamentParticipant.tournamentId → TournamentEntity.id
- **Cascade:** ON DELETE CASCADE

### Sight → SightMark
- **Type:** One-to-Many
- **Foreign Key:** SightMark.sightId → Sight.id
- **Cascade:** ON DELETE CASCADE

---

## Type Converters

RoomKMP uses type converters to handle complex data types:

**KmpConverters.kt:**
- `Distance` ↔ String (e.g., "50 meters", "30 yards")
- `TargetSize` ↔ String (e.g., "122cm", "80cm")
- `ScoringSystem` ↔ String (e.g., "10-ring", "6-ring")
- `SessionParticipant` List ↔ JSON String
- `RingValues` Map ↔ JSON String
- `ArrowPoint` ↔ JSON String (embedded object)
- `ArrowNock` ↔ JSON String (embedded object)
- `Timestamps` ↔ Long (epoch milliseconds)

---

## Indexes & Performance

### Primary Indexes

Every table has a primary key (id) with auto-increment.

### Strategic Indexes

**Round Table:**
- Index on `bowSetupId` (frequent JOINs for equipment performance)
- Index on `tournamentId` (tournament round lookups)
- Composite index on `status, createdAt` (active rounds queries)

**ArrowScore Table:**
- Index on `roundId` (end-by-end retrieval)
- Index on `endScoreId` (arrow grouping)
- Index on `participantId` (multi-participant scoring)

**BowSetup Table:**
- Index on `isActive` (active setup filtering)
- Index on `version` (version history queries)

**TournamentParticipant Table:**
- Index on `tournamentId` (participant lists)
- Index on `userId` (user's tournaments)

---

## Migration History

### Version 17 → 35 (18 Migrations)

The database has evolved from version 17 to 35 during the KMP migration project.

**Key Migrations:**

**v17-19:** Legacy Room database (pre-KMP)
- Equipment entities established
- Basic round scoring

**v20-25:** Round system enhancements
- Multi-participant support added
- Tournament integration
- Round status workflow

**v26-30:** Equipment analytics
- EquipmentStatsCache added
- BowSetup versioning introduced
- ArrowEquipmentSnapshot for history

**v31-33:** Tournament features
- TournamentEntity schema
- Participant management
- Offline sync support

**v34-35:** KMP Migration (Week 13-14)
- Database cutover to shared:database module
- Platform-specific builders
- Migration verification and data repair

### Migration Strategy

**Approach:**
1. **Incremental Migrations** - Each version change is a separate migration
2. **Data Preservation** - No data loss during migrations
3. **Forward-Only** - No downgrades supported
4. **Testing** - Migration tests verify data integrity

**Migration Files:**
- Located in `shared/database/src/commonMain/sqldelight/migrations/`
- Named: `<version>.sqm` (e.g., `35.sqm`)
- Applied automatically on app upgrade

---

## KMP Migration Status

### Big Bang Cutover (Week 13-14)

The database successfully migrated from Android-specific Room to cross-platform RoomKMP.

**Migration Phases:**
1. **Week 11:** Equipment DAOs migrated to shared:database
2. **Week 12:** Tournament DAOs migrated
3. **Week 13-14:** Scoring entities migrated (Big Bang cutover)

**Current State:**
- ✅ All 26 entities in shared:database
- ✅ All DAOs migrated to RoomKMP
- ✅ Platform-specific builders (Android/iOS/JVM)
- ✅ Type converters working cross-platform
- ✅ Migration tests passing
- ✅ Data integrity verified

**Platform Support:**
- **Android:** Room with SQLite
- **iOS:** Room with SQLDelight wrapper
- **JVM:** Room with SQLite JDBC

---

## Developer Guidelines

### Creating New Entities

1. Define entity in `shared/database/src/commonMain/kotlin/entities/`
2. Add type converters if needed in `KmpConverters.kt`
3. Create DAO interface in `dao/` package
4. Write migration SQL
5. Increment database version
6. Add migration tests

### Modifying Existing Entities

1. **Don't modify existing fields** - Can break existing data
2. **Add new fields with defaults** - Safe addition
3. **Create migration** - Handle schema change
4. **Test migration** - Verify data preservation
5. **Update DAO queries** - Reflect schema changes

### Query Best Practices

**Use indexes:**
```kotlin
@Query("SELECT * FROM Round WHERE status = :status ORDER BY createdAt DESC")
// Index on (status, createdAt) makes this fast
```

**Avoid N+1 queries:**
```kotlin
// Bad: Multiple queries
rounds.forEach { round ->
    dao.getEndScores(round.id)
}

// Good: Single query with JOIN
dao.getRoundsWithEnds()
```

**Use transactions:**
```kotlin
database.withTransaction {
    roundDao.insert(round)
    endScoreDao.insertAll(ends)
    arrowScoreDao.insertAll(arrows)
}
```

---

## Related Documentation

**Architecture:**
- [Database Migration Plan](../../internal/kmp-migration/) - KMP migration details
- [Week 13-14 Cutover](../../internal/kmp-migration/week-13-14/) - Big Bang cutover documentation

**Technical Reference:**
- [Database Tables](Tables/) - Detailed table schemas
- [Data Models](../Data-Models/) - Entity class documentation
- [DAOs](../api/daos/) - Data access object interfaces

**Developer Guides:**
- [Database Best Practices](../../developer-guide/guides/best-practices/) - Query optimization
- [Testing Database](../../developer-guide/testing/) - Database testing strategies

---

## Quick Reference

| Entity Type | Count | Key Tables |
|-------------|-------|------------|
| **Equipment** | 13 | Riser, Limbs, Sight, Stabilizer, Arrow, BowSetup |
| **Scoring** | 3 | Round, EndScore, ArrowScore |
| **Tournament** | 3 | TournamentEntity, TournamentParticipant, TournamentScoreCache |
| **Stats/Cache** | 2 | EquipmentStatsCache, ArrowEquipmentSnapshot |
| **Settings** | 1 | Settings |
| **TOTAL** | **26** | |

**Current Version:** 35
**Migrations:** 17→35 (18 total)
**ORM:** RoomKMP
**Platform:** Android, iOS, JVM
