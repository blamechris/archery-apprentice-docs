---
title: "Feature Implementation Examples"
description: "Complete feature implementations from UI to database"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - code-examples
  - features
  - equipment
  - scoring
  - tournament
  - analytics
---

[Home](/) > [Technical Reference](../../) > [Code Examples](../) > Feature Examples

---

# Feature Implementation Examples

This guide provides complete, end-to-end feature implementations showing how all architectural layers work together. Each example demonstrates the full stack from Compose UI through ViewModel, Repository, to Room database.

---

## Overview

Feature examples demonstrate:
- **Complete vertical slices** - UI → ViewModel → Repository → DAO → Database
- **Real production code** - Actual implementations from Archery Apprentice
- **Layer integration** - How patterns compose across MVVM layers
- **Best practices** - State management, error handling, testing

---

## 1. Equipment Management Feature

Complete CRUD implementation for archery equipment with soft-delete and validation.

### Architecture Overview

```
UI (Compose)
    ↓ StateFlow observation
ViewModel
    ↓ Coroutine calls
Repository
    ↓ Suspend functions
DAO
    ↓ SQL queries
Room Database
```

### Data Model

**Entity:**
```kotlin
@Entity(tableName = "arrows")
data class Arrow(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val brand: String,
    val model: String,
    val length: String,      // inches
    val weight: String,      // grains
    val diameter: String,    // inches
    val spine: String,       // 500, 600, etc.
    val quantity: Int = 1,
    val identifier: String = "",
    val pointName: String = "",
    val pointWeight: String = "",
    val nockName: String = "",
    val nockWeight: String = "",
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)
```

**Input State (ViewModel):**
```kotlin
data class ArrowInputState(
    val brand: String = "",
    val model: String = "",
    val length: String = "",
    val weight: String = "",
    val diameter: String = "",
    val spine: String = "",
    val quantity: String = "1",
    val identifier: String = "",
    val pointName: String = "",
    val pointWeight: String = "",
    val nockName: String = "",
    val nockWeight: String = "",
    val notes: String = "",
    val isEditing: Boolean = false,
    val editingId: Long = 0
) {
    fun isValid(): Boolean {
        return brand.isNotBlank() && model.isNotBlank()
    }

    fun getValidationError(): String {
        return when {
            brand.isBlank() -> "Brand is required"
            model.isBlank() -> "Model is required"
            else -> ""
        }
    }

    fun toArrow(): Arrow {
        return Arrow(
            id = if (isEditing) editingId else 0,
            brand = brand.trim(),
            model = model.trim(),
            length = length.trim(),
            weight = weight.trim(),
            diameter = diameter.trim(),
            spine = spine.trim(),
            quantity = quantity.toIntOrNull() ?: 1,
            identifier = identifier.trim(),
            pointName = pointName.trim(),
            pointWeight = pointWeight.trim(),
            nockName = nockName.trim(),
            nockWeight = nockWeight.trim(),
            notes = notes.trim(),
            updatedAt = System.currentTimeMillis()
        )
    }
}
```

### DAO Layer

**File:** `app/src/main/java/com/archeryapprentice/data/dao/ArrowDao.kt`

```kotlin
@Dao
interface ArrowDao {
    // Read operations
    @Query("SELECT * FROM arrows ORDER BY brand ASC, model ASC")
    fun getAll(): Flow<List<Arrow>>

    @Query("SELECT * FROM arrows WHERE id = :id")
    suspend fun getById(id: Long): Arrow?

    @Query("SELECT * FROM arrows WHERE brand LIKE '%' || :search || '%' OR model LIKE '%' || :search || '%'")
    fun searchArrows(search: String): Flow<List<Arrow>>

    // Write operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(arrow: Arrow): Long

    @Update
    suspend fun update(arrow: Arrow)

    @Delete
    suspend fun delete(arrow: Arrow)

    // Bulk operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(arrows: List<Arrow>)

    @Query("DELETE FROM arrows")
    suspend fun deleteAll()

    // Statistics
    @Query("SELECT COUNT(*) FROM arrows")
    suspend fun getCount(): Int
}
```

### Repository Layer

**File:** `app/src/main/java/com/archeryapprentice/domain/repository/ArrowRepository.kt`

```kotlin
class ArrowRepository @Inject constructor(
    private val arrowDao: ArrowDao
) {
    // Reactive data access
    fun getAllArrows(): Flow<List<Arrow>> = arrowDao.getAll()

    fun searchArrows(query: String): Flow<List<Arrow>> = arrowDao.searchArrows(query)

    // Single item access
    suspend fun getArrowById(id: Long): Arrow? = arrowDao.getById(id)

    // CRUD operations
    suspend fun insertArrow(arrow: Arrow): Long {
        return arrowDao.insert(arrow)
    }

    suspend fun updateArrow(arrow: Arrow) {
        val updated = arrow.copy(updatedAt = System.currentTimeMillis())
        arrowDao.update(updated)
    }

    suspend fun deleteArrow(arrow: Arrow) {
        arrowDao.delete(arrow)
    }

    // Bulk operations
    suspend fun insertAll(arrows: List<Arrow>) {
        arrowDao.insertAll(arrows)
    }

    suspend fun deleteAll() {
        arrowDao.deleteAll()
    }

    // Statistics
    suspend fun getArrowCount(): Int = arrowDao.getCount()
}
```

### ViewModel Layer

**File:** `app/src/main/java/com/archeryapprentice/ui/equipment/viewModels/ArrowViewModel.kt`

```kotlin
@HiltViewModel
class ArrowViewModel @Inject constructor(
    private val repository: ArrowRepository
) : ViewModel() {

    // Observable state for UI
    private val _arrows = MutableStateFlow<List<Arrow>>(emptyList())
    val arrows: StateFlow<List<Arrow>> = _arrows.asStateFlow()

    private val _inputState = MutableStateFlow(ArrowInputState())
    val inputState: StateFlow<ArrowInputState> = _inputState.asStateFlow()

    private val _saveResult = MutableStateFlow<SaveResult?>(null)
    val saveResult: StateFlow<SaveResult?> = _saveResult.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Search state
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    init {
        loadArrows()
    }

    // Load arrows with search
    private fun loadArrows() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                if (_searchQuery.value.isBlank()) {
                    repository.getAllArrows().collect { arrowList ->
                        _arrows.value = arrowList
                        _isLoading.value = false
                    }
                } else {
                    repository.searchArrows(_searchQuery.value).collect { arrowList ->
                        _arrows.value = arrowList
                        _isLoading.value = false
                    }
                }
            } catch (e: Exception) {
                _isLoading.value = false
                _saveResult.value = SaveResult.Error("Failed to load arrows: ${e.message}")
            }
        }
    }

    // Save arrow (create or update)
    suspend fun saveArrow(): SaveResult {
        val state = _inputState.value

        // Validate input
        if (!state.isValid()) {
            val result = SaveResult.ValidationError(state.getValidationError())
            _saveResult.value = result
            return result
        }

        return try {
            val arrow = state.toArrow()

            if (state.isEditing) {
                repository.updateArrow(arrow)
            } else {
                repository.insertArrow(arrow)
            }

            clearInputs()
            val result = SaveResult.Success
            _saveResult.value = result
            result
        } catch (e: Exception) {
            val result = SaveResult.Error("Failed to save: ${e.message}")
            _saveResult.value = result
            result
        }
    }

    // Delete arrow
    fun deleteArrow(arrow: Arrow) {
        viewModelScope.launch {
            try {
                repository.deleteArrow(arrow)
                _saveResult.value = SaveResult.Success
            } catch (e: Exception) {
                _saveResult.value = SaveResult.Error("Failed to delete: ${e.message}")
            }
        }
    }

    // Load arrow for editing
    fun loadArrowForEdit(id: Long) {
        viewModelScope.launch {
            try {
                val arrow = repository.getArrowById(id)
                if (arrow != null) {
                    _inputState.value = ArrowInputState(
                        brand = arrow.brand,
                        model = arrow.model,
                        length = arrow.length,
                        weight = arrow.weight,
                        diameter = arrow.diameter,
                        spine = arrow.spine,
                        quantity = arrow.quantity.toString(),
                        identifier = arrow.identifier,
                        pointName = arrow.pointName,
                        pointWeight = arrow.pointWeight,
                        nockName = arrow.nockName,
                        nockWeight = arrow.nockWeight,
                        notes = arrow.notes,
                        isEditing = true,
                        editingId = arrow.id
                    )
                }
            } catch (e: Exception) {
                _saveResult.value = SaveResult.Error("Failed to load arrow: ${e.message}")
            }
        }
    }

    // Input field updates
    fun updateBrand(value: String) {
        _inputState.value = _inputState.value.copy(brand = value)
    }

    fun updateModel(value: String) {
        _inputState.value = _inputState.value.copy(model = value)
    }

    fun updateLength(value: String) {
        _inputState.value = _inputState.value.copy(length = value)
    }

    fun updateWeight(value: String) {
        _inputState.value = _inputState.value.copy(weight = value)
    }

    fun updateSpine(value: String) {
        _inputState.value = _inputState.value.copy(spine = value)
    }

    fun updateNotes(value: String) {
        _inputState.value = _inputState.value.copy(notes = value)
    }

    // Search
    fun updateSearchQuery(query: String) {
        _searchQuery.value = query
        loadArrows()
    }

    // Clear inputs
    fun clearInputs() {
        _inputState.value = ArrowInputState()
    }

    // Clear save result
    fun clearSaveResult() {
        _saveResult.value = null
    }
}
```

### UI Layer (Compose)

**File:** `app/src/main/java/com/archeryapprentice/ui/equipment/screens/ArrowInputScreen.kt`

```kotlin
@Composable
fun ArrowInputScreen(
    viewModel: ArrowViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val inputState by viewModel.inputState.collectAsState()
    val arrows by viewModel.arrows.collectAsState()
    val saveResult by viewModel.saveResult.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    val scope = rememberCoroutineScope()

    // Handle save result
    LaunchedEffect(saveResult) {
        when (saveResult) {
            is SaveResult.Success -> {
                // Could show snackbar or navigate
                viewModel.clearSaveResult()
            }
            is SaveResult.Error -> {
                // Show error dialog
            }
            is SaveResult.ValidationError -> {
                // Show validation error
            }
            null -> { /* No result */ }
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Top app bar
        TopAppBar(
            title = { Text(if (inputState.isEditing) "Edit Arrow" else "Add Arrow") },
            navigationIcon = {
                IconButton(onClick = onNavigateBack) {
                    Icon(Icons.Default.ArrowBack, "Back")
                }
            }
        )

        // Input form
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(16.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Brand field
            OutlinedTextField(
                value = inputState.brand,
                onValueChange = viewModel::updateBrand,
                label = { Text("Brand *") },
                isError = inputState.brand.isBlank(),
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Model field
            OutlinedTextField(
                value = inputState.model,
                onValueChange = viewModel::updateModel,
                label = { Text("Model *") },
                isError = inputState.model.isBlank(),
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Length field
            OutlinedTextField(
                value = inputState.length,
                onValueChange = viewModel::updateLength,
                label = { Text("Length (inches)") },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Spine field
            OutlinedTextField(
                value = inputState.spine,
                onValueChange = viewModel::updateSpine,
                label = { Text("Spine (e.g., 500, 600)") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Notes field
            OutlinedTextField(
                value = inputState.notes,
                onValueChange = viewModel::updateNotes,
                label = { Text("Notes") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Save button
            Button(
                onClick = {
                    scope.launch {
                        viewModel.saveArrow()
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = inputState.isValid()
            ) {
                Text(if (inputState.isEditing) "Update Arrow" else "Save Arrow")
            }

            if (inputState.isEditing) {
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedButton(
                    onClick = { viewModel.clearInputs() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Cancel Edit")
                }
            }
        }

        // Divider
        HorizontalDivider()

        // Arrow list section
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(16.dp)
        ) {
            // Search bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = viewModel::updateSearchQuery,
                label = { Text("Search arrows") },
                leadingIcon = { Icon(Icons.Default.Search, "Search") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Loading indicator
            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else {
                // Arrow list
                LazyColumn {
                    items(arrows, key = { it.id }) { arrow ->
                        ArrowListItem(
                            arrow = arrow,
                            onEdit = { viewModel.loadArrowForEdit(arrow.id) },
                            onDelete = { viewModel.deleteArrow(arrow) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ArrowListItem(
    arrow: Arrow,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "${arrow.brand} ${arrow.model}",
                    style = MaterialTheme.typography.titleMedium
                )
                if (arrow.spine.isNotBlank()) {
                    Text("Spine: ${arrow.spine}", style = MaterialTheme.typography.bodySmall)
                }
                if (arrow.length.isNotBlank()) {
                    Text("Length: ${arrow.length}\"", style = MaterialTheme.typography.bodySmall)
                }
            }

            Row {
                IconButton(onClick = onEdit) {
                    Icon(Icons.Default.Edit, "Edit")
                }
                IconButton(onClick = onDelete) {
                    Icon(Icons.Default.Delete, "Delete")
                }
            }
        }
    }
}
```

### Key Takeaways

**State Flow:**
1. User input → ViewModel updates `_inputState`
2. ViewModel validates → Returns `SaveResult`
3. Repository performs database operation
4. DAO observes changes via Flow
5. UI automatically updates via `collectAsState()`

**Error Handling:**
- Validation before save (client-side)
- Try-catch around database operations
- SaveResult sealed class for type-safe results
- User-friendly error messages in UI

**Reactive Updates:**
- Room Flow emits on database changes
- StateFlow propagates to UI
- Automatic recomposition in Compose

---

## 2. Tournament Integration Feature

Complete offline-first tournament workflow with Firebase sync.

### Architecture Overview

```
UI (Compose)
    ↓
ViewModel
    ↓
HybridTournamentRepository (Offline-first)
    ├─→ OfflineTournamentRepository (Local)
    │       ↓
    │   TournamentDao (Room)
    │
    └─→ FirebaseTournamentRepository (Remote)
            ↓
        Firestore
```

### Key Components

**1. Repository Interface**

```kotlin
interface TournamentRepository {
    // Observe tournaments
    fun getPublicTournaments(): Flow<List<Tournament>>
    fun observeTournament(tournamentId: TournamentId): Flow<Tournament?>

    // Join tournament
    suspend fun joinTournament(
        tournamentId: TournamentId,
        userId: String
    ): Result<Unit>

    // Create round for tournament
    suspend fun createTournamentRound(
        tournamentId: TournamentId,
        round: Round
    ): Result<RoundId>

    // Sync scores
    suspend fun syncArrowScore(
        tournamentId: TournamentId,
        participantId: String,
        score: ArrowScore
    ): Result<Unit>

    // Cleanup
    fun cleanup()
}
```

**2. Hybrid Repository (Offline-First)**

```kotlin
class HybridTournamentRepository(
    private val offlineRepo: OfflineTournamentRepository,
    private val firebaseRepo: FirebaseTournamentRepository,
    private val networkMonitor: NetworkMonitor,
    private val syncScope: CoroutineScope  // Injected scope for background sync
) : TournamentRepository {

    override fun getPublicTournaments(): Flow<List<Tournament>> = flow {
        // 1. Emit local data immediately (offline-first)
        emitAll(offlineRepo.getPublicTournaments())

        // 2. Sync with Firebase in background (if online)
        if (networkMonitor.isConnected) {
            try {
                val remoteTournaments = firebaseRepo.getPublicTournaments().first()
                // Update local cache
                remoteTournaments.forEach { tournament ->
                    offlineRepo.upsertTournament(tournament)
                }
            } catch (e: Exception) {
                // Local data already emitted, silent failure acceptable
                android.util.Log.e("HybridRepo", "Firebase sync failed", e)
            }
        }
    }

    override suspend fun joinTournament(
        tournamentId: TournamentId,
        userId: String
    ): Result<Unit> {
        return try {
            // 1. Save to local database first (immediate response)
            offlineRepo.joinTournament(tournamentId, userId).getOrThrow()

            // 2. Sync to Firebase (with retry on failure)
            if (networkMonitor.isConnected) {
                firebaseRepo.joinTournament(tournamentId, userId).getOrThrow()
            } else {
                // Queue for later sync
                queueForSync(SyncAction.JoinTournament(tournamentId, userId))
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun syncArrowScore(
        tournamentId: TournamentId,
        participantId: String,
        score: ArrowScore
    ): Result<Unit> {
        return try {
            // 1. Save locally first (immediate UI update)
            offlineRepo.saveArrowScore(tournamentId, participantId, score)

            // 2. Sync to Firebase in background
            if (networkMonitor.isConnected) {
                syncScope.launch {
                    retryWithExponentialBackoff {
                        firebaseRepo.syncArrowScore(tournamentId, participantId, score)
                    }
                }
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Exponential backoff retry
    private suspend fun retryWithExponentialBackoff(
        maxAttempts: Int = 5,
        initialDelay: Long = 1000L,
        block: suspend () -> Result<Unit>
    ): Result<Unit> {
        var attempt = 0
        var delay = initialDelay

        while (attempt < maxAttempts) {
            val result = block()
            if (result.isSuccess) return result

            attempt++
            if (attempt < maxAttempts) {
                delay(delay)
                delay *= 2  // Exponential backoff: 1s, 2s, 4s, 8s, 16s
            }
        }

        return Result.failure(Exception("Max retry attempts exceeded"))
    }
}
```

**Important: Repository Scope Injection**

Repositories should **never** use `viewModelScope` directly. This violates MVVM architectural layering:

- ❌ **Wrong:** `viewModelScope.launch { /* background work */ }` in repository
- ✅ **Correct:** Inject a `CoroutineScope` into the repository constructor

**Why?**
- Repositories belong to the **data layer**, ViewModels belong to the **presentation layer**
- Data layer should not depend on presentation layer (maintains clean architecture)
- Injected scope allows proper lifecycle management and testing

**Implementation:**
```kotlin
// In repository constructor (shown above):
class HybridTournamentRepository(
    /* ... other dependencies ... */
    private val syncScope: CoroutineScope  // ✅ Injected scope
)

// In Hilt module:
@Provides
@Singleton
fun provideSyncScope(): CoroutineScope {
    return CoroutineScope(Dispatchers.IO + SupervisorJob())
}
```

---

**3. Tournament Sync Service**

**File:** `app/src/main/java/com/archeryapprentice/domain/services/TournamentSyncService.kt`

```kotlin
@Singleton
class TournamentSyncService @Inject constructor(
    private val firestore: FirebaseFirestore,
    private val repository: TournamentRepository,
    private val networkMonitor: NetworkMonitor
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val listenerJobs = mutableMapOf<String, Job>()

    // Setup real-time listeners for tournament
    fun observeTournamentState(tournamentId: String): Flow<TournamentState> = callbackFlow {
        val listener = firestore
            .collection("tournaments")
            .document(tournamentId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    trySend(TournamentState.Error(error))
                    return@addSnapshotListener
                }

                if (snapshot != null && snapshot.exists()) {
                    val tournament = snapshot.toObject<Tournament>()
                    if (tournament != null) {
                        trySend(TournamentState.Active(tournament))
                    }
                } else {
                    trySend(TournamentState.NotFound)
                }
            }

        awaitClose { listener.remove() }
    }

    // Observe leaderboard updates
    fun observeLeaderboard(tournamentId: String): Flow<List<LeaderboardEntry>> = callbackFlow {
        val listener = firestore
            .collection("tournaments/$tournamentId/leaderboard")
            .orderBy("currentScore", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    android.util.Log.e("TournamentSync", "Leaderboard error", error)
                    return@addSnapshotListener
                }

                if (snapshot != null) {
                    val entries = snapshot.toObjects<LeaderboardEntry>()
                    trySend(entries)
                }
            }

        awaitClose { listener.remove() }
    }

    // Cleanup all listeners
    fun cleanup() {
        listenerJobs.values.forEach { it.cancel() }
        listenerJobs.clear()
    }
}

sealed class TournamentState {
    data class Active(val tournament: Tournament) : TournamentState()
    object NotFound : TournamentState()
    data class Error(val error: Exception) : TournamentState()
}
```

**4. ViewModel Integration**

```kotlin
@HiltViewModel
class TournamentViewModel @Inject constructor(
    private val repository: TournamentRepository,
    private val syncService: TournamentSyncService
) : ViewModel() {

    private val _tournaments = MutableStateFlow<List<Tournament>>(emptyList())
    val tournaments: StateFlow<List<Tournament>> = _tournaments.asStateFlow()

    private val _joinResult = MutableStateFlow<Result<Unit>?>(null)
    val joinResult: StateFlow<Result<Unit>?> = _joinResult.asStateFlow()

    private val _leaderboard = MutableStateFlow<List<LeaderboardEntry>>(emptyList())
    val leaderboard: StateFlow<List<LeaderboardEntry>> = _leaderboard.asStateFlow()

    init {
        loadTournaments()
    }

    private fun loadTournaments() {
        viewModelScope.launch {
            repository.getPublicTournaments().collect { tournamentList ->
                _tournaments.value = tournamentList
            }
        }
    }

    fun joinTournament(tournamentId: String, userId: String) {
        viewModelScope.launch {
            _joinResult.value = repository.joinTournament(
                TournamentId(tournamentId),
                userId
            )
        }
    }

    fun observeLeaderboard(tournamentId: String) {
        viewModelScope.launch {
            syncService.observeLeaderboard(tournamentId).collect { entries ->
                _leaderboard.value = entries
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        syncService.cleanup()
    }
}
```

### Key Takeaways

**Offline-First Strategy:**
1. Always save to local database first (immediate UI response)
2. Sync to Firebase in background (with retry)
3. Local data is source of truth
4. Firebase provides multi-device sync

**Error Handling:**
- Exponential backoff for network failures
- Silent failures for background sync
- User-visible errors for critical operations
- Queue failed syncs for retry

**Real-Time Updates:**
- Firestore snapshot listeners
- Flow-based reactive updates
- Automatic UI refresh on remote changes

---

## 3. Analytics Calculation Feature

Complete statistics computation from raw scores to displayed metrics.

### Architecture Overview

```
UI (Analytics Screen)
    ↓
RoundAnalyticsViewModel
    ↓
StatisticsCalculationService
    ↓
RoundRepository (fetches scores)
    ↓
Room Database
```

### Statistics Calculation Service

**File:** `app/src/main/java/com/archeryapprentice/domain/services/StatisticsCalculationService.kt`

```kotlin
@Singleton
class StatisticsCalculationService @Inject constructor() {

    // Calculate round statistics
    fun calculateRoundStatistics(
        ends: List<EndWithArrowScores>
    ): RoundStatistics {
        val allArrows = ends.flatMap { it.arrowScores }
        val totalScore = allArrows.sumOf { it.score }
        val arrowCount = allArrows.size
        val endCount = ends.size

        val xCount = allArrows.count { it.isXRing }
        val tenCount = allArrows.count { it.score == 10 }

        return RoundStatistics(
            totalScore = totalScore,
            averagePerArrow = if (arrowCount > 0) totalScore.toDouble() / arrowCount else 0.0,
            averagePerEnd = if (endCount > 0) totalScore.toDouble() / endCount else 0.0,
            xCount = xCount,
            tenCount = tenCount,
            arrowCount = arrowCount,
            endCount = endCount,
            accuracy = calculateAccuracy(totalScore, arrowCount, maxScore = 10),
            ringDistribution = calculateRingDistribution(allArrows)
        )
    }

    // Calculate accuracy percentage
    private fun calculateAccuracy(
        totalScore: Int,
        arrowCount: Int,
        maxScore: Int
    ): Double {
        if (arrowCount == 0) return 0.0
        val maxPossible = arrowCount * maxScore
        return (totalScore.toDouble() / maxPossible) * 100.0
    }

    // Calculate ring distribution (how many in each ring)
    private fun calculateRingDistribution(
        arrows: List<ArrowScore>
    ): Map<Int, Int> {
        return arrows.groupingBy { it.score }.eachCount()
    }

    // Calculate fatigue (performance drop in later ends)
    fun calculateFatigue(
        ends: List<EndWithArrowScores>
    ): FatigueMetrics {
        if (ends.size < 3) {
            return FatigueMetrics(
                earlyAverage = 0.0,
                lateAverage = 0.0,
                performanceDrop = 0.0,
                fatigueDetected = false
            )
        }

        // Early ends: first 1/3
        val earlyEndCount = (ends.size / 3).coerceAtLeast(1)
        val earlyEnds = ends.take(earlyEndCount)

        // Late ends: last 1/3
        val lateEndCount = (ends.size / 3).coerceAtLeast(1)
        val lateEnds = ends.takeLast(lateEndCount)

        val earlyAverage = calculateAverageEndScore(earlyEnds)
        val lateAverage = calculateAverageEndScore(lateEnds)

        val performanceDrop = earlyAverage - lateAverage
        val fatigueDetected = performanceDrop > (earlyAverage * 0.05) // > 5% drop

        return FatigueMetrics(
            earlyAverage = earlyAverage,
            lateAverage = lateAverage,
            performanceDrop = performanceDrop,
            performanceDropPercentage = if (earlyAverage > 0) {
                (performanceDrop / earlyAverage) * 100.0
            } else 0.0,
            fatigueDetected = fatigueDetected
        )
    }

    private fun calculateAverageEndScore(ends: List<EndWithArrowScores>): Double {
        if (ends.isEmpty()) return 0.0

        val totalScore = ends.sumOf { end ->
            end.arrowScores.sumOf { it.score }
        }

        return totalScore.toDouble() / ends.size
    }

    // Calculate shot grouping (requires target coordinates)
    fun calculateShotGrouping(
        arrowScores: List<ArrowScore>
    ): ShotGroupingMetrics? {
        // Filter arrows with coordinates
        val arrowsWithCoords = arrowScores.filter { it.targetX != null && it.targetY != null }

        if (arrowsWithCoords.size < 5) {
            return null // Not enough data for meaningful grouping
        }

        val centerX = arrowsWithCoords.map { it.targetX!! }.average()
        val centerY = arrowsWithCoords.map { it.targetY!! }.average()

        // Calculate radial distances from center
        val radialDistances = arrowsWithCoords.map { arrow ->
            val dx = arrow.targetX!! - centerX
            val dy = arrow.targetY!! - centerY
            sqrt(dx * dx + dy * dy)
        }

        val radialSD = calculateStandardDeviation(radialDistances)

        // Calculate eccentricity (how "stretched" the group is)
        val xVariance = calculateVariance(arrowsWithCoords.map { it.targetX!! })
        val yVariance = calculateVariance(arrowsWithCoords.map { it.targetY!! })
        val eccentricity = if (yVariance > 0) xVariance / yVariance else 1.0

        return ShotGroupingMetrics(
            centerX = centerX,
            centerY = centerY,
            radialStandardDeviation = radialSD,
            eccentricity = eccentricity,
            arrowCount = arrowsWithCoords.size
        )
    }

    private fun calculateStandardDeviation(values: List<Double>): Double {
        if (values.isEmpty()) return 0.0
        val mean = values.average()
        val variance = values.map { (it - mean).pow(2) }.average()
        return sqrt(variance)
    }

    private fun calculateVariance(values: List<Double>): Double {
        if (values.isEmpty()) return 0.0
        val mean = values.average()
        return values.map { (it - mean).pow(2) }.average()
    }
}

// Data classes
data class RoundStatistics(
    val totalScore: Int,
    val averagePerArrow: Double,
    val averagePerEnd: Double,
    val xCount: Int,
    val tenCount: Int,
    val arrowCount: Int,
    val endCount: Int,
    val accuracy: Double,
    val ringDistribution: Map<Int, Int>
)

data class FatigueMetrics(
    val earlyAverage: Double,
    val lateAverage: Double,
    val performanceDrop: Double,
    val performanceDropPercentage: Double = 0.0,
    val fatigueDetected: Boolean
)

data class ShotGroupingMetrics(
    val centerX: Double,
    val centerY: Double,
    val radialStandardDeviation: Double,
    val eccentricity: Double,
    val arrowCount: Int
)
```

### ViewModel Integration

```kotlin
@HiltViewModel
class RoundAnalyticsViewModel @Inject constructor(
    private val roundRepository: RoundRepository,
    private val statisticsService: StatisticsCalculationService
) : ViewModel() {

    private val _statistics = MutableStateFlow<RoundStatistics?>(null)
    val statistics: StateFlow<RoundStatistics?> = _statistics.asStateFlow()

    private val _fatigueMetrics = MutableStateFlow<FatigueMetrics?>(null)
    val fatigueMetrics: StateFlow<FatigueMetrics?> = _fatigueMetrics.asStateFlow()

    private val _groupingMetrics = MutableStateFlow<ShotGroupingMetrics?>(null)
    val groupingMetrics: StateFlow<ShotGroupingMetrics?> = _groupingMetrics.asStateFlow()

    fun loadAnalytics(roundId: Int) {
        viewModelScope.launch {
            try {
                val roundWithDetails = roundRepository.getRoundWithDetails(roundId)

                if (roundWithDetails != null) {
                    // Calculate basic statistics
                    _statistics.value = statisticsService.calculateRoundStatistics(
                        roundWithDetails.ends
                    )

                    // Calculate fatigue
                    _fatigueMetrics.value = statisticsService.calculateFatigue(
                        roundWithDetails.ends
                    )

                    // Calculate shot grouping (if coordinates available)
                    val allArrows = roundWithDetails.ends.flatMap { it.arrowScores }
                    _groupingMetrics.value = statisticsService.calculateShotGrouping(allArrows)
                }
            } catch (e: Exception) {
                android.util.Log.e("Analytics", "Failed to load analytics", e)
            }
        }
    }
}
```

### UI Display

```kotlin
@Composable
fun AnalyticsScreen(
    roundId: Int,
    viewModel: RoundAnalyticsViewModel = hiltViewModel()
) {
    val statistics by viewModel.statistics.collectAsState()
    val fatigueMetrics by viewModel.fatigueMetrics.collectAsState()
    val groupingMetrics by viewModel.groupingMetrics.collectAsState()

    LaunchedEffect(roundId) {
        viewModel.loadAnalytics(roundId)
    }

    Column(modifier = Modifier.padding(16.dp)) {
        // Basic statistics
        statistics?.let { stats ->
            StatisticsCard(
                title = "Round Statistics",
                items = listOf(
                    "Total Score" to "${stats.totalScore}",
                    "Average per Arrow" to "%.2f".format(stats.averagePerArrow),
                    "Accuracy" to "%.1f%%".format(stats.accuracy),
                    "X-Count" to "${stats.xCount}",
                    "10-Count" to "${stats.tenCount}"
                )
            )

            Spacer(modifier = Modifier.height(16.dp))
        }

        // Fatigue analysis
        fatigueMetrics?.let { fatigue ->
            FatigueCard(
                earlyAverage = fatigue.earlyAverage,
                lateAverage = fatigue.lateAverage,
                performanceDrop = fatigue.performanceDropPercentage,
                fatigueDetected = fatigue.fatigueDetected
            )

            Spacer(modifier = Modifier.height(16.dp))
        }

        // Shot grouping
        groupingMetrics?.let { grouping ->
            GroupingCard(
                radialSD = grouping.radialStandardDeviation,
                eccentricity = grouping.eccentricity,
                arrowCount = grouping.arrowCount
            )
        }
    }
}
```

### Key Takeaways

**Statistics Flow:**
1. Fetch raw scores from database
2. Transform to domain models
3. Apply calculation algorithms
4. Cache results in StateFlow
5. Display in UI with formatting

**Performance Optimization:**
- Calculate statistics once, cache in StateFlow
- Use suspend functions for heavy computation
- Process on background thread (IO dispatcher)

---

## Related Documentation

- [Common Patterns](../Common-Patterns/) - Reusable code patterns
- [Testing Examples](../Testing-Examples/) - How to test features
- [Code Examples Index](../) - Overview of all examples
- [System Flows](../../Flows/System-Flows/) - Architecture flows

---

**Last Updated:** 2025-11-04
**Features Documented:** 3 complete implementations (Equipment CRUD, Tournament Integration, Analytics Calculation)
