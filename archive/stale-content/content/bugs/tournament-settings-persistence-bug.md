# Tournament Settings Persistence Bug Fix

**Date Discovered**: 2025-10-14  
**Date Fixed**: 2025-10-15  
**Severity**: HIGH (Production Blocker)  
**Status**: ✅ FIXED

## Problem

Tournament settings (specifically `useSettingsDisplayNames`) not persisting from tournament creation to the actual created tournament in Firebase.

### User-Visible Symptom
- User enables "Use Settings Display Names" toggle during tournament creation
- Toggle appears to save successfully  
- After tournament is created, setting reverts to `false` (disabled)
- No error message shown to user
- Silent data loss

### Technical Symptom
Debug logs revealed value changing during sync:
```
18:57:08.877  TournamentSettings: 📝 [Creation] Creating tournament with useSettingsDisplayNames=true
18:57:09.208  TournamentSettings: 🔥 [Firebase] Before .set() - useSettingsDisplayNames=false
```

Value changed from `true` → `false` in <350ms during the sync flow.

## Root Cause

### Offline-First Architecture Data Flow
The app uses an offline-first architecture where all data flows through Room database before syncing to Firebase:

```
TournamentCreationViewModel
  ↓ Tournament{useSettingsDisplayNames=true}
HybridTournamentRepository  
  ↓ tournament.toEntity()
Room Database (TournamentEntity)
  ↓ entity.toDomainModel()
HybridTournamentRepository
  ↓ Tournament{useSettingsDisplayNames=false}  ← BUG: Value lost!
FirebaseTournamentRepository
  ↓ .set() to Firestore
Firebase Firestore (wrong value persisted)
```

### The Missing Link

**TournamentEntity.kt** (Room database entity) was **missing field definitions**:
- `useSettingsDisplayNames` ❌
- `allowAnonymousParticipants` ❌  
- `creatorEmail` ❌
- `createdAtReadable` ❌
- `updatedAtReadable` ❌

When `tournament.toEntity()` was called, these fields were not mapped.  
When `entity.toDomainModel()` was called, Kotlin data class default values were used.

**Result**: Silent data loss during round-trip conversion (Domain → Entity → Domain)

### Why Silent Failure?

1. Room database doesn't validate that all domain model fields are persisted
2. No compilation error when entity is missing fields
3. Kotlin data class default values used during conversion
4. No integration test validating round-trip conversion
5. No user-visible error (data just silently lost)

## Solution

### Code Changes (6 files modified)

#### 1. **TournamentEntity.kt** (+5 fields, +11 lines)
Added missing field definitions to Room entity:
```kotlin
data class TournamentEntity(
    // ... existing fields ...

    val creatorEmail: String = "",
    val createdAtReadable: String = "",
    val updatedAtReadable: String = "",
    
    // ... existing fields ...
    
    val useSettingsDisplayNames: Boolean = false,
    val allowAnonymousParticipants: Boolean = true,
)
```

#### 2. **TournamentEntityMappings.kt** (+10 lines)
Updated bidirectional mapping functions:
```kotlin
// Tournament → TournamentEntity
fun Tournament.toEntity(): TournamentEntity {
    return TournamentEntity(
        // ... existing mappings ...
        creatorEmail = creatorEmail,
        createdAtReadable = createdAtReadable,
        updatedAtReadable = updatedAtReadable,
        useSettingsDisplayNames = useSettingsDisplayNames,
        allowAnonymousParticipants = allowAnonymousParticipants,
        // ... existing mappings ...
    )
}

// TournamentEntity → Tournament  
fun TournamentEntity.toDomainModel(): Tournament {
    return Tournament(
        // ... existing mappings ...
        creatorEmail = creatorEmail,
        createdAtReadable = createdAtReadable,
        updatedAtReadable = updatedAtReadable,
        useSettingsDisplayNames = useSettingsDisplayNames,
        allowAnonymousParticipants = allowAnonymousParticipants,
        // ... existing mappings ...
    )
}
```

#### 3. **Migration34to35.kt** (NEW FILE - 77 lines)
Database migration to add missing columns:
```kotlin
val MIGRATION_34_35 = object : Migration(34, 35) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // Add 5 missing columns with appropriate default values
        db.execSQL("ALTER TABLE tournaments ADD COLUMN useSettingsDisplayNames INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE tournaments ADD COLUMN allowAnonymousParticipants INTEGER NOT NULL DEFAULT 1")
        db.execSQL("ALTER TABLE tournaments ADD COLUMN creatorEmail TEXT NOT NULL DEFAULT ''")
        db.execSQL("ALTER TABLE tournaments ADD COLUMN createdAtReadable TEXT NOT NULL DEFAULT ''")
        db.execSQL("ALTER TABLE tournaments ADD COLUMN updatedAtReadable TEXT NOT NULL DEFAULT ''")
    }
}
```

**Migration Safety Features**:
- Purely additive (no DROP/DELETE/TRUNCATE)
- Default values for backward compatibility  
- Exception handling (logs errors, doesn't crash)
- Non-destructive to existing data

#### 4. **ArcheryDatabase.kt** (+5 lines)
Updated database version and registered migration:
```kotlin
@Database(
    entities = [/* ... */],
    version = 35,  // 34 → 35
    exportSchema = false
)
```

### Test Coverage (2 new test files, 24 tests)

#### **Migration34to35Test.kt** (NEW FILE - 328 lines, 16 tests)
Comprehensive unit tests for database migration:
- Version number validation (34→35)
- SQL statement execution (5 ALTER TABLE commands)
- Column types and default values
- Error handling and rollback safety
- Backward compatibility
- Non-destructive migration verification

#### **TournamentEntityMappingsTest.kt** (NEW FILE - 274 lines, 8 tests)
**CRITICAL REGRESSION PREVENTION TESTS**:

```kotlin
@Test
fun `round-trip conversion preserves all fields`() {
    // Given - Tournament with ALL fields populated
    val originalTournament = createTestTournament(
        useSettingsDisplayNames = true,
        allowAnonymousParticipants = false,
        creatorEmail = "user@example.com",
        // ... all other fields
    )
    
    // When - Convert to entity and back to domain
    val entity = originalTournament.toEntity()
    val roundTrip = entity.toDomainModel()
    
    // Then - ALL fields must survive round-trip
    assertThat(roundTrip.useSettingsDisplayNames).isTrue()
    assertThat(roundTrip.allowAnonymousParticipants).isFalse()
    assertThat(roundTrip.creatorEmail).isEqualTo("user@example.com")
    // ... all other field assertions
}
```

**Purpose**: Prevents future regression where new Tournament fields are added but not mapped to TournamentEntity.

## Impact

### Before Fix
- ❌ Tournament settings silently lost during creation
- ❌ Feature #5 (Tournament Guest Management) not functional
- ❌ Silent data loss (no error to user)
- ❌ Debug logs required to discover issue

### After Fix
- ✅ All tournament settings persist correctly
- ✅ Feature #5 now fully functional
- ✅ Round-trip conversion validated by tests
- ✅ Regression prevention tests ensure future safety

## Lessons Learned

### 1. ORM Mapping Silent Failures
**Problem**: Room doesn't validate that all domain model fields are persisted  
**Lesson**: Always write round-trip conversion tests

**Checklist for Future Entity Changes**:
1. ✅ Add field to domain model
2. ✅ Add field to @Entity class  
3. ✅ Update toEntity() mapping
4. ✅ Update toDomainModel() mapping
5. ✅ Create database migration
6. ✅ Update database version
7. ✅ **Write round-trip conversion test** (CRITICAL)
8. ✅ Write migration unit tests

### 2. Debug Logging Effectiveness
**Strategy**: Add logs at critical points in data flow (5 locations)  
**Result**: Logs immediately revealed exact point where data was lost  
**Time Saved**: ~2 hours of debugging

**Log Locations Added**:
- TournamentCreationViewModel: Before/after tournament creation
- FirebaseTournamentRepository: Before/after Firebase `.set()`
- TournamentDetailsViewModel: During settings dialog load and save

### 3. Integration Testing Gaps
**Gap**: No end-to-end test validating tournament creation with settings enabled  
**Recommendation**: Add E2E test for tournament creation flow

## Related Files

- `TournamentEntity.kt:21-70` - Room database entity
- `TournamentEntityMappings.kt` - Bidirectional mapping functions
- `Migration34to35.kt` - Database migration
- `TournamentCreationViewModel.kt:162-236` - Tournament creation logic
- `HybridTournamentRepository.kt` - Offline-first sync flow
- [[Room Database Migrations]]
- [[Offline-First Architecture]]
- [[Entity Mapping Patterns]]

## Prevention Pattern

### Entity Mapping Round-Trip Test Template
```kotlin
@Test
fun `round-trip conversion preserves all fields`() {
    val original = DomainModel(/* all fields populated */)
    val entity = original.toEntity()
    val roundTrip = entity.toDomainModel()
    
    // Assert ALL fields match
    assertThat(roundTrip).isEqualTo(original)
}
```

**Benefits**:
- Prevents silent data loss
- Fails fast when new fields added without mapping  
- Self-documenting (shows which fields exist)
- Runs in <1ms (unit test, no database)

#bug #tournament #room-database #persistence #fixed #regression-prevention #offline-first
