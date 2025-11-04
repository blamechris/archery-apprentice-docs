---
tags:
  - code-graph
  - patterns
  - best-practices
  - architecture
created: 2025-10-08
related:
  - "[[Architecture-Overview]]"
  - "[[Equipment-ViewModels]]"
  - "[[Scoring-ViewModels]]"
---

# Key Patterns

This document describes common architectural patterns used throughout the Archery Apprentice codebase. Following these patterns ensures consistency, maintainability, and testability.

---

## SaveResult Pattern

**Purpose**: Provide a type-safe, exhaustive way to handle operation results with validation and error states.

**Location**: `app/src/main/java/com/archeryapprentice/data/models/SaveResult.kt`

### Pattern Definition

```kotlin
sealed class SaveResult {
    /**
     * Indicates successful save operation
     */
    object Success : SaveResult()
    
    /**
     * Indicates failed save operation with specific error message
     * @param message User-friendly error message
     */
    data class Error(val message: String) : SaveResult()
    
    /**
     * Indicates validation failed before attempting save
     * @param message User-friendly validation error message
     */
    data class ValidationError(val message: String) : SaveResult()
}
```

### Extension Functions

```kotlin
fun SaveResult.isSuccess(): Boolean = this is SaveResult.Success
fun SaveResult.isError(): Boolean = this is SaveResult.Error || this is SaveResult.ValidationError
fun SaveResult.getErrorMessage(): String? = when (this) {
    is SaveResult.Error -> message
    is SaveResult.ValidationError -> message
    is SaveResult.Success -> null
}
```

### Usage in ViewModels

```kotlin
suspend fun saveArrow(): SaveResult {
    val state = _inputState.value
    
    // 1. Validate before attempting save
    if (!state.isValid()) {
        return SaveResult.ValidationError(
            state.getValidationError() ?: "Invalid input"
        )
    }
    
    // 2. Try to save, catching exceptions
    return try {
        val arrow = toArrow(state)
        if (state.isEditing) {
            repository.updateArrow(arrow)
        } else {
            repository.insertArrow(arrow)
        }
        clearInputs()
        loadArrows()
        SaveResult.Success  // Return success
    } catch (e: Exception) {
        SaveResult.Error("Failed to save arrow: ${e.message}")
    }
}
```

### Usage in UI

```kotlin
@Composable
fun SaveButton(viewModel: ArrowViewModel) {
    val scope = rememberCoroutineScope()
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showSuccess by remember { mutableStateOf(false) }
    
    Button(
        onClick = {
            scope.launch {
                when (val result = viewModel.saveArrow()) {
                    is SaveResult.Success -> {
                        showSuccess = true
                        errorMessage = null
                    }
                    is SaveResult.ValidationError -> {
                        errorMessage = result.message
                    }
                    is SaveResult.Error -> {
                        errorMessage = result.message
                    }
                }
            }
        }
    ) {
        Text("Save")
    }
    
    // Show error if present
    errorMessage?.let { message ->
        Text(
            text = message,
            color = MaterialTheme.colorScheme.error
        )
    }
}
```

### Benefits

✅ **Type Safety**: Compiler ensures all cases are handled
✅ **Explicit Errors**: Clear distinction between validation and runtime errors
✅ **User-Friendly**: Error messages designed for users
✅ **Testable**: Easy to test each outcome path
✅ **Exhaustive**: When expression ensures all cases handled

### Applied To

- All equipment save operations ([[Equipment-ViewModels]])
- Bow setup save operations
- Round creation operations
- Tournament creation operations
- Score submission operations

---

## Repository Pattern

**Purpose**: Abstract data sources and provide a clean API for data operations.

### Pattern Structure

```kotlin
// 1. Repository Interface (in domain layer)
interface MyRepository {
    fun getAll(): Flow<List<MyEntity>>
    suspend fun getById(id: Long): MyEntity?
    suspend fun insert(entity: MyEntity)
    suspend fun update(entity: MyEntity)
    suspend fun delete(entity: MyEntity)
}

// 2. Repository Implementation (in data layer)
class MyRepositoryImpl @Inject constructor(
    private val dao: MyDao
) : MyRepository {
    
    override fun getAll(): Flow<List<MyEntity>> = dao.getAll()
    
    override suspend fun getById(id: Long): MyEntity? = dao.getById(id)
    
    override suspend fun insert(entity: MyEntity) {
        // Business logic here
        dao.insert(entity)
    }
    
    override suspend fun update(entity: MyEntity) {
        dao.update(entity)
    }
    
    override suspend fun delete(entity: MyEntity) {
        dao.delete(entity)
    }
}

// 3. DAO (database layer)
@Dao
interface MyDao {
    @Query("SELECT * FROM my_table ORDER BY name ASC")
    fun getAll(): Flow<List<MyEntity>>
    
    @Query("SELECT * FROM my_table WHERE id = :id")
    suspend fun getById(id: Long): MyEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: MyEntity)
    
    @Update
    suspend fun update(entity: MyEntity)
    
    @Delete
    suspend fun delete(entity: MyEntity)
}
```

### Dependency Flow

```
ViewModel → Repository Interface → Repository Implementation → DAO → Database
```

**Example**:
```
ArrowViewModel → ArrowRepository → ArrowRepositoryImpl → ArrowDao → Room Database
```

### Benefits

✅ **Abstraction**: ViewModel doesn't know about data source
✅ **Testability**: Easy to mock repository in tests
✅ **Flexibility**: Can swap implementations (local, remote, hybrid)
✅ **Business Logic**: Centralized in repository
✅ **Single Responsibility**: Each layer has clear purpose

### Advanced: Multi-Source Repositories

Some repositories coordinate multiple data sources:

```kotlin
class TournamentRepository @Inject constructor(
    private val localDao: TournamentDao,
    private val firebaseService: FirebaseService,
    private val cacheService: CacheService
) {
    fun getTournament(id: String): Flow<Tournament> = flow {
        // 1. Check cache
        val cached = cacheService.get(id)
        if (cached != null) {
            emit(cached)
            return@flow
        }
        
        // 2. Check local database
        val local = localDao.getById(id)
        if (local != null) {
            emit(local)
            cacheService.put(id, local)
        }
        
        // 3. Fetch from Firebase
        val remote = firebaseService.getTournament(id)
        emit(remote)
        
        // 4. Save locally and cache
        localDao.insert(remote)
        cacheService.put(id, remote)
    }
}
```

### Applied To

- **Equipment**: All 10 component repositories
- **Scoring**: RoundRepository (1,443 lines - needs refactoring)
- **Tournament**: 3 implementations (Firebase, Offline, Hybrid)

**Learn More**: [[Equipment-Repositories]], [[Tournament-Repositories]]

---

## StateFlow Usage Pattern

**Purpose**: Expose reactive, observable state from ViewModel to UI using Kotlin Flow's StateFlow.

### Pattern Structure

```kotlin
@HiltViewModel
class MyViewModel @Inject constructor(
    private val repository: MyRepository
) : ViewModel() {
    
    // 1. Private mutable state (internal only)
    private val _uiState = MutableStateFlow(MyUiState())
    
    // 2. Public immutable state (exposed to UI)
    val uiState: StateFlow<MyUiState> = _uiState.asStateFlow()
    
    // 3. Update state internally
    fun updateData(newData: String) {
        _uiState.value = _uiState.value.copy(data = newData)
    }
    
    // 4. Load data from repository
    init {
        viewModelScope.launch {
            repository.getData().collect { data ->
                _uiState.value = _uiState.value.copy(items = data)
            }
        }
    }
}
```

### UI Observation

```kotlin
@Composable
fun MyScreen(viewModel: MyViewModel = hiltViewModel()) {
    // Collect StateFlow as Compose State
    val uiState by viewModel.uiState.collectAsState()
    
    // UI automatically recomposes when state changes
    Text(text = uiState.data)
    
    LazyColumn {
        items(uiState.items) { item ->
            ItemRow(item)
        }
    }
}
```

### State Classes

Define clear state data classes:

```kotlin
data class MyUiState(
    val isLoading: Boolean = false,
    val data: String = "",
    val items: List<Item> = emptyList(),
    val error: String? = null
)
```

### Benefits

✅ **Reactive**: UI automatically updates when state changes
✅ **Lifecycle-Aware**: Automatically handles lifecycle in Compose
✅ **Type-Safe**: Compile-time guarantees
✅ **Hot Stream**: Always has a value (unlike Flow)
✅ **Testable**: Easy to test state transitions

### Common StateFlow Patterns

#### 1. List State

```kotlin
private val _items = MutableStateFlow<List<Item>>(emptyList())
val items: StateFlow<List<Item>> = _items.asStateFlow()

fun loadItems() {
    viewModelScope.launch {
        repository.getItems().collect {
            _items.value = it
        }
    }
}
```

#### 2. Form Input State

```kotlin
private val _inputState = MutableStateFlow(InputState())
val inputState: StateFlow<InputState> = _inputState.asStateFlow()

fun updateField(value: String) {
    _inputState.value = _inputState.value.copy(field = value)
}
```

#### 3. Loading State

```kotlin
private val _isLoading = MutableStateFlow(false)
val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

suspend fun loadData() {
    _isLoading.value = true
    try {
        val data = repository.fetchData()
        _uiState.value = UiState.Success(data)
    } finally {
        _isLoading.value = false
    }
}
```

#### 4. Error State

```kotlin
private val _error = MutableStateFlow<String?>(null)
val error: StateFlow<String?> = _error.asStateFlow()

suspend fun performOperation() {
    try {
        repository.doSomething()
        _error.value = null
    } catch (e: Exception) {
        _error.value = e.message
    }
}
```

### Applied To

- **All Equipment ViewModels**: Items list + input state
- **Scoring ViewModels**: Session state, round state, scoring state
- **Tournament ViewModels**: Tournament list, details, leaderboard
- **Service Layer**: Sync status, conflict state, round state

**Learn More**: [[Equipment-ViewModels]], [[Scoring-ViewModels]]

---

## Copy-Delegate-Validate Pattern

**Purpose**: Safely extract complex logic from god classes (ViewModels) into services while maintaining all functionality.

**Origin**: Proven through [[TournamentSyncService-Extraction-Plan]] extraction (100% success rate)

### Pattern Steps

#### 1. Copy
Copy the method/logic to new service **without removing from original**:

```kotlin
// NEW SERVICE
@Singleton
class TournamentSyncService @Inject constructor(...) {
    // Copy exact implementation from ViewModel
    suspend fun setupTournamentSync(...) {
        // ... original logic copied here ...
    }
}
```

#### 2. Delegate
Update ViewModel to delegate to service (original method still exists):

```kotlin
// VIEWMODEL
@HiltViewModel  
class LiveScoringViewModel @Inject constructor(
    private val tournamentSyncService: TournamentSyncService  // NEW
) : ViewModel() {
    
    // Original method delegates to service
    fun setupTournamentSync(tournamentId: String) {
        viewModelScope.launch {
            tournamentSyncService.setupTournamentSync(tournamentId)
        }
    }
}
```

#### 3. Validate
Run comprehensive test suite:

```kotlin
// Test that delegation works
@Test
fun `setupTournamentSync delegates to service`() {
    viewModel.setupTournamentSync("tournament-id")
    
    verify(tournamentSyncService).setupTournamentSync("tournament-id")
}
```

#### 4. Delete (After Validation)
Only after all tests pass, remove original implementation:

```kotlin
// Remove original logic from ViewModel
// Keep delegation layer if needed for UI compatibility
```

### Benefits

✅ **Safe**: Original code stays intact during migration
✅ **Testable**: Can validate each step independently  
✅ **Reversible**: Easy to rollback if issues found
✅ **Incremental**: Extract one method at a time
✅ **Proven**: 100% success rate on 3 major extractions

### Success Metrics

**Applied To**:
- ✅ TournamentSyncService (556 lines extracted)
- ✅ ScoreConflictResolutionService (262 lines extracted)
- ✅ EndCompletionService (400 lines extracted)

**Results**:
- ✅ All 1,879 tests passing
- ✅ Zero regressions
- ✅ 18% ViewModel size reduction achieved

**Learn More**: [[LiveScoringVM-Analysis]], [[Implementation-Status-10-07-25]]

---

## Input State Pattern

**Purpose**: Encapsulate form input state with built-in validation.

### Pattern Structure

```kotlin
data class ComponentInputState(
    // Field values (always String for input)
    val brand: String = "",
    val model: String = "",
    val weight: String = "",
    
    // Editing state
    val isEditing: Boolean = false,
    val editingId: Long = 0
) {
    // Built-in validation
    fun isValid(): Boolean = 
        brand.isNotBlank() && model.isNotBlank()
    
    // Validation error messages
    fun getValidationError(): String? = when {
        brand.isBlank() -> "Brand is required"
        model.isBlank() -> "Model is required"
        else -> null
    }
}
```

### ViewModel Integration

```kotlin
class MyViewModel(...) : ViewModel() {
    private val _inputState = MutableStateFlow(ComponentInputState())
    val inputState: StateFlow<ComponentInputState> = _inputState.asStateFlow()
    
    fun updateBrand(value: String) {
        _inputState.value = _inputState.value.copy(brand = value)
    }
    
    suspend fun save(): SaveResult {
        val state = _inputState.value
        if (!state.isValid()) {
            return SaveResult.ValidationError(
                state.getValidationError() ?: "Invalid input"
            )
        }
        // ... save logic ...
    }
}
```

### UI Binding

```kotlin
@Composable
fun InputForm(viewModel: MyViewModel) {
    val inputState by viewModel.inputState.collectAsState()
    
    OutlinedTextField(
        value = inputState.brand,
        onValueChange = viewModel::updateBrand,
        label = { Text("Brand") },
        isError = inputState.brand.isBlank()
    )
}
```

### Benefits

✅ **Immutable**: State updates create new copies
✅ **Validated**: Validation logic co-located with state
✅ **Clear**: Single source of truth for form state
✅ **Testable**: Easy to test validation rules
✅ **Reusable**: Same pattern across all forms

### Applied To

- All equipment input forms (10 component types)
- Bow setup input form
- Round creation input form
- Tournament creation input form

---

## Hilt Dependency Injection Pattern

**Purpose**: Provide dependencies to ViewModels, Repositories, and Services automatically.

### ViewModels

```kotlin
@HiltViewModel
class MyViewModel @Inject constructor(
    private val repository: MyRepository
) : ViewModel()
```

Usage:
```kotlin
@Composable
fun MyScreen(viewModel: MyViewModel = hiltViewModel())
```

### Repositories

```kotlin
@Singleton
class MyRepository @Inject constructor(
    private val dao: MyDao
)
```

### Services

```kotlin
@Singleton
class MyService @Inject constructor(
    private val repository: MyRepository,
    private val serviceScope: CoroutineScope? = null
)
```

### Benefits

✅ **Automatic**: No manual instantiation needed
✅ **Testable**: Easy to provide test doubles
✅ **Scoped**: Singletons, ViewModelScoped, etc.
✅ **Type-Safe**: Compile-time dependency resolution

---

## Summary

### Core Patterns

| Pattern | Purpose | Applied To |
|---------|---------|------------|
| **SaveResult** | Type-safe operation results | All save operations |
| **Repository** | Data abstraction | All data access |
| **StateFlow** | Reactive state | All ViewModel state |
| **Copy-Delegate-Validate** | Safe refactoring | Service extractions |
| **Input State** | Form state management | All input forms |
| **Hilt DI** | Dependency injection | All components |

### Pattern Benefits

✅ **Consistency**: Same patterns throughout codebase
✅ **Testability**: Easy to test each pattern
✅ **Maintainability**: Clear, predictable structure
✅ **Type Safety**: Compile-time guarantees
✅ **Proven**: Battle-tested in production

### Learn More

- [[Architecture-Overview]] - Overall architecture
- [[Equipment-ViewModels]] - Pattern applications
- [[Scoring-ViewModels]] - Complex ViewModel patterns
- [[Tournament-Services]] - Service extraction patterns
- [[Tech-Debt]] - Areas needing pattern improvements

---

**Last Updated**: October 8, 2025
**Pattern Status**: ✅ Consistently applied across codebase
**Success Rate**: 100% (based on 3 major service extractions)
