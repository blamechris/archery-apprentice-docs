---
title: "Integration Flows"
description: "External integration patterns and API interactions"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - flows
  - integration
  - api
  - firebase
  - sync
---

[Home](/) > [Technical Reference](../../) > [Flows](../) > Integration Flows

---

# Integration Flows

Complete reference for external service integrations, cloud synchronization, and data exchange patterns in Archery Apprentice.

## Overview

Integration flows describe how Archery Apprentice interacts with external services, including Firebase (authentication, Firestore sync), data exports (CSV, JSON), and potential future integrations. This guide documents all major external integration patterns.

**Flow Organization:**

Flows are organized by integration type:

1. **Firebase Integration** - Authentication, Firestore sync, real-time listeners
2. **Data Exchange** - Exports (CSV, JSON), imports, backups
3. **Future Integrations** - Planned external service integrations

**Related Documentation:**

- [User Flows](../User-Flows/) - User-facing workflows
- [System Flows](../System-Flows/) - Internal system processes
- [Database Overview](../../Database/) - Local data persistence

---

## Firebase Integration Flows

Flows related to Firebase Authentication, Firestore synchronization, and real-time data updates.

### 1. Data Sync Flow (Offline-First Architecture)

**Status:** ✅ Fully Documented (1,399 lines)
**Documentation:** [Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/)

**Overview:**

Comprehensive offline-first architecture with Firebase Firestore sync, exponential backoff retry, conflict resolution, and smart caching.

**Architecture:**

```
Local Room Database (Source of Truth) ⇄ Firebase Firestore (Cloud Backup)
         ↓                                      ↓
   StateFlow → UI                    Real-Time Listeners → Update Local DB
```

**Key Patterns:**

1. **Offline-First** - Local database is the source of truth, UI always reads from local
2. **Background Sync** - Firebase sync happens asynchronously, doesn't block UI
3. **Real-Time Listeners** - Firebase listeners update local DB when remote data changes
4. **Exponential Backoff Retry** - Network failures trigger automatic retry (up to 5 attempts)
5. **Conflict Resolution** - Last-write-wins strategy with timestamp-based detection
6. **Smart Caching** - TTL-based caching reduces network calls (5 minutes for leaderboards)

**Read Flow:**

```
UI Request → Check Local Cache (valid?) → Check Room Database →
Room DB Stale? → Fetch from Firebase → Update Local DB → Emit to UI
```

**Write Flow:**

```
User Action → Update Room Database (Immediate) → Emit Success to UI →
Background: Sync to Firebase (Async with Retry) → Conflict Check → Merge if Needed
```

**Hybrid Repository Pattern:**

The `HybridTournamentRepository.kt` (1,813 lines) implements the hybrid pattern:

```kotlin
class HybridTournamentRepository(
    private val localDao: TournamentDao,           // Room Database
    private val firebaseRepo: FirebaseTournamentRepository, // Firebase
    private val cacheService: TournamentScoreCacheService   // In-Memory Cache
) {
    // Read: Cache → Local DB → Firebase (if network)
    suspend fun getTournament(id: String): Tournament {
        // Check cache first
        cacheService.get(id)?.let { return it }

        // Check local DB
        val local = localDao.getTournament(id)
        if (local != null && !local.isStale()) {
            cacheService.put(id, local)
            return local
        }

        // Fetch from Firebase (if network available)
        if (networkAvailable) {
            val remote = firebaseRepo.getTournament(id)
            localDao.insert(remote) // Update local DB
            cacheService.put(id, remote)
            return remote
        }

        // Offline mode: return stale local data or error
        return local ?: throw OfflineException()
    }

    // Write: Local DB (immediate) → Firebase (async with retry)
    suspend fun submitScore(score: Score) {
        // Update local DB first (source of truth)
        localDao.insertScore(score)

        // Sync to Firebase asynchronously
        viewModelScope.launch {
            submitScoreWithRetry(score, maxRetries = 5)
        }
    }

    private suspend fun submitScoreWithRetry(score: Score, maxRetries: Int): Result {
        var attempt = 0
        var delay = 1000L

        while (attempt < maxRetries) {
            try {
                firebaseRepo.submitScore(score)
                return Result.Success
            } catch (e: IOException) {
                attempt++
                if (attempt >= maxRetries) return Result.Failure(e)
                delay(delay)
                delay *= 2 // Exponential backoff: 1s, 2s, 4s, 8s, 16s
            }
        }
    }
}
```

**Conflict Resolution:**

Timestamp-based last-write-wins strategy:

```kotlin
suspend fun resolveConflict(local: Score, remote: Score): Score {
    // Compare timestamps (epoch milliseconds)
    return if (local.updatedAt > remote.updatedAt) {
        // Local is newer, keep local and overwrite remote
        firebaseRepo.updateScore(local)
        local
    } else {
        // Remote is newer, update local with remote
        localDao.updateScore(remote)
        remote
    }
}
```

**Real-Time Listeners:**

Firebase listeners automatically update local DB when remote data changes:

```kotlin
fun observeTournamentLeaderboard(tournamentId: String): Flow<List<Score>> {
    // Start Firebase listener
    firebaseRepo.observeLeaderboard(tournamentId)
        .onEach { remoteScores ->
            // Update local DB with remote changes
            localDao.insertAll(remoteScores)
        }
        .launchIn(viewModelScope)

    // Return local DB Flow (always up-to-date via listener)
    return localDao.observeScores(tournamentId)
}
```

**Caching Strategy:**

TTL-based caching reduces Firebase network calls:

| Data Type              | TTL      | Rationale                                         |
|------------------------|----------|---------------------------------------------------|
| Tournament Leaderboard | 5 min    | Balance real-time updates vs network load         |
| Equipment Stats        | 5 min    | Infrequently changing, expensive to recalculate   |
| Historical Rounds      | 1 week   | Immutable after completion, safe to cache long-term |

**Network Connectivity Monitoring:**

```kotlin
class NetworkCallback : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) {
        // Network available: trigger pending syncs
        syncPendingScores()
    }

    override fun onLost(network: Network) {
        // Network lost: switch to offline mode
        _networkStatus.value = NetworkStatus.Offline
    }
}
```

**Key Components:**

- HybridTournamentRepository.kt (1,813 lines) - Hybrid offline-first pattern
- TournamentSyncService.kt (556 lines) - Score submission with exponential backoff
- ScoreConflictResolutionService.kt - Timestamp-based conflict resolution
- TournamentScoreCacheService.kt - TTL-based smart caching
- NetworkCallback - Connectivity monitoring

**Performance Considerations:**

- Local DB queries are indexed for fast retrieval
- Firebase listeners use efficient query filters (where clauses)
- Batch operations for initial tournament data loading
- Exponential backoff prevents network spam during failures

**See Full Documentation:** [Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/)

---

### 2. Firebase Authentication Flow

**Status:** ⚠️ Partially Documented (mentioned in Data Sync Flow)
**Documentation:** Examples scattered across flow docs

**Overview:**

Firebase anonymous authentication for tournament participation and score synchronization.

**Authentication Flow:**

```
App Launch → Check Auth State → Signed In? →
  Yes: Continue with existing user
  No: Sign in anonymously → Store Firebase UID → Continue
```

**Anonymous Sign-In:**

```kotlin
suspend fun signInAnonymously(): AuthResult {
    return try {
        val result = FirebaseAuth.getInstance().signInAnonymously().await()
        val uid = result.user?.uid ?: throw AuthException("No UID")

        // Store UID in local settings
        settingsRepository.updateFirebaseUid(uid)

        AuthResult.Success(uid)
    } catch (e: Exception) {
        AuthResult.Failure(e.message)
    }
}
```

**User Identity Resolution:**

Local vs Firebase user identity:

```kotlin
class UserIdentityResolver(
    private val settingsRepository: SettingsRepository,
    private val firebaseAuth: FirebaseAuth
) {
    suspend fun resolveUserId(): String {
        // Prefer Firebase UID if authenticated
        val firebaseUid = firebaseAuth.currentUser?.uid
        if (firebaseUid != null) return firebaseUid

        // Fall back to local settings user name
        val settings = settingsRepository.getSettings()
        return settings.defaultUserName ?: "Unknown User"
    }

    fun isAuthenticated(): Boolean {
        return firebaseAuth.currentUser != null
    }
}
```

**Permission Checks:**

Tournament scoring requires authentication:

```kotlin
suspend fun canScoreInTournament(tournamentId: String): Boolean {
    // Must be authenticated
    if (!firebaseAuth.isAuthenticated()) return false

    // Must be tournament owner or participant
    val tournament = tournamentRepository.getTournament(tournamentId)
    val userId = firebaseAuth.currentUser?.uid ?: return false

    return tournament.ownerId == userId ||
           tournament.participants.any { it.userId == userId }
}
```

**Auth State Monitoring:**

```kotlin
fun observeAuthState(): Flow<AuthState> = callbackFlow {
    val listener = FirebaseAuth.AuthStateListener { auth ->
        trySend(
            if (auth.currentUser != null) {
                AuthState.SignedIn(auth.currentUser!!.uid)
            } else {
                AuthState.SignedOut
            }
        )
    }

    firebaseAuth.addAuthStateListener(listener)
    awaitClose { firebaseAuth.removeAuthStateListener(listener) }
}
```

**Key Components (Identified but Not Fully Documented):**

- FirebaseAuth integration (anonymous sign-in)
- UserIdentityResolver.kt - User identity resolution
- ScoringPermissionService.kt - Tournament permission checks
- Settings entity (stores Firebase UID)

**Authentication Features:**

- Anonymous sign-in (no email/password required)
- Persistent UID across app sessions
- Auth state monitoring for UI updates
- Permission checks for tournament scoring
- Graceful degradation if auth fails (local-only mode)

**Future Enhancements:**

- Email/password authentication (for persistent accounts)
- Social sign-in (Google, Apple)
- Account linking (merge anonymous accounts)
- Multi-device sync (same account across devices)

---

### 3. Real-Time Firebase Listeners

**Status:** ✅ Documented (part of Data Sync Flow)
**Documentation:** [Data Sync Flow - Real-Time Listeners](../../../../developer-guide/technical-reference/flows/data-sync-flow/#real-time-listeners)

**Overview:**

Firebase Firestore listeners provide real-time updates for tournament leaderboards and participant scores.

**Listener Pattern:**

```kotlin
fun observeTournamentScores(tournamentId: String): Flow<List<Score>> {
    return callbackFlow {
        val listener = firestore
            .collection("tournaments")
            .document(tournamentId)
            .collection("scores")
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                val scores = snapshot?.documents?.mapNotNull { doc ->
                    doc.toObject(Score::class.java)
                } ?: emptyList()

                trySend(scores)
            }

        awaitClose { listener.remove() }
    }
}
```

**Listener Lifecycle:**

```
ViewModel Created → Start Listener → Listen for Changes →
Remote Data Changes → Listener Callback → Update Local DB → Emit to UI →
ViewModel Cleared → Remove Listener (Cleanup)
```

**Key Benefits:**

- Real-time leaderboard updates (see other participants' scores live)
- Automatic conflict detection (local vs remote changes)
- No polling required (Firebase pushes updates)
- Efficient bandwidth usage (only deltas are sent)

**See Full Documentation:** [Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/)

---

## Data Exchange Flows

Flows related to exporting, importing, and backing up data.

### 4. Data Export Flow

**Status:** ⚠️ Partially Documented (mentioned in Equipment docs)
**Planned Documentation:** To be created

**Overview:**

Export rounds, equipment, and statistics to CSV or JSON for external analysis or backup.

**Export Flow (High-Level):**

```
User Selects Export → Choose Format (CSV/JSON) → Choose Data Type (Rounds/Equipment/Stats) →
Apply Filters (Date Range, Equipment, Distance) → Generate Export File →
Share via Android Intent (Email, Cloud Storage, Download)
```

**Export Formats:**

1. **CSV (Comma-Separated Values)**
   - Best for: Spreadsheet analysis (Excel, Google Sheets)
   - Supports: Rounds, equipment, statistics
   - Includes: Headers, formatted data, date/time formatting

2. **JSON (JavaScript Object Notation)**
   - Best for: Programmatic access, backups
   - Supports: Full data model with relationships
   - Includes: Complete round/equipment snapshots

**CSV Export Example:**

```kotlin
suspend fun exportRoundsToCSV(
    rounds: List<Round>,
    includeArrows: Boolean = false
): File {
    val csv = StringBuilder()

    // Header row
    csv.appendLine("Date,Round Name,Distance,Target Size,Total Score,Average,Num Ends,Equipment")

    // Data rows
    rounds.forEach { round ->
        csv.appendLine(
            "${round.createdAt.formatDate()}," +
            "${round.roundName}," +
            "${round.distance}," +
            "${round.targetSize}," +
            "${round.totalScore}," +
            "${round.averageScore}," +
            "${round.numEnds}," +
            "${round.equipmentName}"
        )

        // Optionally include arrow-by-arrow data
        if (includeArrows) {
            round.ends.forEach { end ->
                end.arrows.forEach { arrow ->
                    csv.appendLine("  ,End ${end.number},Arrow ${arrow.number},${arrow.score}")
                }
            }
        }
    }

    // Write to temporary file
    val file = File(context.cacheDir, "rounds_export_${System.currentTimeMillis()}.csv")
    file.writeText(csv.toString())
    return file
}
```

**JSON Export Example:**

```kotlin
suspend fun exportEquipmentToJSON(bowSetup: BowSetup): File {
    val json = Json.encodeToString(
        BowSetupExport(
            bowSetup = bowSetup,
            components = listOf(
                bowSetup.arrow,
                bowSetup.sight,
                bowSetup.rest,
                bowSetup.stabilizer,
                // ... other components
            ).filterNotNull(),
            metadata = ExportMetadata(
                exportedAt = Clock.System.now(),
                appVersion = BuildConfig.VERSION_NAME,
                databaseVersion = 35
            )
        )
    )

    val file = File(context.cacheDir, "equipment_export_${bowSetup.id}.json")
    file.writeText(json)
    return file
}
```

**Share via Android Intent:**

```kotlin
fun shareExportFile(file: File) {
    val uri = FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )

    val intent = Intent(Intent.ACTION_SEND).apply {
        type = if (file.extension == "csv") "text/csv" else "application/json"
        putExtra(Intent.EXTRA_STREAM, uri)
        putExtra(Intent.EXTRA_SUBJECT, "Archery Apprentice Export")
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    context.startActivity(Intent.createChooser(intent, "Share Export"))
}
```

**Export Options:**

- **Rounds Export** - All rounds, filtered by date range or equipment
- **Equipment Export** - Complete bow setup with all components
- **Statistics Export** - Aggregated stats (average, consistency, trends)
- **Full Backup** - Complete database export (all data as JSON)

**Key Components (Identified but Not Fully Documented):**

- EquipmentExportScreen.kt - Export UI
- RoundExportService.kt - CSV/JSON generation
- ShareHelper.kt - Android intent sharing

**Future Enhancements:**

- Import from CSV/JSON (reverse flow)
- Scheduled automatic backups (daily, weekly)
- Cloud backup integration (Google Drive, Dropbox)
- Backup encryption (for sensitive data)

---

### 5. Data Import Flow

**Status:** ⚠️ Not Documented (Low Priority)
**Planned Documentation:** To be created

**Overview:**

Import rounds, equipment, or backup data from CSV or JSON files.

**Import Flow (High-Level):**

```
User Selects Import → Choose File (CSV/JSON) → Validate Format →
Parse Data → Resolve Conflicts (Existing vs Imported) →
Preview Changes → Confirm Import → Insert into Database → Show Summary
```

**Validation:**

```kotlin
suspend fun validateImport(file: File): ImportValidation {
    return try {
        when (file.extension) {
            "csv" -> validateCSV(file)
            "json" -> validateJSON(file)
            else -> ImportValidation.UnsupportedFormat
        }
    } catch (e: Exception) {
        ImportValidation.Invalid(e.message)
    }
}

suspend fun validateJSON(file: File): ImportValidation {
    val json = Json.decodeFromString<BowSetupExport>(file.readText())

    // Check version compatibility
    if (json.metadata.databaseVersion > currentDbVersion) {
        return ImportValidation.IncompatibleVersion
    }

    // Check for conflicts
    val existingBowSetup = bowSetupDao.getById(json.bowSetup.id)
    val conflicts = if (existingBowSetup != null) {
        listOf(ImportConflict(json.bowSetup.id, "Bow setup already exists"))
    } else {
        emptyList()
    }

    return ImportValidation.Valid(conflicts)
}
```

**Conflict Resolution:**

- **Skip** - Skip conflicting items, import only new data
- **Overwrite** - Replace existing data with imported data
- **Merge** - Combine existing and imported data (where possible)
- **Create New** - Import as new item with new ID

**Key Challenges:**

- Foreign key resolution (equipment references in rounds)
- Version compatibility (database schema changes)
- Data validation (ensure imported data is well-formed)
- Conflict resolution (user must choose strategy)

---

## Future Integration Flows

Potential future integrations (not yet implemented).

### 6. Social Sharing Integration

**Status:** 🔮 Planned (Future)

**Overview:**

Share round results, statistics, or achievements to social media platforms.

**Potential Integrations:**

- Share to Instagram/Twitter with image of target diagram + scores
- Share to Facebook with round summary and equipment details
- Share to archery-specific social networks (e.g., ArcheryTalk)

---

### 7. Wearable Device Integration

**Status:** 🔮 Planned (Future)

**Overview:**

Integrate with smartwatches or fitness trackers for real-time heart rate monitoring during rounds.

**Potential Integrations:**

- Apple Watch / WearOS for heart rate during scoring
- Correlate heart rate with shot accuracy (fatigue detection)
- Voice commands for hands-free scoring

---

### 8. External Tournament Management Systems

**Status:** 🔮 Planned (Future)

**Overview:**

Integration with official tournament management systems (e.g., Ianseo, ArcheryGB).

**Potential Integrations:**

- Import tournament schedules from Ianseo
- Auto-submit scores to official tournament systems
- Sync official rankings and participant lists

---

## Related Documentation

- **[User Flows](../User-Flows/)** - User-facing workflows and interactions
- **[System Flows](../System-Flows/)** - Internal system processes
- **[Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/)** - Comprehensive Firebase sync documentation
- **[Firebase Documentation](../../../../developer-guide/technical-reference/firebase/)** - Firebase integration guides
- **[Database Overview](../../Database/)** - Local data persistence

---

## Contributing Integration Flow Documentation

To add or improve integration flow documentation:

1. **Map the Integration** - Identify external service, APIs, data formats
2. **Document API Calls** - Show HTTP requests, Firestore queries, etc.
3. **Document Data Transformation** - How is data converted between formats?
4. **Add Error Handling** - What happens when integration fails?
5. **Include Authentication** - How is the integration authenticated/authorized?
6. **Add Performance Notes** - Caching, rate limiting, bandwidth considerations
7. **Cross-Reference** - Link to external API docs, user flows, system flows

**Integration Flow Checklist:**

- [ ] External service overview (purpose, capabilities)
- [ ] Authentication/authorization flow
- [ ] Data format specifications (API schemas, CSV/JSON structures)
- [ ] Request/response examples (API calls, file formats)
- [ ] Error handling and recovery strategies
- [ ] Performance considerations (caching, rate limits, bandwidth)
- [ ] Related flows (user flows, system flows)
- [ ] Testing strategies (mocking external services)

---

**Last Updated:** 2025-11-04
**Documentation Coverage:** 3 flows fully documented (1,399 lines from Data Sync Flow), 4 flows partially documented/planned
