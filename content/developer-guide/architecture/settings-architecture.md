# Settings Architecture

## Overview

The Archery Apprentice app uses a centralized settings system built on Android Room database with reactive StateFlow propagation. Settings are stored as a single-row entity with real-time updates propagated throughout the application.

**Last Updated**: 2025-10-11  
**Related Files**:
- Data Model: `app/src/main/java/com/archeryapprentice/data/models/Settings.kt`
- DAO: `app/src/main/java/com/archeryapprentice/data/dao/SettingsDao.kt`
- ViewModel: `app/src/main/java/com/archeryapprentice/ui/settings/SettingsViewModel.kt`
- UI: `app/src/main/java/com/archeryapprentice/ui/settings/SettingsPage.kt`

---

## Architecture Components

### 1. Data Model Layer

#### Settings.kt (Entity)

```kotlin
@Entity(tableName = "settings")
data class Settings(
    @PrimaryKey val id: Int = 1, // Single-row pattern
    val measurementSystem: MeasurementSystem,
    val targetZoomMode: TargetZoomMode = TargetZoomMode.NO_ZOOM,
    val stayZoomedDuringEnd: Boolean = false,
    val userName: String = "",
    val autoOpenVS: Boolean = false,
    val autoCloseOnEndComplete: Boolean = false,
    val defaultBowSetupId: Long? = null // NEW: Default equipment setup
)
```

**Design Pattern**: Single-row singleton (id = 1)
- Simplifies access (no need to query by user)
- Works with device-local settings model
- Default values provided for all fields

#### Enum Types

**MeasurementSystem**:
- `METRIC` - Meters, centimeters
- `IMPERIAL` - Yards, feet, inches
- `BOTH` - Display both units

**TargetZoomMode**:
- `NO_ZOOM` - Always show full target face
- `CONDITIONAL_ZOOM` - Zoom based on score value
- `ALWAYS_ZOOM` - Always zoom to scoring rings

---

### 2. Data Access Layer

#### SettingsDao.kt

```kotlin
@Dao
interface SettingsDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun updateSettings(settings: Settings)

    @Query("SELECT * FROM settings WHERE id = 1")
    fun getSettings(): Flow<Settings?>
}
```

**Key Features**:
- **Flow-based**: Reactive updates propagate automatically
- **REPLACE strategy**: Upsert behavior for single-row entity
- **Null safety**: Returns `Flow<Settings?>` - null on first launch

---

### 3. ViewModel Layer

#### SettingsViewModel.kt

**Responsibilities**:
- Expose settings as StateFlows
- Provide update methods for each setting
- Handle default value initialization

**StateFlow Exposure Pattern**:
```kotlin
val settings: StateFlow<Settings> = settingsDao.getSettings()
    .map { it ?: Settings(measurementSystem = MeasurementSystem.METRIC) }
    .stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = Settings(measurementSystem = MeasurementSystem.METRIC)
    )

// Derived StateFlows for individual settings
val userName: StateFlow<String> = settings
    .map { it.userName }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), "")
```

**Update Pattern**:
```kotlin
fun setUserName(name: String) {
    viewModelScope.launch {
        val currentSettings = settings.value
        settingsDao.updateSettings(
            currentSettings.copy(userName = name)
        )
    }
}
```

**Key Patterns**:
- **Copy-and-replace**: Immutable Settings with `copy()` for updates
- **Derived StateFlows**: Individual settings exposed as separate StateFlows
- **5-second timeout**: StateFlow subscriptions kept alive for 5s after last subscriber

---

### 4. UI Layer

#### SettingsPage.kt (Jetpack Compose)

**Current Settings Sections**:

1. **Measurement System**
   - Dropdown (3 options: Metric, Imperial, Both)
   - Affects distance/target size display throughout app

2. **User Settings**
   - Text field for userName
   - Max 24 alphanumeric characters
   - Used for tournament display names (when enabled)

3. **Target Zoom Settings**
   - Zoom mode dropdown
   - Conditional "stay zoomed during end" toggle (only visible if zoom enabled)

4. **Auto-Open/Close Settings**
   - Auto-open VS (Viewing Screen) toggle
   - Auto-close on end complete toggle

5. **Equipment Settings** (NEW)
   - Default bow setup dropdown
   - Links to saved equipment configurations

6. **Other**
   - Data Repair button
   - Change Theme button

**Validation Rules**:
- `userName`: 24 char max, alphanumeric + underscore only
- Input filtering applied on `onValueChange`

---

## Settings Propagation Flow

### How Settings Reach Components

```
User Input (SettingsPage)
    ↓
ViewModel.setUserName()
    ↓
SettingsDao.updateSettings()
    ↓
Room Database Update
    ↓
Flow Emission (automatic)
    ↓
StateFlow Collectors Update
    ↓
UI Recomposition (Compose)
```

### Example: Username Update Flow

1. **User types** in SettingsPage `OutlinedTextField`
2. **onValueChange** calls `viewModel.setUserName(newName)`
3. **ViewModel** launches coroutine to update settings
4. **DAO** writes updated Settings to Room (REPLACE strategy)
5. **Room** emits new value to `getSettings()` Flow
6. **StateFlow** receives and emits new `userName` value
7. **All collectors** (SettingsPage, UserIdentityResolver, etc.) receive update
8. **UI recomposes** with new value

**Latency**: Typically < 100ms for local database roundtrip

---

## Integration Points

### 1. Tournament Display Names

**Component**: `UserIdentityResolver.kt`

**Current Logic** (Priority Order):
1. Firebase authenticated user → Firebase displayName or email
2. Settings.userName (if Firebase user absent)
3. "Anonymous User" (fallback)

**NEW: Tournament-Level Override** (when `TournamentSettings.useSettingsDisplayNames = true`):
1. Settings.userName (forced priority)
2. Firebase displayName (fallback if userName blank)
3. "Anonymous User" (final fallback)

**Usage**:
```kotlin
val userIdentity = UserIdentityResolver.resolveUserIdentity(
    firebaseUser = currentUser,
    settings = settings,
    forceSettingsUserName = tournament.settings.useSettingsDisplayNames
)

val participant = TournamentParticipant(
    participantId = userIdentity.id,
    displayName = userIdentity.displayName // Uses settings-based name
)
```

### 2. Equipment Tracking

**Component**: Bow Setup Attribution

**Settings.defaultBowSetupId**:
- Links to `BowSetup.id` (foreign key relationship)
- Auto-populated when joining tournaments
- Enables equipment performance analytics

**Usage**:
```kotlin
val defaultSetupId = settingsViewModel.defaultBowSetupId.value
val participant = TournamentParticipant(
    bowSetupId = defaultSetupId // Equipment attribution
)
```

### 3. Target Zoom Behavior

**Component**: Active Scoring Screen

**Settings Used**:
- `targetZoomMode`: Determines zoom behavior
- `stayZoomedDuringEnd`: Whether to remain zoomed between arrows

**Integration**: Real-time updates to scoring UI zoom state

### 4. Measurement Display

**Component**: Round Configuration, Analytics

**Settings.measurementSystem**:
- Affects distance display (meters vs yards)
- Target size display (cm vs inches)
- Statistics presentation

---

## State Management Patterns

### StateFlow vs LiveData

**Why StateFlow?**
- Consistent with Kotlin Coroutines
- Better Compose integration
- Explicit initial values
- Structural concurrency support

**Pattern**:
```kotlin
// Collect in Composable
val userName by viewModel.userName.collectAsState()

// Collect in ViewModel
viewModelScope.launch {
    settingsViewModel.userName.collect { name ->
        // React to changes
    }
}
```

### Single Source of Truth

**Settings Database** = Single Source of Truth
- All components read from Settings StateFlows
- No local caching (StateFlow handles caching)
- Updates automatically propagate

---

## Tournament Settings Architecture

### Separate from User Settings

**TournamentSettings** (Firestore):
- Stored per-tournament in Firestore
- Controlled by tournament creator
- Affects all tournament participants

**User Settings** (Room):
- Stored locally on device
- User-controlled
- Can be referenced by tournaments (via display name override)

### AdminSettings Subcomponent

```kotlin
data class AdminSettings(
    val requireRegistrationApproval: Boolean = false,
    val allowSelfRegistration: Boolean = true,
    val maxParticipants: Int = 50,
    val allowGuestParticipants: Boolean = true,
    val maxGuestsPerParticipant: Int = 2,
    val maxTotalGuests: Int = 10,
    val useSettingsDisplayNames: Boolean = false // NEW: User preference override
)
```

**Creator vs Participant Control**:
- Tournament **creator** sets `useSettingsDisplayNames` toggle
- All **participants** use their own `Settings.userName` when true
- Creator control ensures consistency across tournament

---

## Settings Storage Details

### Database Schema

**Table**: `settings`

| Column | Type | Constraints | Default |
|--------|------|-------------|---------|
| id | INTEGER | PRIMARY KEY | 1 |
| measurementSystem | TEXT | NOT NULL | "METRIC" |
| targetZoomMode | TEXT | NOT NULL | "NO_ZOOM" |
| stayZoomedDuringEnd | INTEGER (BOOL) | NOT NULL | 0 |
| userName | TEXT | NOT NULL | "" |
| autoOpenVS | INTEGER (BOOL) | NOT NULL | 0 |
| autoCloseOnEndComplete | INTEGER (BOOL) | NOT NULL | 0 |
| defaultBowSetupId | INTEGER | NULLABLE | NULL |

**Migration Strategy**:
- New columns added via Room migrations
- Default values ensure backward compatibility
- Single row (id=1) simplifies migration logic

### Performance Characteristics

**Read Performance**:
- Single-row query: < 10ms
- Flow observation: No performance cost (observes database changes)

**Write Performance**:
- REPLACE operation: < 20ms
- Automatic Flow emission: < 5ms additional latency

**Memory Footprint**:
- Single Settings object: ~200 bytes
- StateFlow overhead: ~1KB per flow

---

## Common Use Cases

### 1. Reading a Setting in Compose UI

```kotlin
@Composable
fun MyScreen(settingsViewModel: SettingsViewModel) {
    val measurementSystem by settingsViewModel.measurementSystem.collectAsState()
    
    Text("Distance: ${formatDistance(distance, measurementSystem)}")
}
```

### 2. Updating a Setting

```kotlin
// From ViewModel
settingsViewModel.setUserName("Archer123")

// From Composable
OutlinedTextField(
    value = currentUserName,
    onValueChange = { settingsViewModel.setUserName(it) }
)
```

### 3. Observing Setting Changes in ViewModel

```kotlin
init {
    viewModelScope.launch {
        settingsViewModel.defaultBowSetupId.collect { setupId ->
            // Update UI or trigger actions based on setup change
            loadEquipmentStats(setupId)
        }
    }
}
```

### 4. Conditional Logic Based on Settings

```kotlin
val settings by settingsViewModel.settings.collectAsState()

when (settings.targetZoomMode) {
    TargetZoomMode.NO_ZOOM -> renderFullTarget()
    TargetZoomMode.CONDITIONAL_ZOOM -> renderConditionalZoom()
    TargetZoomMode.ALWAYS_ZOOM -> renderZoomedTarget()
}
```

---

## Testing Approach

### Unit Tests

**SettingsDao Test**:
- Insert/update operations
- Flow emission verification
- Default value handling

**SettingsViewModel Test**:
- StateFlow derivation correctness
- Update method behavior
- Concurrent modification handling

### Integration Tests

**Settings Propagation Test**:
- Update setting → verify UI recomposition
- Verify cross-component propagation (e.g., userName → tournament display)

**Migration Test**:
- Verify database migrations preserve data
- Test default value application for new columns

---

## Future Enhancements

### Planned Features

1. **Cloud Sync** (Firebase Remote Config)
   - Backup settings to user account
   - Sync across devices

2. **Settings Import/Export**
   - JSON export for backup
   - Import from other devices

3. **Advanced Tournament Preferences**
   - Per-tournament measurement system override
   - Quick settings presets

4. **Profile Settings**
   - Archer profile management
   - Multiple user profiles per device

---

## Related Documentation

- [[target-face-visualization]] - Target zoom settings integration
- [[tournament-participant-flow]] - Display name resolution
- [[equipment-statistics]] - Bow setup tracking
- [[database-schema]] - Settings table structure

---

## Troubleshooting

### Issue: Settings not persisting
**Cause**: DAO not properly injected or database initialization failed  
**Solution**: Verify Hilt DI graph, check database inspector

### Issue: StateFlow not updating UI
**Cause**: Missing `collectAsState()` or composition issue  
**Solution**: Ensure StateFlow collected with `collectAsState()` in Composable

### Issue: userName validation failing
**Cause**: Non-alphanumeric characters or length > 24  
**Solution**: Apply input filter in `onValueChange`: `it.all { char -> char.isLetterOrDigit() || char == '_' } && it.length <= 24`

---

*Generated: 2025-10-11*  
*Architecture Status: Stable with planned enhancements*