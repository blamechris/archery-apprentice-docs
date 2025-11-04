---
title: Data Lifecycle Services Reference
tags:
  - api
  - service
  - data-management
  - export
  - import
  - archive
created: 2025-11-01
---

# Data Lifecycle Services Reference

Reference for data management, archive, export, and import services.

---

## Overview

These services handle the full lifecycle of data: deletion, archiving, export, import, and notifications.

**Services Covered:**
- RoundDeletionService
- ArchiveService
- ExportService
- ImportService
- NotificationService

---

## RoundDeletionService

**File:** `domain/services/RoundDeletionService.kt`
**Purpose:** Safe deletion of rounds with cascade and undo support

### API

```kotlin
class RoundDeletionService(
    private val roundRepository: RoundRepository,
    private val endScoreRepository: EndScoreRepository,
    private val arrowScoreRepository: ArrowScoreRepository
) {
    // Delete round with all related data
    suspend fun deleteRound(roundId: Long): Result<DeletionResult>

    // Soft delete (mark as deleted, keep data)
    suspend fun softDeleteRound(roundId: Long): Result<Unit>

    // Restore soft-deleted round
    suspend fun restoreRound(roundId: Long): Result<Unit>

    // Permanent delete
    suspend fun permanentlyDeleteRound(roundId: Long): Result<Unit>

    // Get deleted rounds
    suspend fun getDeletedRounds(): Result<List<Round>>

    // Bulk delete
    suspend fun deleteRounds(roundIds: List<Long>): Result<BulkDeletionResult>

    // Delete old rounds
    suspend fun deleteRoundsOlderThan(timestamp: Long): Result<Int>
}

data class DeletionResult(
    val roundDeleted: Boolean,
    val endScoresDeleted: Int,
    val arrowScoresDeleted: Int,
    val equipmentUnlinked: Boolean
)

data class BulkDeletionResult(
    val successCount: Int,
    val failedCount: Int,
    val errors: List<String>
)
```

### Usage Examples

#### Safe Deletion with Undo

```kotlin
// Soft delete with undo option
roundDeletionService.softDeleteRound(roundId)
    .onSuccess {
        showUndoSnackbar(
            message = "Round deleted",
            action = "Undo",
            onUndo = {
                viewModelScope.launch {
                    roundDeletionService.restoreRound(roundId)
                }
            }
        )
    }
```

#### Cascade Deletion

```kotlin
// Delete round with all related data
val result = roundDeletionService.deleteRound(roundId)
    .getOrThrow()

println("Deleted round with:")
println("- ${result.endScoresDeleted} ends")
println("- ${result.arrowScoresDeleted} arrows")
```

#### Cleanup Old Data

```kotlin
// Delete rounds older than 1 year
val oneYearAgo = System.currentTimeMillis() - (365 * 24 * 60 * 60 * 1000L)
val deletedCount = roundDeletionService.deleteRoundsOlderThan(oneYearAgo)
    .getOrThrow()

println("Cleaned up $deletedCount old rounds")
```

---

## ArchiveService

**File:** `domain/services/ArchiveService.kt`
**Purpose:** Archive old data to reduce active database size

### API

```kotlin
class ArchiveService(
    private val roundRepository: RoundRepository,
    private val database: AppDatabase
) {
    // Archive round
    suspend fun archiveRound(roundId: Long): Result<ArchiveInfo>

    // Archive multiple rounds
    suspend fun archiveRounds(roundIds: List<Long>): Result<BulkArchiveResult>

    // Archive by criteria
    suspend fun archiveRoundsOlderThan(timestamp: Long): Result<Int>
    suspend fun archiveRoundsBefore(date: Long): Result<Int>

    // Restore archived round
    suspend fun restoreArchivedRound(archiveId: String): Result<Round>

    // Get archived rounds
    suspend fun getArchivedRounds(): Result<List<ArchivedRound>>

    // Permanent delete archived data
    suspend fun deleteArchivedRound(archiveId: String): Result<Unit>

    // Export archive to file
    suspend fun exportArchive(archiveId: String): Result<File>
}

data class ArchivedRound(
    val archiveId: String,
    val roundId: Long,
    val roundName: String,
    val archivedAt: Long,
    val dataSize: Long,  // bytes
    val canRestore: Boolean
)

data class ArchiveInfo(
    val archiveId: String,
    val originalSize: Long,
    val compressedSize: Long,
    val compressionRatio: Double
)

data class BulkArchiveResult(
    val archivedCount: Int,
    val failedCount: Int,
    val totalSizeSaved: Long
)
```

### Usage Examples

#### Archive Old Rounds

```kotlin
// Archive rounds from previous season
val lastSeasonEnd = parseDate("2024-12-31")
val result = archiveService.archiveRoundsBefore(lastSeasonEnd)
    .getOrThrow()

showMessage("Archived $result rounds from previous season")
```

#### Restore Archived Round

```kotlin
// User wants to view old round
val archivedRounds = archiveService.getArchivedRounds().getOrThrow()

// Restore specific round
archiveService.restoreArchivedRound(archiveId)
    .onSuccess { round ->
        navigateToRound(round.id)
    }
```

---

## ExportService

**File:** `domain/services/ExportService.kt`
**Purpose:** Export data to various formats

### Export Formats

```kotlin
enum class ExportFormat {
    JSON,           // JSON format
    CSV,            // CSV spreadsheet
    PDF,            // PDF report
    ARCHERY_GB,     // Archery GB format
    WA_IANSEO       // World Archery Ianseo format
}

data class ExportOptions(
    val format: ExportFormat,
    val includeEquipment: Boolean = true,
    val includeStatistics: Boolean = true,
    val includeNotes: Boolean = true,
    val dateRange: DateRange? = null
)
```

### API

```kotlin
class ExportService(
    private val roundRepository: RoundRepository,
    private val equipmentRepository: BowSetupRepository,
    private val statisticsService: StatisticsCalculationService
) {
    // Export single round
    suspend fun exportRound(
        roundId: Long,
        options: ExportOptions
    ): Result<File>

    // Export multiple rounds
    suspend fun exportRounds(
        roundIds: List<Long>,
        options: ExportOptions
    ): Result<File>

    // Export all data
    suspend fun exportAllData(
        options: ExportOptions
    ): Result<File>

    // Export statistics report
    suspend fun exportStatisticsReport(
        dateRange: DateRange,
        format: ExportFormat = ExportFormat.PDF
    ): Result<File>

    // Export equipment configuration
    suspend fun exportEquipmentSetup(
        setupId: Long,
        format: ExportFormat = ExportFormat.JSON
    ): Result<File>

    // Share exported file
    suspend fun shareExport(file: File): Result<Unit>
}
```

### Usage Examples

#### Export Round to CSV

```kotlin
val options = ExportOptions(
    format = ExportFormat.CSV,
    includeEquipment = true,
    includeStatistics = true
)

exportService.exportRound(roundId, options)
    .onSuccess { file ->
        shareExport(file)
    }
```

#### Export Season Report

```kotlin
val seasonStart = parseDate("2025-01-01")
val seasonEnd = parseDate("2025-12-31")

val options = ExportOptions(
    format = ExportFormat.PDF,
    dateRange = DateRange(seasonStart, seasonEnd),
    includeStatistics = true
)

exportService.exportStatisticsReport(
    dateRange = DateRange(seasonStart, seasonEnd),
    format = ExportFormat.PDF
)
```

#### Export for Competition

```kotlin
// Export in World Archery format for tournament upload
val options = ExportOptions(
    format = ExportFormat.WA_IANSEO,
    includeEquipment = false,  // Competition format doesn't need equipment
    includeNotes = false
)

exportService.exportRound(roundId, options)
    .onSuccess { file ->
        showMessage("Ready to upload to tournament system")
        shareExport(file)
    }
```

---

## ImportService

**File:** `domain/services/ImportService.kt`
**Purpose:** Import data from various sources

### API

```kotlin
class ImportService(
    private val roundRepository: RoundRepository,
    private val equipmentRepository: BowSetupRepository,
    private val validationService: ValidationService
) {
    // Import from file
    suspend fun importFromFile(
        file: File,
        format: ExportFormat
    ): Result<ImportResult>

    // Import round data
    suspend fun importRound(
        data: String,
        format: ExportFormat
    ): Result<Round>

    // Import equipment setup
    suspend fun importEquipmentSetup(
        data: String,
        format: ExportFormat
    ): Result<BowSetup>

    // Import from backup
    suspend fun importFromBackup(
        backupFile: File
    ): Result<ImportResult>

    // Validate import data
    suspend fun validateImportData(
        data: String,
        format: ExportFormat
    ): Result<ValidationResult>

    // Preview import
    suspend fun previewImport(
        file: File,
        format: ExportFormat
    ): Result<ImportPreview>
}

data class ImportResult(
    val roundsImported: Int,
    val equipmentImported: Int,
    val errors: List<String>,
    val warnings: List<String>
)

data class ImportPreview(
    val rounds: List<RoundPreview>,
    val equipment: List<EquipmentPreview>,
    val conflicts: List<String>
)

data class RoundPreview(
    val name: String,
    val date: Long,
    val arrowCount: Int,
    val willOverwrite: Boolean
)
```

### Usage Examples

#### Import from CSV

```kotlin
// User selects CSV file
val file = filePickerResult

// Preview first
val preview = importService.previewImport(file, ExportFormat.CSV)
    .getOrThrow()

showPreviewDialog(preview) { confirmed ->
    if (confirmed) {
        importService.importFromFile(file, ExportFormat.CSV)
            .onSuccess { result ->
                showMessage("Imported ${result.roundsImported} rounds")
            }
    }
}
```

#### Import Equipment Configuration

```kotlin
// Import shared bow setup from JSON
val jsonData = """
{
  "name": "Competition Recurve",
  "manufacturer": "Hoyt",
  "model": "Formula HPX",
  "sight": { ... },
  "stabilizer": { ... }
}
"""

importService.importEquipmentSetup(jsonData, ExportFormat.JSON)
    .onSuccess { bowSetup ->
        showMessage("Equipment imported: ${bowSetup.name}")
    }
```

#### Restore from Backup

```kotlin
// Restore from backup file
importService.importFromBackup(backupFile)
    .onSuccess { result ->
        showDialog(
            title = "Restore Complete",
            message = """
                Restored:
                - ${result.roundsImported} rounds
                - ${result.equipmentImported} equipment setups
            """.trimIndent()
        )
    }
```

---

## NotificationService

**File:** `domain/services/NotificationService.kt`
**Purpose:** Manage app notifications and reminders

### Notification Types

```kotlin
enum class NotificationType {
    ROUND_REMINDER,         // Reminder to shoot
    TOURNAMENT_START,       // Tournament starting soon
    SYNC_COMPLETE,          // Sync completed
    SYNC_CONFLICT,          // Sync conflict needs attention
    ACHIEVEMENT_UNLOCKED,   // New personal best
    EQUIPMENT_MAINTENANCE,  // String replacement reminder
    DATA_EXPORT_READY       // Export completed
}

data class Notification(
    val id: String,
    val type: NotificationType,
    val title: String,
    val message: String,
    val timestamp: Long,
    val actionUrl: String? = null,
    val isRead: Boolean = false
)
```

### API

```kotlin
class NotificationService(
    private val context: Context,
    private val notificationRepository: NotificationRepository
) {
    // Send notification
    suspend fun sendNotification(
        type: NotificationType,
        title: String,
        message: String,
        actionUrl: String? = null
    ): Result<String>  // Returns notification ID

    // Schedule notification
    suspend fun scheduleNotification(
        type: NotificationType,
        title: String,
        message: String,
        scheduledTime: Long,
        actionUrl: String? = null
    ): Result<String>

    // Cancel notification
    suspend fun cancelNotification(notificationId: String): Result<Unit>

    // Get notifications
    suspend fun getNotifications(): Result<List<Notification>>
    suspend fun getUnreadNotifications(): Result<List<Notification>>

    // Mark as read
    suspend fun markAsRead(notificationId: String): Result<Unit>
    suspend fun markAllAsRead(): Result<Unit>

    // Delete notification
    suspend fun deleteNotification(notificationId: String): Result<Unit>

    // Notification preferences
    suspend fun setNotificationsEnabled(enabled: Boolean)
    suspend fun setNotificationTypeEnabled(type: NotificationType, enabled: Boolean)

    // Observe notifications
    fun observeNotifications(): Flow<List<Notification>>
}
```

### Usage Examples

#### Round Reminder

```kotlin
// Schedule reminder for practice session
val practiceTime = tomorrow at 6.PM

notificationService.scheduleNotification(
    type = NotificationType.ROUND_REMINDER,
    title = "Practice Time",
    message = "Time for your evening practice session",
    scheduledTime = practiceTime,
    actionUrl = "app://rounds/new"
)
```

#### Achievement Notification

```kotlin
// Notify on personal best
if (roundScore > personalBest) {
    notificationService.sendNotification(
        type = NotificationType.ACHIEVEMENT_UNLOCKED,
        title = "New Personal Best!",
        message = "You scored $roundScore - your best score yet!",
        actionUrl = "app://rounds/$roundId"
    )
}
```

#### Equipment Maintenance Reminder

```kotlin
// Remind to change string after 1000 arrows
val arrowsSinceStringChange = 1000

if (arrowsSinceStringChange >= 1000) {
    notificationService.sendNotification(
        type = NotificationType.EQUIPMENT_MAINTENANCE,
        title = "String Replacement Due",
        message = "You've shot $arrowsSinceStringChange arrows. Consider replacing your string.",
        actionUrl = "app://equipment/string"
    )
}
```

#### Sync Conflict Notification

```kotlin
// Notify when sync conflicts need attention
syncCoordinator.sync()
    .onSuccess { result ->
        if (result.conflicts.isNotEmpty()) {
            notificationService.sendNotification(
                type = NotificationType.SYNC_CONFLICT,
                title = "Sync Conflicts",
                message = "${result.conflicts.size} conflicts need your attention",
                actionUrl = "app://sync/conflicts"
            )
        }
    }
```

#### Notification Center UI

```kotlin
@Composable
fun NotificationCenter(
    service: NotificationService
) {
    val notifications by service.observeNotifications()
        .collectAsState(initial = emptyList())

    LazyColumn {
        items(notifications) { notification ->
            NotificationCard(
                notification = notification,
                onClick = {
                    service.markAsRead(notification.id)
                    notification.actionUrl?.let { url ->
                        navigateTo(url)
                    }
                },
                onDismiss = {
                    service.deleteNotification(notification.id)
                }
            )
        }
    }
}
```

---

## Integration Example

### Complete Data Management Flow

```kotlin
class DataManagementViewModel(
    private val roundDeletionService: RoundDeletionService,
    private val archiveService: ArchiveService,
    private val exportService: ExportService,
    private val notificationService: NotificationService
) : ViewModel() {

    // Clean up old data
    fun performMaintenance() {
        viewModelScope.launch {
            // 1. Archive old rounds (older than 1 year)
            val oneYearAgo = System.currentTimeMillis() - (365 * 24 * 60 * 60 * 1000L)
            val archived = archiveService.archiveRoundsOlderThan(oneYearAgo)
                .getOrNull() ?: 0

            // 2. Delete very old archived data (older than 2 years)
            val twoYearsAgo = System.currentTimeMillis() - (2 * 365 * 24 * 60 * 60 * 1000L)
            val deleted = roundDeletionService.deleteRoundsOlderThan(twoYearsAgo)
                .getOrNull() ?: 0

            // 3. Notify user
            if (archived > 0 || deleted > 0) {
                notificationService.sendNotification(
                    type = NotificationType.SYNC_COMPLETE,
                    title = "Database Maintenance",
                    message = "Archived: $archived rounds, Deleted: $deleted old rounds"
                )
            }
        }
    }

    // Export backup before major operation
    suspend fun createBackupAndDelete(roundId: Long) {
        // 1. Export first
        val backupFile = exportService.exportRound(
            roundId = roundId,
            options = ExportOptions(format = ExportFormat.JSON)
        ).getOrThrow()

        // 2. Then delete
        roundDeletionService.deleteRound(roundId)
            .onSuccess {
                notificationService.sendNotification(
                    type = NotificationType.DATA_EXPORT_READY,
                    title = "Backup Created",
                    message = "Round backed up before deletion: ${backupFile.name}"
                )
            }
    }
}
```

---

## Best Practices

### 1. Safe Deletion

```kotlin
// GOOD: Soft delete with undo
roundDeletionService.softDeleteRound(roundId)
showUndoOption()

// BAD: Immediate permanent deletion
roundDeletionService.permanentlyDeleteRound(roundId)  // No undo!
```

### 2. Export Before Deletion

```kotlin
// GOOD: Backup first
val backup = exportService.exportRound(roundId, ExportOptions(ExportFormat.JSON))
roundDeletionService.deleteRound(roundId)

// BAD: Delete without backup
roundDeletionService.deleteRound(roundId)  // Data lost forever
```

### 3. Validate Imports

```kotlin
// GOOD: Validate before importing
val validation = importService.validateImportData(data, format)
if (validation.isValid) {
    importService.importFromFile(file, format)
}

// BAD: Import without validation
importService.importFromFile(file, format)  // May corrupt database
```

---

## Related Documentation

- [[../repositories/round-repository|RoundRepository]]
- [[sync-conflict-services-reference|SyncCoordinator]]
- [[statistics-calculation-service|StatisticsCalculationService]]
- [[../../flows/data-export-import-flow|Data Export/Import Flow]]

---

**Status:** ✅ All services in production
**Pattern:** Data lifecycle management with safety features
**Integration:** Works across all data types (rounds, equipment, tournaments)
**Last Updated:** 2025-11-01
