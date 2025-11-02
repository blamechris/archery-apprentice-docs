---
title: Utility Services Reference
tags:
  - api
  - service
  - utility
  - validation
  - logging
created: 2025-11-01
---

# Utility Services Reference

Reference for utility and support services.

---

## Overview

Utility services provide common functionality used throughout the application.

**Services Covered:**
- ValidationService
- DateTimeService
- LoggingService
- DatabaseMigrationService
- TournamentScoreCacheService
- ParticipantManagementService (Recommended)
- EquipmentValidationService

---

## ValidationService

**File:** `domain/services/ValidationService.kt`
**Purpose:** General data validation

### API

```kotlin
class ValidationService {
    // Input validation
    fun validateInput(text: String): Boolean
    fun validateEmail(email: String): Boolean
    fun validateLength(text: String, min: Int, max: Int): Boolean

    // Score validation
    fun validateArrowScore(score: Int): Boolean
    fun validateArrowScores(scores: List<Int>): Boolean

    // Entity validation
    fun validateRound(round: Round): ValidationResult
    fun validateBowSetup(setup: BowSetup): ValidationResult
}

data class ValidationResult(
    val isValid: Boolean,
    val errors: List<String> = emptyList()
)
```

### Usage

```kotlin
val result = validationService.validateRound(round)
if (!result.isValid) {
    result.errors.forEach { error ->
        showError(error)
    }
    return
}
```

---

## DateTimeService

**File:** `domain/services/DateTimeService.kt`
**Purpose:** Timestamp and date utilities

### API

```kotlin
class DateTimeService {
    // Current time
    fun now(): Long = System.currentTimeMillis()

    // Formatting
    fun formatDate(timestamp: Long, pattern: String): String
    fun formatTime(timestamp: Long): String
    fun formatDateTime(timestamp: Long): String

    // Parsing
    fun parseDate(dateString: String, pattern: String): Long?

    // Calculations
    fun addDays(timestamp: Long, days: Int): Long
    fun daysBetween(start: Long, end: Long): Int
    fun isSameDay(timestamp1: Long, timestamp2: Long): Boolean
}
```

### Usage

```kotlin
val formattedDate = dateTimeService.formatDate(
    round.date,
    "MMM dd, yyyy"
)  // "Nov 01, 2025"

val isToday = dateTimeService.isSameDay(round.date, dateTimeService.now())
```

---

## LoggingService

**File:** `domain/services/LoggingService.kt`
**Purpose:** Centralized logging

### API

```kotlin
class LoggingService {
    fun logDebug(tag: String, message: String)
    fun logInfo(tag: String, message: String)
    fun logWarning(tag: String, message: String, throwable: Throwable? = null)
    fun logError(tag: String, message: String, throwable: Throwable)

    // Analytics
    fun logEvent(eventName: String, parameters: Map<String, Any>)
    fun logScreenView(screenName: String)
}
```

### Usage

```kotlin
loggingService.logInfo("RoundRepository", "Creating round: ${round.name}")

try {
    repository.save(data)
} catch (e: Exception) {
    loggingService.logError("Repository", "Save failed", e)
}

loggingService.logEvent("round_completed", mapOf(
    "roundId" to roundId,
    "score" to totalScore
))
```

---

## DatabaseMigrationService

**File:** `data/services/DatabaseMigrationService.kt`
**Purpose:** Room database schema migrations

### API

```kotlin
class DatabaseMigrationService {
    // Migration management
    fun getCurrentVersion(): Int
    fun getTargetVersion(): Int
    fun getMigrationsNeeded(): List<Migration>

    // Execute migrations
    fun executeMigrations(): Result<Unit>
    fun executeMigration(from: Int, to: Int): Result<Unit>

    // Rollback support
    fun canRollback(): Boolean
    fun rollbackMigration(): Result<Unit>

    // Data preservation
    fun backupDatabase(): Result<File>
    fun restoreDatabase(backup: File): Result<Unit>
}
```

### Usage

```kotlin
val migrations = migrationService.getMigrationsNeeded()
if (migrations.isNotEmpty()) {
    println("Need to run ${migrations.size} migrations")

    migrationService.executeMigrations()
        .onSuccess { println("Migrations complete") }
        .onFailure { error ->
            migrationService.rollbackMigration()
            showError(error.message)
        }
}
```

---

## TournamentScoreCacheService

**File:** `data/services/TournamentScoreCacheService.kt`
**Purpose:** Smart caching for tournament data

### Features

- **Status-aware TTL:** Different cache durations based on tournament status
- **50-90% reduction** in Firebase reads
- **5-10x faster** load times
- Automatic cache maintenance

### Cache Strategy

| Tournament Status | TTL | Rationale |
|-------------------|-----|-----------|
| COMPLETED | Indefinite | Immutable data |
| IN_PROGRESS | 5 minutes | Balance freshness vs reads |
| PLANNED | 10 minutes | Rarely changes |

### API

```kotlin
class TournamentScoreCacheService {
    // Get from cache or fetch
    suspend fun getTournament(id: String): Result<Tournament>

    // Cache operations
    fun cacheScore(score: TournamentScore)
    fun invalidateCache(tournamentId: String)
    fun clearCache()

    // Cache stats
    fun getCacheHitRate(): Double
    fun getCacheSizeBytes(): Long
}
```

### Usage

```kotlin
// Automatically uses cache
val tournament = cacheService.getTournament(tournamentId)
    .getOrNull()

// Force refresh
cacheService.invalidateCache(tournamentId)
val fresh = cacheService.getTournament(tournamentId)
```

---

## ParticipantManagementService

**File:** `domain/services/ParticipantManagementService.kt` (Recommended)
**Status:** 📝 **RECOMMENDED FOR EXTRACTION** (~200 lines from LiveScoringViewModel)

### Proposed API

```kotlin
class ParticipantManagementService(
    private val repository: RoundRepository
) {
    // Participant CRUD
    suspend fun addParticipant(roundId: Long, participantId: Long): Result<Unit>
    suspend fun removeParticipant(roundId: Long, participantId: Long): Result<Unit>

    // Participant selection
    suspend fun getParticipants(roundId: Long): Result<List<Participant>>
    suspend fun getActiveParticipant(roundId: Long): Result<Participant?>

    // Multi-participant logic
    suspend fun switchActiveParticipant(
        roundId: Long,
        participantId: Long
    ): Result<Unit>

    suspend fun getParticipantScore(
        roundId: Long,
        participantId: Long
    ): Result<Int>

    suspend fun getRankings(roundId: Long): Result<List<ParticipantRanking>>
}
```

**See:** [[../../../../architecture/live-scoring-vm-analysis#5-participant-management-service|Extraction Plan]]

---

## EquipmentValidationService

**File:** `domain/services/EquipmentValidationService.kt`
**Purpose:** Equipment configuration validation

### API

```kotlin
class EquipmentValidationService {
    // Bow validation
    fun validateBowSetup(setup: BowSetup): ValidationResult

    // Arrow validation
    fun validateArrowSetup(setup: ArrowSetup): ValidationResult

    // Component validation
    fun validateSightConfiguration(sight: SightConfiguration): ValidationResult
    fun validateStabilizerConfiguration(stab: StabilizerConfiguration): ValidationResult

    // Compatibility checks
    fun checkBowArrowCompatibility(
        bow: BowSetup,
        arrows: ArrowSetup
    ): CompatibilityResult
}

data class CompatibilityResult(
    val isCompatible: Boolean,
    val warnings: List<String> = emptyList()
)
```

### Usage

```kotlin
val bowResult = validationService.validateBowSetup(bowSetup)
if (!bowResult.isValid) {
    showErrors(bowResult.errors)
    return
}

val compat = validationService.checkBowArrowCompatibility(bow, arrows)
if (!compat.isCompatible) {
    showWarning("Bow and arrows may not be compatible")
}
```

---

## Best Practices

### All Utility Services Should:

1. **Be Stateless** - No mutable state
2. **Be Pure** - Same input = same output (when possible)
3. **Be Reusable** - Used across multiple features
4. **Be Testable** - Easy to unit test
5. **Have Clear Purpose** - Single responsibility

### Example: Good Utility Service

```kotlin
// GOOD: Stateless, reusable
class DateTimeService {
    fun formatDate(timestamp: Long, pattern: String): String {
        // Pure function
    }
}

// BAD: Stateful
class DateTimeService {
    private var lastTimestamp: Long = 0  // ✗ State

    fun formatDate(timestamp: Long): String {
        lastTimestamp = timestamp  // ✗ Side effect
        // ...
    }
}
```

---

## Related Documentation

- [[../../../../architecture/service-architecture|Service Architecture]]
- [[index|Services API Reference]]
- [[end-completion-service|EndCompletionService]]
- [[statistics-calculation-service|StatisticsCalculationService]]

---

**Status:** ✅ Core services in production, 1 recommended for extraction
**Pattern:** Utility and support functionality
**Last Updated:** 2025-11-01
