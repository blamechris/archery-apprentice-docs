---
title: TournamentRepository Interface API Reference
tags:
  - api
  - repository
  - tournament
  - interface
  - god-interface
created: 2025-11-01
---

# TournamentRepository Interface API Reference

Abstract interface for tournament data operations.

---

## Overview

**File:** `data/repository/TournamentRepository.kt`
**Lines:** 395 lines
**Methods:** 51 methods
**Status:** ✅ Production | ⚠️ **God Interface - Needs Refactoring**

### Purpose

Defines contract for tournament data operations:
- Tournament CRUD
- Participant management
- Score submission
- Leaderboard queries
- Synchronization

### Critical Status

⚠️ **God Interface Warning:** 51 methods (3.4x recommended maximum of 15)

**Recommended Refactoring:** Split into 4 focused interfaces:
1. **TournamentCrudRepository** (~12 methods)
2. **TournamentSyncRepository** (~15 methods)
3. **TournamentScoreRepository** (~18 methods)
4. **TournamentAnalyticsRepository** (~6 methods)

---

## Implementations

### OfflineTournamentRepository
**File:** `data/repository/impl/OfflineTournamentRepository.kt`
**Lines:** 908 lines
**Purpose:** Local Room database storage

### FirebaseTournamentRepository
**File:** `data/repository/impl/FirebaseTournamentRepository.kt`
**Lines:** 1,707 lines (⚠️ God class - 4.3x too large)
**Purpose:** Cloud Firestore synchronization

### HybridTournamentRepository
**File:** `data/repository/impl/HybridTournamentRepository.kt`
**Lines:** 1,506 lines
**Purpose:** Offline-first with automatic sync

**See:** [[hybrid-tournament-repository|HybridTournamentRepository]]

---

## Key Method Groups

### Tournament CRUD (12 methods)

```kotlin
interface TournamentRepository {
    suspend fun createTournament(tournament: Tournament): Result<String>
    suspend fun getTournament(id: String): Result<Tournament?>
    suspend fun updateTournament(tournament: Tournament): Result<Unit>
    suspend fun deleteTournament(id: String): Result<Unit>

    suspend fun getAllTournaments(): Result<List<Tournament>>
    fun observeTournament(id: String): Flow<Tournament?>
    fun observeAllTournaments(): Flow<List<Tournament>>

    suspend fun searchTournaments(query: String): Result<List<Tournament>>
    suspend fun getTournamentsByStatus(status: TournamentStatus): Result<List<Tournament>>
    suspend fun getTournamentsByDateRange(start: Long, end: Long): Result<List<Tournament>>

    suspend fun archiveTournament(id: String): Result<Unit>
    suspend fun restoreTournament(id: String): Result<Unit>
}
```

### Score Operations (18 methods)

```kotlin
    // Score submission
    suspend fun submitScore(
        tournamentId: String,
        participantId: String,
        endNumber: Int,
        score: Int
    ): Result<Unit>

    // Leaderboard
    suspend fun getLeaderboard(tournamentId: String): Result<List<LeaderboardEntry>>
    fun observeLeaderboard(tournamentId: String): Flow<List<LeaderboardEntry>>

    // Participant scores
    suspend fun getParticipantScore(
        tournamentId: String,
        participantId: String
    ): Result<Int>

    suspend fun getParticipantEndScores(
        tournamentId: String,
        participantId: String
    ): Result<List<EndScore>>

    // ... 13 more score-related methods
```

### Synchronization (15 methods)

```kotlin
    // Sync operations
    suspend fun syncTournament(tournamentId: String): Result<Unit>
    suspend fun syncAllTournaments(): Result<Unit>

    fun observeSyncStatus(): Flow<SyncStatus>

    suspend fun resolveConflict(
        conflictId: String,
        resolution: ConflictResolution
    ): Result<Unit>

    // ... 11 more sync-related methods
```

### Analytics (6 methods)

```kotlin
    // Statistics
    suspend fun getTournamentStatistics(id: String): Result<TournamentStats>
    suspend fun getParticipantStatistics(
        tournamentId: String,
        participantId: String
    ): Result<ParticipantStats>

    // ... 4 more analytics methods
```

---

## Usage Example

```kotlin
class TournamentViewModel(
    private val repository: TournamentRepository  // Could be Offline, Firebase, or Hybrid
) : ViewModel() {
    fun loadTournament(id: String) {
        viewModelScope.launch {
            // Repository handles implementation details
            val tournament = repository.getTournament(id).getOrNull()

            _uiState.update { state ->
                state.copy(tournament = tournament)
            }
        }
    }

    fun submitEndScore(endNumber: Int, score: Int) {
        viewModelScope.launch {
            repository.submitScore(
                tournamentId = currentTournamentId,
                participantId = currentParticipantId,
                endNumber = endNumber,
                score = score
            )
        }
    }
}
```

---

## Dependency Injection

```kotlin
// Application provides implementation
@Provides
@Singleton
fun provideTournamentRepository(
    offlineRepo: OfflineTournamentRepository,
    firebaseRepo: FirebaseTournamentRepository,
    networkMonitor: NetworkMonitor
): TournamentRepository {
    // Return hybrid implementation for offline-first
    return HybridTournamentRepository(
        offlineRepo = offlineRepo,
        firebaseRepo = firebaseRepo,
        networkMonitor = networkMonitor
    )
}
```

---

## Problems and Recommendations

### Current Problems

1. **Too Many Methods:** 51 methods violate Interface Segregation Principle
2. **Mixed Concerns:** CRUD, sync, scores, analytics all in one interface
3. **Implementation Burden:** Each implementation must implement all 51 methods
4. **Hard to Mock:** Testing requires mocking 51 methods
5. **God Implementations:** FirebaseTournamentRepository is 1,707 lines

### Recommended Refactoring

**Split into 4 focused interfaces:**

```kotlin
// 1. Core CRUD operations
interface TournamentCrudRepository {
    suspend fun createTournament(tournament: Tournament): Result<String>
    suspend fun getTournament(id: String): Result<Tournament?>
    suspend fun updateTournament(tournament: Tournament): Result<Unit>
    suspend fun deleteTournament(id: String): Result<Unit>
    // ... 8 more CRUD methods
}

// 2. Synchronization
interface TournamentSyncRepository {
    suspend fun syncTournament(id: String): Result<Unit>
    fun observeSyncStatus(): Flow<SyncStatus>
    suspend fun resolveConflict(
        conflictId: String,
        resolution: ConflictResolution
    ): Result<Unit>
    // ... 12 more sync methods
}

// 3. Score management
interface TournamentScoreRepository {
    suspend fun submitScore(...): Result<Unit>
    suspend fun getLeaderboard(id: String): Result<List<LeaderboardEntry>>
    fun observeLeaderboard(id: String): Flow<List<LeaderboardEntry>>
    // ... 15 more score methods
}

// 4. Analytics
interface TournamentAnalyticsRepository {
    suspend fun getTournamentStatistics(id: String): Result<TournamentStats>
    suspend fun getParticipantStatistics(...): Result<ParticipantStats>
    // ... 4 more analytics methods
}
```

**Benefits:**
- Clearer responsibilities
- Easier testing (mock only what you need)
- Simpler implementations
- Better maintainability

---

## Related Documentation

- [[hybrid-tournament-repository|HybridTournamentRepository Implementation]]
- [[../services/tournament-sync-service|TournamentSyncService]]
- [[../../../../internal/project-tracking/checkpoint-findings#critical-5-repository-god-classes|God Class Analysis]]

---

**Status:** ✅ Production | ⚠️ God Interface - Needs Refactoring
**Methods:** 51 (3.4x recommended maximum)
**Total Implementation Code:** 5,959 lines across 3 implementations
**Last Updated:** 2025-11-01
