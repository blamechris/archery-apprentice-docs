# KMP Data Layer Architecture

**Created:** 2025-10-21 | **Agent:** Agent 2 (AAM)
**Tags:** #architecture #kmp #data-layer #kotlin-multiplatform

---

## Overview

The KMP (Kotlin Multiplatform) Data Layer Architecture for Archery Apprentice defines how data flows from the UI through repositories, data sources, and database layers in a cross-platform manner. This architecture enables sharing business logic and data access code across Android, iOS, and future platforms while maintaining platform-specific implementations where necessary.

---

## Core Principles

### 1. Offline-First Architecture
- **Primary Goal:** App works fully offline with local Room database
- **Sync Strategy:** Background sync to Firebase when online
- **Conflict Resolution:** Smart merging with local-first precedence
- **User Experience:** No loading states, instant data access

### 2. Repository Pattern
- **Single Source of Truth:** Repositories coordinate local + remote data
- **Abstraction Layer:** ViewModels/Presenters never touch DAOs directly
- **Testability:** Repositories are interface-based for easy mocking
- **Hybrid Strategy:** Combines offline (Room) + online (Firebase) seamlessly

### 3. Platform Abstraction
- **expect/actual Pattern:** Platform-specific implementations (Context, file paths, timestamps)
- **Shared Logic:** Business rules, validation, data transformations in `commonMain`
- **Platform Optimizations:** Native implementations where performance matters

---

## Module Structure

```
shared/
├── common/           # Foundation utilities
│   ├── expect/actual declarations
│   ├── Platform abstractions
│   └── Common extensions
│
├── domain/           # Business logic & interfaces
│   ├── models/       # Data classes (Round, Tournament, Equipment)
│   ├── repository/   # Repository interfaces
│   └── usecases/     # Business use cases (optional)
│
├── data/             # Repository implementations
│   ├── repository/   # Repository impls (RoundRepositoryImpl, etc.)
│   ├── datasources/  # Data source abstractions
│   │   ├── local/    # Local data source interfaces
│   │   └── remote/   # Remote data source interfaces
│   └── cache/        # Caching strategies (LRU, etc.)
│
├── database/         # Room KMP database
│   ├── entities/     # Database entities (Room annotations)
│   ├── dao/          # Data Access Objects
│   ├── converters/   # Type converters
│   └── migrations/   # Database migrations
│
├── presentation/     # Presentation logic
│   ├── Presenters (shared ViewModels)
│   ├── Screen state classes
│   └── UI events
│
└── di/               # Dependency injection
    ├── SharedModuleFactory
    ├── AndroidSharedModuleFactory
    └── iOSSharedModuleFactory (future)
```

---

## Data Flow: UI → Repository → DAO → Database

### **Layer 1: Presentation (UI)**

**Platform-Specific:**
- Android: Compose UI + AndroidViewModel wrappers
- iOS: SwiftUI + ObservableObject wrappers

**Shared:**
- Presenters (business logic for UI)
- State classes (UI state representations)
- UI events (user interactions)

**Example Flow:**
```kotlin
// Android Compose UI
@Composable
fun RoundDetailsScreen(viewModel: RoundViewModel) {
    val round by viewModel.currentRound.collectAsState()
    // UI renders round data
}

// AndroidViewModel wrapper (thin layer)
class RoundViewModel(private val presenter: RoundPresenter) : ViewModel() {
    val currentRound: StateFlow<Round?> = presenter.currentRound
    fun loadRound(id: Int) = presenter.loadRound(id)
}

// Shared Presenter (business logic)
class RoundPresenter(private val repository: RoundRepository) {
    private val _currentRound = MutableStateFlow<Round?>(null)
    val currentRound: StateFlow<Round?> = _currentRound.asStateFlow()

    suspend fun loadRound(id: Int) {
        _currentRound.value = repository.getRoundById(id)
    }
}
```

---

### **Layer 2: Repository (Business Logic Coordination)**

**Purpose:** Coordinate data access from multiple sources

**Pattern:** Interface-based with hybrid implementations

**Example:**
```kotlin
// Interface (shared/domain)
interface RoundRepository {
    suspend fun getRoundById(id: Int): Round?
    fun getAllRounds(): Flow<List<Round>>
    suspend fun insertRound(round: Round): Long
    suspend fun updateRound(round: Round)
    suspend fun deleteRound(round: Round)
}

// Implementation (shared/data)
class RoundRepositoryImpl(
    private val roundDao: RoundDao,
    private val bowSetupRepository: BowSetupRepository
) : RoundRepository {
    override suspend fun getRoundById(id: Int): Round? {
        return roundDao.getRoundById(id)
    }

    override fun getAllRounds(): Flow<List<Round>> {
        return roundDao.getAllRounds()
    }

    override suspend fun insertRound(round: Round): Long {
        return roundDao.insertRound(round)
    }

    override suspend fun updateRound(round: Round) {
        roundDao.updateRound(round)
    }

    override suspend fun deleteRound(round: Round) {
        // Business logic: cleanup related data
        bowSetupRepository.cleanupGuestSetupsForRound(round.id)
        roundDao.deleteRound(round)
    }
}
```

**Hybrid Repository Pattern:**
```kotlin
// Tournament repositories combine local + remote
class TournamentCrudRepositoryImpl(
    private val localDao: TournamentDao,
    private val remoteDataSource: RemoteTournamentDataSource,
    private val networkMonitor: NetworkMonitor
) : TournamentCrudRepository {
    override suspend fun createTournament(tournament: Tournament): Result<TournamentId> {
        // 1. Save locally first (offline-first)
        val localId = localDao.insertTournament(tournament.toEntity())

        // 2. Sync to Firebase if online
        if (networkMonitor.isOnline()) {
            remoteDataSource.createTournament(tournament)
                .onSuccess { firebaseId ->
                    // Map local ID → Firebase ID
                    idMappingDao.insert(localId, firebaseId)
                }
                .onFailure { error ->
                    // Mark for retry sync
                    syncQueueDao.enqueue(localId, SyncAction.CREATE)
                }
        }

        return Result.success(localId)
    }
}
```

---

### **Layer 3: Data Sources (Platform Abstractions)**

**Purpose:** Abstract local vs remote data access

**Local Data Sources:**
```kotlin
// Interface (shared/data)
interface LocalRoundDataSource {
    suspend fun getRound(id: Int): Round?
    fun observeRounds(): Flow<List<Round>>
    suspend fun saveRound(round: Round): Long
}

// Implementation uses DAO (shared/data)
class LocalRoundDataSourceImpl(
    private val roundDao: RoundDao
) : LocalRoundDataSource {
    override suspend fun getRound(id: Int): Round? = roundDao.getRoundById(id)
    override fun observeRounds(): Flow<List<Round>> = roundDao.getAllRounds()
    override suspend fun saveRound(round: Round): Long = roundDao.insertRound(round)
}
```

**Remote Data Sources:**
```kotlin
// Interface (shared/data)
interface RemoteTournamentDataSource {
    suspend fun getTournament(id: TournamentId): Result<Tournament?>
    fun observeTournament(id: TournamentId): Flow<Tournament?>
    suspend fun createTournament(tournament: Tournament): Result<TournamentId>
}

// Android implementation (Firebase)
class FirebaseTournamentDataSource : RemoteTournamentDataSource {
    private val firestore = Firebase.firestore

    override suspend fun getTournament(id: TournamentId): Result<Tournament?> {
        return try {
            val doc = firestore.collection("tournaments").document(id).get().await()
            Result.success(doc.toTournament())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

// iOS implementation (future - same interface, different platform SDK)
class IOSFirebaseTournamentDataSource : RemoteTournamentDataSource {
    // Uses iOS Firebase SDK
}
```

---

### **Layer 4: DAO (Data Access Objects)**

**Purpose:** Room database queries (SQL abstraction)

**Platform:** Shared (`commonMain`) - Room KMP supports DAOs in shared code

**Example:**
```kotlin
// shared/database/src/commonMain/kotlin/dao/RoundDao.kt
@Dao
interface RoundDao {
    @Insert
    suspend fun insertRound(round: Round): Long

    @Query("SELECT * FROM rounds WHERE id = :roundId")
    suspend fun getRoundById(roundId: Int): Round?

    @Query("SELECT * FROM rounds ORDER BY createdAt DESC")
    fun getAllRounds(): Flow<List<Round>>

    @Update
    suspend fun updateRound(round: Round)

    @Delete
    suspend fun deleteRound(round: Round)

    @Query("DELETE FROM rounds WHERE id = :roundId")
    suspend fun deleteRoundById(roundId: Int)

    // Complex query with joins
    @Transaction
    @Query("""
        SELECT rounds.*,
               COUNT(end_scores.id) as completedEnds
        FROM rounds
        LEFT JOIN end_scores ON rounds.id = end_scores.roundId
        WHERE rounds.id = :roundId
        GROUP BY rounds.id
    """)
    suspend fun getRoundWithStats(roundId: Int): RoundWithDetails?
}
```

---

### **Layer 5: Database (Room KMP)**

**Purpose:** SQLite database abstraction with Room annotations

**Platform Abstraction:** expect/actual for database instantiation

**Common Database Definition:**
```kotlin
// shared/database/src/commonMain/kotlin/database/ArcheryDatabase.kt
@Database(
    entities = [
        Round::class,
        EndScore::class,
        ArrowScore::class,
        BowSetup::class,
        Tournament::class,
        // ... 18 more entities
    ],
    version = 35,
    exportSchema = true
)
@ConstructedBy(ArcheryDatabaseConstructor::class)
abstract class ArcheryDatabase : RoomDatabase() {
    abstract fun roundDao(): RoundDao
    abstract fun tournamentDao(): TournamentDao
    abstract fun bowSetupDao(): BowSetupDao
    // ... 11 more DAOs
}
```

**Platform-Specific Initialization:**

**Android:**
```kotlin
// shared/database/src/androidMain/kotlin/database/DatabaseConstructor.kt
actual object ArcheryDatabaseConstructor : RoomDatabaseConstructor<ArcheryDatabase> {
    private lateinit var applicationContext: Context

    fun initialize(context: Context) {
        applicationContext = context.applicationContext
    }

    override fun initialize(): ArcheryDatabase {
        val dbFile = applicationContext.getDatabasePath("archery.db")
        return Room.databaseBuilder<ArcheryDatabase>(
            context = applicationContext,
            name = dbFile.absolutePath
        )
        .addMigrations(*getAllMigrations())
        .build()
    }
}
```

**iOS (Future):**
```kotlin
// shared/database/src/iosMain/kotlin/database/DatabaseConstructor.kt
actual object ArcheryDatabaseConstructor : RoomDatabaseConstructor<ArcheryDatabase> {
    override fun initialize(): ArcheryDatabase {
        val dbFile = NSHomeDirectory() + "/archery.db"
        return Room.databaseBuilder<ArcheryDatabase>(
            name = dbFile,
            factory = { ArcheryDatabase::class.instantiateImpl() }
        )
        .setDriver(BundledSQLiteDriver())
        .addMigrations(*getAllMigrations())
        .build()
    }
}
```

---

## expect/actual Patterns for Platform-Specific Code

### When to Use expect/actual

**Use for:**
- Database instantiation (Context on Android, file path on iOS)
- SQLite driver initialization
- Timestamp functions (`System.currentTimeMillis` vs `NSDate`)
- File I/O paths
- Network connectivity checks
- Logging implementations

**Don't use for:**
- Entities (pure Kotlin data classes)
- DAOs (pure interfaces with SQL queries)
- TypeConverters (can often stay in commonMain)
- Business logic (should be platform-agnostic)

### Example: Timestamp Function

**Common Declaration:**
```kotlin
// shared/common/src/commonMain/kotlin/platform/Time.kt
expect fun getCurrentTimeMillis(): Long
```

**Android Implementation:**
```kotlin
// shared/common/src/androidMain/kotlin/platform/Time.kt
actual fun getCurrentTimeMillis(): Long = System.currentTimeMillis()
```

**iOS Implementation:**
```kotlin
// shared/common/src/iosMain/kotlin/platform/Time.kt
import platform.Foundation.NSDate

actual fun getCurrentTimeMillis(): Long =
    (NSDate().timeIntervalSince1970 * 1000).toLong()
```

**Usage in Entities:**
```kotlin
// shared/domain/src/commonMain/kotlin/models/Round.kt
data class Round(
    val id: Int = 0,
    val roundName: String,
    val createdAt: Long = getCurrentTimeMillis(), // ✅ Platform-agnostic
    // ... other fields
)
```

---

## Dependency Injection Strategy

### Manual DI Pattern (SharedModuleFactory)

**Why Manual DI?**
- Consistent with existing Android app architecture (RepositoryFactory)
- No third-party framework learning curve
- Simple, explicit, debuggable
- Can add Koin later if needed

**Pattern:**
```kotlin
// shared/di/src/commonMain/kotlin/SharedModuleFactory.kt
abstract class SharedModuleFactory {
    // Database
    abstract fun provideArcheryDatabase(): ArcheryDatabase

    // Repositories
    abstract fun provideRoundRepository(): RoundRepository
    abstract fun provideTournamentRepository(): TournamentRepository
    abstract fun provideBowSetupRepository(): BowSetupRepository
    // ... other repositories
}
```

**Android Implementation:**
```kotlin
// shared/di/src/androidMain/kotlin/AndroidSharedModuleFactory.kt
class AndroidSharedModuleFactory : SharedModuleFactory() {
    private val database: ArcheryDatabase by lazy {
        ArcheryDatabaseConstructor.initialize()
    }

    override fun provideArcheryDatabase(): ArcheryDatabase = database

    override fun provideRoundRepository(): RoundRepository {
        return RoundRepositoryImpl(
            roundDao = database.roundDao(),
            bowSetupRepository = provideBowSetupRepository()
        )
    }

    override fun provideTournamentRepository(): TournamentRepository {
        return HybridTournamentRepository(
            localDao = database.tournamentDao(),
            remoteDataSource = FirebaseTournamentDataSource(),
            networkMonitor = PlatformProvider.networkMonitor
        )
    }

    // ... other repositories
}
```

**Integration with App:**
```kotlin
// app/src/main/java/RepositoryFactory.kt
class RepositoryFactory(
    private val database: ArcheryDatabase,
    private val platformProvider: PlatformProvider
) {
    private val sharedFactory = AndroidSharedModuleFactory()

    fun createRoundRepository(): RoundRepository {
        return sharedFactory.provideRoundRepository()
    }

    fun createTournamentRepository(): TournamentRepository {
        return sharedFactory.provideTournamentRepository()
    }
}
```

---

## Data Flow Example: Loading a Round

### Complete Flow from UI to Database and Back

**1. UI Request (Compose):**
```kotlin
// Android Compose UI
@Composable
fun RoundDetailsScreen(roundId: Int, viewModel: RoundViewModel) {
    val round by viewModel.currentRound.collectAsState()

    LaunchedEffect(roundId) {
        viewModel.loadRound(roundId) // Trigger data load
    }

    round?.let { roundData ->
        Text("Round: ${roundData.roundName}")
        Text("Score: ${roundData.totalScore} / ${roundData.maxPossibleScore}")
    }
}
```

**2. ViewModel Wrapper (Android):**
```kotlin
// app/src/main/java/viewmodels/RoundViewModel.kt
class RoundViewModel(
    private val presenter: RoundPresenter
) : AndroidViewModel() {
    val currentRound: StateFlow<Round?> = presenter.currentRound

    fun loadRound(id: Int) {
        viewModelScope.launch {
            presenter.loadRound(id)
        }
    }
}
```

**3. Presenter (Shared Business Logic):**
```kotlin
// shared/presentation/src/commonMain/kotlin/presenters/RoundPresenter.kt
class RoundPresenter(
    private val roundRepository: RoundRepository
) {
    private val _currentRound = MutableStateFlow<Round?>(null)
    val currentRound: StateFlow<Round?> = _currentRound.asStateFlow()

    suspend fun loadRound(id: Int) {
        _currentRound.value = roundRepository.getRoundById(id)
    }
}
```

**4. Repository (Coordination):**
```kotlin
// shared/data/src/commonMain/kotlin/repository/RoundRepositoryImpl.kt
class RoundRepositoryImpl(
    private val roundDao: RoundDao,
    private val bowSetupRepository: BowSetupRepository
) : RoundRepository {
    override suspend fun getRoundById(id: Int): Round? {
        return roundDao.getRoundById(id)
    }
}
```

**5. DAO (SQL Query):**
```kotlin
// shared/database/src/commonMain/kotlin/dao/RoundDao.kt
@Dao
interface RoundDao {
    @Query("SELECT * FROM rounds WHERE id = :roundId")
    suspend fun getRoundById(roundId: Int): Round?
}
```

**6. Database (Room):**
- Room KMP generates SQL query implementation
- SQLite executes query
- Room maps result to `Round` data class

**7. Data Flows Back:**
- DAO returns `Round?` to Repository
- Repository returns `Round?` to Presenter
- Presenter updates `StateFlow<Round?>`
- ViewModel exposes `StateFlow` to Compose UI
- Compose UI recomposes with new data

**Total Layers:** 6 (UI → ViewModel → Presenter → Repository → DAO → Database)

---

## Hybrid Online/Offline Pattern

### Tournament Repository Example

**Scenario:** User creates tournament while offline, syncs when online

**Flow:**
```kotlin
class TournamentCrudRepositoryImpl(
    private val localDao: TournamentDao,
    private val remoteDataSource: RemoteTournamentDataSource,
    private val networkMonitor: NetworkMonitor,
    private val syncQueue: SyncQueueDao
) : TournamentCrudRepository {

    override suspend fun createTournament(tournament: Tournament): Result<TournamentId> {
        // STEP 1: Save to local database immediately (offline-first)
        val localId = localDao.insertTournament(tournament.toEntity())

        // STEP 2: Attempt Firebase sync if online
        if (networkMonitor.isOnline()) {
            remoteDataSource.createTournament(tournament)
                .onSuccess { firebaseId ->
                    // Success: Map local ID to Firebase ID
                    idMappingDao.insert(localId, firebaseId)
                    localDao.updateSyncStatus(localId, SyncStatus.SYNCED)
                }
                .onFailure { error ->
                    // Failure: Queue for retry
                    syncQueue.enqueue(localId, SyncAction.CREATE)
                    localDao.updateSyncStatus(localId, SyncStatus.FAILED)
                }
        } else {
            // Offline: Queue for later sync
            syncQueue.enqueue(localId, SyncAction.CREATE)
            localDao.updateSyncStatus(localId, SyncStatus.PENDING)
        }

        // STEP 3: Return local ID immediately (user sees instant success)
        return Result.success(localId)
    }

    override fun observeTournament(id: TournamentId): Flow<Tournament?> {
        return combine(
            localDao.observeTournament(id),      // Local database
            remoteDataSource.observeTournament(id) // Firebase real-time
        ) { local, remote ->
            // Merge strategy: Prefer local if modified, otherwise use remote
            when {
                local == null -> remote
                remote == null -> local
                local.updatedAt > remote.updatedAt -> local
                else -> remote
            }
        }
    }
}
```

**Key Benefits:**
- User never sees loading states (instant local response)
- Data syncs transparently in background
- Conflicts resolved with smart merging
- Works fully offline

---

## Migration Strategy

### Phase 1: Domain Models (Agent 1) ✅
- Move entities to `shared/domain`
- Remove Android-specific code (java.util.Date, System.currentTimeMillis)
- Keep Room annotations

### Phase 2: Repository Interfaces (Agent 2 - Week 2)
- Move repository interfaces to `shared/domain`
- Extract interfaces from class-based repositories

### Phase 3: Repository Implementations (Agent 2 - Week 2)
- Move implementations to `shared/data`
- Update imports to use shared/domain models

### Phase 4: Room Database (Agent 2 - Week 2)
- Move DAOs to `shared/database`
- Configure Room KMP with expect/actual
- Test migrations on Android

### Phase 5: Presentation Layer (Week 3-4)
- Extract Presenters from ViewModels
- Move business logic to `shared/presentation`
- ViewModels become thin wrappers

### Phase 6: iOS Integration (Week 5+)
- Implement iOS data sources (Firebase iOS SDK)
- Create iOS database initialization
- Wire up shared modules to SwiftUI

---

## Testing Strategy

### Unit Tests (Common Code)
```kotlin
// shared/data/src/commonTest/kotlin/repository/RoundRepositoryTest.kt
class RoundRepositoryTest {
    private lateinit var mockDao: RoundDao
    private lateinit var repository: RoundRepositoryImpl

    @BeforeTest
    fun setup() {
        mockDao = mockk()
        repository = RoundRepositoryImpl(mockDao, mockk())
    }

    @Test
    fun getRoundById_returnsRound() = runTest {
        val expected = Round(id = 1, roundName = "Test")
        coEvery { mockDao.getRoundById(1) } returns expected

        val result = repository.getRoundById(1)

        assertEquals(expected, result)
    }
}
```

### Integration Tests (Android)
```kotlin
// app/src/androidTest/kotlin/data/RoundRepositoryIntegrationTest.kt
@RunWith(AndroidJUnit4::class)
class RoundRepositoryIntegrationTest {
    private lateinit var database: ArcheryDatabase
    private lateinit var repository: RoundRepository

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, ArcheryDatabase::class.java)
            .build()
        repository = RoundRepositoryImpl(database.roundDao(), mockk())
    }

    @Test
    fun insertAndRetrieveRound() = runTest {
        val round = Round(roundName = "Test Round", numEnds = 6, numArrows = 6)
        val id = repository.insertRound(round)

        val retrieved = repository.getRoundById(id.toInt())

        assertNotNull(retrieved)
        assertEquals("Test Round", retrieved?.roundName)
    }
}
```

---

## Key Architectural Decisions

### 1. Offline-First
**Decision:** Local database is source of truth, Firebase syncs in background
**Rationale:** Users score rounds offline (field, competition venues with poor connectivity)

### 2. Repository Pattern
**Decision:** All data access goes through repositories
**Rationale:** Abstracts data sources, testable, swappable implementations

### 3. Manual DI
**Decision:** SharedModuleFactory pattern, no Hilt/Koin
**Rationale:** Matches existing app architecture, simple, explicit

### 4. Room KMP
**Decision:** Use Room 2.8.1 for cross-platform database
**Rationale:** Keep existing Room code, official Google/JetBrains support

### 5. Hybrid Repositories
**Decision:** Combine local + remote in single repository
**Rationale:** Simplifies ViewModels, encapsulates sync complexity

---

## Performance Considerations

### Database Indexes
- **All foreign keys indexed** (prevents full table scans)
- **Composite indices** for common query patterns
- **Query optimization:** Use `@Transaction` for complex queries

### Caching Strategy
- **LRU Cache** for tournament scores (reduces Firebase reads)
- **In-memory cache** for frequently accessed data
- **Cache invalidation** on data updates

### N+1 Query Prevention
- **Use `@Transaction` queries** to fetch related data in one query
- **Flow.combine()** to merge multiple data sources efficiently

---

## Related Documentation

**Code Repository:**
- [[../../../docs/AGENT_CONTEXTS/AGENT_2_WEEK_2_MIGRATION_PLAN.md|Week 2 Migration Plan]]
- [[../../../docs/kmp-migration/ROOM_KMP_MIGRATION_GUIDE.md|Room KMP Migration Guide]]
- [[../../../docs/kmp-migration/MODULE_ARCHITECTURE.md|Module Architecture]]
- [[../../../shared/di/DI_STRATEGY.md|DI Strategy]]

**Obsidian Vault:**
- [[Repository Migration Strategy]]
- [[Room KMP Architecture]]
- [[KMP Migration Progress]]

---

**Last Updated:** 2025-10-21
**Status:** Conceptual overview complete, implementation in progress (Week 2)
**Next Steps:** Repository interface migration after Agent 1 completes domain models
