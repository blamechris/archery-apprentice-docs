---
title: "Tournament Data Models"
description: "Tournament-related data structures and entities"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - data-models
  - tournament
  - entities
  - multiplayer
---

[Home](/) > [Technical Reference](../../) > [Data Models](../) > Tournament

---

# Tournament Data Models

Complete reference for tournament-related entities in Archery Apprentice. These models support both local (offline) and remote (online) tournaments with full participant management, leaderboard tracking, and offline sync capabilities.

## Overview

**Core Entities:** 3 (TournamentEntity, TournamentParticipantEntity, TournamentScoreCache)
**Location:** `shared:database` module
**Package:** `com.archeryapprentice.database.entities.tournament`

### Entity Relationships

```
TournamentEntity (tournament metadata)
  └── TournamentParticipantEntity (participants)
        └── Scores tracked via Round.tournamentId

TournamentScoreCache (offline sync)
  └── Cached scores for remote tournaments
```

### Tournament Types

| Type | Description | Sync Required | Use Case |
|------|-------------|---------------|----------|
| **Local** | Offline tournament | No | Club events, practice competitions |
| **Remote** | Online tournament | Yes | National competitions, remote participation |
| **Hybrid** | Local with optional sync | Optional | Local event with online leaderboard |

---

## TournamentEntity

The TournamentEntity represents a complete tournament configuration and metadata.

**File:** `TournamentEntity.kt`
**Table:** `TournamentEntity`
**Total Fields:** 36

### Field Categories

#### 1. Identity & Metadata (5 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **id** | String | Primary key (UUID or custom ID) | `"spring-tourney-2025"`, `"uuid-abc-123"` |
| **name** | String | Tournament name | `"Spring Championship 2025"` |
| **description** | String? | Tournament details | `"Annual club championship, 70m outdoor"` |
| **location** | String? | Venue or geographic location | `"Central Archery Range, Chicago"` |
| **organizerId** | String? | User ID of tournament creator | `"user123"` |

#### 2. Creator Information (2 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **createdBy** | String? | Creator username | `"Chris"` |
| **creatorEmail** | String? | Creator email | `"chris@example.com"` |

**Purpose:** Contact information for tournament organizer

#### 3. Status Management (1 field)

| Field | Type | Description | Allowed Values |
|-------|------|-------------|----------------|
| **status** | TournamentStatus | Current tournament state | `OPEN`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED` |

**Status Workflow:**

```
OPEN → IN_PROGRESS → COMPLETED
  ↓
CANCELLED
```

**Status Definitions:**
- **OPEN** - Registration open, tournament not started
- **IN_PROGRESS** - Tournament active, participants shooting
- **COMPLETED** - Tournament finished, final results available
- **CANCELLED** - Tournament abandoned/cancelled

#### 4. Round Format (6 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **numEnds** | Int | Ends per round | `6`, `10`, `12` |
| **numArrows** | Int | Arrows per end | `3`, `6` |
| **distance** | Distance | Shooting distance | `"70 meters"`, `"50 yards"` |
| **targetSize** | TargetSize | Target face size | `"122cm"`, `"80cm"` |
| **scoringSystem** | ScoringSystem | Scoring method | `10-ring`, `6-ring`, `5-zone` |
| **totalRounds** | Int? | Number of rounds in tournament | `3`, `5`, `10` |

**Round Format Notes:**
- All participants shoot same format
- Format locked when tournament starts (status → IN_PROGRESS)
- Compatible with standard Round entity

#### 5. Timestamps (3 fields)

| Field | Type | Description | Purpose |
|-------|------|-------------|---------|
| **startTime** | Instant? | Tournament start time | Scheduling, countdown |
| **endTime** | Instant? | Tournament end time | Deadline enforcement |
| **createdAt** | Instant | Creation timestamp | Sorting, history |

**Timestamp Behavior:**
- `createdAt` set on creation
- `startTime` optional, can be scheduled future event
- `endTime` optional, enforces submission deadline

#### 6. Access Control (4 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **isPublic** | Boolean | Public vs private tournament | `true` (anyone can join), `false` (invite only) |
| **joinCode** | String? | Access code for joining | `"SPRING2025"`, `"ABC123"` |
| **maxParticipants** | Int? | Maximum participants | `50`, `100`, `null` (unlimited) |
| **requireApproval** | Boolean | Require organizer approval to join | `true`, `false` |

**Access Control Modes:**

**Public Tournament:**
```kotlin
val publicTourney = TournamentEntity(
    isPublic = true,
    joinCode = null,           // No code required
    requireApproval = false,   // Auto-join
    maxParticipants = null     // Unlimited
)
```

**Private Tournament:**
```kotlin
val privateTourney = TournamentEntity(
    isPublic = false,
    joinCode = "SECRET2025",   // Code required
    requireApproval = true,    // Manual approval
    maxParticipants = 20       // Limited slots
)
```

#### 7. Tournament Settings (2 fields)

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| **allowSpectators** | Boolean | Allow non-participants to view | `true` |
| **useSettingsDisplayNames** | Boolean | Use Settings usernames vs custom names | `true` |

**Display Name Behavior:**
- `true`: Participants show as Settings.userName
- `false`: Participants can set custom tournament display names

#### 8. Leaderboard & Scoring (4 fields)

| Field | Type | Description | Calculation |
|-------|------|-------------|-------------|
| **currentRound** | Int | Active round number | `1`, `2`, `3` |
| **topScore** | Int? | Highest score across all rounds | Cached for leaderboard |
| **averageScore** | Double? | Mean score of all participants | Cached for statistics |
| **totalParticipants** | Int | Participant count | Cached count |

**Why Cache These?**
- Avoid expensive aggregations on every leaderboard view
- Update on round completion or participant action
- Quick tournament statistics display

#### 9. Sync & Local/Remote (3 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **isLocal** | Boolean | Local (offline) vs remote (online) | `true` (offline), `false` (online) |
| **needsSync** | Boolean | Has unsynced changes | `true` (needs upload), `false` (synced) |
| **lastSyncedAt** | Instant? | Last successful sync time | For conflict resolution |

**Sync Workflow:**

**Local Tournament:**
```kotlin
val localTourney = TournamentEntity(
    isLocal = true,
    needsSync = false,      // No sync needed
    lastSyncedAt = null     // Never synced
)
```

**Remote Tournament with Offline Support:**
```kotlin
// 1. Create remote tournament
val remoteTourney = TournamentEntity(
    isLocal = false,
    needsSync = false,
    lastSyncedAt = Clock.System.now()
)

// 2. Participant shoots offline
// Scores stored in TournamentScoreCache
// needsSync = true

// 3. Device comes online
// Sync cached scores to server
// needsSync = false, lastSyncedAt = now
```

#### 10. Rules & Configuration (6 fields)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **eliminationRounds** | Int? | Number of elimination rounds | `2`, `3` |
| **advancementCriteria** | String? | How participants advance | `"Top 50%"`, `"Top 10 scores"` |
| **tiebreakingRules** | String? | How ties are resolved | `"X-count"`, `"Closest to center"` |
| **customRules** | String? | Additional tournament rules | `"Must use barebow equipment"` |
| **registrationDeadline** | Instant? | Last moment to register | Enforce cutoff |
| **roundDeadlines** | Map<Int, Instant>? | Per-round submission deadlines | `{1: deadline1, 2: deadline2}` |

**Rule Enforcement:**
- Rules stored as strings for flexibility
- Enforcement typically manual or UI-level
- Can be parsed for automated validation

### Complete TournamentEntity Example

```kotlin
val championship = TournamentEntity(
    id = "spring-champ-2025",
    name = "Spring Championship 2025",
    description = "Annual club championship, outdoor 70m",
    location = "Central Archery Range",
    organizerId = "user123",
    createdBy = "Chris",
    creatorEmail = "chris@archeryclub.com",

    // Status
    status = TournamentStatus.OPEN,

    // Round format
    numEnds = 12,
    numArrows = 6,
    distance = Distance.fromString("70 meters"),
    targetSize = TargetSize.fromString("122cm"),
    scoringSystem = ScoringSystem.TEN_RING,
    totalRounds = 3,

    // Timestamps
    startTime = Clock.System.now().plus(7.days),
    endTime = Clock.System.now().plus(14.days),
    createdAt = Clock.System.now(),

    // Access control
    isPublic = true,
    joinCode = null,
    maxParticipants = 50,
    requireApproval = false,

    // Settings
    allowSpectators = true,
    useSettingsDisplayNames = true,

    // Leaderboard
    currentRound = 1,
    topScore = null,
    averageScore = null,
    totalParticipants = 0,

    // Sync
    isLocal = false,  // Remote tournament
    needsSync = false,
    lastSyncedAt = Clock.System.now(),

    // Rules
    eliminationRounds = 2,
    advancementCriteria = "Top 50% advance to finals",
    tiebreakingRules = "X-count, then closest arrow to center",
    customRules = null,
    registrationDeadline = Clock.System.now().plus(6.days),
    roundDeadlines = mapOf(
        1 to Clock.System.now().plus(8.days),
        2 to Clock.System.now().plus(11.days),
        3 to Clock.System.now().plus(14.days)
    )
)
```

---

## TournamentParticipantEntity

Represents a participant in a tournament, tracking their progress and ranking.

**File:** `TournamentParticipantEntity.kt`
**Table:** `TournamentParticipant`

### Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **id** | Long | Primary key, auto-increment | `1`, `2`, `3` |
| **tournamentId** | String | Foreign key → TournamentEntity(id) | `"spring-champ-2025"` |
| **userId** | String | Participant user ID | `"user456"` |
| **displayName** | String | Participant display name | `"Sarah Johnson"` |
| **currentRound** | Int | Current/latest round completed | `1`, `2`, `3` |
| **totalScore** | Int | Aggregate score across all rounds | `1680`, `1750` |
| **ranking** | Int? | Current leaderboard position | `1`, `2`, `3`, `null` (unranked) |
| **status** | ParticipantStatus | Participation status | `ACTIVE`, `WITHDRAWN`, `DISQUALIFIED` |
| **registeredAt** | Instant | Registration timestamp | Sorting, history |
| **lastRoundSubmitted** | Instant? | Last score submission time | Track activity |

### Relationships

**Parent:** TournamentEntity (Many-to-One)
- Foreign Key: `TournamentParticipant.tournamentId → TournamentEntity.id`
- Cascade: ON DELETE CASCADE (deleting tournament deletes all participants)

**Children:** Round entities (via `Round.tournamentId` and `Round.participantId`)

### Participant Status

**ParticipantStatus Values:**
- **ACTIVE** - Currently participating in tournament
- **WITHDRAWN** - Voluntarily withdrew from tournament
- **DISQUALIFIED** - Removed by organizer (rules violation, etc.)
- **COMPLETED** - Finished all rounds (optional status)

### Usage Example

```kotlin
val participant = TournamentParticipantEntity(
    tournamentId = "spring-champ-2025",
    userId = "user456",
    displayName = "Sarah Johnson",
    currentRound = 2,          // Completed 2 rounds
    totalScore = 1120,         // Sum of round 1 + round 2
    ranking = 3,               // 3rd place
    status = ParticipantStatus.ACTIVE,
    registeredAt = Clock.System.now().minus(5.days),
    lastRoundSubmitted = Clock.System.now().minus(1.days)
)
```

### Queries

**Get tournament leaderboard:**
```kotlin
@Query("""
    SELECT * FROM TournamentParticipant
    WHERE tournamentId = :tournamentId
    AND status = 'ACTIVE'
    ORDER BY totalScore DESC
""")
suspend fun getLeaderboard(tournamentId: String): List<TournamentParticipantEntity>
```

**Update participant ranking:**
```kotlin
@Query("""
    UPDATE TournamentParticipant
    SET ranking = :ranking
    WHERE id = :participantId
""")
suspend fun updateRanking(participantId: Long, ranking: Int)
```

**Get participant's rounds:**
```kotlin
@Query("""
    SELECT * FROM Round
    WHERE tournamentId = :tournamentId
    AND participantId = :participantId
    ORDER BY tournamentRoundNumber ASC
""")
suspend fun getParticipantRounds(tournamentId: String, participantId: String): List<RoundEntity>
```

---

## TournamentScoreCache

Caches scores for offline tournament participation, syncing when connection available.

**File:** `TournamentScoreCacheEntity.kt`
**Table:** `TournamentScoreCache`

### Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **id** | Long | Primary key, auto-increment | `1`, `2`, `3` |
| **tournamentId** | String | Tournament reference | `"spring-champ-2025"` |
| **participantId** | String | Participant user ID | `"user456"` |
| **roundNumber** | Int | Which round these scores are for | `1`, `2`, `3` |
| **scores** | List<Int> | Arrow scores (JSON) | `[10, 9, 9, 8, 10, 9, ...]` |
| **lastUpdated** | Instant | Last modification time | For conflict resolution |
| **syncStatus** | SyncStatus | Sync state | `PENDING`, `SYNCED`, `FAILED` |

### Purpose

**Offline Tournament Participation:**

1. Participant shoots offline (no network)
2. Scores saved to TournamentScoreCache
3. When online, cached scores sync to server
4. Server updates leaderboard
5. Cache entry marked SYNCED or deleted

### Sync Status

**SyncStatus Values:**
- **PENDING** - Not yet synced to server
- **SYNCED** - Successfully uploaded
- **FAILED** - Sync attempt failed (will retry)

### Usage Example

```kotlin
// 1. Participant shoots offline
val scoreCache = TournamentScoreCacheEntity(
    tournamentId = "spring-champ-2025",
    participantId = "user456",
    roundNumber = 2,
    scores = listOf(10, 9, 9, 8, 10, 9, 8, 7, 10, 9, ...),  // All arrow scores
    lastUpdated = Clock.System.now(),
    syncStatus = SyncStatus.PENDING
)
scoreCacheDao.insert(scoreCache)

// 2. Device comes online
val pendingScores = scoreCacheDao.getPendingScores()

// 3. Sync to server
for (cache in pendingScores) {
    try {
        tournamentApi.submitScores(cache)
        scoreCacheDao.updateStatus(cache.id, SyncStatus.SYNCED)
        // Optionally delete after successful sync
        scoreCacheDao.delete(cache.id)
    } catch (e: Exception) {
        scoreCacheDao.updateStatus(cache.id, SyncStatus.FAILED)
    }
}
```

### Queries

**Get pending sync items:**
```kotlin
@Query("""
    SELECT * FROM TournamentScoreCache
    WHERE syncStatus = 'PENDING'
    ORDER BY lastUpdated ASC
""")
suspend fun getPendingScores(): List<TournamentScoreCacheEntity>
```

**Get cached scores for tournament:**
```kotlin
@Query("""
    SELECT * FROM TournamentScoreCache
    WHERE tournamentId = :tournamentId
    AND participantId = :participantId
    ORDER BY roundNumber ASC
""")
suspend fun getCachedScores(tournamentId: String, participantId: String): List<TournamentScoreCacheEntity>
```

### Type Converter

```kotlin
// List<Int> ↔ JSON String
@TypeConverter
fun fromIntList(list: List<Int>): String = Json.encodeToString(list)

@TypeConverter
fun toIntList(value: String): List<Int> = Json.decodeFromString(value)
```

---

## Relationships & Data Flow

### Tournament → Participant → Rounds

```
TournamentEntity
  ├── TournamentParticipant (user1)
  │     ├── Round (round 1)
  │     ├── Round (round 2)
  │     └── Round (round 3)
  ├── TournamentParticipant (user2)
  │     ├── Round (round 1)
  │     └── Round (round 2)
  └── TournamentParticipant (user3)
        └── Round (round 1)
```

**Foreign Keys:**
- `TournamentParticipant.tournamentId → TournamentEntity.id` (CASCADE DELETE)
- `Round.tournamentId → TournamentEntity.id` (No FK, but logical relationship)
- `Round.participantId` matches `TournamentParticipant.userId`

### Offline Sync Flow

```
1. User shoots offline
   ↓
2. Save to TournamentScoreCache (PENDING)
   ↓
3. Device goes online
   ↓
4. Sync cached scores to server
   ↓
5. Server updates TournamentParticipant.totalScore
   ↓
6. Recalculate rankings
   ↓
7. Mark cache SYNCED or delete
```

---

## Tournament Lifecycle

### Creating a Tournament

```kotlin
// 1. Create tournament entity
val tournament = TournamentEntity(
    id = generateTournamentId(),
    name = "My Tournament",
    status = TournamentStatus.OPEN,
    numEnds = 6,
    numArrows = 6,
    distance = Distance.fromString("50 meters"),
    targetSize = TargetSize.fromString("122cm"),
    scoringSystem = ScoringSystem.TEN_RING,
    isLocal = false,  // Remote tournament
    createdAt = Clock.System.now()
)
tournamentDao.insert(tournament)
```

### Joining a Tournament

```kotlin
// 1. User requests to join
if (tournament.requireApproval) {
    // Send join request to organizer
    joinRequestDao.insert(JoinRequest(tournamentId, userId))
} else {
    // Auto-join
    val participant = TournamentParticipantEntity(
        tournamentId = tournament.id,
        userId = currentUserId,
        displayName = settingsDao.getUserName(),
        currentRound = 0,
        totalScore = 0,
        ranking = null,
        status = ParticipantStatus.ACTIVE,
        registeredAt = Clock.System.now()
    )
    participantDao.insert(participant)
}
```

### Submitting a Round

```kotlin
// 1. Create round with tournament reference
val round = RoundEntity(
    roundName = "Spring Championship - Round 2",
    tournamentId = tournament.id,
    tournamentRoundNumber = 2,
    numEnds = tournament.numEnds,
    numArrows = tournament.numArrows,
    distance = tournament.distance,
    targetSize = tournament.targetSize,
    scoringSystem = tournament.scoringSystem,
    status = RoundStatus.IN_PROGRESS
)
roundDao.insert(round)

// 2. Score the round normally

// 3. On completion, update participant
val participant = participantDao.getByUserId(tournament.id, currentUserId)
participantDao.update(participant.copy(
    currentRound = 2,
    totalScore = participant.totalScore + round.totalScore,
    lastRoundSubmitted = Clock.System.now()
))

// 4. Recalculate rankings
updateTournamentRankings(tournament.id)
```

### Calculating Rankings

```kotlin
suspend fun updateTournamentRankings(tournamentId: String) {
    // Get all active participants, sorted by score
    val participants = participantDao.getLeaderboard(tournamentId)

    // Assign rankings
    participants.forEachIndexed { index, participant ->
        participantDao.updateRanking(participant.id, index + 1)
    }

    // Update tournament leaderboard cache
    tournamentDao.updateLeaderboardCache(
        tournamentId = tournamentId,
        topScore = participants.firstOrNull()?.totalScore,
        averageScore = participants.map { it.totalScore }.average()
    )
}
```

---

## Local vs Remote Tournaments

### Local Tournament (Offline)

**Characteristics:**
- No network required
- All data stored locally
- No sync needed
- Ideal for club events

**Example:**
```kotlin
val localTourney = TournamentEntity(
    name = "Club Practice Tournament",
    isLocal = true,
    needsSync = false,
    lastSyncedAt = null
)
```

### Remote Tournament (Online)

**Characteristics:**
- Network connection required (or cached offline)
- Scores sync to central server
- Real-time leaderboard updates
- Ideal for national/international events

**Example:**
```kotlin
val remoteTourney = TournamentEntity(
    name = "National Championship",
    isLocal = false,
    needsSync = false,  // Initially synced
    lastSyncedAt = Clock.System.now()
)
```

### Hybrid: Remote with Offline Support

**Workflow:**

1. **Online:** User joins remote tournament, downloads metadata
2. **Offline:** User shoots round, scores cached locally
3. **Online:** Scores sync to server, leaderboard updates

**Implementation:**
```kotlin
// Check network status
if (isOnline) {
    // Direct submission to server
    tournamentApi.submitRound(round)
} else {
    // Cache for later sync
    scoreCacheDao.insert(TournamentScoreCacheEntity(
        tournamentId = tournament.id,
        participantId = userId,
        roundNumber = roundNumber,
        scores = arrowScores,
        syncStatus = SyncStatus.PENDING
    ))
}
```

---

## Advanced Features

### Elimination Rounds

**Concept:** Top participants advance to next round.

**Implementation:**
```kotlin
// After round 1 completes
val allParticipants = participantDao.getLeaderboard(tournamentId)
val advancingCount = (allParticipants.size * 0.5).toInt()  // Top 50%
val advancing = allParticipants.take(advancingCount)

// Mark others as completed/eliminated
allParticipants.drop(advancingCount).forEach { participant ->
    participantDao.updateStatus(participant.id, ParticipantStatus.COMPLETED)
}
```

### Tiebreaking

**Common Rules:**
1. **X-Count** - Most X-ring hits
2. **Last End** - Highest score in final end
3. **Closest Arrow** - Distance to center of best arrow

**Example Query:**
```kotlin
// Tiebreaking by X-count
@Query("""
    SELECT p.*, COUNT(a.isXRing) as xCount
    FROM TournamentParticipant p
    JOIN Round r ON r.tournamentId = p.tournamentId AND r.participantId = p.userId
    JOIN ArrowScore a ON a.roundId = r.id
    WHERE p.tournamentId = :tournamentId
    AND p.totalScore = :tiedScore
    GROUP BY p.id
    ORDER BY xCount DESC
""")
suspend fun breakTie(tournamentId: String, tiedScore: Int): List<ParticipantWithXCount>
```

---

## Related Entities

**Scoring:**
- [Round](../Scoring/#round-entity) - Tournament rounds link via tournamentId
- [ArrowScore](../Scoring/#arrowscore-entity) - Individual scores in tournament rounds

**Equipment:**
- [BowSetup](../Equipment/#bowsetup-entity) - Participants use their equipment

---

## Developer Guidelines

### Best Practices

**1. Always Check Tournament Status**
```kotlin
// Good: Verify status before actions
if (tournament.status == TournamentStatus.OPEN) {
    allowRegistration()
} else {
    showError("Tournament registration closed")
}

// Bad: Assume tournament is open
createParticipant()  // May fail if tournament already started
```

**2. Handle Offline Gracefully**
```kotlin
// Good: Cache offline, sync later
if (isOnline) {
    submitScoresDirectly()
} else {
    cacheScoresForLaterSync()
}

// Bad: Fail on offline
submitScoresDirectly()  // Throws exception if offline
```

**3. Recalculate Rankings After Score Changes**
```kotlin
// Good: Update rankings
submitRound(round)
updateTournamentRankings(tournamentId)

// Bad: Stale rankings
submitRound(round)
// Rankings not updated, leaderboard shows old data
```

**4. Enforce Deadlines**
```kotlin
// Good: Check deadlines before submission
if (tournament.roundDeadlines[roundNumber]?.let { it > Clock.System.now() } == true) {
    allowSubmission()
} else {
    showError("Round deadline passed")
}
```

### Common Queries

**Get active tournaments:**
```kotlin
@Query("""
    SELECT * FROM TournamentEntity
    WHERE status IN ('OPEN', 'IN_PROGRESS')
    ORDER BY startTime ASC
""")
suspend fun getActiveTournaments(): List<TournamentEntity>
```

**Get user's tournaments:**
```kotlin
@Query("""
    SELECT t.* FROM TournamentEntity t
    JOIN TournamentParticipant p ON p.tournamentId = t.id
    WHERE p.userId = :userId
    ORDER BY t.createdAt DESC
""")
suspend fun getUserTournaments(userId: String): List<TournamentEntity>
```

**Get tournament with participants:**
```kotlin
data class TournamentWithParticipants(
    val tournament: TournamentEntity,
    val participants: List<TournamentParticipantEntity>
)

@Transaction
@Query("SELECT * FROM TournamentEntity WHERE id = :tournamentId")
suspend fun getTournamentWithParticipants(tournamentId: String): TournamentWithParticipants
```

---

## Related Documentation

**Database:**
- [Database Overview](../../Database/) - Full database architecture
- [Database Tables](../../Database/Tables/) - Table schemas

**Other Data Models:**
- [Scoring Models](../Scoring/) - Round and arrow data
- [Equipment Models](../Equipment/) - Participant equipment

**User Guides:**
- [Tournament Features](../../../user-guide/features/tournaments/) - User-facing tournament docs

---

## Quick Reference

| Entity | Fields | Purpose | Cascade |
|--------|--------|---------|---------|
| **TournamentEntity** | 36 | Tournament metadata and configuration | Parent → deletes participants |
| **TournamentParticipantEntity** | 10 | Participant progress and ranking | Child of tournament |
| **TournamentScoreCache** | 7 | Offline score caching for sync | Standalone (no FK) |

**Tournament Status Flow:**
`OPEN → IN_PROGRESS → COMPLETED` (or `CANCELLED`)

**Participant Status:**
`ACTIVE`, `WITHDRAWN`, `DISQUALIFIED`, `COMPLETED`

**Sync Status:**
`PENDING`, `SYNCED`, `FAILED`

**Tournament Types:**
- **Local** (isLocal = true): Offline, no sync
- **Remote** (isLocal = false): Online, real-time sync
- **Hybrid**: Remote with offline caching

---

**Next:** [Analytics Data Models](../Analytics/) - Performance metrics and caching entities
