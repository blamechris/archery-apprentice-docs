---
title: How to Create a Database Migration
tags:
  - how-to
  - database
  - room
  - migration
  - schema
created: 2025-11-01
---

# How to Create a Database Migration

Step-by-step guide to creating Room database migrations safely.

---

## Overview

Database migrations allow you to update the schema without losing user data.

**Time:** ~15-30 minutes
**Difficulty:** Intermediate

---

## Step 1: Update the Entity

```kotlin
// BEFORE
@Entity(tableName = "rounds")
data class Round(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val distance: Int
)

// AFTER: Add new field
@Entity(tableName = "rounds")
data class Round(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val distance: Int,
    val targetFace: String = "122cm"  // New field with default
)
```

---

## Step 2: Increment Database Version

```kotlin
// File: data/database/AppDatabase.kt
@Database(
    entities = [Round::class, EndScore::class],
    version = 28,  // Increment from 27 to 28
    exportSchema = true  // Important for migration testing
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun roundDao(): RoundDao
    // ...
}
```

---

## Step 3: Create Migration Object

```kotlin
// File: data/database/migrations/Migration_27_28.kt
val MIGRATION_27_28 = object : Migration(27, 28) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Add new column with default value
        database.execSQL("""
            ALTER TABLE rounds
            ADD COLUMN targetFace TEXT NOT NULL DEFAULT '122cm'
        """.trimIndent())
    }
}
```

---

## Step 4: Add Migration to Database Builder

```kotlin
// File: di/DatabaseModule.kt
@Provides
@Singleton
fun provideDatabase(
    @ApplicationContext context: Context
): AppDatabase {
    return Room.databaseBuilder(
        context,
        AppDatabase::class.java,
        "archery_database"
    )
    .addMigrations(
        // ... existing migrations
        MIGRATION_27_28  // Add new migration
    )
    .build()
}
```

---

## Common Migration Scenarios

### Adding a Column

```kotlin
val MIGRATION_X_Y = object : Migration(X, Y) {
    override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("""
            ALTER TABLE rounds
            ADD COLUMN newColumn TEXT NOT NULL DEFAULT 'default_value'
        """)
    }
}
```

### Adding a Table

```kotlin
val MIGRATION_X_Y = object : Migration(X, Y) {
    override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("""
            CREATE TABLE IF NOT EXISTS new_table (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                name TEXT NOT NULL,
                value INTEGER NOT NULL,
                created_at INTEGER NOT NULL
            )
        """)

        // Add index
        database.execSQL("""
            CREATE INDEX IF NOT EXISTS index_new_table_created_at
            ON new_table(created_at)
        """)
    }
}
```

### Renaming a Column

SQLite doesn't support renaming columns directly. You need to:
1. Create new table with correct schema
2. Copy data
3. Drop old table
4. Rename new table

```kotlin
val MIGRATION_X_Y = object : Migration(X, Y) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // 1. Create new table with renamed column
        database.execSQL("""
            CREATE TABLE rounds_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                name TEXT NOT NULL,
                meters INTEGER NOT NULL  -- Renamed from 'distance'
            )
        """)

        // 2. Copy data from old table
        database.execSQL("""
            INSERT INTO rounds_new (id, name, meters)
            SELECT id, name, distance FROM rounds
        """)

        // 3. Drop old table
        database.execSQL("DROP TABLE rounds")

        // 4. Rename new table
        database.execSQL("ALTER TABLE rounds_new RENAME TO rounds")

        // 5. Recreate indexes
        database.execSQL("""
            CREATE INDEX IF NOT EXISTS index_rounds_name
            ON rounds(name)
        """)
    }
}
```

### Adding a Foreign Key

```kotlin
val MIGRATION_X_Y = object : Migration(X, Y) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Create new table with foreign key
        database.execSQL("""
            CREATE TABLE end_scores_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                roundId INTEGER NOT NULL,
                endNumber INTEGER NOT NULL,
                totalScore INTEGER NOT NULL,
                FOREIGN KEY(roundId) REFERENCES rounds(id) ON DELETE CASCADE
            )
        """)

        // Copy data
        database.execSQL("""
            INSERT INTO end_scores_new
            SELECT * FROM end_scores
        """)

        // Drop old and rename
        database.execSQL("DROP TABLE end_scores")
        database.execSQL("ALTER TABLE end_scores_new RENAME TO end_scores")

        // Recreate indexes
        database.execSQL("""
            CREATE INDEX IF NOT EXISTS index_end_scores_roundId
            ON end_scores(roundId)
        """)
    }
}
```

### Changing Column Type

```kotlin
val MIGRATION_X_Y = object : Migration(X, Y) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Create new table with correct type
        database.execSQL("""
            CREATE TABLE rounds_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                name TEXT NOT NULL,
                distance REAL NOT NULL  -- Changed from INTEGER to REAL
            )
        """)

        // Copy and convert data
        database.execSQL("""
            INSERT INTO rounds_new (id, name, distance)
            SELECT id, name, CAST(distance AS REAL) FROM rounds
        """)

        // Drop old table
        database.execSQL("DROP TABLE rounds")

        // Rename new table
        database.execSQL("ALTER TABLE rounds_new RENAME TO rounds")
    }
}
```

---

## Step 5: Test the Migration

### Manual Testing

```kotlin
// File: androidTest/data/database/MigrationTest.kt
@RunWith(AndroidJUnit4::class)
class MigrationTest {
    private val TEST_DB = "migration_test"

    @get:Rule
    val helper: MigrationTestHelper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        AppDatabase::class.java
    )

    @Test
    fun migrate27To28() {
        // Create database with version 27
        helper.createDatabase(TEST_DB, 27).apply {
            // Insert test data in old schema
            execSQL("""
                INSERT INTO rounds (name, distance)
                VALUES ('Test Round', 18)
            """)
            close()
        }

        // Run migration
        helper.runMigrationsAndValidate(TEST_DB, 28, true, MIGRATION_27_28)

        // Verify data
        val db = helper.runMigrationsAndValidate(TEST_DB, 28, true, MIGRATION_27_28)
        val cursor = db.query("SELECT * FROM rounds")

        assertTrue(cursor.moveToFirst())
        assertEquals("Test Round", cursor.getString(cursor.getColumnIndex("name")))
        assertEquals(18, cursor.getInt(cursor.getColumnIndex("distance")))
        assertEquals("122cm", cursor.getString(cursor.getColumnIndex("targetFace")))  // New column

        cursor.close()
        db.close()
    }
}
```

---

## Best Practices

### 1. Always Provide Defaults for New Columns

```kotlin
// GOOD: Has default
ALTER TABLE rounds ADD COLUMN targetFace TEXT NOT NULL DEFAULT '122cm'

// BAD: No default (will crash if table has data)
ALTER TABLE rounds ADD COLUMN targetFace TEXT NOT NULL
```

### 2. Test Migrations

Write migration tests for every migration:

```kotlin
@Test
fun migrateXToY() {
    helper.createDatabase(TEST_DB, X).apply {
        // Insert test data
        close()
    }

    helper.runMigrationsAndValidate(TEST_DB, Y, true, MIGRATION_X_Y)

    // Verify migration
}
```

### 3. Use trimIndent() for SQL

```kotlin
// GOOD: Readable
database.execSQL("""
    CREATE TABLE rounds (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
    )
""".trimIndent())

// BAD: Hard to read
database.execSQL("CREATE TABLE rounds (id INTEGER PRIMARY KEY, name TEXT NOT NULL)")
```

### 4. Keep Migration Files Organized

```
data/database/migrations/
  ├── Migration_1_2.kt
  ├── Migration_2_3.kt
  ├── Migration_3_4.kt
  └── ...
```

### 5. Document Complex Migrations

```kotlin
/**
 * Migration 27 -> 28
 *
 * Changes:
 * - Added targetFace column to rounds table (default: "122cm")
 * - Added index on rounds.targetFace
 *
 * Reason: Support different target face sizes
 */
val MIGRATION_27_28 = object : Migration(27, 28) {
    // ...
}
```

---

## Common Issues

### Issue: "Cannot find migration path"
**Problem:** Missing migration in chain

**Solution:** Add all intermediate migrations:
```kotlin
.addMigrations(
    MIGRATION_1_2,
    MIGRATION_2_3,  // Don't skip!
    MIGRATION_3_4
)
```

### Issue: "Table already exists"
**Problem:** Migration runs twice

**Solution:** Use `IF NOT EXISTS`:
```kotlin
CREATE TABLE IF NOT EXISTS rounds (...)
```

### Issue: "NOT NULL constraint failed"
**Problem:** Adding NOT NULL column without default

**Solution:** Provide default value:
```kotlin
ALTER TABLE rounds ADD COLUMN name TEXT NOT NULL DEFAULT ''
```

### Issue: Data lost after migration
**Problem:** Destructive migration used

**Solution:** Remove fallbackToDestructiveMigration() from production:
```kotlin
// Development only!
.fallbackToDestructiveMigration()
```

---

## Fallback Strategy (Development Only)

During development, you can use destructive migration:

```kotlin
Room.databaseBuilder(...)
    .fallbackToDestructiveMigration()  // ⚠️ DELETES ALL DATA
    .build()
```

**WARNING:** Never use in production! This deletes all user data.

---

## Migration Checklist

Before deploying:

- [ ] Entity updated with new field/table
- [ ] Database version incremented
- [ ] Migration object created
- [ ] Migration added to database builder
- [ ] Migration tested (manual or automated)
- [ ] Default values provided for new NOT NULL columns
- [ ] Indexes recreated if table was dropped
- [ ] Foreign keys maintained
- [ ] Migration documented

---

## Related Documentation

- [[../technical-reference/api/daos/index|DAOs API Reference]]
- [[add-database-entity|How to Add a Database Entity]]
- [[add-new-repository|How to Add a New Repository]]
- [[../../../../architecture/database-migration-status|Migration History]]

---

**Last Updated:** 2025-11-01
