---
title: Sync & Conflict Services Reference
tags:
  - api
  - service
  - sync
  - conflict-resolution
  - firebase
created: 2025-11-01
---

# Sync & Conflict Services Reference

Reference for synchronization and conflict resolution services.

---

## Overview

These services handle cloud synchronization and conflict resolution for the offline-first architecture.

**Services Covered:**
- ConflictResolutionService
- SyncCoordinator

---

## ConflictResolutionService

**File:** `domain/services/ConflictResolutionService.kt`
**Purpose:** Resolve data conflicts between local and remote changes

### Conflict Types

```kotlin
enum class ConflictType {
    BOTH_MODIFIED,      // Local and remote both changed
    LOCAL_DELETED,      // Local deleted, remote modified
    REMOTE_DELETED,     // Remote deleted, local modified
    TIMESTAMP_MISMATCH  // Timestamps don't align
}

data class DataConflict(
    val id: String,
    val type: ConflictType,
    val localData: Any?,
    val remoteData: Any?,
    val localTimestamp: Long,
    val remoteTimestamp: Long,
    val entityType: EntityType
)

enum class EntityType {
    ROUND,
    END_SCORE,
    ARROW_SCORE,
    TOURNAMENT_SCORE,
    BOW_SETUP,
    EQUIPMENT_CONFIG
}
```

### Resolution Strategies

```kotlin
enum class ResolutionStrategy {
    KEEP_LOCAL,         // Use local version
    KEEP_REMOTE,        // Use remote version
    KEEP_NEWEST,        // Use most recent timestamp
    MERGE,              // Merge both versions
    MANUAL              // User decides
}

data class ConflictResolution(
    val conflictId: String,
    val strategy: ResolutionStrategy,
    val mergedData: Any? = null  // For MERGE strategy
)
```

### API

```kotlin
class ConflictResolutionService(
    private val roundRepository: RoundRepository,
    private val tournamentRepository: TournamentRepository,
    private val equipmentRepository: BowSetupRepository
) {
    // Detect conflicts
    suspend fun detectConflicts(
        entityType: EntityType,
        localData: List<Any>,
        remoteData: List<Any>
    ): Result<List<DataConflict>>

    // Resolve conflict
    suspend fun resolveConflict(
        conflict: DataConflict,
        resolution: ConflictResolution
    ): Result<Unit>

    // Batch resolve
    suspend fun resolveConflicts(
        resolutions: List<ConflictResolution>
    ): Result<Unit>

    // Auto-resolve simple conflicts
    suspend fun autoResolveConflicts(
        conflicts: List<DataConflict>,
        defaultStrategy: ResolutionStrategy = ResolutionStrategy.KEEP_NEWEST
    ): Result<AutoResolveResult>

    // Get pending conflicts
    suspend fun getPendingConflicts(): Result<List<DataConflict>>

    // Conflict history
    suspend fun getConflictHistory(
        entityId: String
    ): Result<List<ResolvedConflict>>
}

data class AutoResolveResult(
    val resolved: List<DataConflict>,
    val requiresManual: List<DataConflict>
)

data class ResolvedConflict(
    val conflict: DataConflict,
    val resolution: ConflictResolution,
    val resolvedAt: Long,
    val resolvedBy: String  // "auto" or user ID
)
```

### Usage Examples

#### Automatic Conflict Resolution

```kotlin
// Detect conflicts during sync
val conflicts = conflictService.detectConflicts(
    entityType = EntityType.ROUND,
    localData = localRounds,
    remoteData = remoteRounds
).getOrThrow()

// Auto-resolve simple conflicts
val result = conflictService.autoResolveConflicts(
    conflicts = conflicts,
    defaultStrategy = ResolutionStrategy.KEEP_NEWEST
).getOrThrow()

// Handle conflicts requiring manual resolution
if (result.requiresManual.isNotEmpty()) {
    showConflictResolutionUI(result.requiresManual)
}
```

#### Manual Conflict Resolution

```kotlin
// User chooses resolution
val resolution = ConflictResolution(
    conflictId = conflict.id,
    strategy = ResolutionStrategy.KEEP_LOCAL
)

conflictService.resolveConflict(conflict, resolution)
    .onSuccess {
        showMessage("Conflict resolved")
    }
    .onFailure { error ->
        showError("Failed to resolve: ${error.message}")
    }
```

#### Merge Strategy

```kotlin
// Merge both versions (e.g., combine arrow scores)
val localRound = conflict.localData as Round
val remoteRound = conflict.remoteData as Round

val mergedRound = Round(
    id = localRound.id,
    name = localRound.name,  // Keep local name
    date = maxOf(localRound.date, remoteRound.date),  // Newest date
    notes = "${localRound.notes}\n${remoteRound.notes}",  // Combine notes
    // ... merge other fields
)

val resolution = ConflictResolution(
    conflictId = conflict.id,
    strategy = ResolutionStrategy.MERGE,
    mergedData = mergedRound
)

conflictService.resolveConflict(conflict, resolution)
```

### Conflict Detection Algorithm

```kotlin
suspend fun detectConflicts(
    entityType: EntityType,
    localData: List<Any>,
    remoteData: List<Any>
): Result<List<DataConflict>> {
    val conflicts = mutableListOf<DataConflict>()

    val localMap = localData.associateBy { (it as HasId).id }
    val remoteMap = remoteData.associateBy { (it as HasId).id }

    // Check all local items
    localMap.forEach { (id, local) ->
        val remote = remoteMap[id]

        when {
            // Remote deleted, local modified
            remote == null && (local as HasTimestamp).modifiedAt > syncTimestamp -> {
                conflicts.add(DataConflict(
                    id = id,
                    type = ConflictType.REMOTE_DELETED,
                    localData = local,
                    remoteData = null,
                    localTimestamp = local.modifiedAt,
                    remoteTimestamp = 0,
                    entityType = entityType
                ))
            }

            // Both modified
            remote != null &&
            (local as HasTimestamp).modifiedAt > syncTimestamp &&
            (remote as HasTimestamp).modifiedAt > syncTimestamp -> {
                conflicts.add(DataConflict(
                    id = id,
                    type = ConflictType.BOTH_MODIFIED,
                    localData = local,
                    remoteData = remote,
                    localTimestamp = local.modifiedAt,
                    remoteTimestamp = remote.modifiedAt,
                    entityType = entityType
                ))
            }
        }
    }

    // Check remote items not in local (local deleted, remote modified)
    remoteMap.forEach { (id, remote) ->
        if (id !in localMap && (remote as HasTimestamp).modifiedAt > syncTimestamp) {
            conflicts.add(DataConflict(
                id = id,
                type = ConflictType.LOCAL_DELETED,
                localData = null,
                remoteData = remote,
                localTimestamp = 0,
                remoteTimestamp = remote.modifiedAt,
                entityType = entityType
            ))
        }
    }

    return Result.success(conflicts)
}
```

---

## SyncCoordinator

**File:** `data/services/SyncCoordinator.kt`
**Purpose:** Coordinate synchronization between local and remote data

### Sync Status

```kotlin
enum class SyncStatus {
    IDLE,
    SYNCING,
    SUCCESS,
    FAILED,
    CONFLICT_PENDING
}

data class SyncState(
    val status: SyncStatus,
    val lastSyncTime: Long?,
    val pendingChanges: Int,
    val pendingConflicts: Int,
    val error: String? = null
)
```

### API

```kotlin
class SyncCoordinator(
    private val roundRepository: RoundRepository,
    private val tournamentRepository: HybridTournamentRepository,
    private val equipmentRepository: BowSetupRepository,
    private val conflictService: ConflictResolutionService,
    private val syncQueueRepository: SyncQueueRepository
) {
    // Sync state
    val syncState: StateFlow<SyncState>

    // Start sync
    suspend fun sync(): Result<SyncResult>

    // Sync specific entity type
    suspend fun syncEntityType(entityType: EntityType): Result<SyncResult>

    // Force sync (ignore cache)
    suspend fun forceSync(): Result<SyncResult>

    // Push pending changes
    suspend fun pushPendingChanges(): Result<PushResult>

    // Pull remote changes
    suspend fun pullRemoteChanges(): Result<PullResult>

    // Get pending changes count
    suspend fun getPendingChangesCount(): Int

    // Enable/disable auto-sync
    fun setAutoSync(enabled: Boolean)

    // Sync interval
    fun setSyncInterval(minutes: Int)

    // Cancel ongoing sync
    fun cancelSync()
}

data class SyncResult(
    val success: Boolean,
    val syncedEntities: Int,
    val conflicts: List<DataConflict>,
    val errors: List<String>,
    val duration: Long  // milliseconds
)

data class PushResult(
    val pushedCount: Int,
    val failedCount: Int,
    val errors: List<String>
)

data class PullResult(
    val pulledCount: Int,
    val conflicts: List<DataConflict>,
    val errors: List<String>
)
```

### Usage Examples

#### Basic Sync

```kotlin
// Start sync
syncCoordinator.sync()
    .onSuccess { result ->
        if (result.conflicts.isNotEmpty()) {
            showConflictUI(result.conflicts)
        } else {
            showMessage("Synced ${result.syncedEntities} items")
        }
    }
    .onFailure { error ->
        showError("Sync failed: ${error.message}")
    }
```

#### Observe Sync State

```kotlin
@Composable
fun SyncStatusIndicator(
    syncCoordinator: SyncCoordinator
) {
    val syncState by syncCoordinator.syncState.collectAsState()

    when (syncState.status) {
        SyncStatus.IDLE -> {
            if (syncState.pendingChanges > 0) {
                Badge(text = "${syncState.pendingChanges} pending")
            }
        }

        SyncStatus.SYNCING -> {
            CircularProgressIndicator()
        }

        SyncStatus.SUCCESS -> {
            Icon(Icons.Default.Check, "Synced")
            syncState.lastSyncTime?.let { time ->
                Text("Last sync: ${formatRelativeTime(time)}")
            }
        }

        SyncStatus.FAILED -> {
            Icon(Icons.Default.Error, "Failed", tint = Color.Red)
            syncState.error?.let { Text(it, color = Color.Red) }
        }

        SyncStatus.CONFLICT_PENDING -> {
            Badge(text = "${syncState.pendingConflicts} conflicts")
            Button(onClick = { showConflictResolution() }) {
                Text("Resolve")
            }
        }
    }
}
```

#### Auto-Sync Configuration

```kotlin
// Enable auto-sync every 15 minutes
syncCoordinator.setAutoSync(enabled = true)
syncCoordinator.setSyncInterval(minutes = 15)

// Sync only specific entity
viewModelScope.launch {
    syncCoordinator.syncEntityType(EntityType.TOURNAMENT_SCORE)
}
```

#### Manual Push/Pull

```kotlin
// Push local changes first
val pushResult = syncCoordinator.pushPendingChanges().getOrThrow()
println("Pushed ${pushResult.pushedCount} changes")

// Then pull remote changes
val pullResult = syncCoordinator.pullRemoteChanges().getOrThrow()
if (pullResult.conflicts.isNotEmpty()) {
    handleConflicts(pullResult.conflicts)
}
```

### Sync Queue

```kotlin
data class SyncQueueItem(
    val id: String,
    val entityType: EntityType,
    val entityId: String,
    val operation: SyncOperation,
    val data: String,  // JSON serialized
    val timestamp: Long,
    val retryCount: Int = 0
)

enum class SyncOperation {
    CREATE,
    UPDATE,
    DELETE
}

// Add to sync queue when offline
suspend fun queueForSync(entity: Any, operation: SyncOperation) {
    val item = SyncQueueItem(
        id = UUID.randomUUID().toString(),
        entityType = entity.toEntityType(),
        entityId = entity.getId(),
        operation = operation,
        data = Json.encodeToString(entity),
        timestamp = System.currentTimeMillis()
    )

    syncQueueRepository.insert(item)
}
```

---

## Integration Example

### Complete Sync Flow with Conflict Resolution

```kotlin
class SyncViewModel(
    private val syncCoordinator: SyncCoordinator,
    private val conflictService: ConflictResolutionService
) : ViewModel() {

    val syncState = syncCoordinator.syncState
    val pendingConflicts = MutableStateFlow<List<DataConflict>>(emptyList())

    fun performSync() {
        viewModelScope.launch {
            // Start sync
            val result = syncCoordinator.sync().getOrNull()
                ?: return@launch

            // Handle conflicts
            if (result.conflicts.isNotEmpty()) {
                // Try auto-resolve
                val autoResolved = conflictService.autoResolveConflicts(
                    conflicts = result.conflicts,
                    defaultStrategy = ResolutionStrategy.KEEP_NEWEST
                ).getOrNull()

                // Show manual conflicts to user
                if (autoResolved != null && autoResolved.requiresManual.isNotEmpty()) {
                    pendingConflicts.value = autoResolved.requiresManual
                }
            }
        }
    }

    fun resolveConflict(conflict: DataConflict, strategy: ResolutionStrategy) {
        viewModelScope.launch {
            val resolution = ConflictResolution(
                conflictId = conflict.id,
                strategy = strategy
            )

            conflictService.resolveConflict(conflict, resolution)
                .onSuccess {
                    // Remove from pending
                    pendingConflicts.value = pendingConflicts.value
                        .filter { it.id != conflict.id }

                    // Retry sync
                    performSync()
                }
        }
    }
}
```

---

## Best Practices

### 1. Conflict Prevention

```kotlin
// GOOD: Frequent syncs reduce conflicts
syncCoordinator.setSyncInterval(minutes = 5)

// GOOD: Sync before major operations
suspend fun startTournament(id: String) {
    syncCoordinator.sync()  // Ensure latest data
    tournamentService.startTournament(id)
}

// BAD: Rarely syncing increases conflict probability
syncCoordinator.setSyncInterval(minutes = 1440)  // Once per day
```

### 2. Conflict Resolution

```kotlin
// GOOD: Auto-resolve when safe
val result = conflictService.autoResolveConflicts(
    conflicts = conflicts,
    defaultStrategy = ResolutionStrategy.KEEP_NEWEST
)

// GOOD: Let user decide for important data
if (conflict.entityType == EntityType.TOURNAMENT_SCORE) {
    showManualResolutionUI(conflict)
}

// BAD: Always keeping local might lose remote changes
conflictService.resolveConflict(conflict, ConflictResolution(
    conflictId = conflict.id,
    strategy = ResolutionStrategy.KEEP_LOCAL  // Always local
))
```

### 3. Error Handling

```kotlin
// GOOD: Graceful degradation
syncCoordinator.sync()
    .onFailure { error ->
        logError("Sync failed", error)
        // App still works offline
        showNotification("Working offline")
    }

// BAD: Blocking on sync
val result = syncCoordinator.sync().getOrThrow()  // Crashes if sync fails
```

---

## Related Documentation

- [[../repositories/hybrid-tournament-repository|HybridTournamentRepository]]
- [[../repositories/sync-queue-repository|SyncQueueRepository]]
- [[../../../../architecture/offline-first-sync|Offline-First Sync Architecture]]
- [[tournament-cache-service|TournamentScoreCacheService]]

---

**Status:** ✅ In production with offline-first architecture
**Pattern:** Conflict detection + resolution strategies
**Integration:** Works with all repositories for cloud sync
**Last Updated:** 2025-11-01
