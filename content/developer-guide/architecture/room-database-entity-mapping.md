# Room Database Entity Mapping Patterns

**Last Updated**: 2025-10-15  
**Status**: Best Practice Established

## Overview

Room database requires separate entity classes (@Entity) from domain models for database persistence. Mapping between these representations must be bidirectional and complete to prevent data loss.

**Critical Lesson**: Missing field mappings cause **silent data loss** during offline-first sync flows.

## The Problem: Silent Data Loss

### What Happened (2025-10-15)

Tournament settings were silently lost during creation due to missing Room entity field mappings.

**Data Flow**:
```
Domain Model (Tournament)
  ↓ tournament.toEntity()
Room Entity (TournamentEntity) - FIELDS MISSING
  ↓ Save to database
  ↓ Read from database  
  ↓ entity.toDomainModel()
Domain Model (Tournament) - DEFAULT VALUES USED ❌
```

**Result**: `useSettingsDisplayNames` changed from `true` → `false` during round-trip conversion.

### Why Silent?

1. **No Compilation Errors**: Kotlin doesn't enforce field mapping
2. **No Runtime Errors**: Room saves whatever fields exist
3. **Default Values**: Kotlin data classes use defaults when fields missing
4. **No Validation**: No automated check that all domain fields are persisted

**Impact**: Production bug, user-visible data loss, Feature #5 broken

## Regression Prevention: The Checklist

When adding fields to domain models that are persisted to Room:

### ✅ Required Steps (8-Step Process)

1. **Add field to domain model** (e.g., `Tournament.kt`)
   ```kotlin
   data class Tournament(
       val useSettingsDisplayNames: Boolean = false,
       // ... other fields
   )
   ```

2. **Add field to @Entity class** (e.g., `TournamentEntity.kt`)
   ```kotlin
   @Entity(tableName = "tournaments")
   data class TournamentEntity(
       val useSettingsDisplayNames: Boolean = false,
       // ... other fields
   )
   ```

3. **Update toEntity() mapping** (e.g., `TournamentEntityMappings.kt`)
   ```kotlin
   fun Tournament.toEntity(): TournamentEntity {
       return TournamentEntity(
           useSettingsDisplayNames = useSettingsDisplayNames,
           // ... other fields
       )
   }
   ```

4. **Update toDomainModel() mapping** (e.g., `TournamentEntityMappings.kt`)
   ```kotlin
   fun TournamentEntity.toDomainModel(): Tournament {
       return Tournament(
           useSettingsDisplayNames = useSettingsDisplayNames,
           // ... other fields
       )
   }
   ```

5. **Create database migration** (e.g., `MigrationXtoY.kt`)
   ```kotlin
   val MIGRATION_X_Y = object : Migration(X, Y) {
       override fun migrate(db: SupportSQLiteDatabase) {
           db.execSQL("""
               ALTER TABLE tournaments
               ADD COLUMN useSettingsDisplayNames INTEGER NOT NULL DEFAULT 0
           """)
       }
   }
   ```

6. **Update ArcheryDatabase.kt**
   ```kotlin
   @Database(
       entities = [/* ... */],
       version = Y,  // Increment version
       exportSchema = false
   )
   ```
   
   Add migration to `.addMigrations()`:
   ```kotlin
   .addMigrations(
       // ... existing migrations
       MIGRATION_X_Y
   )
   ```

7. **Write round-trip conversion test** (e.g., `TournamentEntityMappingsTest.kt`)
   ```kotlin
   @Test
   fun `round-trip conversion preserves all fields`() {
       val original = Tournament(
           useSettingsDisplayNames = true,
           // ... all fields with non-default values
       )
       
       val entity = original.toEntity()
       val roundTrip = entity.toDomainModel()
       
       // CRITICAL: Assert ALL fields match
       assertThat(roundTrip.useSettingsDisplayNames).isTrue()
       // ... all other field assertions
   }
   ```

8. **Write migration unit tests** (e.g., `MigrationXtoYTest.kt`)
   ```kotlin
   @Test
   fun `migration adds useSettingsDisplayNames column correctly`() {
       val mockDatabase = mockk<SupportSQLiteDatabase>(relaxed = true)
       
       MIGRATION_X_Y.migrate(mockDatabase)
       
       verify {
           mockDatabase.execSQL(match { sql ->
               sql.contains("ALTER TABLE tournaments") &&
               sql.contains("ADD COLUMN useSettingsDisplayNames") &&
               sql.contains("INTEGER NOT NULL DEFAULT 0")
           })
       }
   }
   ```

## Test Pattern: Round-Trip Conversion

### Why Critical?

Round-trip conversion tests ensure **ALL** domain model fields survive the conversion chain:
```
Domain → Entity → Domain → ALL FIELDS MATCH ✅
```

If any field is not mapped, the test fails immediately.

### Template

```kotlin
@Test
fun `round-trip conversion preserves all fields`() {
    // Given - Domain model with ALL fields populated with non-default values
    val originalDomain = DomainModel(
        field1 = "non-default-value",
        field2 = true,  // not default false
        field3 = 100,   // not default 0
        // ... EVERY SINGLE FIELD with non-default value
    )
    
    // When - Convert to entity and back to domain
    val entity = originalDomain.toEntity()
    val roundTripDomain = entity.toDomainModel()
    
    // Then - Assert ALL fields match exactly
    assertThat(roundTripDomain.field1).isEqualTo(originalDomain.field1)
    assertThat(roundTripDomain.field2).isEqualTo(originalDomain.field2)
    assertThat(roundTripDomain.field3).isEqualTo(originalDomain.field3)
    // ... EVERY SINGLE FIELD assertion
    
    // OR use data class equals (if no computed fields)
    assertThat(roundTripDomain).isEqualTo(originalDomain)
}
```

### Key Points

1. **Populate ALL fields** with non-default values
   - Default values mask missing mappings
   - `useSettingsDisplayNames = true` (not `false`)
   - `count = 100` (not `0`)

2. **Assert ALL fields** individually
   - Don't rely on data class `.equals()` alone
   - Explicit assertions are self-documenting

3. **Run fast** (<1ms per test)
   - Pure unit test, no database
   - No Room test infrastructure required

## Migration Safety Pattern

### Principles

1. **Purely Additive**
   - Only `ALTER TABLE ADD COLUMN`
   - Never `DROP`, `DELETE`, `TRUNCATE`, `RENAME COLUMN`

2. **Default Values**
   - Always provide sensible defaults
   - Ensures backward compatibility
   - Prevents `NULL` issues

3. **Error Handling**
   - Catch exceptions, log errors
   - Don't crash app on migration failure
   - Allow app to continue (graceful degradation)

4. **Comprehensive Testing**
   - 15+ unit tests per migration
   - Version numbers, SQL statements, safety checks
   - Follow existing migration test pattern

### Template

```kotlin
val MIGRATION_X_Y = object : Migration(X, Y) {
    override fun migrate(db: SupportSQLiteDatabase) {
        android.util.Log.d("Migration", "🔄 Starting migration $X → $Y")
        
        try {
            // Add new column with default value
            db.execSQL("""
                ALTER TABLE table_name
                ADD COLUMN new_column_name TYPE NOT NULL DEFAULT default_value
            """.trimIndent())
            
            android.util.Log.d("Migration", "  ✅ Added new_column_name column")
            android.util.Log.d("Migration", "✅ Migration $X → $Y completed successfully")
            
        } catch (e: Exception) {
            // Log error but don't throw - allow app to continue
            android.util.Log.e("Migration", "❌ Migration $X → $Y failed", e)
            android.util.Log.w("Migration", "⚠️ App will continue - feature may be degraded")
        }
    }
}
```

## Common Pitfalls

### ❌ Pitfall 1: Forgetting to Map New Fields

**Symptom**: Data silently lost during offline sync
**Example**: Added `Tournament.useSettingsDisplayNames` but forgot `TournamentEntity.useSettingsDisplayNames`
**Fix**: Follow 8-step checklist, write round-trip test

### ❌ Pitfall 2: Using Default Values in Tests

**Symptom**: Tests pass but data still lost in production
**Example**: Test uses `field = false` (default), doesn't catch missing mapping
**Fix**: Always use non-default values in round-trip tests

### ❌ Pitfall 3: Skipping Migration Tests

**Symptom**: Migration crashes app in production
**Example**: Forgot `NOT NULL`, migration fails on existing data
**Fix**: Write 15+ migration tests following established pattern

### ❌ Pitfall 4: Manual Field Tracking

**Symptom**: Developers forget which fields exist
**Example**: "Did we add `creatorEmail` to the entity?"
**Fix**: Round-trip tests are self-documenting - they show ALL fields

## Benefits of This Pattern

### 1. **Fails Fast**
- Compilation error if toEntity()/toDomainModel() missing field reference
- Test failure if field not mapped correctly
- No silent data loss in production

### 2. **Self-Documenting**
- Round-trip tests show which fields exist
- Migration tests show database schema evolution
- No need to manually track mappings

### 3. **Regression Prevention**
- Future field additions caught by existing tests
- Pattern ensures consistency across all entities
- Developers follow established workflow

### 4. **Fast Feedback**
- Tests run in <1ms (pure unit tests)
- No database setup required
- CI/CD validates every commit

## Example: TournamentEntity Mapping

### Before Fix (Missing Mappings)

```kotlin
// Tournament.kt
data class Tournament(
    val useSettingsDisplayNames: Boolean = false,
    // ... other fields
)

// TournamentEntity.kt - MISSING FIELD ❌
data class TournamentEntity(
    // useSettingsDisplayNames NOT DEFINED
    // ... other fields
)

// TournamentEntityMappings.kt - INCOMPLETE ❌
fun Tournament.toEntity(): TournamentEntity {
    return TournamentEntity(
        // useSettingsDisplayNames NOT MAPPED
        // ... other fields
    )
}
```

**Result**: Data loss during round-trip conversion

### After Fix (Complete Mappings)

```kotlin
// Tournament.kt
data class Tournament(
    val useSettingsDisplayNames: Boolean = false,
    // ... other fields
)

// TournamentEntity.kt - FIELD ADDED ✅
data class TournamentEntity(
    val useSettingsDisplayNames: Boolean = false,
    // ... other fields
)

// TournamentEntityMappings.kt - COMPLETE ✅
fun Tournament.toEntity(): TournamentEntity {
    return TournamentEntity(
        useSettingsDisplayNames = useSettingsDisplayNames,
        // ... other fields
    )
}

fun TournamentEntity.toDomainModel(): Tournament {
    return Tournament(
        useSettingsDisplayNames = useSettingsDisplayNames,
        // ... other fields
    )
}

// TournamentEntityMappingsTest.kt - REGRESSION TEST ✅
@Test
fun `round-trip conversion preserves useSettingsDisplayNames`() {
    val original = Tournament(useSettingsDisplayNames = true)
    val entity = original.toEntity()
    val roundTrip = entity.toDomainModel()
    assertThat(roundTrip.useSettingsDisplayNames).isTrue()
}
```

**Result**: All fields preserved, regression prevented

## Related Documentation

- [[Tournament Settings Persistence Bug]] - Real-world example of missing mappings
- [[Room Database Migrations]] - Database migration patterns
- [[Offline-First Architecture]] - Why entity mapping matters
- [[Testing Patterns]] - Test infrastructure and best practices

## Quick Reference

### When to Use This Pattern
- ✅ Any time a field is added to a persisted domain model
- ✅ When creating new entity/domain model pairs
- ✅ When refactoring existing entity mappings

### Files to Update (Example: Tournament)
1. `Tournament.kt` - Domain model
2. `TournamentEntity.kt` - Room entity
3. `TournamentEntityMappings.kt` - Bidirectional mappings
4. `MigrationXtoY.kt` - Database migration
5. `ArcheryDatabase.kt` - Version and migration registration
6. `TournamentEntityMappingsTest.kt` - Round-trip tests
7. `MigrationXtoYTest.kt` - Migration unit tests

### Test Files to Create
- `XxxEntityMappingsTest.kt` - Round-trip conversion tests (8+ tests)
- `MigrationXtoYTest.kt` - Migration safety tests (15+ tests)

#architecture #room-database #testing #patterns #regression-prevention #best-practices
