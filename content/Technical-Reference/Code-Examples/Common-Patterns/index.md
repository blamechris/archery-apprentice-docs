---
title: "Common Code Patterns"
description: "Frequently used patterns throughout the codebase"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - code-examples
  - patterns
  - repository
  - stateflow
  - coroutines
  - compose
---

[Home](/) > [Technical Reference](../../) > [Code Examples](../) > Common Patterns

---

# Common Code Patterns

This guide documents frequently used code patterns throughout the Archery Apprentice codebase. These patterns represent tested, production-ready approaches to common development tasks.

---

## Overview

All examples in this guide are taken directly from the archery-apprentice codebase and follow these principles:

- **Consistency** - Patterns used across multiple features
- **Testability** - Designed for unit and integration testing
- **Maintainability** - Clear separation of concerns
- **Performance** - Optimized for Android and KMP

---

## 1. Repository Pattern

Repositories abstract data access and provide a clean API for ViewModels to interact with data sources.

### Basic Repository Structure

**Pattern:** Constructor injection of DAOs, Flow for reactive data, suspend functions for operations.

```kotlin
class BowSetupRepository(
    private val bowSetupDao: BowSetupDao,
    private val riserDao: RiserDao,
    private val limbsDao: LimbsDao,
    // ... other DAOs
) {
    // Flow for reactive lists - UI automatically updates
    fun getAllBowSetups(): Flow<List<BowSetup>> =
        bowSetupDao.getAllActiveBowSetups()

    // Flow for single item observation
    fun getBowSetupFlow(id: Long): Flow<BowSetup?> =
        bowSetupDao.getBowSetupFlow(id)

    // Suspend for single operations
    suspend fun getBowSetupById(id: Long): BowSetup? =
        bowSetupDao.getBowSetupById(id)

    suspend fun insertBowSetup(bowSetup: BowSetup): Long =
        bowSetupDao.insertBowSetup(bowSetup)

    suspend fun updateBowSetup(bowSetup: BowSetup) =
        bowSetupDao.updateBowSetup(bowSetup)
}
```

**When to use:** All data access should go through repositories, never directly to DAOs from ViewModels.

### Repository with Business Logic

**Pattern:** Complex operations with multiple DAOs, helper methods, transactions.

```kotlin
class RoundRepository(
    private val roundDao: RoundDao,
    private val bowSetupRepository: BowSetupRepository
) {
    // Basic CRUD
    suspend fun insertRound(round: Round): Long = roundDao.insertRound(round)

    fun getAllRounds(): Flow<List<Round>> = roundDao.getAllRounds()

    // Complex operation with business logic
    suspend fun getRoundWithDetails(roundId: Int): RoundWithDetails? {
        val round = roundDao.getRoundById(roundId) ?: return null

        val bowSetup = if (round.bowSetupId > 0) {
            bowSetupRepository.getBowSetupWithEquipment(round.bowSetupId)
        } else null

        val endWithArrowData = roundDao.getEndsWithArrowsForRound(roundId)
        val ends = groupEndWithArrowData(endWithArrowData)

        return RoundWithDetails(round, bowSetup, ends)
    }

    // Transaction ensures atomicity
    @Transaction
    suspend fun recordCompletedEndAndAdvance(
        roundId: Int,
        participantId: String,
        endNumber: Int,
        arrowScores: List<Int>
    ): Int? {
        // 1. Validate round state
        val round = roundDao.getRoundById(roundId) ?: return null

        // 2. Create end record
        val end = End(/* ... */)
        val endId = roundDao.insertEnd(end)

        // 3. Create arrow score records
        arrowScores.forEachIndexed { index, score ->
            val arrowScore = ArrowScore(
                endId = endId.toInt(),
                arrowNumber = index + 1,
                score = score
            )
            roundDao.insertArrowScore(arrowScore)
        }

        // 4. Return next end number
        return endNumber + 1
    }

    // Private helper for grouping data
    private fun groupEndWithArrowData(
        endWithArrowData: List<EndWithArrowData>
    ): List<EndWithArrowScores> {
        return endWithArrowData.groupBy { it.endId }
            .map { (endId, dataList) ->
                val firstData = dataList.first()
                val end = /* construct End from firstData */
                val arrows = dataList.map { /* construct ArrowScore */ }
                EndWithArrowScores(end, arrows)
            }
    }
}
```

**When to use:** When operations span multiple tables or require domain logic beyond simple CRUD.

### Interface Repository (Abstraction)

**Pattern:** Interface for multiple implementations (local, remote, hybrid).

```kotlin
interface TournamentRepository {
    // Observe public tournaments
    fun getPublicTournaments(): Flow<List<Tournament>>

    // Create tournament with Result<T> error handling
    suspend fun createTournament(tournament: Tournament): Result<TournamentId>

    // Get single tournament
    suspend fun getTournament(tournamentId: TournamentId): Result<Tournament?>

    // Real-time observation
    fun observeTournament(tournamentId: TournamentId): Flow<Tournament?>

    // Resource cleanup
    fun cleanup()
}

// Implementation: HybridTournamentRepository
class HybridTournamentRepository(
    private val localDao: TournamentDao,
    private val firebaseSource: FirebaseTournamentSource
) : TournamentRepository {

    override fun getPublicTournaments(): Flow<List<Tournament>> = flow {
        // Emit local data first (offline-first)
        emitAll(localDao.getAllTournaments())

        // Then sync with Firebase in background
        try {
            val remoteTournaments = firebaseSource.getPublicTournaments()
            localDao.insertAll(remoteTournaments)
        } catch (e: Exception) {
            // Local data already emitted, silent failure is acceptable
        }
    }

    override suspend fun createTournament(tournament: Tournament): Result<TournamentId> {
        return try {
            // Save locally first
            val localId = localDao.insert(tournament)

            // Sync to Firebase
            val remoteId = firebaseSource.createTournament(tournament)

            Result.success(remoteId)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

**When to use:** When you need multiple data sources (local + remote) or want to swap implementations for testing.

---

## 2. StateFlow and Flow Usage

StateFlow provides reactive state management with lifecycle-aware observation in Compose.

### ViewModel State Exposure

**Pattern 1: Derived StateFlow from Repository**

```kotlin
class AuthenticationViewModel(
    private val authRepository: AuthenticationRepository
) : ViewModel() {

    // Transform repository Flow to StateFlow with initial value
    val authenticationState: StateFlow<AuthenticationState> = authRepository.currentUser()
        .map { user ->
            if (user != null) {
                AuthenticationState.Authenticated(user)
            } else {
                AuthenticationState.Unauthenticated
            }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(),
            initialValue = AuthenticationState.Loading
        )
}
```

**When to use:** When you need to transform repository data before exposing to UI.

**Pattern 2: Simple State with Backing Field**

```kotlin
class AuthenticationViewModel(/* ... */) : ViewModel() {

    // Private MutableStateFlow for internal writes
    private val _isLoading = MutableStateFlow(false)

    // Public StateFlow exposed as read-only
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // ViewModel can modify state
    fun signInWithEmail(email: String, password: String) {
        viewModelScope.launch {
            _isLoading.value = true  // Only ViewModel can write
            // ... perform sign-in
            _isLoading.value = false
        }
    }
}
```

**When to use:** When ViewModel needs to control state directly (loading flags, UI state, form validation).

**Pattern 3: Nullable State for Optional Data**

```kotlin
private val _lastResult = MutableStateFlow<AuthenticationResult?>(null)
val lastResult: StateFlow<AuthenticationResult?> = _lastResult.asStateFlow()

fun signInWithEmail(email: String, password: String) {
    viewModelScope.launch {
        _lastResult.value = null  // Clear previous result

        val result = authRepository.signInWithEmail(email, password)

        _lastResult.value = if (result.isSuccess) {
            AuthenticationResult.Success
        } else {
            val error = result.exceptionOrNull() ?: Exception("Unknown error")
            AuthenticationResult.Error(error, getErrorMessage(error))
        }
    }
}
```

**When to use:** For one-shot events (navigation, snackbar messages, operation results).

### Compose UI Collection

**Pattern: `collectAsState()` with `by` delegation**

```kotlin
@Composable
fun SettingsScreen(viewModel: SettingsViewModel) {
    // Collect StateFlow as Compose State
    val selectedSystem by viewModel.measurementSystem.collectAsState()
    val selectedZoomMode by viewModel.targetZoomMode.collectAsState()
    val userName by viewModel.userName.collectAsState()

    // UI automatically recomposes when these values change
    Column {
        Text("User: $userName")

        when (selectedSystem) {
            MeasurementSystem.METRIC -> Text("Using metric")
            MeasurementSystem.IMPERIAL -> Text("Using imperial")
        }
    }
}
```

**When to use:** Always use `collectAsState()` for StateFlow in Composables. Never use `.collect {}` inside composable functions (causes recomposition issues).

### Flow Collection with LaunchedEffect

**Pattern: Side effects with Flow collection**

```kotlin
@Composable
fun TournamentScreen(viewModel: TournamentDiscoveryViewModel) {
    val tournaments by viewModel.tournaments.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    // LaunchedEffect for one-time events
    LaunchedEffect(Unit) {
        viewModel.loadTournaments()
    }

    // Display UI based on state
    when {
        uiState.isLoading -> CircularProgressIndicator()
        uiState.errorMessage != null -> ErrorMessage(uiState.errorMessage)
        tournaments.isEmpty() -> EmptyState()
        else -> TournamentList(tournaments)
    }
}
```

**ViewModel implementation:**

```kotlin
fun loadTournaments() {
    viewModelScope.launch {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        try {
            tournamentRepository.getPublicTournaments().collect { tournaments ->
                _uiState.value = _uiState.value.copy(
                    tournaments = tournaments,
                    isLoading = false,
                    isEmpty = tournaments.isEmpty()
                )
            }
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                errorMessage = "Failed to load tournaments: ${e.message}"
            )
        }
    }
}
```

**When to use:** For initial data loading, one-time operations, or when you need to handle Flow events.

---

## 3. Coroutine Patterns

Coroutines enable structured concurrency for asynchronous operations.

### ViewModel Coroutine Scope

**Pattern: `viewModelScope.launch` for UI operations**

```kotlin
class AuthenticationViewModel(
    private val authRepository: AuthenticationRepository
) : ViewModel() {

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _lastResult = MutableStateFlow<AuthenticationResult?>(null)
    val lastResult: StateFlow<AuthenticationResult?> = _lastResult.asStateFlow()

    fun signInWithEmail(email: String, password: String) {
        viewModelScope.launch {
            // 1. Set loading state
            _isLoading.value = true
            _lastResult.value = null

            // 2. Perform async operation
            val result = authRepository.signInWithEmail(email, password)

            // 3. Update result state
            _lastResult.value = if (result.isSuccess) {
                AuthenticationResult.Success
            } else {
                val error = result.exceptionOrNull() ?: Exception("Unknown error")
                AuthenticationResult.Error(error, getErrorMessage(error))
            }

            // 4. Clear loading state
            _isLoading.value = false
        }
    }
}
```

**Key Points:**
- Use `viewModelScope.launch` for all ViewModel coroutines
- Automatically canceled when ViewModel is cleared
- Set loading state before/after operations
- Clear previous results before new operations

### Repository Suspend Functions

**Pattern: Suspend functions for database operations**

```kotlin
suspend fun startRound(roundId: Int): Boolean {
    android.util.Log.d("RoundRepository", "Attempting to start round: $roundId")

    // 1. Fetch current state
    val round = roundDao.getRoundById(roundId)
    if (round == null) {
        android.util.Log.e("RoundRepository", "Round not found: $roundId")
        return false
    }

    // 2. Validate state transition
    if (round.status != RoundStatus.PLANNED) {
        android.util.Log.e("RoundRepository", "Round status is not PLANNED: ${round.status}")
        return false
    }

    // 3. Update with new state and timestamp
    val updatedRound = round.copy(
        status = RoundStatus.IN_PROGRESS,
        startTime = System.currentTimeMillis(),
        updatedAt = System.currentTimeMillis()
    )

    roundDao.updateRound(updatedRound)
    return true
}
```

**Key Points:**
- Early returns for validation failures
- Logging for debugging (conditional on BuildConfig.DEBUG in production)
- Update timestamps when modifying entities
- Return success/failure boolean or Result<T>

---

## 4. Error Handling Patterns

Sealed classes provide type-safe error handling with exhaustive when expressions.

### Sealed Class for Results

**Pattern: Success/Error variants**

```kotlin
sealed class SaveResult {
    object Success : SaveResult()
    data class Error(val message: String) : SaveResult()
    data class ValidationError(val message: String) : SaveResult()
}

// Extension functions for convenience
fun SaveResult.isSuccess(): Boolean = this is SaveResult.Success

fun SaveResult.isError(): Boolean =
    this is SaveResult.Error || this is SaveResult.ValidationError

fun SaveResult.getErrorMessage(): String? = when (this) {
    is SaveResult.Error -> message
    is SaveResult.ValidationError -> message
    is SaveResult.Success -> null
}
```

**Usage in ViewModel:**

```kotlin
class SightViewModel(private val repository: SightRepository) : ViewModel() {
    private val _saveResult = MutableStateFlow<SaveResult?>(null)
    val saveResult: StateFlow<SaveResult?> = _saveResult.asStateFlow()

    fun saveSight(sight: Sight) {
        viewModelScope.launch {
            _saveResult.value = try {
                repository.insertSight(sight)
                SaveResult.Success
            } catch (e: Exception) {
                SaveResult.Error(e.message ?: "Unknown error")
            }
        }
    }
}
```

**Usage in Compose:**

```kotlin
@Composable
fun SightForm(viewModel: SightViewModel) {
    val result by viewModel.saveResult.collectAsState()

    when (result) {
        is SaveResult.Success -> {
            LaunchedEffect(Unit) {
                // Navigate back or show success message
            }
        }
        is SaveResult.Error -> {
            Text("Error: ${result.getErrorMessage()}", color = Color.Red)
        }
        is SaveResult.ValidationError -> {
            Text("Validation error: ${result.message}", color = Color.Orange)
        }
        null -> { /* No result yet */ }
    }
}
```

### Sealed Class for State

**Pattern: Loading/Success/Error states**

```kotlin
sealed class AuthenticationState {
    object Loading : AuthenticationState()
    data class Authenticated(val user: User) : AuthenticationState()
    object Unauthenticated : AuthenticationState()
    data class Error(val error: Throwable) : AuthenticationState()
}

sealed class AuthenticationResult {
    object Success : AuthenticationResult()
    data class Error(val error: Throwable, val message: String) : AuthenticationResult()
}
```

**When to use:**
- **State** - For ongoing UI state (loading, authenticated, error)
- **Result** - For one-shot operation results (sign in result, save result)

### Repository Error Handling

**Pattern: Try-catch with fallback values**

```kotlin
suspend fun getArrowScoresWithContextForSetup(bowSetupId: Long): List<ArrowScoreWithContext> {
    return try {
        roundDao.getArrowScoresWithContextForSetup(bowSetupId)
    } catch (e: Exception) {
        emptyList()  // Return empty list on error
    }
}

suspend fun getEquipmentPerformanceStats(bowSetupId: Long): EquipmentPerformanceStats? {
    return try {
        roundDao.getEquipmentPerformanceStats(bowSetupId)
    } catch (e: Exception) {
        null  // Return null on error
    }
}
```

**When to use:** For non-critical operations where empty/null fallback is acceptable.

---

## 5. Dependency Injection Patterns

DI provides loose coupling and testability through constructor injection.

### Constructor Injection (ViewModels)

**Pattern: Single repository dependency**

```kotlin
class SightViewModel(private val repository: SightRepository) : ViewModel() {
    // ViewModel logic
}

class PlungerViewModel(private val repository: PlungerRepository) : ViewModel() {
    // ViewModel logic
}

class ArrowViewModel(private val repository: ArrowRepository) : ViewModel() {
    // ViewModel logic
}
```

**Key Points:**
- Always use `private val` for dependencies
- Extend `ViewModel` base class
- Keep ViewModels focused on single repository when possible

### Factory Pattern for Repositories

**Pattern: Centralized factory for all repositories**

```kotlin
open class RepositoryFactory(
    private val riserDao: RiserDao,
    private val limbsDao: LimbsDao,
    private val sightDao: SightDao,
    private val settingsDao: SettingsDao,
    // ... all other DAOs
    private val kmpDatabase: ArcheryKmpDatabase,
    private val tournamentModeProvider: TournamentModeProvider,
    private val networkMonitor: NetworkMonitor
) {
    open fun createSightRepository(): SightRepository =
        SightRepository(sightDao, settingsDao)

    open fun createBowSetupRepository(): BowSetupRepository =
        BowSetupRepository(
            bowSetupDao = kmpDatabase.getBowSetupDao(),
            riserDao = riserDao,
            limbsDao = limbsDao,
            sightDao = sightDao,
            stabilizerDao = kmpDatabase.getStabilizerDao(),
            plungerDao = kmpDatabase.getPlungerDao(),
            restDao = kmpDatabase.getRestDao(),
            bowStringDao = kmpDatabase.getBowStringDao(),
            arrowDao = kmpDatabase.getArrowDao(),
            weightDao = kmpDatabase.getWeightDao(),
            accessoryDao = kmpDatabase.getAccessoryDao()
        )

    open fun createRoundRepository(): RoundRepository =
        RoundRepository(
            roundDao = kmpDatabase.getRoundDao(),
            bowSetupRepository = createBowSetupRepository()
        )
}
```

**Key Points:**
- `open` class for test overrides
- Factory methods return repository instances
- Repositories can depend on other repositories
- All DAOs injected at factory level

### Singleton Provider Pattern

**Pattern: App-wide singleton for repository access**

```kotlin
object RepositoryProvider {
    private var repositoryFactory: RepositoryFactory? = null

    fun initialize(
        kmpDatabase: ArcheryKmpDatabase,
        tournamentModeProvider: TournamentModeProvider? = null,
        networkMonitor: NetworkMonitor? = null
    ) {
        require(PlatformProvider.isInitialized() ||
                (tournamentModeProvider != null && networkMonitor != null)) {
            "PlatformProvider must be initialized first"
        }

        repositoryFactory = RepositoryFactory(
            riserDao = kmpDatabase.getRiserDao(),
            limbsDao = kmpDatabase.getLimbsDao(),
            // ... all DAOs
            kmpDatabase = kmpDatabase,
            tournamentModeProvider = tournamentModeProvider ?: PlatformProvider.getTournamentModeProvider(),
            networkMonitor = networkMonitor ?: PlatformProvider.getNetworkMonitor()
        )
    }

    fun getFactory(): RepositoryFactory {
        return repositoryFactory ?: throw IllegalStateException(
            "RepositoryProvider not initialized. Call initialize() first."
        )
    }

    fun clear() {
        repositoryFactory = null
    }
}
```

**Usage in Application:**

```kotlin
class ArcheryApprenticeApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        val database = ArcheryKmpDatabase.getInstance(this)
        RepositoryProvider.initialize(database)
    }
}
```

**Usage in Activity/Fragment:**

```kotlin
val factory = RepositoryProvider.getFactory()
val repository = factory.createSightRepository()
val viewModel = SightViewModel(repository)
```

---

## 6. Compose UI Patterns

Jetpack Compose uses declarative UI with state hoisting for reusability.

### State Hoisting with Callbacks

**Pattern: Parent manages state, children are stateless**

```kotlin
@Composable
fun ParticipantListInput(
    guestParticipants: List<GuestParticipantInput>,
    onAddGuest: () -> Unit,
    onRemoveGuest: (String) -> Unit,
    onUpdateGuestName: (String, String) -> Unit,
    maxGuests: Int = 9,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        // Header with Add button
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Participants",
                style = MaterialTheme.typography.titleMedium
            )

            OutlinedButton(
                onClick = onAddGuest,
                enabled = guestParticipants.size < maxGuests
            ) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Add Guest")
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Guest participant cards
        guestParticipants.forEachIndexed { index, guest ->
            GuestParticipantCard(
                guest = guest,
                guestNumber = index + 1,
                onRemove = { onRemoveGuest(guest.id) },
                onNameChange = { newName -> onUpdateGuestName(guest.id, newName) }
            )

            if (index < guestParticipants.size - 1) {
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}
```

**Key Points:**
- Data passed as parameters
- Actions passed as callbacks
- Composable is fully reusable
- Parent controls state, children render

### ViewModel Integration

**Pattern: Collect state at top level, pass down as parameters**

```kotlin
@Composable
fun SignUpScreen(
    viewModel: AuthenticationViewModel,
    onNavigateBack: () -> Unit
) {
    // Collect all state at top level
    val authState by viewModel.authenticationState.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val lastResult by viewModel.lastResult.collectAsState()

    // Pass state down to child composables
    SignUpContent(
        authState = authState,
        isLoading = isLoading,
        lastResult = lastResult,
        onSignUp = { email, password -> viewModel.signUpWithEmail(email, password) },
        onNavigateBack = onNavigateBack
    )
}

@Composable
private fun SignUpContent(
    authState: AuthenticationState,
    isLoading: Boolean,
    lastResult: AuthenticationResult?,
    onSignUp: (String, String) -> Unit,
    onNavigateBack: () -> Unit
) {
    // Stateless UI based on parameters
    Column {
        if (isLoading) {
            CircularProgressIndicator()
        }

        when (val result = lastResult) {
            is AuthenticationResult.Success -> {
                Text("Sign up successful!")
            }
            is AuthenticationResult.Error -> {
                Text("Error: ${result.message}", color = Color.Red)
            }
            null -> { /* No result yet */ }
        }

        // Sign up form
        SignUpForm(
            onSignUp = onSignUp,
            enabled = !isLoading
        )
    }
}
```

**Key Points:**
- ViewModel stays at top level
- State collected once and passed down
- Child composables are testable without ViewModel
- Clear separation of concerns

### Common Composable Patterns

**LazyColumn for Lists:**

```kotlin
@Composable
fun EquipmentList(
    bowSetups: List<BowSetup>,
    onSetupClick: (Long) -> Unit
) {
    LazyColumn {
        items(
            items = bowSetups,
            key = { it.id }  // Key for efficient updates
        ) { setup ->
            BowSetupCard(
                setup = setup,
                onClick = { onSetupClick(setup.id) }
            )
        }
    }
}
```

**Dialog Composable:**

```kotlin
@Composable
fun ConfirmDialog(
    title: String,
    message: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    confirmText: String = "Confirm",
    dismissText: String = "Cancel"
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(confirmText)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(dismissText)
            }
        }
    )
}
```

---

## 7. Testing Patterns

Testing ensures code correctness and prevents regressions.

### ViewModel Test Setup

**Pattern: MockK with UnconfinedTestDispatcher**

```kotlin
@ExperimentalCoroutinesApi
@RunWith(RobolectricTestRunner::class)
class AuthenticationViewModelTest {
    // Test dependencies
    private lateinit var viewModel: AuthenticationViewModel
    private lateinit var mockAuthRepository: AuthenticationRepository
    private lateinit var userFlow: MutableStateFlow<User?>

    // Test dispatcher for immediate execution
    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setup() {
        // Set main dispatcher for testing
        Dispatchers.setMain(testDispatcher)

        // Create controllable Flow for testing
        userFlow = MutableStateFlow(null)

        // Mock repository
        mockAuthRepository = mockk()
        every { mockAuthRepository.currentUser() } returns userFlow

        // Create ViewModel with mock
        viewModel = AuthenticationViewModel(mockAuthRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
        unmockkAll()
    }
}
```

**Key Points:**
- `UnconfinedTestDispatcher` for immediate coroutine execution
- `MockK` for mocking dependencies
- `MutableStateFlow` for controllable test data
- `@Before` for setup, `@After` for cleanup

### Test Patterns

**Pattern: Given-When-Then structure**

```kotlin
@Test
fun `signInWithEmail with valid credentials returns Success`() = runTest(testDispatcher) {
    // Given
    val testUser = User(id = "123", email = "test@example.com")
    coEvery {
        mockAuthRepository.signInWithEmail("test@example.com", "password123")
    } returns Result.success(testUser)

    // When
    viewModel.signInWithEmail("test@example.com", "password123")
    testDispatcher.scheduler.advanceUntilIdle()

    // Then
    coVerify { mockAuthRepository.signInWithEmail("test@example.com", "password123") }
    assertTrue(viewModel.lastResult.value is AuthenticationResult.Success)
    assertFalse(viewModel.isLoading.value)
}

@Test
fun `signInWithEmail with invalid credentials returns Error`() = runTest(testDispatcher) {
    // Given
    val exception = Exception("Invalid credentials")
    coEvery {
        mockAuthRepository.signInWithEmail(any(), any())
    } returns Result.failure(exception)

    // When
    viewModel.signInWithEmail("test@example.com", "wrongpassword")
    testDispatcher.scheduler.advanceUntilIdle()

    // Then
    val result = viewModel.lastResult.value
    assertTrue(result is AuthenticationResult.Error)
    assertEquals("Invalid credentials", (result as AuthenticationResult.Error).message)
}
```

**Pattern: Initial state testing**

```kotlin
@Test
fun `initial state has default values`() = runTest {
    // Get initial StateFlow value
    val initialState = viewModel.scoringSession.first()

    // Assert default state
    assertEquals(ScoringSessionState(), initialState)
    assertNull(initialState.currentRound)
    assertEquals(1, initialState.currentEndNumber)
    assertEquals(emptyList<Int>(), initialState.currentEndArrows)
    assertFalse(initialState.isEndComplete)
}
```

**Pattern: StateFlow observation in tests**

```kotlin
@Test
fun `userFlow emission updates authenticationState`() = runTest {
    // Given - initial state is Loading
    assertEquals(AuthenticationState.Loading, viewModel.authenticationState.value)

    // When - emit authenticated user
    val testUser = User(id = "123", email = "test@example.com")
    userFlow.value = testUser
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - state updates to Authenticated
    val state = viewModel.authenticationState.value
    assertTrue(state is AuthenticationState.Authenticated)
    assertEquals(testUser, (state as AuthenticationState.Authenticated).user)
}
```

---

## Pattern Composition Examples

### Repository → ViewModel → Compose Flow

**Complete data flow from database to UI:**

```kotlin
// 1. Repository exposes Flow from DAO
class BowSetupRepository(private val bowSetupDao: BowSetupDao) {
    fun getAllBowSetups(): Flow<List<BowSetup>> =
        bowSetupDao.getAllActiveBowSetups()
}

// 2. ViewModel collects and transforms to StateFlow
class EquipmentViewModel(private val repository: BowSetupRepository) : ViewModel() {
    val bowSetups: StateFlow<List<BowSetup>> = repository.getAllBowSetups()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(),
            initialValue = emptyList()
        )
}

// 3. Compose collects StateFlow as State
@Composable
fun EquipmentScreen(viewModel: EquipmentViewModel) {
    val bowSetups by viewModel.bowSetups.collectAsState()

    LazyColumn {
        items(bowSetups, key = { it.id }) { setup ->
            BowSetupCard(setup = setup)
        }
    }
}
```

**Result:** UI automatically updates when database changes.

### DI → Error Handling → State Management

**Complete operation flow with error handling:**

```kotlin
// 1. Factory provides repository
val factory = RepositoryProvider.getFactory()
val repository = factory.createSightRepository()

// 2. ViewModel uses repository with error handling
class SightViewModel(private val repository: SightRepository) : ViewModel() {
    private val _saveResult = MutableStateFlow<SaveResult?>(null)
    val saveResult: StateFlow<SaveResult?> = _saveResult.asStateFlow()

    fun saveSight(sight: Sight) {
        viewModelScope.launch {
            _saveResult.value = try {
                repository.insertSight(sight)
                SaveResult.Success
            } catch (e: Exception) {
                SaveResult.Error(e.message ?: "Unknown error")
            }
        }
    }
}

// 3. Compose handles result state
@Composable
fun SightForm(viewModel: SightViewModel) {
    val result by viewModel.saveResult.collectAsState()

    when (result) {
        is SaveResult.Success -> {
            // Navigate back or show success
            LaunchedEffect(Unit) { /* navigate */ }
        }
        is SaveResult.Error -> {
            Text("Error: ${result.message}", color = Color.Red)
        }
        null -> { /* Show form */ }
    }
}
```

---

## Best Practices Summary

### Repository Best Practices

✅ **DO:**
- Use Flow for reactive data
- Use suspend functions for single operations
- Use `@Transaction` for multi-step operations
- Return Result<T> for operations that can fail
- Log errors with context

❌ **DON'T:**
- Expose DAOs to ViewModels directly
- Perform UI operations in repositories
- Use callbacks instead of suspend/Flow
- Ignore errors silently without logging

### StateFlow Best Practices

✅ **DO:**
- Use StateFlow for state that UI observes
- Use `_private` mutable + public read-only pattern
- Use `stateIn()` for Flow → StateFlow conversion
- Use `collectAsState()` in Compose

❌ **DON'T:**
- Expose MutableStateFlow publicly
- Use `.collect {}` inside composable functions
- Forget initial value in `stateIn()`
- Create StateFlow without proper scope

### Coroutine Best Practices

✅ **DO:**
- Use `viewModelScope` in ViewModels
- Set loading state before/after operations
- Handle errors with try-catch
- Use `advanceUntilIdle()` in tests

❌ **DON'T:**
- Use GlobalScope
- Forget to clear loading states
- Ignore coroutine cancellation
- Block the main thread

### Testing Best Practices

✅ **DO:**
- Test initial state
- Test success and error paths
- Use descriptive test names with backticks
- Use `runTest` for coroutine tests
- Mock external dependencies

❌ **DON'T:**
- Test implementation details
- Forget to advance test dispatcher
- Leave mocks active after tests
- Test multiple concerns in one test

---

## Related Documentation

- [Feature Examples](../Feature-Examples/) - Complete feature implementations
- [Testing Examples](../Testing-Examples/) - Comprehensive test examples
- [Code Examples Index](../) - Overview of all code examples
- [System Flows](../../Flows/System-Flows/) - Architecture and data flows

---

**Last Updated:** 2025-11-04
**Pattern Count:** 7 major patterns with 25+ code examples
