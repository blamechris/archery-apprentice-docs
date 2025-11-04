---
title: Refactoring Roadmap
tags:
  - architecture
  - refactoring
  - roadmap
  - performance
  - priorities
created: 2025-10-08
source: docs/architecture/REFACTORING_ROADMAP.md
last-updated: 2025-01
version: 1.0
---

# Archery Apprentice - Refactoring Roadmap

## Executive Summary

This document provides a prioritized roadmap for addressing technical debt and architectural improvements based on comprehensive architectural audit findings. The roadmap focuses on critical god class decomposition, layer violation fixes, performance optimization, and testing gap closure.

## Priority Classification

- **CRITICAL** 🚨 - Blocking issues that impact maintainability and performance
- **HIGH** ⚠️ - Important improvements with significant impact
- **MEDIUM** 📋 - Valuable improvements that enhance code quality
- **LOW** 💡 - Nice-to-have optimizations and polish

## Project Context Update

### Tournament Scale Requirements

- **Target Scale**: 500 concurrent users per tournament
- **Data Volume**: 50+ rounds per participant, 30-end tournament rounds (180 arrows)
- **Architecture**: Offline-first with aggressive caching
- **Performance**: <200ms round loading, <100ms UI responsiveness

### Adjusted Priority Matrix

Based on tournament scale requirements, priorities have been reordered to focus on **database performance and memory management** before networking features.

## PHASE 1: CRITICAL FIXES (1-2 weeks)

### 🚨 CRITICAL #1: Database Performance (BLOCKING FOR TOURNAMENTS)

#### Add Critical Database Indexes (IMMEDIATE)

**File:** Database migration
**Effort:** S (1 day)
**Impact:** 60-80% query performance improvement

**Tournament-Critical Indexes:**
```sql
-- Migration_27_28.kt
-- CRITICAL: Equipment performance queries (tournament analytics)
CREATE INDEX idx_arrow_scores_equipment_time
ON arrow_scores(bowSetupId, scoredAt);

-- CRITICAL: Multi-participant tournaments
CREATE INDEX idx_end_scores_round_participant
ON end_scores(roundId, participantId);

-- CRITICAL: Historical data queries (50+ rounds per user)
CREATE INDEX idx_rounds_status_date
ON rounds(status, createdAt DESC);

-- CRITICAL: Arrow loading for large ends
CREATE INDEX idx_arrow_scores_end_arrow
ON arrow_scores(endScoreId, arrowNumber);

-- CRITICAL: Participant filtering for tournaments
CREATE INDEX idx_rounds_participant_status
ON rounds(participantId, status, createdAt DESC);
```

**Expected Performance Impact:**
- Tournament round loading: 500ms → <200ms
- Historical queries: 200ms → <50ms
- Multi-participant operations: 300ms → <100ms

#### Fix N+1 Query Problems (IMMEDIATE)

**File:** `RoundRepository.kt`
**Effort:** M (2-3 days)
**Impact:** BLOCKING for 500-user scale

**Current Problem:**
```kotlin
// DISASTER for tournaments: 30-end round = 31+ queries
val endScores = roundDao.getEndScoresForRound(roundId)
val ends = endScores.map { endScore ->
    val arrows = roundDao.getArrowScoresForEnd(endScore.id.toLong())
    EndScoreWithArrows(endScore, arrows)
}
```

**Tournament-Optimized Solution:**
```kotlin
@Query("""
    SELECT
        es.id as end_id,
        es.roundId,
        es.endNumber,
        es.participantId,
        es.totalScore as end_total,
        es.isCompleted,
        ars.id as arrow_id,
        ars.arrowNumber,
        ars.scoreValue,
        ars.isX,
        ars.scoredAt,
        ars.bowSetupId
    FROM end_scores es
    LEFT JOIN arrow_scores ars ON es.id = ars.endScoreId
    WHERE es.roundId = :roundId
    ORDER BY es.participantId, es.endNumber, ars.arrowNumber
""")
suspend fun getRoundDetailsOptimized(roundId: Int): List<EndWithArrowData>
```

#### Tournament Performance Validation

**File:** `DatabasePerformanceTest.kt` ✅ CREATED

**Critical Tests:**
- 30-end tournament round loading <200ms
- 10-participant round operations <300ms
- 50 historical rounds query <100ms
- Rapid 6-arrow entry <100ms
- Memory usage <50MB for large datasets

### 🚨 CRITICAL #2: Memory Management (TOURNAMENT SCALE)

#### Implement LRU Caching (IMMEDIATE)

**Files:** Multiple ViewModels with unbounded caches
**Effort:** S (1-2 days)
**Impact:** Prevents crashes with 500 users

**Current Problem:**
```kotlin
// DISASTER: Unbounded cache grows to 100MB+ with tournament data
private val displayDataCache = mutableMapOf<Int, RoundDisplayData>()
private var statisticsCache: StatisticsContribution? = null
```

**Tournament-Safe Solution:**
```kotlin
// Tournament-optimized caching
private val displayDataCache = LruCache<Int, RoundDisplayData>(
    maxSize = calculateOptimalCacheSize() // Based on available memory
)

private val statisticsCache = LruCache<String, StatisticsContribution>(50)

// Aggressive cache invalidation for tournaments
fun invalidateTournamentCache(tournamentId: Long) {
    displayDataCache.evictAll()
    statisticsCache.evictAll()
}

private fun calculateOptimalCacheSize(): Int {
    val memoryClass = (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).memoryClass
    return (memoryClass * 1024 * 1024 / 16) // Use 1/16 of available memory
}
```

### 🚨 CRITICAL #3: Incremental God Class Refactoring

#### Extract Statistics Logic from RoundViewModel (INCREMENTAL)

**File:** `RoundViewModel.kt`
**Effort:** S (2-3 days)
**Impact:** Improved maintainability without breaking changes

**Incremental Approach:**
```kotlin
// Phase 1: Extract statistics calculation (safe)
class TournamentStatisticsService(
    private val statisticsCalculator: StatisticsCalculator
) {
    suspend fun calculateRealTimeStats(
        arrows: List<Int>,
        xRings: List<Boolean>,
        completedEnds: Int
    ): TournamentStatistics

    suspend fun calculateMultiParticipantRankings(
        participants: List<SessionParticipant>,
        roundData: Map<String, ParticipantRoundData>
    ): List<ParticipantRanking>
}

// Phase 2: Extract tournament-specific logic
class TournamentRoundService {
    suspend fun handleParticipantSwitch(
        fromParticipant: String,
        toParticipant: String,
        sessionState: ScoringSessionState
    ): ScoringSessionState
}
```

**Success Criteria:**
- [ ] RoundViewModel reduced to <1500 lines (30% reduction)
- [ ] Statistics calculations moved to service layer
- [ ] All tournament functionality preserved
- [ ] Performance improved for multi-participant rounds

## PHASE 2: HIGH PRIORITY IMPROVEMENTS (2-3 weeks)

### ⚠️ HIGH #1: UI Performance Optimization

#### Fix Compose Recomposition Issues

**File:** `ActiveScoringScreen.kt`
**Effort:** M (2-3 days)

```kotlin
// BEFORE: Multiple StateFlow derivations
val isVisible: StateFlow<Boolean> = _dialogState.map { it.isVisible }.stateIn(...)
val title: StateFlow<String> = _dialogState.map { it.title }.stateIn(...)

// AFTER: Single state object
data class DialogUIState(
    val isVisible: Boolean,
    val title: String,
    val message: String
)
val dialogUIState: StateFlow<DialogUIState> = _dialogState.asStateFlow()
```

**Success Criteria:**
- [ ] Eliminate frame drops during scoring
- [ ] Reduce recomposition count by 50%
- [ ] Stable keys for all LazyColumn implementations

### ⚠️ HIGH #2: Testing Gap Closure

#### Equipment ViewModel Tests

**Files:** 11 untested equipment ViewModels
**Effort:** M (3-4 days)

**Missing Tests:**
- AccessoryViewModel.kt
- ArrowViewModel.kt
- BowSetupViewModel.kt
- BowStringViewModel.kt
- LimbsViewModel.kt
- PlungerViewModel.kt
- RestViewModel.kt
- RiserViewModel.kt
- SightViewModel.kt
- StabilizerViewModel.kt
- WeightViewModel.kt

**Success Criteria:**
- [ ] 95% ViewModel test coverage
- [ ] CRUD operations tested for all equipment types
- [ ] Error handling scenarios covered

### ⚠️ HIGH #3: Code Duplication Elimination

#### Extract Magic Numbers

**Files:** 50+ files with hardcoded values
**Effort:** S (1-2 days)

```kotlin
object ScoringConstants {
    const val MIN_SCORE = 0
    const val MAX_SCORE_WORLD_ARCHERY = 10
    const val DEFAULT_ARROWS_PER_END = 6
    const val DEFAULT_ENDS_PER_ROUND = 10
    const val TARGET_FACE_DIAMETER_CM = 122
    const val ANIMATION_DURATION_MS = 300L
}

object DatabaseConstants {
    const val CACHE_SIZE_ROUNDS = 100
    const val QUERY_TIMEOUT_MS = 5000L
    const val BATCH_SIZE_ARROWS = 50
}
```

## PHASE 3: MEDIUM PRIORITY ENHANCEMENTS (2-3 weeks)

### 📋 MEDIUM #1: Advanced Performance Features

#### Implement Data Pagination

**Files:** Historical data screens
**Effort:** M (3-4 days)

```kotlin
@Query("SELECT * FROM rounds ORDER BY createdAt DESC LIMIT :limit OFFSET :offset")
suspend fun getRoundsPaged(limit: Int, offset: Int): List<Round>

// Implement Paging 3 integration
class RoundPagingSource : PagingSource<Int, Round>() {
    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, Round> {
        // Pagination logic
    }
}
```

**Success Criteria:**
- [ ] Smooth scrolling for 1000+ rounds
- [ ] Progressive loading indicators
- [ ] Memory usage remains constant

## PHASE 4: LOW PRIORITY OPTIMIZATIONS (1-2 weeks)

### 💡 LOW #1: Advanced Architecture Patterns

#### Implement Use Case Pattern

**Effort:** L (3-4 days)

```kotlin
// Domain use cases for complex business logic
class ScoreArrowUseCase(
    private val roundRepository: RoundRepository,
    private val statisticsService: StatisticsCalculationService,
    private val validationService: ValidationService
) {
    suspend operator fun invoke(
        roundId: Long,
        score: Int,
        isX: Boolean,
        coordinate: ArrowCoordinate? = null
    ): Result<ArrowScoringResult>
}
```

## Implementation Timeline (TOURNAMENT-FOCUSED)

### Week 1: DATABASE PERFORMANCE (BLOCKING)

**Day 1:** Create and run `DatabasePerformanceTest.kt` to baseline current performance
**Day 2:** Create Migration_27_28 with critical indexes
**Day 3-4:** Fix N+1 query problems in RoundRepository
**Day 5:** Validate performance improvements with tests

**Success Gate:** All tournament performance tests pass before proceeding

### Week 2: MEMORY & STABILITY

**Day 1-2:** Implement LRU caching in all ViewModels
**Day 3-4:** Extract statistics service from RoundViewModel (incremental)
**Day 5:** Tournament load testing and memory validation

**Success Gate:** Memory usage <50MB for tournament datasets

### Week 3-4: UI PERFORMANCE & TESTING (Optional)

**Only proceed if networking features aren't ready**
- Fix Compose recomposition issues
- Add critical equipment ViewModel tests
- Performance monitoring setup

## PRE-NETWORKING READINESS CHECKLIST

### Database Performance ✅

- [ ] Tournament round loading <200ms
- [ ] Multi-participant operations <300ms
- [ ] Historical queries <100ms
- [ ] Zero N+1 queries in critical paths

### Memory Management ✅

- [ ] LRU caches implemented
- [ ] Memory usage <50MB for tournaments
- [ ] No memory leaks in long sessions
- [ ] Cache invalidation strategies

### Stability ✅

- [ ] Performance tests passing in CI
- [ ] Tournament scenarios validated
- [ ] 500-user scale assumptions validated

## Success Metrics

### Code Quality Metrics

- [ ] **Files >500 lines:** Reduce from 15 to <5
- [ ] **God classes:** Reduce from 24 to <10
- [ ] **Magic numbers:** Extract all 50+ instances
- [ ] **Test coverage:** Maintain >75% throughout refactoring

### Performance Metrics

- [ ] **Database queries:** <50ms for UI operations
- [ ] **UI responsiveness:** <100ms for all interactions
- [ ] **Memory usage:** <20MB per ViewModel
- [ ] **App startup:** <2 seconds cold start

### Architecture Metrics

- [ ] **Layer violations:** 0 critical violations
- [ ] **Circular dependencies:** 0 detected
- [ ] **Package coupling:** <80% coupling ratio
- [ ] **Method complexity:** <15 methods per class average

## Risk Mitigation

### High-Risk Activities

1. **God Class Decomposition** - Risk of breaking existing functionality
   - Mitigation: Comprehensive test coverage validation at each step
   - Rollback plan: Feature flags for new ViewModels

2. **Database Schema Changes** - Risk of data loss or migration failures
   - Mitigation: Test migrations on production database copies
   - Rollback plan: Database backup before migration deployment

3. **Performance Optimizations** - Risk of introducing new bugs
   - Mitigation: Performance regression testing
   - Rollback plan: Performance monitoring with automatic alerts

## Related Documentation

- [[LiveScoringVM-Analysis]] - Detailed god class analysis
- [[Technical-Debt]] - Comprehensive tech debt tracking
- [[System-Architecture]] - Overall architecture design
- [[Checkpoint-Findings]] - Investigation results

## Conclusion

This refactoring roadmap provides a systematic approach to addressing technical debt. By following the phased approach and success metrics, the codebase will evolve from a C+ architecture grade to a robust, maintainable, and high-performance application.

The roadmap balances immediate critical fixes with long-term architectural improvements, ensuring development velocity is maintained while systematically improving code quality and system performance.

---

*Document Version: 1.0*
*Last Updated: January 2025*
*Total Estimated Effort: 8-10 weeks*
*Source: `docs/architecture/REFACTORING_ROADMAP.md`*