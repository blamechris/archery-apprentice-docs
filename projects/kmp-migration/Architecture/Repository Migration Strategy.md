# Repository Migration Strategy

**Created:** 2025-10-21 | **Agent:** Agent 2 (AAM)
**Tags:** #kmp #repository-pattern #migration-strategy #architecture

---

## Overview

The Repository Migration Strategy defines the conceptual approach for migrating repository layer code from Android-only (`app/`) to Kotlin Multiplatform shared modules (`shared/domain`, `shared/data`). This migration enables cross-platform code sharing while maintaining the existing offline-first, hybrid sync architecture.

---

## Strategic Goals

### 1. **Enable Cross-Platform Code Sharing**
- Repository interfaces and implementations become platform-agnostic
- Business logic (validation, sync strategies) shared across Android, iOS, web
- Platform-specific code (Firebase SDKs, Context) isolated via abstractions

### 2. **Maintain Offline-First Architecture**
- Local Room database remains source of truth
- Hybrid repositories continue to combine local + remote seamlessly
- No user-facing changes (app still works fully offline)

### 3. **Preserve Existing Patterns**
- Manual DI (SharedModuleFactory) matches current RepositoryFactory
- Repository pattern unchanged (interface-based, testable)
- Hybrid sync strategy continues (no architectural shift)

### 4. **Minimize Risk**
- Incremental migration (one repository at a time)
- Comprehensive test coverage maintained (60% patch / 80% project)
- All existing tests must pass after each migration phase

---

## Current State Analysis

### Repository Inventory (14 Repositories)

**1. TournamentRepository (Interface)**
- **Location:** `app/src/main/java/.../domain/repository/TournamentRepository.kt`
- **Type:** Interface (52 methods across 8 concerns)
- **Status:** ⚠️ Agent 3 is splitting into 4 specialized repositories
- **Migration:** Wait for Agent 3's split, then migrate clean architecture

**2. RoundRepository (Class)**
- **Location:** `app/src/main/java/.../domain/repository/RoundRepository.kt`
- **Type:** Class (needs interface extraction)
- **Dependencies:** RoundDao, BowSetupRepository
- **Migration:** Extract interface → Move to shared

**3. Equipment Repositories (11 Classes)**
- BowSetupRepository
- AccessoryRepository, ArrowRepository, BowStringRepository
- LimbsRepository, PlungerRepository, RestRepository
- RiserRepository, SightRepository, StabilizerRepository, WeightRepository
- **Type:** All classes (need interface extraction)
- **Pattern:** Take DAO dependencies, expose Flow/suspend methods
- **Migration:** Batch migration (similar patterns)

**4. Support Classes**
- RepositoryFactory (manual DI factory)
- RepositoryProvider (singleton provider)
- UpgradeRepairManager (database migration utility)
- **Migration:** Evolve into SharedModuleFactory

---

## Dependency Management Strategy

### Critical Dependencies

**Agent 1 (Domain Models) - BLOCKING**
```
Why:
- Repository interfaces reference domain models heavily
- Can't move interfaces without models in shared/domain first

Example:
interface RoundRepository {
    suspend fun getRoundById(id: Int): Round?  // Needs Round in shared/domain
    fun getAllRounds(): Flow<List<Round>>
}

Status: ⏸️ Waiting for Agent 1 to complete
Estimated: 2-3 days
```

**Agent 3 (Repository Split) - BLOCKING**
```
Why:
- Agent 3 is splitting HybridTournamentRepository into 4 specialized repos NOW
- Migrating monolithic version would create merge conflicts

Agent 3's Split:
1. TournamentDiscoveryRepository (~280 lines)
2. TournamentCrudRepository (~320 lines)
3. TournamentParticipantRepository (~400 lines)
4. TournamentScoringRepository (~350 lines)

Status: ⏸️ Waiting for Agent 3's PR to merge
Estimated: 2-3 days
```

### Migration Order (After Dependencies Resolve)

**Phase 1: Interfaces First**
1. TournamentRepository (4 interfaces from Agent 3's split)
2. Extract RoundRepository interface
3. Extract Equipment repository interfaces (batch)

**Phase 2: Implementations Second**
1. Move tournament repository implementations
2. Move RoundRepositoryImpl
3. Move equipment repository implementations (batch)

**Phase 3: Database Last**
1. Move DAOs (already interfaces)
2. Configure Room KMP
3. Test migrations

**Rationale for Order:**
- Interfaces are pure Kotlin (no platform dependencies)
- Implementations may need platform abstractions
- Database requires expect/actual setup (most complex)

---

## Repository Split Integration (Agent 3's Work)

### Current: Monolithic HybridTournamentRepository

**Problem:**
- 1,809 lines, 52 methods
- 8+ distinct concerns (Discovery, CRUD, Participants, Scoring, Rounds, Settings, Moderation, Sync)
- Violates Single Responsibility Principle
- Hard to test, hard to maintain

### Future: 4 Specialized Repositories + Coordinator

**1. TournamentDiscoveryRepository**
```kotlin
interface TournamentDiscoveryRepository {
    fun getPublicTournaments(): Flow<List<Tournament>>
    fun getMyTournaments(userId: String): Flow<List<Tournament>>
    fun searchTournaments(query: String): Flow<List<Tournament>>
    fun getTournamentsByStatus(status: TournamentStatus): Flow<List<Tournament>>
    fun getTournamentsInDateRange(start: Long, end: Long): Flow<List<Tournament>>
    suspend fun getTournament(id: TournamentId): Result<Tournament?>
    fun observeTournament(id: TournamentId): Flow<Tournament?>
}
```
**Concern:** Finding and browsing tournaments
**Lines:** ~280
**Pattern:** Read-only hybrid (combines local + remote)

**2. TournamentCrudRepository**
```kotlin
interface TournamentCrudRepository {
    suspend fun createTournament(tournament: Tournament): Result<TournamentId>
    suspend fun updateTournament(tournament: Tournament): Result<Unit>
    suspend fun deleteTournament(id: TournamentId): Result<Unit>
    suspend fun cancelTournament(id: TournamentId, reason: String): Result<Unit>
    suspend fun startTournament(id: TournamentId): Result<Unit>
    suspend fun endTournament(id: TournamentId): Result<Unit>
    suspend fun syncLocalTournament(localId: TournamentId): Result<Unit>
}
```
**Concern:** Create, update, delete, lifecycle transitions
**Lines:** ~320
**Pattern:** Offline-first with background sync

**3. TournamentParticipantRepository**
```kotlin
interface TournamentParticipantRepository {
    suspend fun joinTournament(
        tournamentId: TournamentId,
        participant: TournamentParticipant,
        authenticatedUserId: String? = null
    ): Result<Unit>
    suspend fun retryTournamentJoinSync(
        tournamentId: TournamentId,
        participant: TournamentParticipant
    ): Result<Unit>
    suspend fun joinTournamentWithCode(
        joinCode: String,
        participant: TournamentParticipant
    ): Result<Unit>
    suspend fun leaveTournament(
        tournamentId: TournamentId,
        participantId: String
    ): Result<Unit>
    fun getTournamentParticipants(tournamentId: TournamentId): Flow<List<TournamentParticipant>>
    suspend fun getParticipant(tournamentId: TournamentId, participantId: String): Result<TournamentParticipant?>
    suspend fun updateParticipantStatus(
        tournamentId: TournamentId,
        participantId: String,
        status: ParticipantStatus
    ): Result<Unit>
}
```
**Concern:** Participant management and join flow
**Lines:** ~400
**Pattern:** Offline-first join with explicit auth state passing

**4. TournamentScoringRepository**
```kotlin
interface TournamentScoringRepository {
    suspend fun submitScore(
        tournamentId: TournamentId,
        participantId: String,
        roundNumber: Int,
        arrowScores: List<Int>,
        isXFlags: List<Boolean>,
        endNumber: Int,
        deviceId: String
    ): Result<Unit>
    fun getTournamentLeaderboard(tournamentId: TournamentId): Flow<List<LeaderboardEntry>>
    fun observeTournamentScores(
        tournamentId: TournamentId,
        roundNumber: Int
    ): Flow<List<TournamentScore>>
    fun getParticipantRoundArrows(
        tournamentId: TournamentId,
        participantId: String,
        roundNumber: Int
    ): Flow<List<EndScoreWithArrows>>
    suspend fun invalidateTournamentCache(tournamentId: TournamentId)
}
```
**Concern:** Score submission, leaderboards, real-time scoring
**Lines:** ~350
**Pattern:** Hybrid with smart caching (TournamentScoreCacheService integration)

**5. HybridTournamentRepository (Coordinator)**
```kotlin
class HybridTournamentRepository(
    private val discoveryRepo: TournamentDiscoveryRepository,
    private val crudRepo: TournamentCrudRepository,
    private val participantRepo: TournamentParticipantRepository,
    private val scoringRepo: TournamentScoringRepository,
    private val networkMonitor: NetworkMonitor
) {
    // Façade methods that delegate to specialized repositories
    fun getPublicTournaments() = discoveryRepo.getPublicTournaments()
    suspend fun createTournament(t: Tournament) = crudRepo.createTournament(t)
    suspend fun joinTournament(id, p) = participantRepo.joinTournament(id, p)
    suspend fun submitScore(...) = scoringRepo.submitScore(...)

    // Coordinator responsibilities:
    // - Network monitoring
    // - ID mapping (local ↔ Firebase)
    // - Sync orchestration
    // - Utility methods
}
```
**New Role:** Façade coordinating 4 specialized repositories
**Lines:** ~600-700 (61% reduction)

### Migration Integration Strategy

**When Agent 3 Completes:**
1. Pull latest main (get 4 specialized repository interfaces)
2. Migrate 4 interfaces to `shared/domain/repository/tournament/`
3. Migrate 4 implementations to `shared/data/repository/tournament/`
4. Update HybridTournamentRepository to use shared repos
5. Test all tournament flows (create, join, score, sync)

**Benefits:**
- Clean architecture from the start (no need to re-migrate)
- Single Responsibility Principle enforced
- Easier to test (smaller, focused repositories)
- Avoids merge conflicts

---

## Interface Extraction Patterns

### Pattern 1: Extract Interface from Class Repository

**Current (Class-based):**
```kotlin
// app/src/main/java/.../repository/RoundRepository.kt
class RoundRepository(
    private val roundDao: RoundDao,
    private val bowSetupRepository: BowSetupRepository
) {
    suspend fun insertRound(round: Round): Long = roundDao.insertRound(round)
    fun getAllRounds(): Flow<List<Round>> = roundDao.getAllRounds()
    suspend fun getRoundById(roundId: Int): Round? = roundDao.getRoundById(roundId)
    suspend fun updateRound(round: Round) = roundDao.updateRound(round)
    suspend fun deleteRound(round: Round) {
        bowSetupRepository.cleanupGuestSetupsForRound(round.id)
        roundDao.deleteRound(round)
    }
}
```

**Target (Interface + Implementation):**

**Interface:**
```kotlin
// shared/domain/src/commonMain/kotlin/repository/RoundRepository.kt
interface RoundRepository {
    suspend fun insertRound(round: Round): Long
    fun getAllRounds(): Flow<List<Round>>
    suspend fun getRoundById(roundId: Int): Round?
    suspend fun updateRound(round: Round)
    suspend fun deleteRound(round: Round)
}
```

**Implementation:**
```kotlin
// shared/data/src/commonMain/kotlin/repository/RoundRepositoryImpl.kt
class RoundRepositoryImpl(
    private val roundDao: RoundDao,
    private val bowSetupRepository: BowSetupRepository
) : RoundRepository {
    override suspend fun insertRound(round: Round): Long {
        return roundDao.insertRound(round)
    }

    override fun getAllRounds(): Flow<List<Round>> {
        return roundDao.getAllRounds()
    }

    override suspend fun getRoundById(roundId: Int): Round? {
        return roundDao.getRoundById(roundId)
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

**Steps:**
1. Create interface in `shared/domain` with all public method signatures
2. Create implementation in `shared/data` extending the interface
3. Move implementation code from current class
4. Update RepositoryFactory to provide interface (not class)
5. Update all call sites to use interface type

### Pattern 2: Equipment Repository Batch Migration

**Observation:** 11 equipment repositories follow identical pattern

**Template:**
```kotlin
// Interface (shared/domain)
interface [EquipmentType]Repository {
    suspend fun insert(item: [EquipmentType]): Long
    suspend fun update(item: [EquipmentType])
    suspend fun delete(item: [EquipmentType])
    suspend fun getById(id: Long): [EquipmentType]?
    fun getAll(): Flow<List<[EquipmentType]>>
    fun getAllActive(): Flow<List<[EquipmentType]>>
}

// Implementation (shared/data)
class [EquipmentType]RepositoryImpl(
    private val dao: [EquipmentType]Dao
) : [EquipmentType]Repository {
    override suspend fun insert(item: [EquipmentType]): Long = dao.insert(item)
    override suspend fun update(item: [EquipmentType]) = dao.update(item)
    override suspend fun delete(item: [EquipmentType]) = dao.delete(item)
    override suspend fun getById(id: Long) = dao.getById(id)
    override fun getAll() = dao.getAll()
    override fun getAllActive() = dao.getAllActive()
}
```

**Batch Migration Strategy:**
1. Create all 11 interfaces in `shared/domain/repository/equipment/`
2. Create all 11 implementations in `shared/data/repository/equipment/`
3. Update SharedModuleFactory to provide all 11 repositories
4. Test with existing equipment tests
5. Update app RepositoryFactory to delegate to SharedModuleFactory

**Time Savings:** Batch approach saves ~2-3 days vs individual migration

---

## Platform Abstraction Patterns

### Identify Platform-Specific Code

**Common Platform Dependencies:**
1. **Android Context** - Already removed by Agent 1 ✅
2. **Firebase SDKs** - Need abstraction for iOS
3. **Logging** - Need platform-agnostic logging
4. **Network connectivity** - Already abstracted by Agent 1 ✅

### Pattern: RemoteTournamentDataSource Abstraction

**Problem:** Firebase SDK is platform-specific (different for Android vs iOS)

**Solution:** Abstract remote data source interface

**Interface (Shared):**
```kotlin
// shared/data/src/commonMain/kotlin/datasources/RemoteTournamentDataSource.kt
interface RemoteTournamentDataSource {
    suspend fun getTournament(id: TournamentId): Result<Tournament?>
    fun observeTournament(id: TournamentId): Flow<Tournament?>
    suspend fun createTournament(tournament: Tournament): Result<TournamentId>
    suspend fun updateTournament(tournament: Tournament): Result<Unit>
    suspend fun deleteTournament(id: TournamentId): Result<Unit>
    fun getTournamentParticipants(id: TournamentId): Flow<List<TournamentParticipant>>
    suspend fun submitScore(...): Result<Unit>
}
```

**Android Implementation:**
```kotlin
// shared/data/src/androidMain/kotlin/datasources/FirebaseTournamentDataSource.kt
class FirebaseTournamentDataSource : RemoteTournamentDataSource {
    private val firestore = Firebase.firestore

    override suspend fun getTournament(id: TournamentId): Result<Tournament?> {
        return try {
            val doc = firestore.collection("tournaments")
                .document(id)
                .get()
                .await()
            Result.success(doc.toTournament())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun observeTournament(id: TournamentId): Flow<Tournament?> {
        return callbackFlow {
            val listener = firestore.collection("tournaments")
                .document(id)
                .addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        close(error)
                    } else {
                        trySend(snapshot?.toTournament())
                    }
                }
            awaitClose { listener.remove() }
        }
    }

    // ... other methods
}
```

**iOS Implementation (Future):**
```kotlin
// shared/data/src/iosMain/kotlin/datasources/FirebaseTournamentDataSource.kt
class FirebaseTournamentDataSource : RemoteTournamentDataSource {
    // Use iOS Firebase SDK (Cocoapods dependency)
    // Similar logic, different platform SDK
}
```

**Repository Uses Abstraction:**
```kotlin
class TournamentCrudRepositoryImpl(
    private val localDao: TournamentDao,
    private val remoteDataSource: RemoteTournamentDataSource, // ✅ Interface
    private val networkMonitor: NetworkMonitor
) : TournamentCrudRepository {
    // Repository doesn't care which platform implementation is used
    override suspend fun createTournament(tournament: Tournament): Result<TournamentId> {
        val localId = localDao.insertTournament(tournament.toEntity())

        if (networkMonitor.isOnline()) {
            remoteDataSource.createTournament(tournament) // ✅ Platform-agnostic call
                .onSuccess { firebaseId ->
                    idMappingDao.insert(localId, firebaseId)
                }
        }

        return Result.success(localId)
    }
}
```

**DI Integration:**
```kotlin
// shared/di/src/androidMain/kotlin/AndroidSharedModuleFactory.kt
class AndroidSharedModuleFactory : SharedModuleFactory() {
    override fun provideTournamentCrudRepository(): TournamentCrudRepository {
        return TournamentCrudRepositoryImpl(
            localDao = database.tournamentDao(),
            remoteDataSource = FirebaseTournamentDataSource(), // ✅ Android implementation
            networkMonitor = PlatformProvider.networkMonitor
        )
    }
}

// shared/di/src/iosMain/kotlin/IosSharedModuleFactory.kt (future)
class IosSharedModuleFactory : SharedModuleFactory() {
    override fun provideTournamentCrudRepository(): TournamentCrudRepository {
        return TournamentCrudRepositoryImpl(
            localDao = database.tournamentDao(),
            remoteDataSource = FirebaseTournamentDataSource(), // ✅ iOS implementation
            networkMonitor = PlatformProvider.networkMonitor
        )
    }
}
```

---

## Risk Mitigation Patterns

### Risk 1: Breaking Existing Tests

**Mitigation Strategy:**
- Run full test suite after each repository migration
- Update test imports incrementally
- Keep app tests passing (3,400+ tests)
- Add shared module tests in commonTest

**Test Migration Pattern:**
```kotlin
// Before (Android test)
// app/src/test/java/.../repository/RoundRepositoryTest.kt
class RoundRepositoryTest {
    private val mockDao: RoundDao = mockk()
    private val repository = RoundRepository(mockDao, mockk())

    @Test
    fun getRoundById_returnsRound() = runTest {
        val expected = Round(id = 1, roundName = "Test")
        coEvery { mockDao.getRoundById(1) } returns expected

        val result = repository.getRoundById(1)

        assertEquals(expected, result)
    }
}

// After (Shared common test)
// shared/data/src/commonTest/kotlin/repository/RoundRepositoryImplTest.kt
class RoundRepositoryImplTest {
    private val mockDao: RoundDao = mockk()
    private val repository = RoundRepositoryImpl(mockDao, mockk())

    @Test
    fun getRoundById_returnsRound() = runTest {
        val expected = Round(id = 1, roundName = "Test")
        coEvery { mockDao.getRoundById(1) } returns expected

        val result = repository.getRoundById(1)

        assertEquals(expected, result)
    }
}
```

**Keep Android tests for platform-specific code:**
```kotlin
// app/src/test/java/.../repository/FirebaseTournamentDataSourceTest.kt
@RunWith(AndroidJUnit4::class)
class FirebaseTournamentDataSourceTest {
    // Test Android Firebase SDK integration
}
```

### Risk 2: Merge Conflicts with Agent 3

**Mitigation Strategy:**
- **WAIT for Agent 3 to complete repository split**
- Pull main AFTER Agent 3's PR merges
- Migrate clean, split architecture (not monolithic)
- No concurrent work on same files

**Coordination Protocol:**
1. Agent 2 waits in "productive waiting" mode
2. Agent 3 completes repository split
3. Agent 3's PR merges to main
4. Agent 2 pulls main (gets split repos)
5. Agent 2 begins repository migration (no conflicts)

### Risk 3: Repository Interface Changes

**Mitigation Strategy:**
- Interface extraction must preserve ALL method signatures
- Use IDE refactoring tools (extract interface)
- Verify all call sites compile after extraction
- Run tests to catch behavioral changes

**Verification Checklist:**
- [ ] All method signatures preserved
- [ ] All return types match
- [ ] All parameter types match
- [ ] All suspend functions marked correctly
- [ ] All Flow return types correct
- [ ] All documentation preserved

---

## Migration Phases (Detailed)

### Phase 1: Repository Interfaces (2-3 days)

**Prerequisites:**
- ✅ Agent 1 completes domain model migration
- ✅ Agent 3 completes repository split

**Tasks:**
1. **Migrate Tournament Interfaces (from Agent 3's split)**
   - TournamentDiscoveryRepository.kt → `shared/domain/repository/tournament/`
   - TournamentCrudRepository.kt → `shared/domain/repository/tournament/`
   - TournamentParticipantRepository.kt → `shared/domain/repository/tournament/`
   - TournamentScoringRepository.kt → `shared/domain/repository/tournament/`

2. **Extract RoundRepository Interface**
   - Create `shared/domain/repository/RoundRepository.kt`
   - Extract all public method signatures
   - Update imports to use shared/domain models

3. **Extract Equipment Repository Interfaces (Batch)**
   - Create 11 interfaces in `shared/domain/repository/equipment/`
   - Use template pattern (all follow same structure)

**Validation:**
- [ ] All interfaces compile in shared/domain
- [ ] No Android-specific imports
- [ ] All model references point to shared/domain

### Phase 2: Repository Implementations (2-3 days)

**Tasks:**
1. **Migrate Tournament Implementations**
   - Move 4 implementations to `shared/data/repository/tournament/`
   - Abstract Firebase with RemoteTournamentDataSource
   - Keep hybrid sync logic

2. **Create RoundRepositoryImpl**
   - Move implementation to `shared/data/repository/RoundRepositoryImpl.kt`
   - Update package imports
   - Remove any Android-specific code (logging)

3. **Create Equipment Repository Implementations (Batch)**
   - Create 11 implementations in `shared/data/repository/equipment/`
   - Use template pattern

**Validation:**
- [ ] All implementations compile in shared/data
- [ ] No Android SDK dependencies (except platform abstractions)
- [ ] All tests pass

### Phase 3: Dependency Injection (1-2 days)

**Tasks:**
1. **Extend SharedModuleFactory**
   - Add methods for all repository interfaces
   - Provide singleton instances

2. **Implement AndroidSharedModuleFactory**
   - Provide repository implementations
   - Inject DAOs from database
   - Inject platform abstractions

3. **Update App RepositoryFactory**
   - Delegate to AndroidSharedModuleFactory
   - Keep backward compatibility
   - Update tests

**Validation:**
- [ ] All repositories accessible via SharedModuleFactory
- [ ] No circular dependencies
- [ ] Singletons work correctly

### Phase 4: Testing & Validation (2-3 days)

**Tasks:**
1. **Migrate Repository Tests to Common**
   - Move unit tests to `shared/data/src/commonTest/`
   - Update imports
   - Run tests on JVM target

2. **Run Full Test Suite**
   - All app unit tests (3,400+ tests)
   - All E2E tests (5 suites)
   - All shared module tests

3. **Integration Testing**
   - Test repository DI
   - Test database access
   - Test hybrid sync flows

**Validation:**
- [ ] All existing tests pass
- [ ] New shared tests pass
- [ ] Coverage maintained (60% patch / 80% project)
- [ ] E2E tests pass

---

## Success Metrics

### Code Migration
- [ ] All repository interfaces in `shared/domain` (~1,000 lines)
- [ ] All repository implementations in `shared/data` (~2,200 lines)
- [ ] SharedModuleFactory fully implemented
- [ ] App RepositoryFactory delegates to SharedModuleFactory

### Build & Compilation
- [ ] `./gradlew :shared:domain:build` - SUCCESS
- [ ] `./gradlew :shared:data:build` - SUCCESS
- [ ] `./gradlew :app:build` - SUCCESS
- [ ] No Android SDK in shared/domain or shared/data

### Testing
- [ ] All existing tests pass (3,400+ tests)
- [ ] New shared tests added
- [ ] Coverage maintained (60% patch / 80% project)
- [ ] E2E tests pass

### Quality Gates
- [ ] Manual DI pattern maintained
- [ ] All detekt checks pass
- [ ] No merge conflicts with Agent 1 or Agent 3
- [ ] Clean architecture (SRP enforced)

---

## Timeline Estimate

**Total: 12-17 days (active work)**

- **Waiting for Dependencies:** 3-5 days (Agent 1 & Agent 3)
- **Phase 1 (Interfaces):** 2-3 days
- **Phase 2 (Implementations):** 2-3 days
- **Phase 3 (DI):** 1-2 days
- **Phase 4 (Testing):** 2-3 days
- **Phase 5 (Database):** 3-4 days (covered in [[Room KMP Architecture]])
- **Phase 6 (Final Validation):** 2-3 days

**Critical Path:** Agent 1 → Agent 3 → Agent 2

---

## Related Documentation

**Code Repository:**
- [[../../../docs/AGENT_CONTEXTS/AGENT_2_WEEK_2_MIGRATION_PLAN.md|Week 2 Migration Plan]] (Implementation details)
- [[../../../docs/kmp-migration/ROOM_KMP_MIGRATION_GUIDE.md|Room KMP Migration Guide]]
- [[../../../docs/GOD_CLASS_EXTRACTION_PLANS.md|God Class Extraction Plans]]

**Obsidian Vault:**
- [[KMP Data Layer Architecture]] (Architecture overview)
- [[Room KMP Architecture]] (Database migration)
- [[KMP Migration Progress]] (Project status)

---

**Last Updated:** 2025-10-21
**Status:** Strategy complete, waiting for dependencies (Agent 1 & Agent 3)
**Next Steps:** Pull main after Agent 1 & Agent 3 merge, begin Phase 1
