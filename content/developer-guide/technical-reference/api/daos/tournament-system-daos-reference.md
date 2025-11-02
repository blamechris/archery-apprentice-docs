---
title: Tournament & System DAOs Reference
tags:
  - api
  - dao
  - room
  - tournament
  - sync
  - system
created: 2025-11-01
---

# Tournament & System DAOs Reference

Consolidated reference for tournament and system infrastructure DAOs.

---

## Overview

These DAOs handle tournament data and system infrastructure for cloud sync and user management.

**DAOs Covered:**

**Tournament DAOs (3):**
- TournamentDao
- TournamentParticipantDao
- TournamentScoreDao

**System DAOs (3):**
- UserDao
- SyncQueueDao
- ConflictDao

---

## Tournament DAOs

### TournamentDao

**File:** `data/dao/TournamentDao.kt`
**Table:** `tournaments`
**Purpose:** Tournament metadata and configuration

#### Schema

```kotlin
@Entity(tableName = "tournaments")
data class Tournament(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val location: String,
    val startDate: Long,
    val endDate: Long,
    val format: String,          // TournamentFormat enum
    val organizer: String,
    val status: String,          // PLANNED, IN_PROGRESS, COMPLETED, CANCELLED
    val liveScoringEnabled: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val modifiedAt: Long = System.currentTimeMillis(),
    val syncStatus: String = "SYNCED"
)
```

#### API

```kotlin
@Dao
interface TournamentDao {
    // Insert/Update
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(tournament: Tournament): Long

    @Update
    suspend fun update(tournament: Tournament)

    @Upsert
    suspend fun upsert(tournament: Tournament)

    // Query
    @Query("SELECT * FROM tournaments WHERE id = :tournamentId")
    suspend fun getById(tournamentId: String): Tournament?

    @Query("SELECT * FROM tournaments WHERE status = :status ORDER BY startDate DESC")
    suspend fun getByStatus(status: String): List<Tournament>

    @Query("SELECT * FROM tournaments WHERE startDate >= :startDate AND endDate <= :endDate")
    suspend fun getInDateRange(startDate: Long, endDate: Long): List<Tournament>

    @Query("SELECT * FROM tournaments ORDER BY startDate DESC")
    fun observeAll(): Flow<List<Tournament>>

    @Query("SELECT * FROM tournaments WHERE id = :tournamentId")
    fun observe(tournamentId: String): Flow<Tournament?>

    // Delete
    @Delete
    suspend fun delete(tournament: Tournament)

    @Query("DELETE FROM tournaments WHERE id = :tournamentId")
    suspend fun deleteById(tournamentId: String)

    // Sync queries
    @Query("SELECT * FROM tournaments WHERE syncStatus != 'SYNCED'")
    suspend fun getUnsyncedTournaments(): List<Tournament>

    @Query("UPDATE tournaments SET syncStatus = :status WHERE id = :tournamentId")
    suspend fun updateSyncStatus(tournamentId: String, status: String)
}
```

#### Usage Example

```kotlin
// Create tournament
val tournament = Tournament(
    name = "Spring Championship 2025",
    location = "National Archery Center",
    startDate = parseDate("2025-05-15"),
    endDate = parseDate("2025-05-17"),
    format = "WA_720",
    organizer = "State Archery Association",
    status = "PLANNED"
)

tournamentDao.insert(tournament)

// Query upcoming tournaments
val upcoming = tournamentDao.getByStatus("PLANNED")

// Start tournament
val started = tournament.copy(status = "IN_PROGRESS")
tournamentDao.update(started)

// Observe tournament changes
tournamentDao.observe(tournamentId)
    .collect { tournament ->
        updateUI(tournament)
    }
```

---

### TournamentParticipantDao

**File:** `data/dao/TournamentParticipantDao.kt`
**Table:** `tournament_participants`
**Purpose:** Participant registration and details

#### Schema

```kotlin
@Entity(
    tableName = "tournament_participants",
    foreignKeys = [
        ForeignKey(
            entity = Tournament::class,
            parentColumns = ["id"],
            childColumns = ["tournamentId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("tournamentId")]
)
data class TournamentParticipant(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val tournamentId: String,
    val name: String,
    val division: String,       // Division enum
    val ageCategory: String,    // AgeCategory enum
    val club: String? = null,
    val email: String? = null,
    val targetNumber: String? = null,
    val registeredAt: Long = System.currentTimeMillis()
)
```

#### API

```kotlin
@Dao
interface TournamentParticipantDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(participant: TournamentParticipant): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(participants: List<TournamentParticipant>)

    @Update
    suspend fun update(participant: TournamentParticipant)

    @Delete
    suspend fun delete(participant: TournamentParticipant)

    // Query by tournament
    @Query("SELECT * FROM tournament_participants WHERE tournamentId = :tournamentId")
    suspend fun getForTournament(tournamentId: String): List<TournamentParticipant>

    @Query("SELECT * FROM tournament_participants WHERE tournamentId = :tournamentId AND division = :division")
    suspend fun getForTournamentAndDivision(tournamentId: String, division: String): List<TournamentParticipant>

    // Query by ID
    @Query("SELECT * FROM tournament_participants WHERE id = :participantId")
    suspend fun getById(participantId: String): TournamentParticipant?

    // Observe
    @Query("SELECT * FROM tournament_participants WHERE tournamentId = :tournamentId")
    fun observeForTournament(tournamentId: String): Flow<List<TournamentParticipant>>

    // Count
    @Query("SELECT COUNT(*) FROM tournament_participants WHERE tournamentId = :tournamentId")
    suspend fun getParticipantCount(tournamentId: String): Int

    // Search
    @Query("SELECT * FROM tournament_participants WHERE tournamentId = :tournamentId AND name LIKE '%' || :query || '%'")
    suspend fun searchParticipants(tournamentId: String, query: String): List<TournamentParticipant>
}
```

#### Usage Example

```kotlin
// Add participant
val participant = TournamentParticipant(
    tournamentId = tournamentId,
    name = "Alice Johnson",
    division = "RECURVE_WOMEN",
    ageCategory = "SENIOR",
    club = "City Archers",
    targetNumber = "1A"
)

participantDao.insert(participant)

// Bulk add
val participants = listOf(/* ... */)
participantDao.insertAll(participants)

// Get all participants for tournament
val allParticipants = participantDao.getForTournament(tournamentId)

// Get by division
val recurveWomen = participantDao.getForTournamentAndDivision(
    tournamentId = tournamentId,
    division = "RECURVE_WOMEN"
)

// Search
val searchResults = participantDao.searchParticipants(tournamentId, "Alice")
```

---

### TournamentScoreDao

**File:** `data/dao/TournamentScoreDao.kt`
**Table:** `tournament_scores`
**Purpose:** Tournament scoring data

#### Schema

```kotlin
@Entity(
    tableName = "tournament_scores",
    foreignKeys = [
        ForeignKey(
            entity = Tournament::class,
            parentColumns = ["id"],
            childColumns = ["tournamentId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = TournamentParticipant::class,
            parentColumns = ["id"],
            childColumns = ["participantId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("tournamentId"), Index("participantId")]
)
data class TournamentScore(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val tournamentId: String,
    val participantId: String,
    val endScoresJson: String,  // Serialized List<EndScore>
    val total: Int,
    val xCount: Int,
    val timestamp: Long = System.currentTimeMillis(),
    val syncStatus: String = "SYNCED"
)

// Used for serialization
data class EndScore(
    val endNumber: Int,
    val arrows: List<Int>
)
```

#### API

```kotlin
@Dao
interface TournamentScoreDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(score: TournamentScore): Long

    @Update
    suspend fun update(score: TournamentScore)

    @Delete
    suspend fun delete(score: TournamentScore)

    // Query by tournament
    @Query("SELECT * FROM tournament_scores WHERE tournamentId = :tournamentId ORDER BY total DESC")
    suspend fun getForTournament(tournamentId: String): List<TournamentScore>

    // Query by participant
    @Query("SELECT * FROM tournament_scores WHERE participantId = :participantId")
    suspend fun getForParticipant(participantId: String): List<TournamentScore>

    @Query("SELECT * FROM tournament_scores WHERE tournamentId = :tournamentId AND participantId = :participantId")
    suspend fun getForTournamentAndParticipant(
        tournamentId: String,
        participantId: String
    ): TournamentScore?

    // Leaderboard
    @Query("""
        SELECT ts.*, tp.name, tp.division
        FROM tournament_scores ts
        JOIN tournament_participants tp ON ts.participantId = tp.id
        WHERE ts.tournamentId = :tournamentId
        ORDER BY ts.total DESC, ts.xCount DESC
    """)
    suspend fun getLeaderboard(tournamentId: String): List<LeaderboardEntry>

    // Observe
    @Query("SELECT * FROM tournament_scores WHERE tournamentId = :tournamentId ORDER BY total DESC")
    fun observeForTournament(tournamentId: String): Flow<List<TournamentScore>>

    // Statistics
    @Query("SELECT AVG(total) FROM tournament_scores WHERE tournamentId = :tournamentId")
    suspend fun getAverageScore(tournamentId: String): Double?

    @Query("SELECT MAX(total) FROM tournament_scores WHERE tournamentId = :tournamentId")
    suspend fun getHighScore(tournamentId: String): Int?

    // Sync
    @Query("SELECT * FROM tournament_scores WHERE syncStatus != 'SYNCED'")
    suspend fun getUnsyncedScores(): List<TournamentScore>
}

// Result class for leaderboard query
data class LeaderboardEntry(
    val id: String,
    val tournamentId: String,
    val participantId: String,
    val endScoresJson: String,
    val total: Int,
    val xCount: Int,
    val timestamp: Long,
    val syncStatus: String,
    val name: String,
    val division: String
)
```

#### Usage Example

```kotlin
// Submit score
val score = TournamentScore(
    tournamentId = tournamentId,
    participantId = participantId,
    endScoresJson = Json.encodeToString(endScores),
    total = 654,
    xCount = 45
)

scoreDao.insert(score)

// Get leaderboard
val leaderboard = scoreDao.getLeaderboard(tournamentId)

leaderboard.forEachIndexed { index, entry ->
    println("${index + 1}. ${entry.name}: ${entry.total} (${entry.xCount}X)")
}

// Real-time updates
scoreDao.observeForTournament(tournamentId)
    .collect { scores ->
        updateLeaderboardUI(scores)
    }
```

---

## System DAOs

### UserDao

**File:** `data/dao/UserDao.kt`
**Table:** `users`
**Purpose:** User profile and preferences

#### Schema

```kotlin
@Entity(tableName = "users")
data class User(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val firebaseUid: String? = null,
    val email: String,
    val displayName: String,
    val photoUrl: String? = null,
    val club: String? = null,
    val division: String? = null,
    val ageCategory: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val lastLoginAt: Long = System.currentTimeMillis(),
    val preferences: String = "{}"  // JSON serialized preferences
)
```

#### API

```kotlin
@Dao
interface UserDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(user: User): Long

    @Update
    suspend fun update(user: User)

    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getById(userId: String): User?

    @Query("SELECT * FROM users WHERE firebaseUid = :firebaseUid")
    suspend fun getByFirebaseUid(firebaseUid: String): User?

    @Query("SELECT * FROM users WHERE email = :email")
    suspend fun getByEmail(email: String): User?

    @Query("SELECT * FROM users LIMIT 1")
    suspend fun getCurrentUser(): User?

    @Query("UPDATE users SET lastLoginAt = :timestamp WHERE id = :userId")
    suspend fun updateLastLogin(userId: String, timestamp: Long)

    @Query("UPDATE users SET preferences = :preferencesJson WHERE id = :userId")
    suspend fun updatePreferences(userId: String, preferencesJson: String)

    @Delete
    suspend fun delete(user: User)

    fun observeCurrentUser(): Flow<User?>
}
```

#### Usage Example

```kotlin
// Create user on first login
val user = User(
    firebaseUid = firebaseAuth.currentUser?.uid,
    email = "archer@example.com",
    displayName = "Alice Archer",
    club = "City Archers",
    division = "RECURVE_WOMEN"
)

userDao.insert(user)

// Update preferences
val preferences = Preferences(
    theme = "dark",
    units = "metric",
    notifications = true
)

userDao.updatePreferences(
    userId = user.id,
    preferencesJson = Json.encodeToString(preferences)
)

// Get current user
val currentUser = userDao.getCurrentUser()
```

---

### SyncQueueDao

**File:** `data/dao/SyncQueueDao.kt`
**Table:** `sync_queue`
**Purpose:** Queue pending sync operations for offline support

#### Schema

```kotlin
@Entity(tableName = "sync_queue")
data class SyncQueueItem(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val entityType: String,      // "ROUND", "TOURNAMENT_SCORE", etc.
    val entityId: String,
    val operation: String,       // "CREATE", "UPDATE", "DELETE"
    val dataJson: String,        // Serialized entity data
    val timestamp: Long = System.currentTimeMillis(),
    val retryCount: Int = 0,
    val lastAttempt: Long? = null,
    val error: String? = null
)
```

#### API

```kotlin
@Dao
interface SyncQueueDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: SyncQueueItem): Long

    @Insert
    suspend fun insertAll(items: List<SyncQueueItem>)

    @Update
    suspend fun update(item: SyncQueueItem)

    @Delete
    suspend fun delete(item: SyncQueueItem)

    // Get pending items
    @Query("SELECT * FROM sync_queue ORDER BY timestamp ASC")
    suspend fun getAllPending(): List<SyncQueueItem>

    @Query("SELECT * FROM sync_queue WHERE entityType = :entityType")
    suspend fun getPendingForEntityType(entityType: String): List<SyncQueueItem>

    @Query("SELECT COUNT(*) FROM sync_queue")
    suspend fun getPendingCount(): Int

    // Retry management
    @Query("SELECT * FROM sync_queue WHERE retryCount < :maxRetries")
    suspend fun getPendingWithRetries(maxRetries: Int = 3): List<SyncQueueItem>

    @Query("UPDATE sync_queue SET retryCount = retryCount + 1, lastAttempt = :timestamp, error = :error WHERE id = :itemId")
    suspend fun incrementRetry(itemId: String, timestamp: Long, error: String)

    // Clean up
    @Query("DELETE FROM sync_queue WHERE id = :itemId")
    suspend fun deleteById(itemId: String)

    @Query("DELETE FROM sync_queue WHERE retryCount >= :maxRetries")
    suspend fun deleteFailedItems(maxRetries: Int = 5)

    // Observe
    fun observePendingCount(): Flow<Int>
}
```

#### Usage Example

```kotlin
// Queue item for sync when offline
val queueItem = SyncQueueItem(
    entityType = "TOURNAMENT_SCORE",
    entityId = score.id,
    operation = "CREATE",
    dataJson = Json.encodeToString(score)
)

syncQueueDao.insert(queueItem)

// Process queue when online
val pendingItems = syncQueueDao.getAllPending()

pendingItems.forEach { item ->
    try {
        // Sync to cloud
        firebaseService.sync(item)
        syncQueueDao.delete(item)
    } catch (e: Exception) {
        // Increment retry count
        syncQueueDao.incrementRetry(
            itemId = item.id,
            timestamp = System.currentTimeMillis(),
            error = e.message ?: "Unknown error"
        )
    }
}

// Show pending count in UI
syncQueueDao.observePendingCount()
    .collect { count ->
        updateBadge(count)
    }
```

---

### ConflictDao

**File:** `data/dao/ConflictDao.kt`
**Table:** `conflicts`
**Purpose:** Track and resolve sync conflicts

#### Schema

```kotlin
@Entity(tableName = "conflicts")
data class DataConflict(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val entityType: String,
    val entityId: String,
    val conflictType: String,    // "BOTH_MODIFIED", "LOCAL_DELETED", etc.
    val localDataJson: String?,
    val remoteDataJson: String?,
    val localTimestamp: Long,
    val remoteTimestamp: Long,
    val detectedAt: Long = System.currentTimeMillis(),
    val resolvedAt: Long? = null,
    val resolution: String? = null,  // "KEEP_LOCAL", "KEEP_REMOTE", "MERGE"
    val resolvedBy: String? = null   // User ID or "auto"
)
```

#### API

```kotlin
@Dao
interface ConflictDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(conflict: DataConflict): Long

    @Insert
    suspend fun insertAll(conflicts: List<DataConflict>)

    @Update
    suspend fun update(conflict: DataConflict)

    @Delete
    suspend fun delete(conflict: DataConflict)

    // Query pending conflicts
    @Query("SELECT * FROM conflicts WHERE resolvedAt IS NULL ORDER BY detectedAt DESC")
    suspend fun getPendingConflicts(): List<DataConflict>

    @Query("SELECT * FROM conflicts WHERE resolvedAt IS NULL AND entityType = :entityType")
    suspend fun getPendingConflictsForEntityType(entityType: String): List<DataConflict>

    @Query("SELECT COUNT(*) FROM conflicts WHERE resolvedAt IS NULL")
    suspend fun getPendingConflictCount(): Int

    // Resolve conflict
    @Query("""
        UPDATE conflicts
        SET resolvedAt = :timestamp, resolution = :resolution, resolvedBy = :resolvedBy
        WHERE id = :conflictId
    """)
    suspend fun resolveConflict(
        conflictId: String,
        resolution: String,
        resolvedBy: String,
        timestamp: Long
    )

    // History
    @Query("SELECT * FROM conflicts WHERE entityId = :entityId ORDER BY detectedAt DESC")
    suspend fun getConflictHistory(entityId: String): List<DataConflict>

    @Query("SELECT * FROM conflicts WHERE resolvedAt IS NOT NULL ORDER BY resolvedAt DESC LIMIT :limit")
    suspend fun getRecentlyResolved(limit: Int = 10): List<DataConflict>

    // Clean up old resolved conflicts
    @Query("DELETE FROM conflicts WHERE resolvedAt IS NOT NULL AND resolvedAt < :timestamp")
    suspend fun deleteOldResolved(timestamp: Long)

    // Observe
    @Query("SELECT COUNT(*) FROM conflicts WHERE resolvedAt IS NULL")
    fun observePendingCount(): Flow<Int>
}
```

#### Usage Example

```kotlin
// Detect and store conflict
val conflict = DataConflict(
    entityType = "ROUND",
    entityId = round.id.toString(),
    conflictType = "BOTH_MODIFIED",
    localDataJson = Json.encodeToString(localRound),
    remoteDataJson = Json.encodeToString(remoteRound),
    localTimestamp = localRound.modifiedAt,
    remoteTimestamp = remoteRound.modifiedAt
)

conflictDao.insert(conflict)

// Get pending conflicts
val pending = conflictDao.getPendingConflicts()

// Show conflict resolution UI
pending.forEach { conflict ->
    showConflictDialog(conflict) { resolution ->
        conflictDao.resolveConflict(
            conflictId = conflict.id,
            resolution = resolution.strategy,
            resolvedBy = currentUser.id,
            timestamp = System.currentTimeMillis()
        )
    }
}

// Monitor conflicts
conflictDao.observePendingCount()
    .collect { count ->
        if (count > 0) {
            showConflictBadge(count)
        }
    }
```

---

## Testing

### Example Tests

```kotlin
@Test
fun insertAndRetrieveTournament() = runTest {
    val tournament = Tournament(
        name = "Test Tournament",
        location = "Test Location",
        startDate = System.currentTimeMillis(),
        endDate = System.currentTimeMillis() + 86400000,
        format = "WA_720",
        organizer = "Test Org",
        status = "PLANNED"
    )

    tournamentDao.insert(tournament)
    val retrieved = tournamentDao.getById(tournament.id)

    assertEquals(tournament.name, retrieved?.name)
}

@Test
fun getLeaderboardSortedByScore() = runTest {
    // Insert participants and scores
    val p1 = TournamentParticipant(id = "p1", tournamentId = "t1", name = "Alice", ...)
    val p2 = TournamentParticipant(id = "p2", tournamentId = "t1", name = "Bob", ...)

    participantDao.insertAll(listOf(p1, p2))

    val s1 = TournamentScore(tournamentId = "t1", participantId = "p1", total = 650, xCount = 40)
    val s2 = TournamentScore(tournamentId = "t1", participantId = "p2", total = 680, xCount = 45)

    scoreDao.insert(s1)
    scoreDao.insert(s2)

    val leaderboard = scoreDao.getLeaderboard("t1")

    assertEquals("Bob", leaderboard[0].name)  // Higher score first
    assertEquals(680, leaderboard[0].total)
}

@Test
fun syncQueueProcessing() = runTest {
    val item = SyncQueueItem(
        entityType = "ROUND",
        entityId = "r1",
        operation = "CREATE",
        dataJson = "{}"
    )

    syncQueueDao.insert(item)
    assertEquals(1, syncQueueDao.getPendingCount())

    syncQueueDao.deleteById(item.id)
    assertEquals(0, syncQueueDao.getPendingCount())
}
```

---

## Related Documentation

- [[../repositories/hybrid-tournament-repository|HybridTournamentRepository]]
- [[../repositories/tournament-repository|TournamentRepository]]
- [[../services/sync-conflict-services-reference|Sync & Conflict Services]]
- [[../services/tournament-management-service|TournamentManagementService]]

---

**Status:** ✅ All 6 DAOs in production
**Pattern:** Consistent Room DAO with offline-first support
**Test Coverage:** Integration tests for all DAOs
**Last Updated:** 2025-11-01
