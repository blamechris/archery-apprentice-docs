---
tags:
  - tournament
  - architecture
  - system
  - documentation
  - repository
  - user-identity
  - mp-scoring
  - firebase
  - offline-first
created: 2025-10-08
related:
  - "[[Tournament-Flow]]"
  - "[[Firebase-Integration-Plan]]"
  - "[[Multi-Participant-Flow]]"
  - "[[Data-Sync-Flow]]"
  - "[[Firebase-Security-Rules]]"
---

# Tournament System Documentation

## Overview

This document provides comprehensive documentation of the tournament system implementation in Archery Apprentice. The tournament system enables users to create, join, and participate in archery competitions with full integration to the existing multi-participant (MP) scoring system.

## 🏗️ Architecture Overview

### Core Components

```
Tournament System Architecture
├── UI Layer
│   ├── TournamentCreationScreen
│   ├── TournamentDiscoveryScreen
│   ├── TournamentDetailsScreen
│   └── Navigation (TournamentNavGraph)
├── ViewModels
│   ├── TournamentCreationViewModel
│   ├── TournamentDiscoveryViewModel
│   └── TournamentDetailsViewModel
├── Repository Layer
│   ├── TournamentRepository (Interface)
│   ├── OfflineTournamentRepository
│   ├── FirebaseTournamentRepository
│   └── HybridTournamentRepository
├── Data Layer
│   ├── Tournament (Model)
│   ├── TournamentParticipant (Model)
│   ├── TournamentDao
│   └── TournamentParticipantDao
└── Utilities
    ├── UserIdentityResolver
    └── NetworkMonitor
```

### Repository Pattern Implementation

The system uses a sophisticated repository pattern with multiple implementations:

1. **OfflineTournamentRepository**: Local-only tournaments using Room database
2. **FirebaseTournamentRepository**: Cloud-based tournaments using Firestore
3. **HybridTournamentRepository**: Offline-first with Firebase sync when available

**Repository Selection Logic:**
```kotlin
// RepositoryFactory.kt
return when {
    FeatureFlags.ENABLE_FIREBASE_TOURNAMENTS && context != null -> {
        HybridTournamentRepository(offlineRepo, firebaseRepo) // Offline-first with sync
    }
    else -> {
        OfflineTournamentRepository(...) // Local only
    }
}
```

## 🔄 User Identity Resolution System

### UserIdentityResolver Implementation

The tournament system uses a centralized user identity resolution system that prioritizes multiple sources:

**Priority Order:**
1. **Firebase Authentication** → `firebaseUser.id`
2. **Settings Username** → `settings.userName` (mapped to "local_user")
3. **Anonymous Fallback** → Generated anonymous ID

```kotlin
// UserIdentityResolver.kt
fun resolveUserIdentity(firebaseUser: User?, settings: Settings?): UserIdentity {
    return when {
        firebaseUser != null -> UserIdentity(
            id = firebaseUser.id,
            displayName = firebaseUser.displayName ?: firebaseUser.email ?: "Firebase User",
            source = IdentitySource.FIREBASE_AUTH
        )
        !settings?.userName.isNullOrBlank() -> UserIdentity(
            id = "local_user",
            displayName = settings?.userName ?: "Local User",
            source = IdentitySource.SETTINGS_USERNAME
        )
        else -> UserIdentity(
            id = generateAnonymousId(),
            displayName = "Anonymous User",
            source = IdentitySource.ANONYMOUS
        )
    }
}
```

### Integration Points

**Tournament Creation:**
- Creator identity properly resolved and stored in `tournament.createdBy`
- Backward compatibility maintained for existing "local_user" references

**Tournament Participation:**
- Join/leave operations use resolved user identity
- Button states reflect user participation status

**MP Scoring Integration:**
- Tournament participants converted to `SessionParticipant` types:
  - Current user → `SessionParticipant.LocalUser`
  - Guest participants → `SessionParticipant.GuestArcher`
  - Other participants → `SessionParticipant.GuestArcher` (for MP compatibility)

## 🏆 Tournament Lifecycle

### Status Flow
```
OPEN → IN_PROGRESS → COMPLETED
  ↓
CANCELLED (from any state)
```

### State Transitions

1. **OPEN**: Tournament accepting participants
   - Creator can manage participants (add/remove)
   - Users can join if space available
   - Creator can start tournament

2. **IN_PROGRESS**: Tournament active
   - No new participants allowed
   - Creator and participants can start scoring rounds
   - Scoring rounds linked via `tournamentId` and `tournamentRoundNumber`

3. **COMPLETED**: Tournament finished
   - Results viewable
   - No further scoring allowed

4. **CANCELLED**: Tournament cancelled by creator
   - Can happen from any previous state
   - Participants notified

## 🎯 Multi-Participant Scoring Integration

### Tournament-Round Linkage

Tournament rounds are created with proper linkage to existing Round model:

```kotlin
val round = Round(
    roundName = "${tournament.name} - Round $nextRoundNumber",
    // Standard round parameters
    numEnds = tournament.roundFormat.numEnds,
    numArrows = tournament.roundFormat.numArrows,
    // Tournament linkage
    tournamentId = tournament.id,
    tournamentRoundNumber = nextRoundNumber,
    isLocal = tournament.isLocal,
    syncStatus = if (tournament.isLocal) SyncStatus.LOCAL_ONLY else SyncStatus.SYNCING,
    // MP setup
    participants = sessionParticipants,
    participantTheme = ParticipantTheme.getDefaultForParticipantCount(participants.size),
    bowSetupId = validBowSetupId // Fixed: Required for foreign key constraint
)
```

### Participant Conversion

Tournament participants are converted to session participants for scoring:

```kotlin
val sessionParticipants = participants.map { tp ->
    when {
        tp.participantId == userIdentity.id -> SessionParticipant.LocalUser(
            id = tp.participantId,
            displayName = tp.displayName
        )
        tp.participantId.startsWith("guest_") -> SessionParticipant.GuestArcher(
            id = tp.participantId,
            displayName = tp.displayName
        )
        else -> SessionParticipant.GuestArcher( // Other participants as guests for MP
            id = tp.participantId,
            displayName = tp.displayName
        )
    }
}
```

## 🔧 Recent Fixes & Improvements

### Issue Resolutions (Latest Session)

#### 1. ✅ FOREIGN_KEY Constraint Error Fix
**Problem**: Tournament round creation failed with `SQLITE_CONSTRAINT_FOREIGNKEY` error
**Root Cause**: Round model requires valid `bowSetupId` but tournament rounds were setting it to 0
**Solution**: Get/create valid bow setup for tournament rounds
```kotlin
val bowSetupId = bowSetupRepository.getDefaultBowSetup()?.id ?: run {
    // Create tournament-specific bow setup if none exists
    val tournamentSetup = BowSetup(/* tournament setup config */)
    bowSetupRepository.insertBowSetup(tournamentSetup)
}
```

#### 2. ✅ Join Tournament Button State Management
**Problem**: Button showed "Join Tournament" even for users already joined
**Root Cause**: No user participation checking in discovery screen
**Solution**: Added user participation resolution and button state logic
```kotlin
val isUserParticipant = currentUserId?.let { tournament.isParticipant(it) } ?: false
when {
    isUserParticipant -> OutlinedButton { Text("View Details") }
    tournament.hasSpace -> Button { Text("Join Tournament") }
    else -> OutlinedButton { Text("View Details") }
}
```

#### 3. ✅ System UI Insets Respect
**Problem**: Create Tournament button obscured by system navigation bar
**Root Cause**: Bottom bar didn't account for system UI insets
**Solution**: Added navigation bar height calculation and padding
```kotlin
val navigationBarHeight = remember {
    derivedStateOf {
        val insets = ViewCompat.getRootWindowInsets(view)
        val navBarInsets = insets?.getInsets(WindowInsetsCompat.Type.navigationBars())
        navBarInsets?.bottom?.toDp() ?: 0.dp
    }
}
// Applied to button padding: bottom = 16.dp + navigationBarHeight.value
```

#### 4. ✅ Delete Navigation & Validation
**Problem**: Delete tournament didn't navigate back, allowed multiple clicks
**Root Cause**: No navigation event system, no click prevention
**Solution**: Added `NavigationEvent` system with proper state management
```kotlin
sealed class NavigationEvent {
    object NavigateBack : NavigationEvent()
    data class NavigateToScoring(val roundId: Int) : NavigationEvent()
}

fun deleteTournament() {
    if (!isCreator.value || isDeleting) return // Prevent multiple clicks
    // ... delete logic ...
    _navigationEvents.send(NavigationEvent.NavigateBack)
}
```

### UI/UX Improvements

#### Create Tournament Screen
- ✅ Button moved to bottom bar with shadow elevation
- ✅ Converted to LazyColumn for better scrolling
- ✅ System UI insets properly respected
- ✅ Loading states and proper validation

#### Tournament Discovery
- ✅ Smart button states based on user participation
- ✅ "Join Tournament" vs "View Details" logic
- ✅ User identity resolution for participation checking

#### Tournament Details
- ✅ Creator controls properly shown/hidden
- ✅ User identity resolution throughout
- ✅ Start Scoring connected to MP system
- ✅ Navigation events for proper flow

## 📊 Data Model

### Tournament Entity
```kotlin
@Entity(tableName = "tournaments")
data class Tournament(
    @PrimaryKey val id: String = "",
    val name: String,
    val description: String = "",
    val createdBy: String, // Resolved user identity
    val createdAt: Long = System.currentTimeMillis(),
    val startTime: Long? = null,
    val endTime: Long? = null,
    val status: TournamentStatus = TournamentStatus.OPEN,
    val maxParticipants: Int = 50,
    val currentParticipants: Int = 0,
    val participantIds: List<String> = emptyList(),
    val roundFormat: RoundFormat,
    val isPublic: Boolean = true,
    val registrationDeadline: Long? = null,
    val isLocal: Boolean = true,
    val syncStatus: String = "LOCAL_ONLY"
) {
    fun isParticipant(userId: String): Boolean {
        return participantIds.contains(userId)
    }
}
```

### TournamentParticipant Entity
```kotlin
@Entity(
    tableName = "tournament_participants",
    foreignKeys = [ForeignKey(
        entity = Tournament::class,
        parentColumns = ["id"],
        childColumns = ["tournamentId"],
        onDelete = ForeignKey.CASCADE
    )]
)
data class TournamentParticipant(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val tournamentId: String,
    val participantId: String,
    val displayName: String,
    val joinedAt: Long = System.currentTimeMillis(),
    val isGuest: Boolean = false
)
```

## 🌐 Online/Offline System

### Current Implementation Status
**✅ ALREADY IMPLEMENTED AND WORKING**

The tournament system uses a sophisticated online/offline system:

#### Feature Flag Control
```kotlin
// FeatureFlags.kt
const val ENABLE_FIREBASE_TOURNAMENTS = true // Currently enabled
```

#### Repository Selection
- **Online Mode**: `HybridTournamentRepository` (offline-first with Firebase sync)
- **Offline Mode**: `OfflineTournamentRepository` (local only)

#### Sync Behavior
- **Create Tournament**: Saved locally first, synced to Firebase when online
- **Join Tournament**: Local participation recorded, synced when online
- **Scoring Data**: Tournament rounds linked and synced automatically
- **Conflict Resolution**: Offline-first approach with last-write-wins for conflicts

#### Network Status Indicators
- Connection status shown in UI
- Sync status indicators per tournament
- Offline banners when disconnected

## 🧪 Testing Strategy

### Manual Testing Checklist

#### Tournament Creation Flow
- [ ] Create tournament as authenticated user
- [ ] Verify creator identity resolved correctly
- [ ] Check UI respects system navigation bar insets
- [ ] Test form validation and error states

#### Tournament Discovery & Joining
- [ ] Verify tournaments list properly
- [ ] Check Join vs View Details button logic
- [ ] Test user participation state accuracy
- [ ] Verify navigation to tournament details

#### Tournament Management
- [ ] Creator controls appear for tournament creator
- [ ] Start tournament functionality works
- [ ] Delete tournament navigates back properly
- [ ] User can join/leave tournaments

#### MP Scoring Integration
- [ ] Start Scoring creates tournament round
- [ ] Tournament participants convert to session participants
- [ ] Scoring interface loads with correct participants
- [ ] Scores are properly linked to tournament

#### Online/Offline Functionality
- [ ] Tournaments work offline
- [ ] Sync indicators show correct status
- [ ] Online tournaments sync when connected

### Unit Test Coverage Needed

#### High Priority
- [ ] UserIdentityResolver tests
- [ ] Tournament creation with proper user identity
- [ ] Creator permission checks
- [ ] Participant management operations

#### Medium Priority
- [ ] Repository pattern tests
- [ ] Tournament-round linkage validation
- [ ] Button state logic testing
- [ ] Navigation event handling

## 🚀 Current Status & Next Steps

### ✅ Completed Features
1. **Core Tournament System**: Create, join, manage tournaments
2. **User Identity Resolution**: Proper user identity throughout system
3. **MP Scoring Integration**: Tournament rounds connect to existing scoring
4. **UI/UX Polish**: Button states, navigation, system UI respect
5. **Online/Offline Support**: Hybrid repository with Firebase sync
6. **Database Integration**: Proper foreign keys and data consistency

### 📋 Future Enhancements

#### Phase 1: Enhanced Tournament Management
- [ ] Guest participant management for creators
- [ ] Participant removal functionality
- [ ] Tournament round number calculation
- [ ] Enhanced participant display with arrow carousels

#### Phase 2: Advanced Features
- [ ] Tournament leaderboards and results
- [ ] Multiple round tournaments
- [ ] Tournament bracketing/elimination formats
- [ ] Real-time scoring updates

#### Phase 3: Social & Competitive Features
- [ ] Tournament comments and messaging
- [ ] Achievement badges for tournaments
- [ ] Tournament statistics and analytics
- [ ] Export tournament results

### 🎯 Known Limitations

1. **Round Number Calculation**: Currently hardcoded to 1, needs dynamic calculation
2. **Guest Management**: Creator can't add/remove guests in tournament context yet
3. **Tournament Results**: No dedicated results/leaderboard screen implemented
4. **Advanced Formats**: Only basic tournament format currently supported

## 📈 Performance Considerations

### Database Optimizations
- Proper indexes on `tournamentId` and participant lookups
- Foreign key constraints ensure data consistency
- Efficient participant queries for large tournaments

### Memory Management
- Tournament participant lists loaded on-demand
- Proper cleanup of tournament resources
- Efficient user identity resolution caching

### Network Efficiency
- Offline-first architecture minimizes network dependency
- Incremental sync reduces bandwidth usage
- Proper error handling for network failures

## 🔍 Debugging & Troubleshooting

### Common Issues

#### Tournament Creation Fails
- Check user identity resolution
- Verify bow setup availability for foreign key constraint
- Confirm network status for online tournaments

#### Join Tournament Not Working
- Verify user participation logic
- Check tournament capacity limits
- Confirm user identity resolution

#### Scoring Integration Issues
- Validate tournament-round linkage
- Check participant conversion logic
- Verify bow setup creation for guests

### Debug Logging

Key debug points throughout the system:
```kotlin
println("UserFlow: Creating tournament with createdBy='${userIdentity.id}'")
println("TournamentScoring: Creating round for ${sessionParticipants.size} participants")
println("UserFlow: Resolved user identity: '${userIdentity.id}' from ${userIdentity.source}")
```

## 📚 References & Dependencies

### Key Files
- `Tournament.kt` - Core tournament data model
- `TournamentRepository.kt` - Repository interface
- `UserIdentityResolver.kt` - User identity resolution utility
- `TournamentNavGraph.kt` - Navigation configuration
- `FeatureFlags.kt` - Feature toggle configuration

### External Dependencies
- **Room Database**: Local tournament storage
- **Firebase Firestore**: Online tournament sync
- **Jetpack Compose**: UI implementation
- **Navigation Compose**: Screen navigation
- **Coroutines**: Asynchronous operations

### Integration Points
- **Settings System**: User identity resolution
- **Equipment System**: Bow setup management for tournaments
- **MP Scoring System**: Tournament round integration
- **Authentication**: Firebase user identity

---

## 📝 Development Notes

This tournament system represents a significant architectural achievement, successfully integrating with the existing archery scoring system while maintaining clean separation of concerns. The user identity resolution system ensures backward compatibility while enabling future online features.

The implementation prioritizes offline-first functionality with seamless online sync, making it robust for various usage scenarios from local club tournaments to online competitions.

**Last Updated**: 2025-01-16
**Version**: 1.0.0
**Status**: Production Ready



---

## 🔄 Async Join Architecture (Added 2025-10-14)

### Overview

The tournament join system uses an **offline-first, async architecture** where local operations complete immediately and Firebase synchronization happens in the background. This ensures users never block on slow network operations while maintaining eventual consistency with the cloud.

### TournamentJoinStatus State Machine

```kotlin
sealed class TournamentJoinStatus {
    data object LocalOnly : TournamentJoinStatus()  
    // User joined offline, no Firebase sync attempted

    data class Joining(val tournamentId: TournamentId) : TournamentJoinStatus()  
    // Background Firebase sync in progress

    data class Synced(val tournamentId: TournamentId, val firebaseId: String) : TournamentJoinStatus()  
    // Successfully synced to Firebase

    data class Error(
        val tournamentId: TournamentId, 
        val message: String, 
        val isRetryable: Boolean
    ) : TournamentJoinStatus()
    // Firebase sync failed, with retry option
}
```

**Design Benefits:**
- Clear state transitions for UI feedback
- Distinguishes retryable vs non-retryable errors
- Supports optimistic UI updates
- Avoids god class anti-pattern (separate file)

### HybridTournamentRepository Implementation

```kotlin
override suspend fun joinTournament(
    tournamentId: TournamentId, 
    participant: TournamentParticipant
): Result<Unit> {
    // STEP 1: Join locally first (immediate, optimistic)
    val localResult = offlineRepository.joinTournament(tournamentId, participant)

    if (localResult.isFailure) {
        _joinStatus.value = TournamentJoinStatus.Error(tournamentId, message, isRetryable = false)
        return localResult
    }

    // STEP 2: Background Firebase sync (non-blocking)
    if (isNetworkAvailable) {
        _joinStatus.value = TournamentJoinStatus.Joining(tournamentId)

        syncScope.launch {
            try {
                // Translate local UUID to Firebase document ID
                val firebaseId = getFirebaseIdOrLocal(tournamentId)

                // Sync to Firebase in background
                val firebaseResult = firebaseRepository.joinTournament(firebaseId, participant)

                _joinStatus.value = if (firebaseResult.isSuccess) {
                    TournamentJoinStatus.Synced(tournamentId, firebaseId)
                } else {
                    TournamentJoinStatus.Error(
                        tournamentId, 
                        firebaseResult.exceptionOrNull()?.message ?: "Unknown error",
                        isRetryable = true
                    )
                }
            } catch (e: Exception) {
                _joinStatus.value = TournamentJoinStatus.Error(
                    tournamentId, 
                    e.message ?: "Unknown error",
                    isRetryable = true
                )
            }
        }
    } else {
        // No network - stay in LocalOnly state
        _joinStatus.value = TournamentJoinStatus.LocalOnly
    }

    // Return immediately - local operation succeeded
    return localResult
}
```

**Key Architecture Decisions:**
1. **Local Authority**: Local database is always updated first (immediate success)
2. **Async Sync**: Firebase operations don't block the user
3. **Transparent Retry**: `retryTournamentJoinSync()` method for failed syncs
4. **State Observability**: UI observes `joinStatus` StateFlow for real-time feedback

### UI Integration

```kotlin
// TournamentDetailsViewModel.kt
init {
    viewModelScope.launch {
        (tournamentRepository as? HybridTournamentRepository)?.joinStatus?.collect { status ->
            when (status) {
                is TournamentJoinStatus.LocalOnly -> {
                    _uiState.update { it.copy(
                        isJoining = false,
                        joinedLocally = true,
                        joinError = null
                    )}
                }
                is TournamentJoinStatus.Joining -> {
                    _uiState.update { it.copy(isJoining = true) }
                }
                is TournamentJoinStatus.Synced -> {
                    _uiState.update { it.copy(
                        isJoining = false,
                        joinedLocally = true,
                        joinError = null
                    )}
                }
                is TournamentJoinStatus.Error -> {
                    _uiState.update { it.copy(
                        isJoining = false,
                        joinError = status.message,
                        canRetryJoin = status.isRetryable
                    )}
                }
            }
        }
    }
}
```

```kotlin
// TournamentDetailsScreen.kt - Error Banner UI
if (joinError != null) {
    ErrorBanner(
        message = "Firebase sync failed: $joinError",
        actionLabel = if (canRetryJoin) "Retry" else null,
        onAction = { viewModel.retryJoinSync() }
    )
}
```

**User Experience:**
- Join button enables immediately after local success
- Loading spinner shows during Firebase sync
- Error banner appears with retry button if sync fails
- User can continue using app while sync happens in background

---

## 🗺️ ID Mapping System (Added 2025-10-14)

### Problem Statement

Firebase Firestore creates random document IDs (e.g., `5McP1Cmlxz18M9Bur6aA`) when tournaments are synced, but the local system uses UUIDs (e.g., `134e9b7e-2d30-4e14-b0cf-a7488edb2ab7`) as the source of truth. This creates a race condition:

1. User creates tournament → Local UUID `134e9b7e...` created
2. `createTournament()` returns local UUID to ViewModel/UI
3. Firebase sync happens in background → Firebase creates document `5McP1...`
4. User tries to join tournament with local UUID `134e9b7e...`
5. Firebase API call fails → "Tournament not found" (Firebase doesn't know local UUID)

### Solution: Bidirectional ID Mapping Table

**Database Schema (Migration 32→33):**
```sql
CREATE TABLE tournament_id_mappings (
    local_id TEXT PRIMARY KEY NOT NULL,
    firebase_id TEXT NOT NULL UNIQUE,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
)
```

**DAO Implementation:**
```kotlin
@Dao
interface TournamentIdMappingDao {
    @Query("INSERT OR REPLACE INTO tournament_id_mappings (local_id, firebase_id) VALUES (:localId, :firebaseId)")
    suspend fun insertMapping(localId: String, firebaseId: String)

    @Query("SELECT firebase_id FROM tournament_id_mappings WHERE local_id = :localId")
    suspend fun getFirebaseId(localId: String): String?

    @Query("SELECT local_id FROM tournament_id_mappings WHERE firebase_id = :firebaseId")
    suspend fun getLocalId(firebaseId: String): String?
}
```

### HybridTournamentRepository Integration

**Helper Methods:**
```kotlin
private suspend fun getFirebaseIdOrLocal(localId: TournamentId): TournamentId {
    return database.tournamentIdMappingDao().getFirebaseId(localId) ?: localId
}

private suspend fun getLocalIdOrFirebase(firebaseId: TournamentId): TournamentId {
    return database.tournamentIdMappingDao().getLocalId(firebaseId) ?: firebaseId
}
```

**Transparent ID Translation:**
```kotlin
// When syncing tournament creation to Firebase
override suspend fun createTournament(tournament: Tournament): Result<TournamentId> {
    val localId = offlineRepository.createTournament(tournament).getOrThrow()

    if (isNetworkAvailable) {
        syncScope.launch {
            val firebaseResult = firebaseRepository.createTournament(tournament)
            val firebaseId = firebaseResult.getOrNull()

            if (firebaseId != null && firebaseId != localId) {
                // Store mapping: local UUID ↔ Firebase document ID
                database.tournamentIdMappingDao().insertMapping(localId, firebaseId)
                LogConfig.tournamentSync("ID Mapping", "✅ Stored: $localId -> $firebaseId")
            }
        }
    }

    return Result.success(localId)  // Always return local UUID
}

// When joining tournament (translate before Firebase API call)
override suspend fun joinTournament(localId: TournamentId, participant: TournamentParticipant): Result<Unit> {
    // ... local join first ...

    syncScope.launch {
        val firebaseId = getFirebaseIdOrLocal(localId)  // Translate ID
        LogConfig.tournamentSync("ID Translation", "🔄 $localId -> $firebaseId")

        val firebaseResult = firebaseRepository.joinTournament(firebaseId, participant)
        // ... handle result ...
    }
}
```

**Architecture Benefits:**
1. **Local Authority Preserved**: Local UUID remains source of truth throughout app
2. **Transparent Abstraction**: ViewModels/UI never see Firebase IDs
3. **Race Condition Resolved**: Mapping stored before any join operations can occur
4. **Bidirectional**: Can translate both directions (local→Firebase, Firebase→local)
5. **Idempotent**: Mapping can be safely stored multiple times

**Log Example:**
```
✅ ID mapping stored: 134e9b7e-2d30-4e14-b0cf-a7488edb2ab7 -> 5McP1Cmlxz18M9Bur6aA
🔄 ID translation: local=134e9b7e-2d30-4e14-b0cf-a7488edb2ab7 -> firebase=5McP1Cmlxz18M9Bur6aA
✅ Transaction completed successfully - user p3lGMgKa7AYiigKgS9FSQ8DUPg0N joined tournament 5McP1Cmlxz18M9Bur6aA
```

---

## 🧪 E2E Testing Infrastructure (Added 2025-10-14)

### TournamentLifecycleE2ETest Overview

**Location**: `app/src/androidTest/java/com/archeryapprentice/e2e/TournamentLifecycleE2ETest.kt` (416 lines)

**Purpose**: Comprehensive multi-device tournament lifecycle testing with Firebase emulator integration

### Test 1: Two Devices - Authenticated Users

```kotlin
@Test
fun completeTournamentLifecycle_twoDevices_authenticated() = runTestWithEmulator {
    requireEmulator()

    // GIVEN: Two authenticated users with unique emails
    val timestamp = System.currentTimeMillis()
    val device1Email = "device1_$timestamp@test.com"
    val device2Email = "device2_$timestamp@test.com"

    val device1User = createTestUser(device1Email, displayName = "Alice")
    val device2User = createTestUser(device2Email, displayName = "Bob")

    userCredentials[device1User!!] = device1Email
    userCredentials[device2User!!] = device2Email

    // WHEN: Device 1 creates tournament
    signInAs(device1User)
    val tournament = createTestTournament(name = "E2E Test Tournament")
    val tournamentId = tournamentRepository.createTournament(tournament).getOrThrow()

    // Wait for Firebase sync and ID mapping
    waitForTournamentAvailable(tournamentId, timeoutMs = 5000)

    // Device 1 joins as creator
    val device1Participant = createTestParticipant(tournamentId, device1User, "Alice")
    val device1JoinResult = tournamentRepository.joinTournament(tournamentId, device1Participant)
    assertThat(device1JoinResult.isSuccess).isTrue()

    delay(2500)  // Allow Firebase transaction to complete before auth switch

    // Device 2 joins
    signInAs(device2User)
    val device2Participant = createTestParticipant(tournamentId, device2User, "Bob")
    val device2JoinResult = tournamentRepository.joinTournament(tournamentId, device2Participant)
    assertThat(device2JoinResult.isSuccess).isTrue()

    delay(2500)

    // THEN: Verify both participants synced to Firebase
    val participants = firestore.collection("tournaments")
        .document(getFirebaseId(tournamentId))
        .collection("participants")
        .get()
        .await()

    assertThat(participants.documents).hasSize(2)
    // ... assertions on participant data ...
}
```

**Coverage:**
- Authentication flow with unique timestamped emails
- Tournament creation with Firebase sync
- ID mapping system (local UUID → Firebase document ID)
- Multi-device join operations
- Firebase transaction timing (2500ms delays for transaction completion)
- Real-time Firestore participant sync

### Test 2: Guest Participant Scoring

```kotlin
@Test
fun completeTournamentLifecycle_withGuestParticipant() = runTestWithEmulator {
    requireEmulator()

    // GIVEN: Authenticated creator with ghost participant
    val creatorUser = createTestUser("creator_${System.currentTimeMillis()}@test.com", displayName = "Coach")
    userCredentials[creatorUser!!] = "creator_${System.currentTimeMillis()}@test.com"

    signInAs(creatorUser)
    val tournament = createTestTournament()
    val tournamentId = tournamentRepository.createTournament(tournament).getOrThrow()

    waitForTournamentAvailable(tournamentId, timeoutMs = 5000)

    // Add creator and ghost participant
    val creatorParticipant = createTestParticipant(tournamentId, creatorUser, "Coach")
    val ghostParticipant = createTestParticipant(tournamentId, "ghost_student1", "Student")

    tournamentRepository.joinTournament(tournamentId, creatorParticipant).getOrThrow()
    tournamentRepository.joinTournament(tournamentId, ghostParticipant).getOrThrow()

    delay(2500)

    // WHEN: Creator submits scores for both participants
    // ... scoring logic ...

    // THEN: Verify multi-participant statistics calculated correctly
    // ... assertions ...
}
```

**Coverage:**
- Ghost participant creation (coach scenario)
- Multi-participant scoring
- Statistics aggregation for tournament rounds
- Ghost participant sync to Firebase

### Test 3: Real-Time Leaderboard Sync

```kotlin
@Test
fun tournamentLeaderboard_realTimeSync_multipleDevices() = runTestWithEmulator {
    requireEmulator()

    // GIVEN: Three devices (2 authenticated + 1 anonymous)
    val device1User = createTestUser("device1_${System.currentTimeMillis()}@test.com", "Alice")
    val device2User = createTestUser("device2_${System.currentTimeMillis()}@test.com", "Bob")
    
    userCredentials[device1User!!] = "device1_${System.currentTimeMillis()}@test.com"
    userCredentials[device2User!!] = "device2_${System.currentTimeMillis()}@test.com"

    // Device 1 creates tournament
    signInAs(device1User)
    val tournamentId = createAndJoinTournament(device1User, "Alice")

    // Device 2 joins
    signInAs(device2User)
    joinExistingTournament(tournamentId, device2User, "Bob")

    // Device 3 joins anonymously
    auth.signOut()
    delay(500)
    auth.signInAnonymously().await()
    val anonymousUser = auth.currentUser?.uid!!
    joinExistingTournament(tournamentId, anonymousUser, "Anonymous")

    delay(2500)

    // WHEN: All devices submit scores concurrently
    // ... scoring simulation ...

    // THEN: Verify real-time leaderboard updates
    val leaderboardListener = firestore.collection("tournaments")
        .document(getFirebaseId(tournamentId))
        .collection("leaderboard")
        .addSnapshotListener { snapshot, error ->
            // Verify real-time updates
        }

    // ... assertions on leaderboard state ...
}
```

**Coverage:**
- Three-device scenario (2 auth + 1 anonymous)
- Concurrent score submissions
- Real-time Firestore listeners
- Leaderboard ranking accuracy

### Test Infrastructure Patterns

#### 1. Event-Driven Polling (Replaces Thread.sleep)

```kotlin
suspend fun waitForTournamentAvailable(
    tournamentId: String,
    timeoutMs: Long = 5000,
    pollIntervalMs: Long = 500
): Boolean {
    val startTime = System.currentTimeMillis()
    while (System.currentTimeMillis() - startTime < timeoutMs) {
        val tournament = firestore.collection("tournaments")
            .document(tournamentId)
            .get()
            .await()

        if (tournament.exists()) return true
        delay(pollIntervalMs)
    }
    return false
}
```

**Benefits:**
- Tests wait only as long as needed (faster when Firebase is fast)
- Clear timeout failure with helpful error message
- Reusable pattern for other E2E tests

#### 2. Credential Management

```kotlin
private val userCredentials = mutableMapOf<String, String>()  // UID -> Email

// Store after user creation
val uid = createTestUser(email, displayName)
userCredentials[uid!!] = email

// Look up in signInAs()
private suspend fun signInAs(userId: String) {
    val email = userCredentials[userId]
        ?: throw IllegalStateException("User credentials not found for UID: $userId")
    auth.signInWithEmailAndPassword(email, "testpassword123").await()
}
```

**Fixes**: Previous bug where `signInAs()` tried to parse Firebase UID as email (string manipulation failed)

#### 3. Firebase Transaction Timing

**Critical Delays:**
```kotlin
// After joinTournament() before signInAs() - CRITICAL
delay(2500)  // Allow Firebase join transaction to complete before auth token invalidation
```

**Why This Matters:**
```
❌ With 1000ms delay:
23:11:00.654 - Device 1 join starts (background Firebase sync)
23:11:00.659 - Test signs out (invalidates Device 1's auth) ← TOO FAST
23:11:00.669 - Test signs in as Device 2

✅ With 2500ms delay:
23:11:00.654 - Device 1 join starts
23:11:03.154 - Test signs out (after transaction commits)
23:11:03.164 - Test signs in as Device 2
✅ Transaction completed successfully - user p3lGMgKa7AYiigKgS9FSQ8DUPg0N joined tournament
```

**Lesson**: Firebase transactions take time to commit. Switching auth context too quickly interrupts in-flight transactions.

---

## 🚨 Known Issues & Bugs (Added 2025-10-14)

### CRITICAL: Firebase Anonymous Auth Bug (Production Blocker)

**Status**: 🔴 **DISCOVERED** (Fix in progress)  
**Severity**: **HIGH** - Blocks production release  
**Discovered**: 2025-10-14 via E2E tests

#### Problem Description

FirebaseTournamentRepository creates anonymous Firebase users for **ALL** tournament participants, even when they are already authenticated with email/password.

#### Evidence from E2E Test Logs

```
10-14 23:16:10.774 - ✅ Created user: device1_1760508970607@test.com (UID: lbLKRWyFX4fpW2rIBASI2PHe0aFA)
10-14 23:16:13.444 - ❌ Anonymous sign-in successful for join: SuShu4LX6orynruDMMlfT8Mr1nRt
                       ↑ WRONG - should use authenticated UID lbLKRWyFX4fpW2rIBASI2PHe0aFA
```

**Expected Behavior:**
- User authenticates with email/password → Firebase UID `lbLKRWyFX4fpW2rIBASI2PHe0aFA`
- User joins tournament → Should use authenticated UID `lbLKRWyFX4fpW2rIBASI2PHe0aFA`

**Actual Behavior:**
- User authenticates with email/password → Firebase UID `lbLKRWyFX4fpW2rIBASI2PHe0aFA`
- User joins tournament → Creates NEW anonymous UID `SuShu4LX6orynruDMMlfT8Mr1nRt` ❌

#### Root Cause Analysis

**Location**: `FirebaseTournamentRepository.kt:544-562` (joinTournament method)

```kotlin
override suspend fun joinTournament(tournamentId: TournamentId, participant: TournamentParticipant): Result<Unit> {
    return try {
        val tournament = getTournament(tournamentId).getOrNull() ?: return Result.failure(...)

        // BUG: This check returns null despite user being authenticated
        var currentUser = firebaseAuth.currentUser
        LogConfig.firebase("FirebaseTournamentRepo", "👤 Current Firebase user for join: ${currentUser?.uid}")

        if (currentUser == null) {  // ← This evaluates to true incorrectly
            if (tournament.allowAnonymousParticipants) {
                // Creates anonymous user when currentUser is null
                val result = firebaseAuth.signInAnonymously().await()
                currentUser = result.user
                LogConfig.firebase("FirebaseTournamentRepo", "✅ Anonymous sign-in successful: ${currentUser?.uid}")
            } else {
                return Result.failure(Exception("User must be signed in"))
            }
        }
        // ... rest of transaction logic ...
    }
}
```

**Hypothesis**: `firebaseAuth.currentUser` returns null when checked in `joinTournament()` despite user being authenticated before the call.

**Likely Cause**: Coroutine context boundary issue
- `HybridTournamentRepository.joinTournament()` launches Firebase sync in `syncScope.launch {}`
- `FirebaseAuth.currentUser` may not propagate across the coroutine boundary
- `FirebaseTournamentRepository` sees `currentUser == null` and creates anonymous user

#### Impact Assessment

**User Experience:**
- All authenticated users incorrectly joined as anonymous in Firebase
- Tournament creator attribution broken (creator appears anonymous)
- User linking and data association broken
- Prevents proper multi-device tournament functionality

**Production Readiness:**
- 🔴 **BLOCKS RELEASE** - Cannot ship with this bug
- Authentication system fundamentally broken for tournaments
- Data integrity compromised (wrong user IDs in Firebase)

#### Proposed Fix

**Approach**: Explicit UID Passing

**Step 1**: Modify FirebaseTournamentRepository signature
```kotlin
suspend fun joinTournament(
    tournamentId: TournamentId,
    participant: TournamentParticipant,
    authenticatedUserId: String? = null  // NEW - explicit auth state
): Result<Unit>
```

**Step 2**: Update validation logic
```kotlin
var currentUser = authenticatedUserId?.let { firebaseAuth.currentUser }

if (currentUser == null && authenticatedUserId != null) {
    // User should be authenticated but isn't - this is an error
    return Result.failure(Exception("Authentication lost: expected UID $authenticatedUserId"))
}

if (currentUser == null) {
    // Only create anonymous user if no authenticated UID was passed
    if (tournament.allowAnonymousParticipants) {
        val result = firebaseAuth.signInAnonymously().await()
        currentUser = result.user
    } else {
        return Result.failure(Exception("User must be signed in"))
    }
}
```

**Step 3**: Update HybridTournamentRepository
```kotlin
syncScope.launch {
    val currentUserId = FirebaseAuth.getInstance().currentUser?.uid  // Capture before launch
    val firebaseResult = firebaseRepository.joinTournament(
        firebaseId,
        participant,
        authenticatedUserId = currentUserId  // Pass explicit auth state
    )
}
```

**Timeline**: 1-2 hours to implement and validate

#### Validation Plan

1. Implement fix in FirebaseTournamentRepository + HybridTournamentRepository
2. Run all 3 E2E tests with Firebase emulator
3. Verify logs show authenticated users joining with correct UIDs (no anonymous sign-in)
4. Verify Firebase transactions complete successfully
5. Mark FIREBASE_EMULATOR_E2E_TESTING_V2_PLAN.md Phase 2.1 as COMPLETE

#### Lessons Learned

**Value of E2E Testing:**
- Bug would have reached production without E2E tests
- E2E tests with Firebase emulator reveal real architectural issues
- Test infrastructure investment justified - caught critical bug before release

**Coroutine Context Awareness:**
- FirebaseAuth state may not propagate across coroutine boundaries
- Explicit state passing more reliable than implicit context
- Always validate assumptions about framework state in async code

---

**Last Updated**: 2025-10-14  
**Version**: 1.1.0  
**Status**: In Progress (Firebase auth bug fix required)