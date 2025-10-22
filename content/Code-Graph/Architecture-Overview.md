---
tags:
  - architecture
  - code-graph
  - layers
  - mvvm
created: 2025-10-08
related:
  - "[[README]]"
  - "[[Architecture]]"
  - "[[Key-Patterns]]"
---

# Architecture Overview

Archery Apprentice follows a **Clean Architecture** approach with **MVVM (Model-View-ViewModel)** pattern and **Repository Pattern** for data access.

## Layered Architecture

```
┌─────────────────────────────────────────┐
│         UI Layer (Compose)              │
│  - Screens & Composables                │
│  - Navigation                            │
│  - User Input Handling                   │
└────────────┬────────────────────────────┘
             │ observes StateFlow
             ↓
┌─────────────────────────────────────────┐
│      ViewModel Layer (State)            │
│  - State Management (StateFlow)         │
│  - Business Logic Coordination          │
│  - UI State Transformation              │
└────────────┬────────────────────────────┘
             │ calls methods
             ↓
┌─────────────────────────────────────────┐
│    Repository Layer (Business Logic)    │
│  - Data Operations                       │
│  - Business Rules                        │
│  - Multi-Source Coordination            │
└────────────┬────────────────────────────┘
             │ queries / writes
             ↓
┌─────────────────────────────────────────┐
│     Database Layer (Room DAOs)          │
│  - SQL Queries                           │
│  - Transactions                          │
│  - Data Persistence                      │
└─────────────────────────────────────────┘
```

---

## UI Layer (Composables)

**Purpose**: Present data and handle user interactions using Jetpack Compose.

### Key Screens

#### Equipment Screens
- `BowSetupDetailScreen.kt` - Equipment setup management
- `EquipmentListScreen.kt` - Equipment inventory
- Component-specific screens for each equipment type

#### Scoring Screens
- `ActiveScoringScreen.kt` (1,958 lines) - Live scoring interface
- `RoundDetailsScreen.kt` - Round history and statistics
- `RoundCreationScreen.kt` - Create new rounds

#### Tournament Screens
- `TournamentDiscoveryScreen.kt` - Browse tournaments
- `TournamentDetailsScreen.kt` - Tournament info and leaderboard
- `LiveLeaderboardCard.kt` - Real-time rankings

### Navigation
- `AppNavigation.kt` - Main navigation graph
- `TournamentNavGraph.kt` - Tournament sub-navigation

### Pattern
```kotlin
@Composable
fun MyScreen(viewModel: MyViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()
    
    // UI reacts to state changes
    when (state) {
        is UiState.Loading -> LoadingIndicator()
        is UiState.Success -> SuccessContent(state.data)
        is UiState.Error -> ErrorMessage(state.message)
    }
}
```

**Learn More**: [[UI-Layer-Patterns]]

---

## ViewModel Layer (State Management)

**Purpose**: Manage UI state, coordinate business logic, and expose data streams to UI.

### ViewModels by Feature

#### 1. Equipment ViewModels (13 total)
→ See [[Equipment-ViewModels]] for details

**Component ViewModels**:
- `ArrowViewModel` → uses `ArrowRepository`
- `StabilizerViewModel` → uses `StabilizerRepository`
- `SightViewModel` → uses `SightRepository`
- `RiserViewModel` → uses `RiserRepository`
- `LimbsViewModel` → uses `LimbsRepository`
- `BowStringViewModel` → uses `BowStringRepository`
- `PlungerViewModel` → uses `PlungerRepository`
- `RestViewModel` → uses `RestRepository`
- `AccessoryViewModel` → uses `AccessoryRepository`
- `WeightViewModel` → uses `WeightRepository`

**Setup ViewModels**:
- `BowSetupViewModel` → uses `BowSetupRepository`
- `EquipmentListViewModel` → coordinates equipment display

#### 2. Scoring ViewModels (8 total)
→ See [[Scoring-ViewModels]] for details

**Distributed Architecture** (Extracted from 3,000-line monolith):
- `RoundViewModel` (2,079 lines) - Core orchestration
- `LiveScoringViewModel` (2,304 lines) - Active scoring (being refactored)
- `RoundCreationViewModel` (480 lines) - Round setup ✅
- `RoundAnalyticsViewModel` (605 lines) - Statistics ✅
- `RoundManagementViewModel` (495 lines) - Round lifecycle ✅
- `RoundDisplayViewModel` (216 lines) - UI formatting ✅
- `RoundNavigationViewModel` (192 lines) - Navigation ✅
- `RoundScoringViewModel` (187 lines) - Scoring logic ✅

#### 3. Tournament ViewModels (3 total)
→ See [[Tournament-ViewModels]] for details

- `TournamentDiscoveryViewModel` → uses `TournamentRepository`
- `TournamentDetailsViewModel` → uses `TournamentRepository`
- `TournamentCreationViewModel` → uses `TournamentRepository`

#### 4. Other ViewModels
- `AuthenticationViewModel` → uses `AuthenticationRepository`
- `SettingsViewModel` → uses `SettingsRepository`

### Common ViewModel Pattern
```kotlin
@HiltViewModel
class MyViewModel @Inject constructor(
    private val repository: MyRepository
) : ViewModel() {
    
    // State exposed to UI
    private val _uiState = MutableStateFlow(MyUiState())
    val uiState: StateFlow<MyUiState> = _uiState.asStateFlow()
    
    // Input state for forms
    private val _inputState = MutableStateFlow(InputState())
    val inputState: StateFlow<InputState> = _inputState.asStateFlow()
    
    // Methods called by UI
    fun updateField(value: String) {
        _inputState.value = _inputState.value.copy(field = value)
    }
    
    suspend fun save(): SaveResult {
        // Validate, call repository, handle result
    }
}
```

**Learn More**: [[ViewModel-Patterns]]

---

## Repository Layer (Business Logic)

**Purpose**: Abstract data sources, implement business rules, coordinate between multiple data sources.

### Repositories by Feature

#### Equipment Repositories (10 total)
→ See [[Equipment-Repositories]] for details

- `ArrowRepository` - Arrow CRUD operations
- `StabilizerRepository` - Stabilizer CRUD operations
- `SightRepository` - Sight CRUD operations
- `RiserRepository` - Riser CRUD operations
- `LimbsRepository` - Limbs CRUD operations
- `BowStringRepository` - Bow string CRUD operations
- `PlungerRepository` - Plunger CRUD operations
- `RestRepository` - Rest CRUD operations
- `AccessoryRepository` - Accessory CRUD operations
- `WeightRepository` - Weight CRUD operations
- `BowSetupRepository` - Bow setup coordination
- `EquipmentStatsRepository` - Equipment statistics

#### Scoring Repositories
→ See [[Scoring-Repositories]] for details

- `RoundRepository` (1,443 lines) - Round and score operations
  - **Issue**: God class - should be split into 3 repositories
  - See [[Checkpoint-Findings]] for refactoring plan

#### Tournament Repositories (3 implementations)
→ See [[Tournament-Repositories]] for details

**Interface**: `TournamentRepository` (395 lines, 51 methods)
- **Issue**: Interface too large (should have ~15 methods)

**Implementations**:
1. `FirebaseTournamentRepository` (1,707 lines) - Firestore-based
2. `OfflineTournamentRepository` (908 lines) - Local-only
3. `HybridTournamentRepository` (1,506 lines) - Offline-first with sync

**Factory**: `RepositoryFactory` - Creates appropriate repository based on mode

### Common Repository Pattern
```kotlin
class MyRepository @Inject constructor(
    private val dao: MyDao
) {
    // Return Flow for observable data
    fun getAll(): Flow<List<MyEntity>> = dao.getAll()
    
    // Suspend functions for one-time operations
    suspend fun insert(entity: MyEntity)
    suspend fun update(entity: MyEntity)
    suspend fun delete(entity: MyEntity)
    suspend fun getById(id: Long): MyEntity?
}
```

**Learn More**: [[Repository-Patterns]]

---

## Database Layer (Room DAOs)

**Purpose**: Provide type-safe SQL queries and transaction management using Room.

### DAOs by Feature

#### Equipment DAOs
- `ArrowDao` - Arrow queries
- `StabilizerDao` - Stabilizer queries
- `SightDao` - Sight queries
- `RiserDao` - Riser queries
- `LimbsDao` - Limbs queries
- `BowStringDao` - Bow string queries
- `PlungerDao` - Plunger queries
- `RestDao` - Rest queries
- `AccessoryDao` - Accessory queries
- `WeightDao` - Weight queries
- `BowSetupDao` - Bow setup queries

#### Scoring DAOs
- `RoundDao` - Round queries
- `EndScoreDao` - End score queries
- `ArrowScoreDao` - Arrow score queries

#### Tournament DAOs
- `TournamentScoreCacheDao` - Score caching queries

### Common DAO Pattern
```kotlin
@Dao
interface MyDao {
    // Observable queries return Flow
    @Query("SELECT * FROM my_table ORDER BY name ASC")
    fun getAll(): Flow<List<MyEntity>>
    
    // One-time queries
    @Query("SELECT * FROM my_table WHERE id = :id")
    suspend fun getById(id: Long): MyEntity?
    
    // Modifications
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: MyEntity)
    
    @Update
    suspend fun update(entity: MyEntity)
    
    @Delete
    suspend fun delete(entity: MyEntity)
}
```

### Database Migrations
- **Current Version**: 31
- **Migration Path**: `Migration_30_31.kt` - Added tournament score cache
- See [[Tech-Debt]] for database optimization opportunities

**Learn More**: [[Database-Patterns]]

---

## Service Layer (Extracted Services)

**Purpose**: Extract complex business logic from ViewModels to improve testability and maintainability.

### Tournament Services
→ See [[Tournament-Services]] for details

**Extracted from LiveScoringViewModel** (2,808 → 2,304 lines):
1. `TournamentSyncService` (556 lines) - Firebase sync ✅
2. `ScoreConflictResolutionService` (262 lines) - Conflict resolution ✅
3. `EndCompletionService` (400 lines) - End finalization ✅
4. `TournamentRoundLifecycleService` (~200 lines) - Round lifecycle ⏳ TODO
5. `StatisticsAggregationService` (~150 lines) - Statistics ⏳ TODO

**Pattern**: See [[TournamentSyncService-Extraction-Plan]] for proven extraction pattern

### Common Service Pattern
```kotlin
@Singleton
class MyService @Inject constructor(
    private val repository: MyRepository,
    private val serviceScope: CoroutineScope? = null
) {
    private val scope = serviceScope ?: CoroutineScope(SupervisorJob())
    
    // StateFlows for observable state
    private val _state = MutableStateFlow(MyState())
    val state: StateFlow<MyState> = _state.asStateFlow()
    
    // Public API
    suspend fun doOperation(...) { ... }
    
    // Cleanup
    fun cleanup() { ... }
}
```

**Learn More**: [[Service-Patterns]]

---

## Dependency Injection (Hilt)

All components use **Hilt** for dependency injection:

```kotlin
// ViewModels
@HiltViewModel
class MyViewModel @Inject constructor(...) : ViewModel()

// Repositories  
@Singleton
class MyRepository @Inject constructor(...)

// Services
@Singleton  
class MyService @Inject constructor(...)
```

---

## Data Flow Example

Here's how data flows through the layers for a typical operation:

### Example: Saving an Arrow

```
1. UI Layer (ActiveScoringScreen.kt)
   User clicks "Save Arrow"
   ↓
2. ViewModel Layer (ArrowViewModel)
   suspend fun saveArrow(): SaveResult
   → Validates input
   → Calls repository
   ↓
3. Repository Layer (ArrowRepository)
   suspend fun insertArrow(arrow: Arrow)
   → Applies business rules
   → Calls DAO
   ↓
4. Database Layer (ArrowDao)
   @Insert suspend fun insert(arrow: Arrow)
   → Executes SQL
   → Persists to Room database
   ↓
5. Observation (Flow)
   fun getAll(): Flow<List<Arrow>>
   ← Emits updated list
   ↑
6. ViewModel Updates State
   loadArrows() observes Flow
   → Updates _arrows StateFlow
   ↑
7. UI Reacts
   val arrows by viewModel.arrows.collectAsState()
   → Composable recomposes with new data
```

---

## Cross-Cutting Concerns

### Coroutines & Flow
- **ViewModelScope**: Used in ViewModels for lifecycle-aware operations
- **StateFlow**: Exposes observable state to UI
- **Flow**: Used by DAOs for reactive data

### Error Handling
- **SaveResult Pattern**: See [[Key-Patterns#SaveResult-Pattern]]
- Validation at ViewModel layer
- Try-catch at Repository layer
- User-friendly error messages to UI

### Caching
- **Tournament Score Cache**: 5-10x performance improvement
- Status-aware TTL (30s for active, indefinite for completed)
- See [[Phase2-Completion-Summary]]

---

## Navigation Map

- **Layer Details**:
  - [[UI-Layer-Patterns]]
  - [[ViewModel-Patterns]]
  - [[Repository-Patterns]]
  - [[Database-Patterns]]
  - [[Service-Patterns]]

- **Feature Areas**:
  - [[Equipment-ViewModels]]
  - [[Scoring-ViewModels]]
  - [[Tournament-ViewModels]]
  - [[Equipment-Repositories]]
  - [[Scoring-Repositories]]
  - [[Tournament-Repositories]]
  - [[Tournament-Services]]

- **Patterns**:
  - [[Key-Patterns]]

- **Architecture Docs**:
  - [[Architecture]] - Comprehensive architecture guide
  - [[Tech-Debt]] - Known architectural issues
  - [[LiveScoringVM-Analysis]] - God class analysis
  - [[Checkpoint-Findings]] - Architecture audit findings

---

**Last Updated**: October 8, 2025
**Database Version**: 31
**Total Lines of Code**: ~50,000+ (estimated)
**Architecture Status**: Clean Architecture with known refactoring opportunities
