---
title: "Database Migrations"
description: "Migration history and guides for database schema changes"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - database
  - migrations
  - schema
  - versioning
---

[Home](/) > [Technical Reference](../../) > [Database](../) > Migrations

---

# Database Migrations

Complete migration history and best practices for evolving the Archery Apprentice database schema from version 17 to the current version 35.

## Overview

**Current Version:** 35
**Initial Tracked Version:** 17
**Total Migrations:** 18 (v17→v35)
**Migration System:** RoomKMP Auto-Migrations + Manual SQL
**Location:** `shared/database/src/commonMain/sqldelight/migrations/`

### Migration Philosophy

**Forward-Only:**
- No rollback support (Room limitation)
- Test migrations thoroughly before deployment
- Always preserve user data

**Incremental:**
- Each schema change gets own migration
- Small, focused changes easier to test
- Clear changelog of database evolution

**Data Preservation:**
- Never lose user data
- Provide defaults for new columns
- Migrate existing data when schema changes

---

## Migration History

### Version 17-19: Foundation (Pre-KMP)

**Legacy Room Database (Android-only)**

#### Version 17 → 18
**Changes:**
- Initial tracked version
- Equipment entities established (Riser, Limbs, Sight, Stabilizer, Arrow, etc.)
- BowSetup entity for equipment configurations
- Basic Round and ArrowScore entities

**Migration:**
```sql
-- Baseline schema (no migration needed, starting point)
```

#### Version 18 → 19
**Changes:**
- Added SightMark entity for distance-specific sight settings
- Added foreign key constraints for equipment relationships

**Migration:**
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
```

**Impact:** Equipment management enhancement, sight tuning support

---

### Version 20-25: Multi-Participant & Tournaments

#### Version 19 → 20
**Changes:**
- Added `participants` field to Round (JSON array)
- Added `participantTheme` field (SINGLE_USER vs MULTI_PARTICIPANT)
- Added `participantId` field to EndScore and ArrowScore

**Migration:**
```sql
ALTER TABLE Round ADD COLUMN participants TEXT;
ALTER TABLE Round ADD COLUMN participantTheme TEXT NOT NULL DEFAULT 'SINGLE_USER';

ALTER TABLE EndScore ADD COLUMN participantId TEXT;
ALTER TABLE ArrowScore ADD COLUMN participantId TEXT;

CREATE INDEX idx_end_score_participant_id ON EndScore(participantId);
CREATE INDEX idx_arrow_score_participant_id ON ArrowScore(participantId);
```

**Impact:** Multi-participant rounds enabled (up to 4 archers)

**Data Migration:**
```sql
-- Existing rounds default to SINGLE_USER
UPDATE Round SET participantTheme = 'SINGLE_USER' WHERE participantTheme IS NULL;
```

#### Version 20 → 21
**Changes:**
- Added unique constraint on (roundId, endNumber, participantId) for EndScore
- Prevents duplicate end entries

**Migration:**
```sql
CREATE UNIQUE INDEX idx_end_score_unique ON EndScore(roundId, endNumber, participantId);
```

#### Version 21 → 22
**Changes:**
- Added TournamentEntity table
- Added TournamentParticipant table
- Added tournament fields to Round (tournamentId, tournamentRoundNumber)

**Migration:**
```sql
CREATE TABLE TournamentEntity (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    location TEXT,
    status TEXT NOT NULL DEFAULT 'OPEN',
    numEnds INTEGER NOT NULL,
    numArrows INTEGER NOT NULL,
    distance TEXT NOT NULL,
    targetSize TEXT NOT NULL,
    scoringSystem TEXT NOT NULL,
    createdAt INTEGER NOT NULL
    -- (additional fields)
);

CREATE TABLE TournamentParticipant (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    tournamentId TEXT NOT NULL,
    userId TEXT NOT NULL,
    displayName TEXT NOT NULL,
    currentRound INTEGER NOT NULL DEFAULT 0,
    totalScore INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    registeredAt INTEGER NOT NULL,
    FOREIGN KEY (tournamentId) REFERENCES TournamentEntity(id) ON DELETE CASCADE
);

ALTER TABLE Round ADD COLUMN tournamentId TEXT;
ALTER TABLE Round ADD COLUMN tournamentRoundNumber INTEGER;

CREATE INDEX idx_round_tournament_id ON Round(tournamentId);
CREATE INDEX idx_tournament_participant_tournament_id ON TournamentParticipant(tournamentId);
```

**Impact:** Tournament management capabilities added

#### Version 22 → 23
**Changes:**
- Added `isLocal` and `syncStatus` fields to Round for offline support
- Added TournamentScoreCache table

**Migration:**
```sql
ALTER TABLE Round ADD COLUMN isLocal INTEGER NOT NULL DEFAULT 1;
ALTER TABLE Round ADD COLUMN syncStatus TEXT;

CREATE TABLE TournamentScoreCache (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    tournamentId TEXT NOT NULL,
    participantId TEXT NOT NULL,
    roundNumber INTEGER NOT NULL,
    scores TEXT NOT NULL,
    lastUpdated INTEGER NOT NULL,
    syncStatus TEXT NOT NULL DEFAULT 'PENDING'
);

CREATE INDEX idx_tournament_score_cache_sync_status ON TournamentScoreCache(syncStatus);
```

**Impact:** Offline tournament participation enabled

#### Version 23 → 24
**Changes:**
- Added `ranking` field to TournamentParticipant
- Added leaderboard caching fields to TournamentEntity

**Migration:**
```sql
ALTER TABLE TournamentParticipant ADD COLUMN ranking INTEGER;

ALTER TABLE TournamentEntity ADD COLUMN topScore INTEGER;
ALTER TABLE TournamentEntity ADD COLUMN averageScore REAL;
ALTER TABLE TournamentEntity ADD COLUMN totalParticipants INTEGER NOT NULL DEFAULT 0;

CREATE INDEX idx_tournament_participant_ranking ON TournamentParticipant(ranking);
```

**Impact:** Leaderboard performance optimization

#### Version 24 → 25
**Changes:**
- Added tournament access control fields (joinCode, maxParticipants, requireApproval)
- Added tournament rules fields (eliminationRounds, tiebreakingRules, etc.)

**Migration:**
```sql
ALTER TABLE TournamentEntity ADD COLUMN joinCode TEXT;
ALTER TABLE TournamentEntity ADD COLUMN maxParticipants INTEGER;
ALTER TABLE TournamentEntity ADD COLUMN requireApproval INTEGER NOT NULL DEFAULT 0;
ALTER TABLE TournamentEntity ADD COLUMN eliminationRounds INTEGER;
ALTER TABLE TournamentEntity ADD COLUMN advancementCriteria TEXT;
ALTER TABLE TournamentEntity ADD COLUMN tiebreakingRules TEXT;
ALTER TABLE TournamentEntity ADD COLUMN customRules TEXT;
ALTER TABLE TournamentEntity ADD COLUMN roundDeadlines TEXT;
```

**Impact:** Advanced tournament features (private tournaments, elimination rounds)

---

### Version 26-30: Equipment Analytics

#### Version 25 → 26
**Changes:**
- Added BowSetup versioning (`version` field)
- Added `isActive` field for soft deletes
- Added `bowSetupVersion` to Round and ArrowScore

**Migration:**
```sql
ALTER TABLE BowSetup ADD COLUMN version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE BowSetup ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1;

ALTER TABLE Round ADD COLUMN bowSetupVersion INTEGER;
ALTER TABLE ArrowScore ADD COLUMN bowSetupVersion INTEGER;

CREATE INDEX idx_bowsetup_version ON BowSetup(version);
CREATE INDEX idx_bowsetup_active ON BowSetup(isActive);
```

**Impact:** Equipment versioning enables historical performance tracking

**Data Migration:**
```sql
-- Set all existing setups to version 1, active
UPDATE BowSetup SET version = 1 WHERE version IS NULL;
UPDATE BowSetup SET isActive = 1 WHERE isActive IS NULL;

-- Backfill bowSetupVersion for existing rounds
UPDATE Round
SET bowSetupVersion = 1
WHERE bowSetupId IS NOT NULL AND bowSetupVersion IS NULL;
```

#### Version 26 → 27
**Changes:**
- Added EquipmentStatsCache table for performance metrics

**Migration:**
```sql
CREATE TABLE EquipmentStatsCache (
    setupId INTEGER NOT NULL,
    distance TEXT NOT NULL,
    totalRounds INTEGER NOT NULL DEFAULT 0,
    averageScore REAL NOT NULL DEFAULT 0.0,
    accuracy REAL NOT NULL DEFAULT 0.0,
    ringDistribution TEXT,
    lastUpdated INTEGER NOT NULL,
    PRIMARY KEY (setupId, distance)
);

CREATE INDEX idx_stats_cache_setup_id ON EquipmentStatsCache(setupId);
CREATE INDEX idx_stats_cache_distance ON EquipmentStatsCache(distance);
```

**Impact:** Fast equipment performance queries

#### Version 27 → 28
**Changes:**
- Added ArrowEquipmentSnapshot table for historical snapshots

**Migration:**
```sql
CREATE TABLE ArrowEquipmentSnapshot (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    arrowScoreId INTEGER NOT NULL,
    bowSetupSnapshot TEXT NOT NULL,
    FOREIGN KEY (arrowScoreId) REFERENCES ArrowScore(id) ON DELETE CASCADE
);

CREATE INDEX idx_snapshot_arrow_id ON ArrowEquipmentSnapshot(arrowScoreId);
CREATE UNIQUE INDEX idx_snapshot_unique ON ArrowEquipmentSnapshot(arrowScoreId);
```

**Impact:** Equipment configuration snapshots for historical accuracy

#### Version 28 → 29
**Changes:**
- Added coordinate tracking fields to ArrowScore (targetX, targetY, etc.)
- Added `inputMethod` field

**Migration:**
```sql
ALTER TABLE ArrowScore ADD COLUMN targetX REAL;
ALTER TABLE ArrowScore ADD COLUMN targetY REAL;
ALTER TABLE ArrowScore ADD COLUMN centerX REAL;
ALTER TABLE ArrowScore ADD COLUMN centerY REAL;
ALTER TABLE ArrowScore ADD COLUMN ringNumber INTEGER;
ALTER TABLE ArrowScore ADD COLUMN clockPosition INTEGER;
ALTER TABLE ArrowScore ADD COLUMN inputMethod TEXT NOT NULL DEFAULT 'MANUAL';
```

**Impact:** Shot grouping analysis enabled (eccentricity, radial SD, bias)

#### Version 29 → 30
**Changes:**
- Added composite index on (status, createdAt) for Round queries
- Performance optimization for common queries

**Migration:**
```sql
CREATE INDEX idx_round_status_created ON Round(status, createdAt);
```

**Impact:** Faster "active rounds" queries

---

### Version 31-33: Tournament Expansion

#### Version 30 → 31
**Changes:**
- Added Settings table for user preferences

**Migration:**
```sql
CREATE TABLE Settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    userName TEXT,
    preferredDistance TEXT,
    preferredTargetSize TEXT,
    theme TEXT,
    measurementSystem TEXT
);

-- Insert default settings row
INSERT INTO Settings (id) VALUES (1);
```

**Impact:** User preferences persistence

#### Version 31 → 32
**Changes:**
- Added `useSettingsDisplayNames` field to TournamentEntity
- Added `lastRoundSubmitted` to TournamentParticipant

**Migration:**
```sql
ALTER TABLE TournamentEntity ADD COLUMN useSettingsDisplayNames INTEGER NOT NULL DEFAULT 1;
ALTER TABLE TournamentParticipant ADD COLUMN lastRoundSubmitted INTEGER;
```

#### Version 32 → 33
**Changes:**
- Added unique constraint on (tournamentId, userId) for TournamentParticipant
- Prevents duplicate participant entries

**Migration:**
```sql
-- Remove any existing duplicates first
DELETE FROM TournamentParticipant
WHERE id NOT IN (
    SELECT MIN(id)
    FROM TournamentParticipant
    GROUP BY tournamentId, userId
);

CREATE UNIQUE INDEX idx_tournament_participant_unique
ON TournamentParticipant(tournamentId, userId);
```

**Impact:** Data integrity for tournament participants

---

### Version 34-35: KMP Migration (Week 13-14)

#### Version 33 → 34
**Changes:**
- Database cutover from Android Room to RoomKMP
- No schema changes, platform migration only
- Moved from `androidApp:database` to `shared:database`

**Migration:**
```sql
-- No SQL migration needed
-- Database file copied from Android to shared location
-- Platform-specific builders configured
```

**Impact:** Cross-platform database support (Android, iOS, JVM)

**Technical Details:**
- SQLite database file remains compatible
- Room → RoomKMP API migration
- Type converters updated for KMP
- Platform-specific builders (Android, iOS, JVM)

#### Version 34 → 35
**Changes:**
- Migration verification and data repair
- Index rebuild for optimization
- Type converter validation

**Migration:**
```sql
-- Rebuild indexes for optimization
REINDEX;

-- Analyze tables for query planning
ANALYZE;

-- Validate foreign key constraints
PRAGMA foreign_key_check;
```

**Impact:** Database integrity verification post-KMP migration

---

## Migration Checklist

### Before Creating a Migration

1. **Identify Schema Change:**
   - What tables/columns need to change?
   - Is this a breaking change?
   - Does existing data need migration?

2. **Plan Data Migration:**
   - Will new columns need default values?
   - Do existing rows need updates?
   - Are there data transformations needed?

3. **Consider Performance:**
   - Will migration block app startup?
   - Are there large tables involved?
   - Do indexes need rebuilding?

4. **Test with Real Data:**
   - Export production-like database
   - Test migration on copy
   - Verify data integrity after migration

### Creating a New Migration

#### Step 1: Increment Database Version

```kotlin
// shared/database/src/commonMain/kotlin/DatabaseBuilder.kt
@Database(
    entities = [ /* all entities */ ],
    version = 36,  // Increment from 35 to 36
    exportSchema = true
)
abstract class ArcheryKmpDatabase : RoomDatabase() {
    // ...
}
```

#### Step 2: Write Migration SQL

```kotlin
// shared/database/src/commonMain/kotlin/Migrations.kt
val MIGRATION_35_36 = object : Migration(35, 36) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Add new column
        database.execSQL(
            "ALTER TABLE Round ADD COLUMN newField TEXT"
        )

        // Backfill existing data
        database.execSQL(
            "UPDATE Round SET newField = 'default' WHERE newField IS NULL"
        )

        // Add index if needed
        database.execSQL(
            "CREATE INDEX idx_round_new_field ON Round(newField)"
        )
    }
}
```

#### Step 3: Register Migration

```kotlin
// In DatabaseBuilder.kt
fun buildDatabase(context: Any): ArcheryKmpDatabase {
    return Room.databaseBuilder<ArcheryKmpDatabase>(
        context = context,
        name = "archery_kmp_database"
    )
    .addMigrations(
        MIGRATION_17_18,
        MIGRATION_18_19,
        // ... all previous migrations
        MIGRATION_35_36  // Add new migration
    )
    .build()
}
```

#### Step 4: Test Migration

```kotlin
@Test
fun testMigration35to36() {
    // Create database at version 35
    val helper = MigrationTestHelper(
        instrumentation,
        ArcheryKmpDatabase::class.java
    )

    val db = helper.createDatabase("test_db", 35).apply {
        // Insert test data at version 35
        execSQL("INSERT INTO Round (id, roundName, numEnds, numArrows, ...) VALUES (...)")
        close()
    }

    // Run migration
    helper.runMigrationsAndValidate("test_db", 36, true, MIGRATION_35_36)

    // Verify migrated data
    val migratedDb = helper.getMigratableDatabase("test_db", 36)
    val cursor = migratedDb.query("SELECT * FROM Round")

    cursor.moveToFirst()
    val newField = cursor.getString(cursor.getColumnIndex("newField"))
    assertEquals("default", newField)
}
```

---

## Migration Best Practices

### 1. Always Provide Defaults

```sql
-- Good: Provides default for new non-null column
ALTER TABLE Round ADD COLUMN status TEXT NOT NULL DEFAULT 'PLANNED';

-- Bad: Fails if table has existing rows
ALTER TABLE Round ADD COLUMN status TEXT NOT NULL;
```

### 2. Preserve Existing Data

```sql
-- Good: Backfills existing rows
ALTER TABLE BowSetup ADD COLUMN version INTEGER;
UPDATE BowSetup SET version = 1 WHERE version IS NULL;

-- Bad: Leaves existing rows with NULL
ALTER TABLE BowSetup ADD COLUMN version INTEGER;
```

### 3. Handle Foreign Keys Carefully

```sql
-- Good: Adds FK after data migration
ALTER TABLE Round ADD COLUMN bowSetupId INTEGER;
UPDATE Round SET bowSetupId = (SELECT id FROM BowSetup LIMIT 1);
-- Then add FK constraint in next migration after validation

-- Bad: Adds FK immediately, may fail if data inconsistent
ALTER TABLE Round ADD COLUMN bowSetupId INTEGER
    REFERENCES BowSetup(id);
```

### 4. Test on Large Datasets

```kotlin
// Simulate production data volume
@Test
fun testMigrationPerformance() {
    val helper = MigrationTestHelper(...)
    val db = helper.createDatabase("test_db", 35)

    // Insert 10,000 rounds (simulating real usage)
    repeat(10_000) { i ->
        db.execSQL("INSERT INTO Round (...) VALUES (...)")
    }

    db.close()

    // Measure migration time
    val startTime = System.currentTimeMillis()
    helper.runMigrationsAndValidate("test_db", 36, true, MIGRATION_35_36)
    val duration = System.currentTimeMillis() - startTime

    // Assert migration completes in reasonable time
    assertTrue(duration < 5000, "Migration took ${duration}ms, expected < 5000ms")
}
```

### 5. Use Transactions for Complex Migrations

```kotlin
override fun migrate(database: SupportSQLiteDatabase) {
    database.beginTransaction()
    try {
        // Multiple related changes
        database.execSQL("ALTER TABLE Round ADD COLUMN field1 TEXT")
        database.execSQL("ALTER TABLE Round ADD COLUMN field2 TEXT")
        database.execSQL("UPDATE Round SET field1 = ..., field2 = ...")

        database.setTransactionSuccessful()
    } finally {
        database.endTransaction()
    }
}
```

### 6. Document Breaking Changes

```kotlin
/**
 * Migration 35 → 36: Added newField to Round
 *
 * BREAKING CHANGE: Apps older than v2.5 cannot read database after this migration
 *
 * Changes:
 * - Added Round.newField (TEXT, default 'value')
 * - Backfilled all existing rounds with default value
 * - Added index on newField for performance
 *
 * Data Impact: None, all existing data preserved
 */
val MIGRATION_35_36 = object : Migration(35, 36) { ... }
```

---

## Troubleshooting Migrations

### Migration Fails on App Upgrade

**Symptom:** App crashes on startup after upgrade

**Causes:**
1. Missing migration (Room can't find path from old version to new)
2. SQL syntax error in migration
3. Foreign key constraint violation

**Solutions:**
```kotlin
// 1. Check logcat for specific error
// 2. Verify all migrations registered
.addMigrations(
    MIGRATION_17_18,
    // ... ensure no gaps
    MIGRATION_35_36
)

// 3. For testing, allow destructive migrations (WARNING: loses data)
.fallbackToDestructiveMigration()  // Only for development!
```

### Data Lost After Migration

**Symptom:** User data missing after app upgrade

**Prevention:**
1. **Test migrations thoroughly**
2. **Never use `fallbackToDestructiveMigration()` in production**
3. **Verify data integrity in tests**

**Recovery:**
- No automatic recovery (Room doesn't support rollback)
- Require users to restore from backup
- Prevent by thorough testing before release

### Performance Degradation

**Symptom:** App slow after migration, especially startup

**Causes:**
1. Missing indexes
2. Inefficient data migration queries
3. Large dataset transformations

**Solutions:**
```sql
-- Recreate indexes after data migration
REINDEX;

-- Update query planner statistics
ANALYZE;

-- For large migrations, consider background processing
-- (though Room migrations run on main thread)
```

---

## Migration Testing Strategy

### Unit Tests

```kotlin
@Test
fun testMigration35to36_addsField() {
    val helper = MigrationTestHelper(...)

    // Setup: Create v35 database
    helper.createDatabase("test", 35)

    // Execute: Run migration
    helper.runMigrationsAndValidate("test", 36, true, MIGRATION_35_36)

    // Verify: Check schema
    val db = helper.getMigratableDatabase("test", 36)
    val cursor = db.query("PRAGMA table_info(Round)")

    var foundNewField = false
    while (cursor.moveToNext()) {
        val colName = cursor.getString(cursor.getColumnIndex("name"))
        if (colName == "newField") {
            foundNewField = true
        }
    }

    assertTrue(foundNewField, "newField not found in Round table")
}
```

### Integration Tests

```kotlin
@Test
fun testMigrationChain_17to36() {
    val helper = MigrationTestHelper(...)

    // Test full migration chain
    val db = helper.createDatabase("test", 17)

    // Insert data at v17
    db.execSQL("INSERT INTO BowSetup (...) VALUES (...)")
    db.close()

    // Migrate through all versions
    helper.runMigrationsAndValidate(
        "test", 36, true,
        MIGRATION_17_18, MIGRATION_18_19, /* ... */ MIGRATION_35_36
    )

    // Verify data survived migration chain
    val finalDb = helper.getMigratableDatabase("test", 36)
    val cursor = finalDb.query("SELECT * FROM BowSetup")

    assertEquals(1, cursor.count)
}
```

### Manual Testing Checklist

- [ ] Export production database from device
- [ ] Copy to test device at lower version
- [ ] Install new app version
- [ ] Verify app launches successfully
- [ ] Verify existing data intact
- [ ] Verify new features work
- [ ] Check logcat for migration logs
- [ ] Test backward compatibility (if supported)

---

## Related Documentation

**Database:**
- [Database Overview](../) - Architecture and entity overview
- [Database Tables](../Tables/) - Complete table schemas

**KMP Migration:**
- [Week 13-14 Vault](../../../internal/kmp-migration/week-13-14/) - Big Bang cutover documentation

**Testing:**
- [Database Testing](../../../developer-guide/testing/) - Testing strategies

---

## Quick Reference

**Current Version:** 35
**Migration Count:** 18 (v17→v35)
**Migration System:** RoomKMP
**Migration Location:** `shared/database/src/commonMain/kotlin/Migrations.kt`

**Migration Categories:**
- **v17-19:** Foundation (equipment, basic scoring)
- **v20-25:** Multi-participant & tournaments
- **v26-30:** Equipment analytics & versioning
- **v31-33:** Tournament expansion
- **v34-35:** KMP migration cutover

**Key Migrations:**
- **v19→20:** Multi-participant support
- **v21→22:** Tournament management
- **v25→26:** Equipment versioning
- **v26→27:** Performance caching (EquipmentStatsCache)
- **v27→28:** Equipment snapshots
- **v28→29:** Shot grouping coordinates
- **v33→34:** KMP database cutover

**Migration Command:**
```kotlin
Room.databaseBuilder<ArcheryKmpDatabase>(...)
    .addMigrations(MIGRATION_17_18, ..., MIGRATION_35_36)
    .build()
```

---

**Database Version:** 35
**Last Migration:** Week 13-14 (KMP Cutover)
**Next Version:** 36 (TBD)
