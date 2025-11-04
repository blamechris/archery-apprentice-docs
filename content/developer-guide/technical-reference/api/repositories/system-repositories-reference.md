---
title: System Repositories Reference
tags:
  - api
  - repository
  - system
  - sync
  - user
created: 2025-11-01
---

# System Repositories Reference

Consolidated reference for system infrastructure repositories.

---

## Overview

System repositories handle user management, sync operations, conflict resolution, archiving, and data export.

**Repositories Covered (5):**
- UserRepository
- SyncQueueRepository
- ConflictResolutionRepository
- ArchiveRepository
- ExportRepository

---

## UserRepository

**File:** `data/repositories/UserRepository.kt`
**Purpose:** User profile and preferences management

### API

```kotlin
class UserRepository(
    private val userDao: UserDao,
    private val firebaseAuth: FirebaseAuth
) {
    // User management
    suspend fun createUser(
        email: String,
        displayName: String,
        firebaseUid: String?
    ): Result<User>

    suspend fun updateUser(user: User): Result<Unit>
    suspend fun deleteUser(userId: String): Result<Unit>

    // Query
    suspend fun getCurrentUser(): Result<User?>
    suspend fun getUserById(userId: String): Result<User?>
    suspend fun getUserByEmail(email: String): Result<User?>

    // Authentication
    suspend fun signIn(email: String, password: String): Result<User>
    suspend fun signOut(): Result<Unit>
    suspend fun updateLastLogin(userId: String): Result<Unit>

    // Preferences
    suspend fun updatePreferences(
        userId: String,
        preferences: UserPreferences
    ): Result<Unit>

    suspend fun getPreferences(userId: String): Result<UserPreferences>

    // Profile
    suspend fun updateProfile(
        userId: String,
        displayName: String? = null,
        photoUrl: String? = null,
        club: String? = null,
        division: String? = null
    ): Result<Unit>

    // Observe
    fun observeCurrentUser(): Flow<User?>
}

data class UserPreferences(
    val theme: String = "system",           // "light", "dark", "system"
    val units: String = "metric",           // "metric", "imperial"
    val notifications: Boolean = true,
    val autoSync: Boolean = true,
    val syncInterval: Int = 15,             // minutes
    val defaultBowSetupId: Long? = null,
    val defaultArrowSetupId: Long? = null
)
```

### Usage Examples

#### User Registration

```kotlin
// Create user after Firebase authentication
firebaseAuth.createUserWithEmailAndPassword(email, password)
    .addOnSuccessListener { authResult ->
        viewModelScope.launch {
            userRepository.createUser(
                email = email,
                displayName = displayName,
                firebaseUid = authResult.user?.uid
            ).onSuccess { user ->
                navigateToMain()
            }
        }
    }
```

#### Update Preferences

```kotlin
// Update user preferences
val preferences = UserPreferences(
    theme = "dark",
    units = "imperial",
    notifications = true,
    autoSync = true,
    syncInterval = 10
)

userRepository.updatePreferences(userId, preferences)
    .onSuccess {
        showMessage("Preferences updated")
        applyTheme(preferences.theme)
    }
```

#### Profile Management

```kotlin
// Update profile
userRepository.updateProfile(
    userId = currentUser.id,
    displayName = "Alice Archer",
    club = "City Archers",
    division = "RECURVE_WOMEN"
)

// Observe current user
@Composable
fun ProfileScreen() {
    val user by userRepository.observeCurrentUser()
        .collectAsState(initial = null)

    user?.let { currentUser ->
        ProfileCard(
            name = currentUser.displayName,
            email = currentUser.email,
            club = currentUser.club
        )
    }
}
```

---

## SyncQueueRepository

**File:** `data/repositories/SyncQueueRepository.kt`
**Purpose:** Manage offline sync queue

### API

```kotlin
class SyncQueueRepository(
    private val syncQueueDao: SyncQueueDao,
    private val firebaseService: FirebaseService
) {
    // Queue operations
    suspend fun queueForSync(
        entityType: EntityType,
        entityId: String,
        operation: SyncOperation,
        data: Any
    ): Result<Unit>

    suspend fun queueBatch(items: List<SyncQueueItem>): Result<Unit>

    // Process queue
    suspend fun processPendingQueue(): Result<ProcessResult>
    suspend fun processItem(itemId: String): Result<Unit>

    // Query
    suspend fun getAllPending(): Result<List<SyncQueueItem>>
    suspend fun getPendingCount(): Result<Int>
    suspend fun getPendingForEntityType(entityType: EntityType): Result<List<SyncQueueItem>>

    // Retry management
    suspend fun retryFailed(): Result<RetryResult>
    suspend fun clearFailedItems(): Result<Int>

    // Observe
    fun observePendingCount(): Flow<Int>
    fun observeQueueState(): Flow<QueueState>
}

enum class SyncOperation {
    CREATE,
    UPDATE,
    DELETE
}

data class ProcessResult(
    val processedCount: Int,
    val successCount: Int,
    val failedCount: Int,
    val errors: List<String>
)

data class RetryResult(
    val retriedCount: Int,
    val successCount: Int,
    val permanentFailures: Int
)

data class QueueState(
    val pendingCount: Int,
    val isProcessing: Boolean,
    val lastProcessedAt: Long?
)
```

### Usage Examples

#### Queue Items When Offline

```kotlin
// User creates round while offline
val round = Round(/* ... */)
roundRepository.insert(round)

// Queue for sync
syncQueueRepository.queueForSync(
    entityType = EntityType.ROUND,
    entityId = round.id.toString(),
    operation = SyncOperation.CREATE,
    data = round
)
```

#### Process Queue When Online

```kotlin
// Network becomes available
networkMonitor.observeNetworkState()
    .filter { it == NetworkState.ONLINE }
    .collect {
        // Process pending queue
        val result = syncQueueRepository.processPendingQueue()
            .getOrNull()

        if (result != null) {
            showMessage("Synced ${result.successCount} items")

            if (result.failedCount > 0) {
                showMessage("${result.failedCount} items failed to sync")
            }
        }
    }
```

#### Monitor Sync Queue

```kotlin
@Composable
fun SyncQueueIndicator() {
    val queueState by syncQueueRepository.observeQueueState()
        .collectAsState(initial = QueueState(0, false, null))

    if (queueState.pendingCount > 0) {
        Badge(text = "${queueState.pendingCount} pending") {
            Icon(Icons.Default.CloudUpload, "Sync")
        }
    }

    if (queueState.isProcessing) {
        CircularProgressIndicator()
    }
}
```

---

## ConflictResolutionRepository

**File:** `data/repositories/ConflictResolutionRepository.kt`
**Purpose:** Store and manage sync conflicts

### API

```kotlin
class ConflictResolutionRepository(
    private val conflictDao: ConflictDao,
    private val roundRepository: RoundRepository,
    private val tournamentRepository: TournamentRepository
) {
    // Store conflicts
    suspend fun storeConflict(conflict: DataConflict): Result<Unit>
    suspend fun storeConflicts(conflicts: List<DataConflict>): Result<Unit>

    // Query conflicts
    suspend fun getPendingConflicts(): Result<List<DataConflict>>
    suspend fun getPendingConflictsForEntity(
        entityType: EntityType
    ): Result<List<DataConflict>>
    suspend fun getPendingConflictCount(): Result<Int>

    // Resolve conflicts
    suspend fun resolveConflict(
        conflictId: String,
        resolution: ConflictResolution
    ): Result<Unit>

    suspend fun resolveConflicts(
        resolutions: List<ConflictResolution>
    ): Result<ResolveResult>

    suspend fun autoResolveConflicts(
        strategy: ResolutionStrategy = ResolutionStrategy.KEEP_NEWEST
    ): Result<AutoResolveResult>

    // History
    suspend fun getConflictHistory(entityId: String): Result<List<DataConflict>>
    suspend fun getRecentlyResolved(limit: Int = 10): Result<List<DataConflict>>

    // Cleanup
    suspend fun cleanupOldResolved(olderThan: Long): Result<Int>

    // Observe
    fun observePendingCount(): Flow<Int>
    fun observePendingConflicts(): Flow<List<DataConflict>>
}

data class ResolveResult(
    val resolvedCount: Int,
    val failedCount: Int,
    val errors: List<String>
)

data class AutoResolveResult(
    val autoResolvedCount: Int,
    val requiresManualCount: Int,
    val manualConflicts: List<DataConflict>
)
```

### Usage Examples

#### Store Detected Conflict

```kotlin
// During sync, conflict detected
val localRound = roundRepository.getRound(roundId)
val remoteRound = firebaseService.getRound(roundId)

if (localRound.modifiedAt != remoteRound.modifiedAt) {
    val conflict = DataConflict(
        entityType = EntityType.ROUND,
        entityId = roundId.toString(),
        conflictType = ConflictType.BOTH_MODIFIED,
        localData = localRound,
        remoteData = remoteRound,
        localTimestamp = localRound.modifiedAt,
        remoteTimestamp = remoteRound.modifiedAt
    )

    conflictRepository.storeConflict(conflict)
}
```

#### Auto-Resolve Conflicts

```kotlin
// Attempt auto-resolution
val result = conflictRepository.autoResolveConflicts(
    strategy = ResolutionStrategy.KEEP_NEWEST
).getOrThrow()

println("Auto-resolved: ${result.autoResolvedCount}")

// Show manual conflicts to user
if (result.requiresManualCount > 0) {
    showConflictResolutionUI(result.manualConflicts)
}
```

#### Manual Resolution

```kotlin
@Composable
fun ConflictResolutionScreen() {
    val conflicts by conflictRepository.observePendingConflicts()
        .collectAsState(initial = emptyList())

    LazyColumn {
        items(conflicts) { conflict ->
            ConflictCard(
                conflict = conflict,
                onResolve = { strategy ->
                    viewModelScope.launch {
                        conflictRepository.resolveConflict(
                            conflictId = conflict.id,
                            resolution = ConflictResolution(
                                conflictId = conflict.id,
                                strategy = strategy
                            )
                        )
                    }
                }
            )
        }
    }
}
```

---

## ArchiveRepository

**File:** `data/repositories/ArchiveRepository.kt`
**Purpose:** Archive old data to reduce database size

### API

```kotlin
class ArchiveRepository(
    private val database: AppDatabase,
    private val roundRepository: RoundRepository,
    private val compressionService: CompressionService
) {
    // Archive operations
    suspend fun archiveRound(roundId: Long): Result<ArchiveInfo>
    suspend fun archiveRounds(roundIds: List<Long>): Result<BulkArchiveResult>

    suspend fun archiveByDate(beforeDate: Long): Result<Int>
    suspend fun archiveByAge(olderThanDays: Int): Result<Int>

    // Restore
    suspend fun restoreArchive(archiveId: String): Result<Round>
    suspend fun restoreArchives(archiveIds: List<String>): Result<RestoreResult>

    // Query archives
    suspend fun getArchivedRounds(): Result<List<ArchivedRound>>
    suspend fun getArchiveById(archiveId: String): Result<ArchivedRound?>
    suspend fun searchArchives(query: String): Result<List<ArchivedRound>>

    // Delete archives
    suspend fun deleteArchive(archiveId: String): Result<Unit>
    suspend fun deleteOldArchives(olderThanDays: Int): Result<Int>

    // Export archive
    suspend fun exportArchive(archiveId: String): Result<File>

    // Statistics
    suspend fun getArchiveStats(): Result<ArchiveStats>
}

data class ArchiveInfo(
    val archiveId: String,
    val roundId: Long,
    val originalSize: Long,
    val compressedSize: Long,
    val compressionRatio: Double,
    val archivedAt: Long
)

data class BulkArchiveResult(
    val archivedCount: Int,
    val failedCount: Int,
    val totalSpaceSaved: Long,
    val errors: List<String>
)

data class RestoreResult(
    val restoredCount: Int,
    val failedCount: Int,
    val errors: List<String>
)

data class ArchiveStats(
    val totalArchives: Int,
    val totalSize: Long,
    val spaceSaved: Long,
    val oldestArchive: Long?,
    val newestArchive: Long?
)
```

### Usage Examples

#### Archive Old Rounds

```kotlin
// Archive rounds older than 1 year
val oneYearAgo = System.currentTimeMillis() - (365 * 24 * 60 * 60 * 1000L)

val count = archiveRepository.archiveByDate(oneYearAgo)
    .getOrThrow()

showMessage("Archived $count old rounds")
```

#### Restore Archived Round

```kotlin
// User wants to view old round
val archives = archiveRepository.getArchivedRounds().getOrThrow()

// Show archive selection
showArchiveList(archives) { selectedArchive ->
    viewModelScope.launch {
        archiveRepository.restoreArchive(selectedArchive.id)
            .onSuccess { round ->
                navigateToRound(round.id)
            }
    }
}
```

#### Archive Management

```kotlin
@Composable
fun ArchiveManagementScreen() {
    val stats by remember {
        viewModelScope.async {
            archiveRepository.getArchiveStats().getOrNull()
        }
    }.collectAsState(initial = null)

    stats?.let {
        Column {
            Text("Total Archives: ${it.totalArchives}")
            Text("Space Saved: ${formatBytes(it.spaceSaved)}")

            Button(onClick = {
                viewModelScope.launch {
                    // Delete archives older than 2 years
                    archiveRepository.deleteOldArchives(730)
                }
            }) {
                Text("Clean Up Old Archives")
            }
        }
    }
}
```

---

## ExportRepository

**File:** `data/repositories/ExportRepository.kt`
**Purpose:** Export data to various formats

### API

```kotlin
class ExportRepository(
    private val database: AppDatabase,
    private val exportService: ExportService,
    private val context: Context
) {
    // Export rounds
    suspend fun exportRound(
        roundId: Long,
        format: ExportFormat
    ): Result<File>

    suspend fun exportRounds(
        roundIds: List<Long>,
        format: ExportFormat
    ): Result<File>

    suspend fun exportAllRounds(format: ExportFormat): Result<File>

    // Export equipment
    suspend fun exportBowSetup(
        setupId: Long,
        format: ExportFormat
    ): Result<File>

    suspend fun exportAllEquipment(format: ExportFormat): Result<File>

    // Export tournaments
    suspend fun exportTournament(
        tournamentId: String,
        format: ExportFormat
    ): Result<File>

    // Export statistics
    suspend fun exportStatistics(
        dateRange: DateRange,
        format: ExportFormat
    ): Result<File>

    // Full backup
    suspend fun createFullBackup(): Result<File>
    suspend fun restoreFromBackup(backupFile: File): Result<RestoreResult>

    // Share exported file
    suspend fun shareExport(file: File): Result<Unit>

    // Export history
    suspend fun getExportHistory(): Result<List<ExportRecord>>
}

enum class ExportFormat {
    JSON,
    CSV,
    PDF,
    EXCEL,
    ARCHERY_GB,
    WA_IANSEO
}

data class ExportRecord(
    val id: String,
    val fileName: String,
    val format: ExportFormat,
    val exportedAt: Long,
    val fileSize: Long,
    val filePath: String
)

data class DateRange(
    val start: Long,
    val end: Long
)
```

### Usage Examples

#### Export Round to CSV

```kotlin
// Export round for spreadsheet analysis
exportRepository.exportRound(roundId, ExportFormat.CSV)
    .onSuccess { file ->
        showMessage("Exported to ${file.name}")

        // Share file
        exportRepository.shareExport(file)
    }
```

#### Export for Tournament Upload

```kotlin
// Export in World Archery format
exportRepository.exportRound(roundId, ExportFormat.WA_IANSEO)
    .onSuccess { file ->
        showDialog(
            title = "Ready for Upload",
            message = "File: ${file.name}\nYou can now upload this to the tournament system."
        )
    }
```

#### Full Backup and Restore

```kotlin
// Create full backup before major operation
val backupFile = exportRepository.createFullBackup()
    .getOrThrow()

showMessage("Backup created: ${backupFile.name}")

// Later, restore from backup
exportRepository.restoreFromBackup(backupFile)
    .onSuccess { result ->
        showMessage("""
            Restored:
            - ${result.roundsRestored} rounds
            - ${result.equipmentRestored} equipment setups
        """.trimIndent())
    }
```

#### Export Statistics Report

```kotlin
// Export season report
val seasonStart = parseDate("2025-01-01")
val seasonEnd = parseDate("2025-12-31")

exportRepository.exportStatistics(
    dateRange = DateRange(seasonStart, seasonEnd),
    format = ExportFormat.PDF
).onSuccess { file ->
    openFile(file)
}
```

---

## Integration Example

### Complete System Flow

```kotlin
class SystemManagementViewModel(
    private val userRepository: UserRepository,
    private val syncQueueRepository: SyncQueueRepository,
    private val conflictRepository: ConflictResolutionRepository,
    private val archiveRepository: ArchiveRepository,
    private val exportRepository: ExportRepository
) : ViewModel() {

    val currentUser = userRepository.observeCurrentUser()
    val syncQueueCount = syncQueueRepository.observePendingCount()
    val conflictCount = conflictRepository.observePendingCount()

    // Perform full maintenance
    suspend fun performMaintenance() {
        // 1. Process sync queue
        syncQueueRepository.processPendingQueue()

        // 2. Resolve conflicts
        conflictRepository.autoResolveConflicts()

        // 3. Archive old data
        val oneYearAgo = System.currentTimeMillis() - (365 * 24 * 60 * 60 * 1000L)
        archiveRepository.archiveByDate(oneYearAgo)

        // 4. Create backup
        exportRepository.createFullBackup()

        // 5. Clean up
        conflictRepository.cleanupOldResolved(oneYearAgo)
        archiveRepository.deleteOldArchives(730)  // 2 years
    }

    // System status
    suspend fun getSystemStatus(): SystemStatus {
        return SystemStatus(
            user = userRepository.getCurrentUser().getOrNull(),
            pendingSync = syncQueueRepository.getPendingCount().getOrNull() ?: 0,
            pendingConflicts = conflictRepository.getPendingConflictCount().getOrNull() ?: 0,
            archiveStats = archiveRepository.getArchiveStats().getOrNull()
        )
    }
}

data class SystemStatus(
    val user: User?,
    val pendingSync: Int,
    val pendingConflicts: Int,
    val archiveStats: ArchiveStats?
)
```

---

## Best Practices

### 1. User Data

```kotlin
// GOOD: Update last login
userRepository.updateLastLogin(userId)

// GOOD: Store preferences locally
userRepository.updatePreferences(userId, preferences)

// BAD: Storing sensitive data unencrypted
// Use Android Keystore for sensitive data
```

### 2. Sync Queue

```kotlin
// GOOD: Queue items when offline
if (!networkMonitor.isOnline()) {
    syncQueueRepository.queueForSync(entityType, entityId, operation, data)
}

// GOOD: Retry failed items with exponential backoff
syncQueueRepository.retryFailed()

// BAD: Infinite retries
while (syncQueueRepository.getPendingCount() > 0) {
    syncQueueRepository.processPendingQueue()  // May never complete
}
```

### 3. Archiving

```kotlin
// GOOD: Archive before deletion
archiveRepository.archiveRound(roundId)
roundDeletionService.deleteRound(roundId)

// GOOD: Compression for space savings
archiveRepository.archiveByAge(olderThanDays = 365)

// BAD: Deleting without archiving
roundDeletionService.deleteRound(roundId)  // Data lost
```

---

## Related Documentation

- [[../daos/tournament-system-daos-reference|Tournament & System DAOs Reference]]
- [[../services/sync-conflict-services-reference|Sync & Conflict Services]]
- [[../services/data-lifecycle-services-reference|Data Lifecycle Services]]
- [[../../flows/offline-sync-flow|Offline-First Sync Flow]]

---

**Status:** ✅ All 5 system repositories in production
**Pattern:** Offline-first with conflict resolution
**Integration:** Works across all entity types
**Last Updated:** 2025-11-01
