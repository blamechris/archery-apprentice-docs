---
title: TournamentManagementService
tags:
  - api
  - service
  - tournament
  - competition
  - firebase
created: 2025-11-01
---

# TournamentManagementService

Complete tournament lifecycle management service.

---

## Overview

**File:** `domain/services/TournamentManagementService.kt`
**Lines:** ~850 lines
**Purpose:** Comprehensive tournament management from creation to completion

TournamentManagementService orchestrates all tournament operations including creation, participant management, scoring, and completion workflows.

---

## API Reference

### Tournament Lifecycle

```kotlin
class TournamentManagementService(
    private val tournamentRepository: HybridTournamentRepository,
    private val roundRepository: RoundRepository,
    private val syncCoordinator: SyncCoordinator,
    private val notificationService: NotificationService
) {
    // Create tournament
    suspend fun createTournament(
        name: String,
        location: String,
        startDate: Long,
        endDate: Long,
        format: TournamentFormat,
        organizer: String
    ): Result<Tournament>

    // Update tournament
    suspend fun updateTournament(tournament: Tournament): Result<Unit>

    // Delete tournament
    suspend fun deleteTournament(tournamentId: String): Result<Unit>

    // Get tournament
    suspend fun getTournament(tournamentId: String): Result<Tournament>

    // List tournaments
    suspend fun getAllTournaments(): Result<List<Tournament>>
    suspend fun getUpcomingTournaments(): Result<List<Tournament>>
    suspend fun getPastTournaments(): Result<List<Tournament>>
    suspend fun getActiveTournaments(): Result<List<Tournament>>

    // Tournament status
    suspend fun startTournament(tournamentId: String): Result<Unit>
    suspend fun completeTournament(tournamentId: String): Result<Unit>
    suspend fun cancelTournament(tournamentId: String): Result<Unit>
}
```

### Participant Management

```kotlin
// Add participants
suspend fun addParticipant(
    tournamentId: String,
    participant: TournamentParticipant
): Result<Unit>

suspend fun addParticipants(
    tournamentId: String,
    participants: List<TournamentParticipant>
): Result<BulkAddResult>

// Remove participants
suspend fun removeParticipant(
    tournamentId: String,
    participantId: String
): Result<Unit>

// Get participants
suspend fun getParticipants(
    tournamentId: String
): Result<List<TournamentParticipant>>

suspend fun getParticipant(
    tournamentId: String,
    participantId: String
): Result<TournamentParticipant>

// Update participant
suspend fun updateParticipant(
    participant: TournamentParticipant
): Result<Unit>

data class BulkAddResult(
    val successCount: Int,
    val failedCount: Int,
    val duplicates: List<String>,
    val errors: List<String>
)
```

### Scoring Management

```kotlin
// Submit score
suspend fun submitScore(
    tournamentId: String,
    participantId: String,
    score: TournamentScore
): Result<Unit>

// Update score
suspend fun updateScore(
    scoreId: String,
    newScore: TournamentScore
): Result<Unit>

// Get scores
suspend fun getScores(
    tournamentId: String
): Result<List<TournamentScore>>

suspend fun getScoreForParticipant(
    tournamentId: String,
    participantId: String
): Result<TournamentScore?>

// Delete score
suspend fun deleteScore(scoreId: String): Result<Unit>

// Leaderboard
suspend fun getLeaderboard(
    tournamentId: String,
    division: String? = null
): Result<List<LeaderboardEntry>>

data class LeaderboardEntry(
    val rank: Int,
    val participant: TournamentParticipant,
    val score: Int,
    val xCount: Int,
    val division: String
)
```

### Tournament Formats

```kotlin
enum class TournamentFormat {
    WA_1440,           // World Archery 1440 round
    WA_720,            // World Archery 720 round (70m)
    INDOOR_18M,        // Indoor 18m
    INDOOR_25M,        // Indoor 25m
    FITA_OUTDOOR,      // Outdoor FITA
    IMPERIAL,          // Imperial rounds
    FIELD,             // Field archery
    CLOUT,             // Clout shooting
    CUSTOM             // Custom format
}

data class TournamentFormatDetails(
    val format: TournamentFormat,
    val distances: List<Int>,      // meters
    val arrowsPerEnd: Int,
    val endsPerDistance: Int,
    val maxScore: Int
)

fun getTournamentFormat(format: TournamentFormat): TournamentFormatDetails {
    return when (format) {
        TournamentFormat.WA_720 -> TournamentFormatDetails(
            format = WA_720,
            distances = listOf(70),
            arrowsPerEnd = 6,
            endsPerDistance = 12,
            maxScore = 720
        )
        // ... other formats
    }
}
```

### Divisions and Categories

```kotlin
enum class Division {
    RECURVE_MEN,
    RECURVE_WOMEN,
    COMPOUND_MEN,
    COMPOUND_WOMEN,
    BAREBOW_MEN,
    BAREBOW_WOMEN,
    LONGBOW_MEN,
    LONGBOW_WOMEN
}

enum class AgeCategory {
    UNDER_15,
    UNDER_18,
    UNDER_21,
    SENIOR,
    MASTER_50_PLUS,
    MASTER_60_PLUS
}

data class TournamentParticipant(
    val id: String,
    val name: String,
    val division: Division,
    val ageCategory: AgeCategory,
    val club: String? = null,
    val email: String? = null,
    val targetNumber: String? = null
)
```

### Live Scoring

```kotlin
// Enable live scoring
suspend fun enableLiveScoring(
    tournamentId: String,
    enabled: Boolean
): Result<Unit>

// Real-time score updates
fun observeScores(
    tournamentId: String
): Flow<List<TournamentScore>>

fun observeLeaderboard(
    tournamentId: String,
    division: String? = null
): Flow<List<LeaderboardEntry>>

// Scoring validation
suspend fun validateScore(
    score: TournamentScore,
    format: TournamentFormat
): Result<ValidationResult>
```

---

## Usage Examples

### Create and Setup Tournament

```kotlin
// Create tournament
val tournament = tournamentService.createTournament(
    name = "Spring Championship 2025",
    location = "National Archery Center",
    startDate = parseDate("2025-05-15"),
    endDate = parseDate("2025-05-17"),
    format = TournamentFormat.WA_720,
    organizer = "State Archery Association"
).getOrThrow()

// Add participants
val participants = listOf(
    TournamentParticipant(
        id = "p1",
        name = "Alice Johnson",
        division = Division.RECURVE_WOMEN,
        ageCategory = AgeCategory.SENIOR,
        club = "City Archers",
        targetNumber = "1A"
    ),
    TournamentParticipant(
        id = "p2",
        name = "Bob Smith",
        division = Division.RECURVE_MEN,
        ageCategory = AgeCategory.SENIOR,
        club = "Valley Bowmen",
        targetNumber = "1B"
    )
)

val result = tournamentService.addParticipants(tournament.id, participants)
    .getOrThrow()

println("Added ${result.successCount} participants")

// Enable live scoring
tournamentService.enableLiveScoring(tournament.id, enabled = true)

// Start tournament
tournamentService.startTournament(tournament.id)
```

### Submit and Track Scores

```kotlin
// Submit participant score
val score = TournamentScore(
    id = UUID.randomUUID().toString(),
    tournamentId = tournamentId,
    participantId = "p1",
    endScores = listOf(
        EndScore(1, listOf(10, 10, 9, 9, 8, 8)),  // End 1
        EndScore(2, listOf(10, 9, 9, 8, 8, 7)),   // End 2
        // ... more ends
    ),
    total = 654,
    xCount = 45,
    timestamp = System.currentTimeMillis()
)

tournamentService.submitScore(tournamentId, "p1", score)
    .onSuccess {
        println("Score submitted successfully")
    }
```

### Live Leaderboard

```kotlin
@Composable
fun LiveLeaderboardScreen(
    tournamentId: String,
    service: TournamentManagementService
) {
    val leaderboard by service.observeLeaderboard(tournamentId)
        .collectAsState(initial = emptyList())

    LazyColumn {
        item {
            Text(
                "Live Leaderboard",
                style = MaterialTheme.typography.headlineMedium
            )
        }

        items(leaderboard) { entry ->
            LeaderboardRow(
                rank = entry.rank,
                name = entry.participant.name,
                score = entry.score,
                xCount = entry.xCount,
                division = entry.division
            )
        }
    }

    // Auto-refresh every 30 seconds
    LaunchedEffect(tournamentId) {
        while (true) {
            delay(30000)
            service.getLeaderboard(tournamentId)
        }
    }
}
```

### Complete Tournament

```kotlin
// End of tournament
tournamentService.completeTournament(tournamentId)
    .onSuccess {
        // Generate final results
        val leaderboard = tournamentService.getLeaderboard(tournamentId)
            .getOrThrow()

        // Notify participants
        leaderboard.take(3).forEach { entry ->
            notificationService.sendNotification(
                type = NotificationType.ACHIEVEMENT_UNLOCKED,
                title = "Tournament Complete",
                message = "${entry.participant.name} finished ${entry.rank}${getRankSuffix(entry.rank)}!"
            )
        }

        // Export results
        exportService.exportTournamentResults(tournamentId)
    }
```

---

## Advanced Features

### Multi-Day Tournaments

```kotlin
suspend fun createMultiDayTournament(
    name: String,
    location: String,
    days: List<TournamentDay>
): Result<Tournament> {
    val tournament = createTournament(
        name = name,
        location = location,
        startDate = days.first().date,
        endDate = days.last().date,
        format = TournamentFormat.CUSTOM,
        organizer = "Multi-Day Organizer"
    ).getOrThrow()

    // Configure each day
    days.forEach { day ->
        configureTournamentDay(
            tournamentId = tournament.id,
            dayNumber = day.dayNumber,
            format = day.format,
            distances = day.distances
        )
    }

    return Result.success(tournament)
}

data class TournamentDay(
    val dayNumber: Int,
    val date: Long,
    val format: TournamentFormat,
    val distances: List<Int>
)
```

### Team Competitions

```kotlin
data class Team(
    val id: String,
    val name: String,
    val members: List<String>,  // Participant IDs
    val club: String
)

suspend fun addTeam(
    tournamentId: String,
    team: Team
): Result<Unit>

suspend fun getTeamStandings(
    tournamentId: String
): Result<List<TeamStanding>>

data class TeamStanding(
    val rank: Int,
    val team: Team,
    val totalScore: Int,
    val averageScore: Double
)
```

### Elimination Rounds

```kotlin
enum class EliminationType {
    SINGLE_ELIMINATION,
    DOUBLE_ELIMINATION,
    ROUND_ROBIN
}

suspend fun createEliminationRound(
    tournamentId: String,
    type: EliminationType,
    qualifiers: List<String>  // Participant IDs
): Result<EliminationBracket>

data class EliminationBracket(
    val type: EliminationType,
    val matches: List<Match>,
    val currentRound: Int,
    val totalRounds: Int
)

data class Match(
    val id: String,
    val roundNumber: Int,
    val participant1: TournamentParticipant,
    val participant2: TournamentParticipant,
    val score1: Int?,
    val score2: Int?,
    val winner: String?  // Participant ID
)
```

---

## Integration with Other Services

### Sync Integration

```kotlin
class TournamentManagementService(
    private val syncCoordinator: SyncCoordinator,
    // ... other dependencies
) {
    suspend fun submitScore(
        tournamentId: String,
        participantId: String,
        score: TournamentScore
    ): Result<Unit> {
        // Save locally
        val result = tournamentRepository.submitScore(score)

        // Sync to cloud
        if (result.isSuccess) {
            syncCoordinator.syncEntityType(EntityType.TOURNAMENT_SCORE)
        }

        return result
    }
}
```

### Statistics Integration

```kotlin
suspend fun getTournamentStatistics(
    tournamentId: String
): Result<TournamentStatistics> {
    val scores = getScores(tournamentId).getOrThrow()

    return Result.success(TournamentStatistics(
        totalParticipants = scores.size,
        averageScore = scores.map { it.total }.average(),
        highScore = scores.maxOf { it.total },
        lowScore = scores.minOf { it.total },
        totalXs = scores.sumOf { it.xCount },
        completionRate = calculateCompletionRate(scores)
    ))
}

data class TournamentStatistics(
    val totalParticipants: Int,
    val averageScore: Double,
    val highScore: Int,
    val lowScore: Int,
    val totalXs: Int,
    val completionRate: Double
)
```

---

## Best Practices

### 1. Validation

```kotlin
// GOOD: Validate before submission
val validation = tournamentService.validateScore(score, format)
if (validation.isValid) {
    tournamentService.submitScore(tournamentId, participantId, score)
} else {
    showErrors(validation.errors)
}

// BAD: Submit without validation
tournamentService.submitScore(tournamentId, participantId, score)
```

### 2. Error Handling

```kotlin
// GOOD: Handle all failure cases
tournamentService.submitScore(tournamentId, participantId, score)
    .onSuccess {
        showMessage("Score submitted")
    }
    .onFailure { error ->
        when (error) {
            is NetworkException -> showMessage("Will sync when online")
            is ValidationException -> showErrors(error.errors)
            else -> showError("Failed to submit")
        }
    }
```

### 3. Real-time Updates

```kotlin
// GOOD: Use reactive streams for live data
@Composable
fun TournamentScreen(tournamentId: String) {
    val scores by service.observeScores(tournamentId)
        .collectAsState(initial = emptyList())

    // UI updates automatically
}

// BAD: Polling
LaunchedEffect(Unit) {
    while (true) {
        service.getScores(tournamentId)  // Inefficient
        delay(5000)
    }
}
```

---

## Testing

### Example Tests

```kotlin
class TournamentManagementServiceTest {
    @Test
    fun `create tournament with valid data succeeds`() = runTest {
        val result = service.createTournament(
            name = "Test Tournament",
            location = "Test Location",
            startDate = System.currentTimeMillis(),
            endDate = System.currentTimeMillis() + 86400000,
            format = TournamentFormat.WA_720,
            organizer = "Test Organizer"
        )

        assertTrue(result.isSuccess)
        val tournament = result.getOrThrow()
        assertEquals("Test Tournament", tournament.name)
    }

    @Test
    fun `submit duplicate score fails`() = runTest {
        // First submission
        service.submitScore(tournamentId, participantId, score1)

        // Duplicate submission
        val result = service.submitScore(tournamentId, participantId, score2)

        assertTrue(result.isFailure)
    }

    @Test
    fun `leaderboard sorts by score descending`() = runTest {
        // Submit various scores
        service.submitScore(tournamentId, "p1", score(650))
        service.submitScore(tournamentId, "p2", score(680))
        service.submitScore(tournamentId, "p3", score(670))

        val leaderboard = service.getLeaderboard(tournamentId).getOrThrow()

        assertEquals(1, leaderboard[0].rank)
        assertEquals(680, leaderboard[0].score)
        assertEquals(2, leaderboard[1].rank)
        assertEquals(670, leaderboard[1].score)
    }
}
```

---

## Related Documentation

- [[../repositories/hybrid-tournament-repository|HybridTournamentRepository]]
- [[../repositories/tournament-repository|TournamentRepository]]
- [[sync-conflict-services-reference|SyncCoordinator]]
- [[../../flows/tournament-participation-end-to-end-flow|Tournament Participation Flow]]

---

**Status:** ✅ In production with live tournament support
**Complexity:** High (~850 lines, multi-domain orchestration)
**Key Features:** Real-time leaderboard, offline support, multiple formats
**Last Updated:** 2025-11-01
