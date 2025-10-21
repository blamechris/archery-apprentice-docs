# Round Lifecycle Flow

---
tags: #flow #round-lifecycle #round-status #session-management #statistics
created: 2025-10-08
related:
  - "[[Flows/Scoring-Flow]]"
  - "[[Flows/Multi-Participant-Flow]]"
  - "[[Flows/Equipment-Management-Flow]]"
  - "[[Flows/Tournament-Flow]]"
  - "[[Architecture/MVVM-Architecture]]"
---

## Overview

The Round Lifecycle Flow describes the complete journey of a round from creation through active scoring to historical viewing. This flow covers round status transitions, validation, persistence, completion logic, and data display.

### Architecture Components

**Round Lifecycle Layer:**
- MVVM architecture with specialized ViewModels (god class extraction in progress)
- Repository pattern for database operations
- Room Database for local persistence
- Firebase integration for tournament rounds
- StateFlow for reactive UI updates

### Round Status State Machine

```
PLANNED → IN_PROGRESS → COMPLETED
    ↓           ↓           ↑
    ↓       PAUSED ←--------┘
    ↓
CANCELLED
```

**Status Definitions:**
- `PLANNED`: Round created but not yet started
- `IN_PROGRESS`: Currently scoring arrows
- `PAUSED`: Temporarily suspended, can resume
- `COMPLETED`: All ends finished, statistics finalized
- `CANCELLED`: Abandoned, marked for cleanup

---

## Round Creation Flow

### Entry Point: Round Creation UI

**User Action:** Create new round from Home screen

**Call Chain:**
1. `RoundViewModel.kt:1791` - `saveRound()` - Validate and persist round
2. `RoundRepository.kt:52` - `insertRound()` - Database insertion
3. `RoundInputState.toRound()` - Convert UI state to Round entity

### Round Creation Process

```mermaid
sequenceDiagram
    participant User
    participant UI as RoundCreationUI
    participant VM as RoundViewModel
    participant State as RoundInputState
    participant Repo as RoundRepository
    participant DB as Room Database
    participant BowRepo as BowSetupRepository

    User->>UI: Fill round details
    UI->>VM: Update input fields
    VM->>State: Update RoundInputState
    
    User->>UI: Select bow setup
    VM->>BowRepo: Get selectable setups
    BowRepo-->>VM: Available setups
    VM->>State: Update selected setup
    
    User->>UI: Add guest archer (optional)
    VM->>State: Enable guest, set name
    
    User->>UI: Tap "Create Round"
    UI->>VM: saveRound()
    VM->>State: isValid() check
    
    alt No bow setup selected
        VM->>BowRepo: getDefaultBowSetup()
        BowRepo-->>VM: Default setup
    end
    
    VM->>State: toRound(bowSetup)
    State-->>VM: Round entity (status=PLANNED)
    
    VM->>Repo: insertRound(round)
    Repo->>DB: INSERT INTO rounds
    DB-->>Repo: Round ID
    Repo-->>VM: Round ID
    VM-->>UI: Navigate to round
</mermaid>

### Round Input Validation

**Code:** `RoundInputState.kt` (state package)

```kotlin
// RoundInputState validation
fun isValid(): Boolean {
    return roundName.isNotBlank() &&
           numEnds.toIntOrNull()?.let { it > 0 } == true &&
           numArrows.toIntOrNull()?.let { it > 0 } == true &&
           selectedDistance != null &&
           selectedTargetSize != null &&
           selectedScoringSystem != null
}
```

**Validation Rules:**
- Round name must not be blank
- Number of ends must be positive integer
- Number of arrows must be positive integer
- Distance, target size, and scoring system must be selected
- Bow setup auto-selects default if none chosen

### Round Entity Creation

**Code:** `Round.kt:29`

```kotlin
// Round entity with complete metadata
data class Round(
    @PrimaryKey(autoGenerate = true)
    val id: Int = 0,
    val roundName: String,
    val numEnds: Int,
    val numArrows: Int,
    val distance: Distance,
    val targetSize: TargetSize,
    val createdAt: Long = System.currentTimeMillis(),
    val scoringSystem: ScoringSystem,
    
    // Enhanced fields
    val bowSetupId: Long = 0,
    val status: RoundStatus = RoundStatus.PLANNED,
    val weatherConditions: String = "",
    val notes: String = "",
    val totalScore: Int = 0,
    val maxPossibleScore: Int,
    val completedEnds: Int = 0,
    val startTime: Long? = null,
    val endTime: Long? = null,
    val updatedAt: Long = System.currentTimeMillis(),
    
    // Multi-participant support
    val participants: List<SessionParticipant>? = null,
    val participantTheme: ParticipantTheme = ParticipantTheme.SINGLE_USER,
    
    // Tournament integration
    val tournamentId: String? = null,
    val tournamentRoundNumber: Int? = null,
    val isLocal: Boolean = true,
    val syncStatus: SyncStatus = SyncStatus.LOCAL_ONLY
)
```

### Database Insertion

**Code:** `RoundRepository.kt:52`

```kotlin
suspend fun insertRound(round: Round): Long = roundDao.insertRound(round)
```

**Database Indexes:** `Round.kt:21`
- `bowSetupId` - Fast equipment lookup
- `createdAt` - Chronological sorting
- `tournamentId` - Tournament round filtering
- `(tournamentId, tournamentRoundNumber)` - Composite tournament key
- `syncStatus` - Offline sync queries

---

## Round Starting Flow

### Entry Point: Start Scoring Session

**User Action:** Tap "Start Scoring" on a PLANNED round

**Call Chain:**
1. `RoundViewModel.kt:1735` - `startScoringSession()` - Load and start
2. `RoundRepository.kt:232` - `startRound()` - Update status
3. `RoundViewModel.kt:830` - `loadScoringSession()` - Initialize state

### Round Starting Process

```mermaid
sequenceDiagram
    participant User
    participant UI as RoundListUI
    participant VM as RoundViewModel
    participant Repo as RoundRepository
    participant DB as Room Database

    User->>UI: Tap "Start Scoring"
    UI->>VM: startScoringSession(roundId)
    VM->>Repo: startRound(roundId)
    
    Repo->>DB: SELECT round WHERE id=?
    DB-->>Repo: Round entity
    
    alt Round not found
        Repo-->>VM: false
        VM-->>UI: Error: Round not found
    else Status not PLANNED
        Repo-->>VM: false
        VM-->>UI: Error: Already started
    else Valid transition
        Repo->>Repo: round.copy(status=IN_PROGRESS, startTime=now)
        Repo->>DB: UPDATE rounds SET status=?, startTime=?
        DB-->>Repo: Success
        Repo-->>VM: true
        
        VM->>Repo: getRoundWithDetails(roundId)
        Repo->>DB: Get round + bow setup + ends
        DB-->>Repo: RoundWithDetails
        
        VM->>Repo: getNextEndNumber(roundId)
        Repo-->>VM: 1 (first end)
        
        VM->>Repo: calculateRoundStatistics(roundId)
        Repo-->>VM: null (no statistics yet)
        
        VM->>VM: Load participant ends/progress
        VM->>VM: Initialize ScoringSessionState
        VM-->>UI: Navigate to ActiveScoringScreen
    end
</mermaid>

### Status Transition Logic

**Code:** `RoundRepository.kt:232`

```kotlin
suspend fun startRound(roundId: Int): Boolean {
    android.util.Log.d("RoundRepository", "=== startRound START ===")
    android.util.Log.d("RoundRepository", "Attempting to start round: $roundId")
    
    val round = roundDao.getRoundById(roundId)
    if (round == null) {
        android.util.Log.e("RoundRepository", "FAILED: Round not found")
        return false
    }
    
    if (round.status != RoundStatus.PLANNED) {
        android.util.Log.e("RoundRepository", "FAILED: Not PLANNED: ${round.status}")
        return false
    }

    val updatedRound = round.copy(
        status = RoundStatus.IN_PROGRESS,
        startTime = System.currentTimeMillis(),
        updatedAt = System.currentTimeMillis()
    )

    roundDao.updateRound(updatedRound)
    android.util.Log.d("RoundRepository", "=== startRound SUCCESS ===")
    return true
}
```

### Scoring Session Initialization

**Code:** `RoundViewModel.kt:830`

```kotlin
fun loadScoringSession(roundId: Int) {
    viewModelScope.launch {
        try {
            _isLoading.value = true

            val roundWithDetails = roundRepository.getRoundWithDetails(roundId)
            if (roundWithDetails == null) {
                _errorMessage.value = "Round not found"
                return@launch
            }

            val nextEndNumber = roundRepository.getNextEndNumber(roundId) ?: 1
            val statistics = roundRepository.calculateRoundStatistics(roundId)

            // Load per-participant ends and progress
            val endsMap = mutableMapOf<String, List<EndScoreWithArrows>>()
            val totalsMap = mutableMapOf<String, Int>()
            val endsCountMap = mutableMapOf<String, Int>()
            
            roundWithDetails.round.participants?.forEach { p ->
                val ends = roundRepository.getEndsWithArrowsForParticipant(
                    roundWithDetails.round.id.toLong(), 
                    p.id
                )
                endsMap[p.id] = ends
                totalsMap[p.id] = ends.sumOf { it.endScore.totalScore }
                endsCountMap[p.id] = ends.size
            }

            val newSessionState = ScoringSessionState(
                currentRound = roundWithDetails,
                currentEndNumber = nextEndNumber,
                currentArrowNumber = 1,
                statistics = statistics,
                sessionStatus = SessionStatus.Active,
                currentParticipantId = getDefaultParticipantId(
                    roundWithDetails.round.participants
                ),
                participantEndsWithArrows = endsMap,
                participantProgress = createParticipantProgressMap(
                    endsCountMap, 
                    roundWithDetails
                )
            )
            
            _scoringSession.value = newSessionState
        } finally {
            _isLoading.value = false
        }
    }
}
```

---

## Active Scoring Flow

### Integration with Scoring Flow

**See:** [[Flows/Scoring-Flow]] for complete arrow scoring details

**Key Integration Points:**
1. Arrow input and coordinate capture
2. End completion triggers round progress updates
3. Participant switching preserves round state
4. Real-time statistics calculation
5. Multi-participant progress tracking

### Round Progress Tracking

**Code:** `RoundViewModel.kt:322`

```kotlin
// Calculate overall round progress (0.0 to 1.0)
private fun calculateOverallProgress(): Float {
    val session = _scoringSession.value
    val currentRound = session.currentRound?.round ?: return 0f

    if (currentRound.numEnds == 0) return 0f

    val completedEnds = currentRound.completedEnds
    val currentEndProgress = calculateCurrentEndProgress()

    return (completedEnds + currentEndProgress) / currentRound.numEnds
}
```

### Multi-Participant Progress

**See:** [[Flows/Multi-Participant-Flow]] for participant management

**Progress Structure:** `ParticipantProgress`

```kotlin
data class ParticipantProgress(
    val endsCompleted: Int,
    val endsTotal: Int,
    val isComplete: Boolean,
    val version: Int = 0,
    val updatedAt: Instant = Instant.now(),
    val isDirty: Boolean = false
)
```

---

## Round Pause/Resume Flow

### Pause Round

**Call Chain:**
1. User taps "Pause" button
2. `RoundRepository.kt:264` - `pauseRound()` - Status transition

**Code:** `RoundRepository.kt:264`

```kotlin
suspend fun pauseRound(roundId: Int): Boolean {
    val round = roundDao.getRoundById(roundId) ?: return false

    if (round.status != RoundStatus.IN_PROGRESS) return false

    val updatedRound = round.copy(
        status = RoundStatus.PAUSED,
        updatedAt = System.currentTimeMillis()
    )

    roundDao.updateRound(updatedRound)
    return true
}
```

### Resume Round

**Call Chain:**
1. User taps "Resume" on paused round
2. `RoundRepository.kt:281` - `resumeRound()` - Status transition
3. `loadScoringSession()` - Restore session state

**Code:** `RoundRepository.kt:281`

```kotlin
suspend fun resumeRound(roundId: Int): Boolean {
    val round = roundDao.getRoundById(roundId) ?: return false

    if (round.status != RoundStatus.PAUSED) return false

    val updatedRound = round.copy(
        status = RoundStatus.IN_PROGRESS,
        updatedAt = System.currentTimeMillis()
    )

    roundDao.updateRound(updatedRound)
    return true
}
```

---

## Round Completion Flow

### Entry Point: Complete Final End

**User Action:** Complete the final end of the round

**Call Chain:**
1. `LiveScoringViewModel` - `completeCurrentEnd()` - End completion
2. `EndCompletionService.kt:173` - `completeCurrentEnd()` - End finalization
3. `RoundRepository.kt:298` - `completeRound()` - Round finalization

### Round Completion Process

```mermaid
sequenceDiagram
    participant User
    participant UI as ActiveScoringScreen
    participant LiveVM as LiveScoringViewModel
    participant EndSvc as EndCompletionService
    participant Repo as RoundRepository
    participant DB as Room Database

    User->>UI: Score final arrow
    UI->>LiveVM: completeCurrentEnd()
    LiveVM->>EndSvc: completeCurrentEnd(session, round)
    
    EndSvc->>EndSvc: finalizeEnd() validation
    EndSvc->>Repo: scoreEnd() - Record end
    Repo->>DB: INSERT end_scores + arrow_scores
    
    alt Multi-participant round
        EndSvc->>EndSvc: Check all participants complete
        alt Not all complete
            EndSvc-->>LiveVM: Success, continue
            LiveVM-->>UI: Switch participant or wait
        else All participants complete
            LiveVM->>Repo: completeRound(roundId)
        end
    else Single participant
        LiveVM->>Repo: completeRound(roundId)
    end
    
    Repo->>Repo: calculateRoundStatistics()
    Repo->>Repo: Calculate final score
    
    alt Multi-participant
        Repo->>Repo: Get MU-only score
        Note over Repo: Filter ends by LocalUser ID
    else Single participant
        Repo->>Repo: Use aggregate statistics
    end
    
    Repo->>Repo: round.copy(status=COMPLETED, endTime=now)
    Repo->>DB: UPDATE rounds SET status=?, totalScore=?
    DB-->>Repo: Success
    
    Repo-->>LiveVM: Success
    LiveVM->>LiveVM: Trigger roundCompleteEvent
    LiveVM-->>UI: Show completion celebration
    UI-->>User: Navigate to round details
</mermaid>

### Completion Logic

**Code:** `RoundRepository.kt:298`

```kotlin
suspend fun completeRound(roundId: Int): Boolean {
    val round = roundDao.getRoundById(roundId) ?: return false

    if (round.status == RoundStatus.COMPLETED) return true

    // Calculate final statistics
    val statistics = calculateRoundStatistics(roundId)
    
    // CRITICAL FIX: For multi-participant, store MU-only score
    val finalTotalScore = if ((round.participants?.size ?: 1) > 1) {
        // Multi-participant: Calculate MU-only total score
        val endScores = roundDao.getEndScoresForRound(roundId)
        val muId = resolveLocalParticipantId(round)
        val muScore = endScores.filter {
            it.isCompleted && (it.participantId == muId || 
                              (muId == null && it.participantId == null))
        }.sumOf { it.totalScore }
        android.util.Log.d("RoundRepository", 
            "completeRound: Multi-participant, MU-only score: $muScore")
        muScore
    } else {
        // Single participant: Use aggregate statistics
        statistics?.totalScore ?: 0
    }

    val updatedRound = round.copy(
        status = RoundStatus.COMPLETED,
        endTime = System.currentTimeMillis(),
        totalScore = finalTotalScore,
        completedEnds = roundDao.getEndScoresForRound(roundId)
            .count { it.isCompleted },
        updatedAt = System.currentTimeMillis()
    )

    roundDao.updateRound(updatedRound)
    return true
}
```

### Statistics Calculation

**Code:** `RoundRepository.kt:658`

```kotlin
suspend fun calculateRoundStatistics(roundId: Int): RoundStatistics? {
    val round = roundDao.getRoundById(roundId) ?: return null
    val statsData = roundDao.getRoundStatistics(roundId) ?: return null

    val maxPossibleScore = round.numEnds * round.numArrows * 
        round.scoringSystem.maxScore
    val accuracy = if (maxPossibleScore > 0) {
        (statsData.totalScore.toDouble() / maxPossibleScore) * 100
    } else 0.0

    val completionPercentage = if (round.numEnds > 0) {
        (round.completedEnds.toDouble() / round.numEnds) * 100
    } else 0.0

    return RoundStatistics(
        totalScore = statsData.totalScore,
        maxPossibleScore = maxPossibleScore,
        averagePerArrow = statsData.averageScore,
        averagePerEnd = if (round.completedEnds > 0) {
            statsData.totalScore.toDouble() / round.completedEnds
        } else 0.0,
        accuracy = accuracy,
        xCount = statsData.xCount,
        tenCount = statsData.tenCount,
        nineCount = statsData.nineCount,
        missCount = statsData.missCount,
        completionPercentage = completionPercentage
    )
}
```

---

## Round Cancellation Flow

### Entry Point: Cancel Round

**User Action:** Select "Cancel Round" from menu

**Call Chain:**
1. UI confirmation dialog
2. `RoundRepository.kt:336` - `cancelRound()` - Status transition

**Code:** `RoundRepository.kt:336`

```kotlin
suspend fun cancelRound(roundId: Int): Boolean {
    val round = roundDao.getRoundById(roundId) ?: return false

    val updatedRound = round.copy(
        status = RoundStatus.CANCELLED,
        endTime = System.currentTimeMillis(),
        updatedAt = System.currentTimeMillis()
    )

    roundDao.updateRound(updatedRound)
    return true
}
```

**Maintenance:** Cancelled rounds are automatically cleaned up by background jobs

---

## Historical Round Viewing Flow

### Entry Point: Historical Rounds Screen

**User Action:** View completed/cancelled rounds

**Call Chain:**
1. `RoundViewModel.kt:1002` - `createRoundDisplayData()` - Format display
2. `RoundRepository.kt:90` - `getRoundWithDetails()` - Load data
3. `RoundViewModel.kt:744` - `recomputeRoundTotals()` - Calculate scores

### Historical Viewing Process

```mermaid
sequenceDiagram
    participant User
    participant UI as HistoricalRoundsScreen
    participant VM as RoundViewModel
    participant Repo as RoundRepository
    participant DB as Room Database

    User->>UI: Open Historical Rounds
    UI->>VM: Observe roundsByStatus Flow
    VM->>Repo: getAllRounds()
    Repo->>DB: SELECT * FROM rounds
    DB-->>Repo: List<Round>
    Repo-->>VM: Flow<List<Round>>
    
    VM->>VM: Group by status
    VM->>VM: Filter by selected tab
    
    loop For each round
        VM->>VM: createRoundDisplayData(round, settings)
        
        alt Cached data exists
            VM-->>VM: Return cached display data
        else Calculate fresh
            VM->>VM: resolveMuSubject(round)
            VM->>Repo: getMuScore(round)
            
            alt Multi-participant
                Repo->>Repo: recomputeRoundTotals()
                Repo->>DB: Get all arrows for round
                DB-->>Repo: Arrow data
                Repo->>Repo: Filter by LocalUser ID
                Repo-->>VM: MU-only score
            else Single participant
                VM-->>VM: Use round.totalScore
            end
            
            alt Completed multi-participant
                VM->>VM: calculateMuRank(round)
                
                alt Tournament round
                    VM->>TournamentRepo: Get participant
                    TournamentRepo->>Firebase: Read finalRank
                    Firebase-->>VM: Server-side rank
                else Local multi-participant
                    VM->>Repo: Calculate local rank
                    Repo->>Repo: Sort by score + X count
                    Repo-->>VM: Calculated rank
                end
            end
            
            VM->>VM: Format display title
            VM->>VM: Calculate progress/accuracy
            VM->>VM: Cache display data
        end
    end
    
    VM-->>UI: Display data list
    UI-->>User: Show rounds with stats
</mermaid>

### Display Data Formatting

**Code:** `RoundViewModel.kt:1002`

```kotlin
suspend fun createRoundDisplayData(
    round: Round, 
    settings: Settings?
): RoundDisplayData {
    // Cache for completed rounds (immutable)
    if (round.status == RoundStatus.COMPLETED) {
        displayDataCache[round.id]?.let { return it }
    }

    // Subject resolution (supports future team mode)
    val subject = resolveMuSubject(round, settings)

    // Calculate MU-only scores
    val muScore = getSubjectScore(round, subject)
    val muMaxScore = getSubjectMaxScore(round, subject)
    val muAccuracy = calculateAccuracy(muScore, muMaxScore).toFloat()
    
    val totalParticipants = getTotalParticipants(round)

    // Calculate ranking for completed rounds
    val muRank = if (round.status == RoundStatus.COMPLETED) {
        calculateMuRank(round, targetParticipantId = null)
    } else null
    
    // Create display title
    val displayTitle = when {
        totalParticipants > 1 && muRank != null -> {
            val muDisplayName = settings?.userName ?: "You"
            val rankDisplay = formatRankDisplay(muRank, totalParticipants)
            "$muDisplayName -- $rankDisplay"
        }
        totalParticipants > 1 -> {
            SessionParticipant.getDisplayNames(
                round.participants ?: emptyList(), 
                settings
            )
        }
        else -> round.roundName
    }
    
    // Calculate progress
    val progressPercentage = if (round.numEnds > 0) {
        (round.completedEnds.toFloat() / round.numEnds).coerceIn(0f, 1f)
    } else 0f
    
    val result = RoundDisplayData(
        round = round,
        displayTitle = displayTitle,
        muScore = muScore,
        muMaxScore = muMaxScore,
        muAccuracy = muAccuracy,
        muRank = muRank,
        totalParticipants = totalParticipants,
        createdDate = formatReadableDate(round.createdAt),
        updatedDate = formatReadableDate(round.updatedAt),
        progressPercentage = progressPercentage,
        // Legacy compatibility fields...
    )

    // Cache completed rounds
    if (round.status == RoundStatus.COMPLETED) {
        displayDataCache[round.id] = result
    }

    return result
}
```

### Ranking Calculation

**Code:** `RoundViewModel.kt:1366`

```kotlin
suspend fun calculateMuRank(
    round: Round, 
    targetParticipantId: String? = null
): Int? {
    if (round.status != RoundStatus.COMPLETED || 
        round.participants.isNullOrEmpty() || 
        round.participants.size <= 1) {
        return null
    }

    return try {
        // TOURNAMENT ROUNDS: Read from Firebase
        if (!round.tournamentId.isNullOrBlank() && repositoryFactory != null) {
            val tournamentRepo = repositoryFactory.createTournamentRepository(
                getApplication<Application>().applicationContext
            )
            
            val muId = targetParticipantId 
                ?: round.participants?.find { it is SessionParticipant.LocalUser }?.id
            
            if (muId != null) {
                val participantResult = tournamentRepo.getParticipant(
                    round.tournamentId, 
                    muId
                )
                
                if (participantResult.isSuccess) {
                    val participant = participantResult.getOrNull()
                    if (participant?.finalRank != null) {
                        return participant.finalRank
                    }
                }
            }
            return null // Tournament rank not yet calculated
        }

        // LOCAL ROUNDS: Calculate from database
        val roundTotals = recomputeRoundTotals(round.id.toLong())
        val participantScores = roundTotals.perParticipant

        val muId = targetParticipantId 
            ?: round.participants?.find { it is SessionParticipant.LocalUser }?.id

        // Calculate X counts for tie-breaking
        val participantXCounts = mutableMapOf<String?, Int>()
        round.participants?.forEach { participant ->
            val ends = roundRepository.getEndsWithArrowsForParticipant(
                round.id.toLong(), 
                participant.id
            )
            participantXCounts[participant.id] = 
                ends.sumOf { end -> end.arrows.count { it.isX } }
        }

        // Create ranking with tie-breaking
        data class ParticipantRankData(
            val id: String?,
            val score: Int,
            val xCount: Int
        )

        val rankingData = participantScores.map { (id, score) ->
            ParticipantRankData(
                id = id,
                score = score,
                xCount = participantXCounts[id] ?: 0
            )
        }.sortedWith(
            compareByDescending<ParticipantRankData> { it.score }
                .thenByDescending { it.xCount }
        )

        // Find rank with tie-breaking
        var currentRank = 1
        rankingData.forEachIndexed { index, data ->
            if (index > 0) {
                val previous = rankingData[index - 1]
                val isTrueTie = data.score == previous.score && 
                               data.xCount == previous.xCount
                if (!isTrueTie) {
                    currentRank = index + 1
                }
            }
            if (data.id == muId) {
                return currentRank
            }
        }

        null
    } catch (e: Exception) {
        android.util.Log.e("RoundViewModel", 
            "Failed to calculate rank", e)
        null
    }
}
```

---

## Round Details View

### Entry Point: Tap Round Card

**User Action:** Tap on a round in historical list

**Call Chain:**
1. `RoundViewModel.kt:720` - `loadRoundDetailsWithStats()` - Load complete data
2. `RoundRepository.kt:90` - `getRoundWithDetails()` - Get round + ends + equipment
3. `RoundViewModel.kt:744` - `recomputeRoundTotals()` - Calculate per-participant totals

### Details Loading Process

```mermaid
sequenceDiagram
    participant User
    participant UI as RoundDetailsScreen
    participant VM as RoundViewModel
    participant Repo as RoundRepository
    participant DB as Room Database

    User->>UI: Tap round card
    UI->>VM: loadRoundDetailsWithStats(roundId)
    
    VM->>Repo: getRoundWithDetails(roundId)
    Repo->>DB: Get round by ID
    DB-->>Repo: Round entity
    
    Repo->>BowRepo: getBowSetupWithEquipment(setupId)
    BowRepo-->>Repo: Bow setup + equipment
    
    Repo->>DB: getEndsWithArrowsForRound(roundId)
    DB-->>Repo: All ends with arrows
    
    Repo-->>VM: RoundWithDetails
    
    alt Completed round
        VM->>VM: recomputeRoundTotals(roundId)
        
        alt Multi-participant
            VM->>Repo: getAllArrowsForRound(roundId)
            Repo-->>VM: All arrow data
            VM->>VM: Group by participant ID
            VM->>VM: Sum per participant
            VM-->>VM: RoundTotals with per-participant map
        else Single participant
            VM->>Repo: getAggregateStats(roundId)
            Repo-->>VM: Aggregate statistics
            VM-->>VM: RoundTotals with single total
        end
        
        VM->>Repo: getAggregateStatsForParticipant(roundId, muId)
        Repo-->>VM: MU-specific statistics
    end
    
    VM-->>UI: Callback with data
    UI-->>User: Show round details with statistics
</mermaid>

### Round Totals Calculation

**Code:** `RoundViewModel.kt:744`

```kotlin
suspend fun recomputeRoundTotals(roundId: Long): RoundTotals {
    val round = roundRepository.getRoundById(roundId.toInt())
    val participants = round?.participants ?: emptyList()
    
    return if (participants.size > 1) {
        // Multi-participant: per-participant totals
        val allArrows = roundRepository.getAllArrowsForRound(roundId)
        val perParticipantTotals = participants.associate { participant ->
            val participantArrows = allArrows.filter { 
                it.participantId == participant.id 
            }
            participant.id to participantArrows.sumOf { it.scoreValue }
        }
        val totalScore = perParticipantTotals.values.sum()
        RoundTotals(perParticipantTotals, totalScore)
    } else {
        // Single participant: aggregate stats
        roundRepository.getAggregateStats(roundId).let { stats ->
            val perParticipantMap = mapOf(null to stats.totalScore)
            RoundTotals(perParticipantMap, stats.totalScore)
        }
    }
}
```

---

## Key Classes and Files

| File | Location | Purpose |
|------|----------|---------|
| **Round.kt** | `data/models/Round.kt:29` | Round entity with status machine |
| **RoundStatus.kt** | `data/models/Round.kt:143` | Status enum definition |
| **RoundWithDetails.kt** | `data/models/RoundWithDetails.kt:11` | Composite round + ends + equipment |
| **RoundStatistics.kt** | `data/models/RoundWithDetails.kt:22` | Statistics data class |
| **RoundRepository.kt** | `domain/repository/RoundRepository.kt:40` | Round CRUD and lifecycle operations |
| **RoundViewModel.kt** | `ui/roundScoring/RoundViewModel.kt:201` | God class (being extracted) |
| **RoundInputState.kt** | `ui/roundScoring/state/RoundInputState.kt` | Creation form state |
| **RoundDisplayData.kt** | `ui/roundScoring/RoundViewModel.kt:57` | Historical display formatting |
| **HistoricalRoundsScreen.kt** | `ui/roundScoring/HistoricalRoundsScreen.kt` | Historical rounds UI |

---

## State Management

### Round Input State

**Structure:** `RoundInputState`

```kotlin
data class RoundInputState(
    val roundName: String = "",
    val numEnds: String = "6",
    val numArrows: String = "6",
    val selectedDistance: Distance? = Distance.EIGHTEEN_METERS,
    val selectedTargetSize: TargetSize? = TargetSize.FORTY_CM,
    val selectedScoringSystem: ScoringSystem = ScoringSystem.STANDARD_10_RING,
    val selectedBowSetup: BowSetup? = null,
    val guestArcherEnabled: Boolean = false,
    val guestArcherName: String = "",
    val weatherConditions: String = "",
    val notes: String = ""
)
```

### Scoring Session State

**See:** [[Flows/Scoring-Flow]] for `ScoringSessionState` details

**Key Round-Related Fields:**
- `currentRound: RoundWithDetails?` - Active round data
- `currentEndNumber: Int` - Current end (1-indexed)
- `sessionStatus: SessionStatus` - Active/Complete/Error
- `isRoundComplete: Boolean` - All participants finished
- `statistics: RoundStatistics?` - Live statistics

### Round Display Data

**Structure:** `RoundDisplayData` (RoundViewModel.kt:57)

```kotlin
data class RoundDisplayData(
    val round: Round,
    val displayTitle: String,        // "MU name -- rank / participants"
    val muScore: Int,                 // MU-only score
    val muMaxScore: Int,              // MU max possible
    val muAccuracy: Float,            // MU accuracy percentage
    val muRank: Int?,                 // Rank (1-based) or null
    val totalParticipants: Int,       // Total participant count
    val createdDate: String,          // Formatted creation date
    val updatedDate: String,          // Formatted update date
    val progressPercentage: Float,    // 0.0 to 1.0
    // Legacy compatibility fields...
)
```

---

## Error Handling

### Validation Failures

**Round Creation:**
- Empty round name → Show validation error
- Invalid numeric fields → Prevent save
- Missing required fields → Disable save button
- Bow setup unavailable → Auto-select default

**Round Starting:**
- Round not found → "Round not found" error
- Already started → "Round already in progress"
- Status mismatch → Silently handle, refresh UI

### Data Loading Failures

**Round Details:**
- Round deleted → Navigate back to list
- Database error → Show retry option
- Missing equipment → Display "Unknown Equipment"
- Corrupted data → Attempt recovery, log error

### Completion Failures

**Round Completion:**
- Incomplete ends → Prevent completion
- Database write failure → Retry logic
- Statistics calculation error → Use fallback values
- Sync failure (tournament) → Mark as LOCAL_ONLY

---

## Performance Considerations

### Database Optimization

**Indexes:** `Round.kt:21`
- `createdAt` - Fast chronological queries
- `bowSetupId` - Equipment lookup optimization
- `tournamentId` - Tournament filtering
- `syncStatus` - Offline sync queries

**Query Patterns:**
```kotlin
// OPTIMIZED: Single query with JOIN
val roundWithDetails = roundRepository.getRoundWithDetails(roundId)

// AVOIDED: N+1 query pattern
// for (endId in endIds) { getEndById(endId) } ❌
```

### Caching Strategy

**Display Data Cache:** `RoundViewModel.kt:1496`
```kotlin
private val displayDataCache: MutableMap<Int, RoundDisplayData> = mutableMapOf()

// Cache completed rounds (immutable)
if (round.status == RoundStatus.COMPLETED) {
    displayDataCache[round.id] = result
}
```

**Cache Invalidation:**
- Round status changes → Clear cache entry
- Round deletion → Remove from cache
- App restart → Cache reset (in-memory only)

### Background Processing

**Maintenance Operations:** `RoundRepository.kt:1205`
```kotlin
// Clean up old cancelled rounds
suspend fun cleanupCancelledRounds()

// Auto-cancel old unfinished rounds (>30 days)
suspend fun cancelOldUnfinishedRounds(daysOld: Int = 30)
```

---

## Related Flows

- **[[Flows/Scoring-Flow]]** - Active arrow scoring and end completion
- **[[Flows/Multi-Participant-Flow]]** - Multi-participant round management
- **[[Flows/Equipment-Management-Flow]]** - Bow setup selection and tracking
- **[[Flows/Tournament-Flow]]** - Tournament round creation and sync

---

## Future Enhancements

### Team Mode Support

**Planned:** Team-based scoring mode
- Team assignments per participant
- Team aggregate scoring
- Team rankings and leaderboards
- Individual + team progress tracking

**Code Preparation:** `RoundViewModel.kt:1553`
```kotlin
// TODO(team-mode): Replace with real field when schema adds scoringMode
private fun inferScoringMode(round: Round): RoundScoringMode =
    if (FeatureFlags.TEAM_MODE) RoundScoringMode.TEAM 
    else RoundScoringMode.INDIVIDUAL
```

### Specialized ViewModels

**Extraction In Progress:**
- `RoundCreationViewModel` - Round creation logic
- `RoundManagementViewModel` - Round list/deletion
- `RoundAnalyticsViewModel` - Statistics and rankings
- `LiveScoringViewModel` - Active scoring (completed)

**Current Status:** RoundViewModel is a 2,177-line god class being refactored

### Advanced Analytics

**Planned Features:**
- Round comparison tools
- Progress trend analysis
- Equipment performance correlation
- Fatigue detection across rounds
- Historical pattern recognition
