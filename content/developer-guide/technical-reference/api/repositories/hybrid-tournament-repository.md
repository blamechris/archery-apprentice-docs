---
title: HybridTournamentRepository API Reference
tags:
  - api
  - repository
  - tournament
  - offline-first
  - sync
created: 2025-11-01
---

# HybridTournamentRepository API Reference

Offline-first tournament repository with automatic cloud synchronization.

---

## Overview

**File:** `data/repository/impl/HybridTournamentRepository.kt`
**Lines:** 1,506 lines
**Status:** ✅ Production

### Purpose

Implements offline-first architecture for tournament data:
- Local-first data access
- Automatic background sync
- Network connectivity monitoring
- Smart caching with TTL
- Conflict resolution

---

## Offline-First Pattern

```kotlin
override suspend fun getTournament(id: Long): Result<Tournament> {
    // 1. Return local data immediately
    val local = offlineRepo.getTournament(id).getOrNull()

    // 2. Sync with remote in background
    if (networkMonitor.isConnected) {
        viewModelScope.launch {
            val remote = firebaseRepo.getTournament(id).getOrNull()
            if (remote != null) {
                offlineRepo.updateTournament(remote)
            }
        }
    }

    return Result.success(local)
}
```

---

## Cache Strategy

| Tournament Status | TTL | Rationale |
|-------------------|-----|-----------|
| COMPLETED | Indefinite | Immutable data |
| IN_PROGRESS | 5 minutes | Balance freshness vs reads |
| PLANNED | 10 minutes | Rarely changes |

**Performance:** 50-90% reduction in Firebase reads, 5-10x faster load times

---

## Key Features

```kotlin
// Smart sync
fun enableAutoSync()
fun disableAutoSync()
fun forceSyncNow()

// Network monitoring
fun observeNetworkStatus(): Flow<NetworkStatus>

// Cache management
fun clearCache()
fun invalidateCache(tournamentId: Long)
```

---

## Usage Example

```kotlin
@Composable
fun TournamentScreen(
    tournamentId: Long,
    repository: HybridTournamentRepository
) {
    // Data loads from local cache immediately
    val tournament by repository
        .observeTournament(tournamentId)
        .collectAsState(initial = null)

    // Network status indicator
    val networkStatus by repository
        .observeNetworkStatus()
        .collectAsState(initial = NetworkStatus.UNKNOWN)

    tournament?.let { data ->
        TournamentContent(data)
    }

    if (networkStatus == NetworkStatus.OFFLINE) {
        OfflineBanner()
    }
}
```

---

## Related Documentation

- [[../../../../architecture/offline-first-architecture|Offline-First Architecture]]
- [[../../../flows/data-sync-flow|Data Sync Flow]]
- [[../services/tournament-sync-service|TournamentSyncService]]

---

**Status:** ✅ Production
**Lines:** 1,506 (god class - consider refactoring)
**Last Updated:** 2025-11-01
