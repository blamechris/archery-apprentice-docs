---
title: MVVM Architecture Patterns
tags:
  - architecture
  - mvvm
  - patterns
  - viewmodel
  - repository
created: 2025-10-08
---

# MVVM Architecture Patterns

## Overview

Archery Apprentice follows the MVVM (Model-View-ViewModel) architectural pattern, which provides clear separation of concerns and testability.

## Architecture Layers

### View Layer (UI)
**Technology:** Jetpack Compose

**Responsibilities:**
- Display UI components
- Handle user interactions
- Observe ViewModel state
- No business logic

**Patterns:**
- Composable functions for UI components
- State hoisting for reusability
- Preview functions for component testing

**Example:**
```kotlin
@Composable
fun FeatureScreen(
    viewModel: FeatureViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    // UI implementation
}
```

---

## ViewModel Layer

**Responsibilities:**
- Manage UI state
- Handle user actions
- Coordinate data flow from repositories
- Expose StateFlow/Flow to UI

**Patterns:**
- Use `StateFlow` over `LiveData` (project standard)
- Expose immutable state to UI
- Handle coroutines with `viewModelScope`
- Single source of truth for UI state

**Example:**
```kotlin
class FeatureViewModel @Inject constructor(
    private val repository: FeatureRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(FeatureUiState())
    val uiState: StateFlow<FeatureUiState> = _uiState.asStateFlow()
    
    fun handleAction(action: UserAction) {
        viewModelScope.launch {
            // Handle action
        }
    }
}
```

### Key ViewModels
- `RoundViewModel` - Round scoring and management ⚠️ (2,058 lines - needs refactoring)
- `LiveScoringViewModel` - Live scoring session management (1,753 lines)
- `EquipmentViewModel` - Equipment CRUD operations
- `TournamentViewModel` - Tournament management

---

## Repository Layer

**Responsibilities:**
- Abstract data sources (Room, network, preferences)
- Provide clean API to ViewModels
- Handle data mapping between layers
- Coordinate multiple data sources

**Patterns:**
- Repository pattern (single access point)
- Flow-based reactive data
- Error handling and mapping
- Optional caching layer

**Example:**
```kotlin
class FeatureRepository @Inject constructor(
    private val dao: FeatureDao,
    private val remoteDataSource: RemoteDataSource
) {
    fun getFeatures(): Flow<List<Feature>> = dao.getAllFeatures()
    
    suspend fun syncFeatures() {
        // Coordinate local and remote data
    }
}
```

### Key Repositories
- `RoundRepository` - Round data access
- `EquipmentRepository` - Equipment management
- `TournamentRepository` - Tournament operations
- `StatisticsRepository` - Performance analytics

---

## Data Layer (Model)

**Database:** Room

**Responsibilities:**
- Define data entities
- Database access through DAOs
- Data persistence
- Relationships and queries

**Patterns:**
- Room entities with proper annotations
- DAOs for database operations
- Type converters for complex types
- Database migrations

**Example:**
```kotlin
@Entity(tableName = "features")
data class FeatureEntity(
    @PrimaryKey val id: Long,
    val name: String,
    val timestamp: Long
)

@Dao
interface FeatureDao {
    @Query("SELECT * FROM features")
    fun getAllFeatures(): Flow<List<FeatureEntity>>
}
```

---

## Testing Strategy

### ViewModel Tests
- Mock repository dependencies with MockK
- Test state transitions
- Verify coroutine handling
- Use Turbine for Flow testing

### Repository Tests
- Use in-memory Room database
- Test data transformations
- Verify Flow emissions

### UI Tests
- Compose UI testing with `createComposeRule()`
- Unit tests with Robolectric (debug builds)
- Instrumented tests for integration

---

## Current Issues & Refactoring Needs

### God Classes 🚨
1. **RoundViewModel** (2,058 lines)
   - Extract statistics service
   - Separate scoring logic
   - Create dedicated use cases

2. **LiveScoringViewModel** (1,753 lines)
   - Extract tournament sync logic
   - Separate participant management

### Performance Optimizations 🚨
- Add database indexes for tournament queries
- Fix N+1 query issues in round loading
- Implement LRU caching for equipment data

---

## Best Practices

✅ **Do:**
- Use `StateFlow` for state management
- Keep ViewModels focused and testable
- Use repository pattern for data access
- Write tests following Given-When-Then structure
- Use MockK for mocking in tests

❌ **Don't:**
- Access database directly from ViewModels
- Put business logic in Composables
- Use `LiveData` (use `StateFlow` instead)
- Create god classes (keep files under 500 lines)

---

## Related Documentation
- [[Project-Overview/README|Project Overview]]
- [[Testing-Strategy|Testing Guidelines]]
- [[Performance-Optimization|Performance Guide]]
