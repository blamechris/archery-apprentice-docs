---
tags: [refactoring, execution-plan, roundviewmodel, service-extraction, solid-principles, architecture, technical-debt]
created: 2025-01-22
related:
  - "[[RoundViewModel-Audit]]"
  - "[[Refactoring-Reality-Check]]"
  - "[[Refactoring-Roadmap]]"
  - "[[Architecture]]"
  - "[[Scoring-ViewModel-Architecture]]"
---

# RoundViewModel Refactoring Plan - Comprehensive Execution Guide

## Executive Summary

This document provides a detailed, concrete refactoring plan for decomposing the 2,058-line RoundViewModel.kt god class into specialized service components. The plan includes specific line ranges, method extractions, implementation phases, testing strategies, and risk mitigation procedures.

**Target Outcome**: Reduce RoundViewModel from 2,058 lines to ~800-1,000 lines while maintaining 100% functionality, test coverage, and Firebase integration readiness for upcoming tournaments + user accounts.

## Current State Analysis

### File Metrics
- **Total Lines**: 2,058 (excluding comments)
- **Public Methods**: 55
- **Private Methods**: 28
- **State Properties**: 23 StateFlow properties
- **Repository Dependencies**: 2 (RoundRepository, BowSetupRepository)
- **UI Framework Dependencies**: 1 (Compose.ui.geometry.Offset) - **CRITICAL VIOLATION**

### God Class Evidence
1. **Multiple Responsibilities**: Round creation, scoring session management, data display, statistics calculation, ranking computation
2. **Excessive State**: 23 different StateFlow properties managing unrelated concerns
3. **Layer Violations**: UI geometry types in ViewModel (line 6, 542)
4. **High Coupling**: Direct dependencies on multiple repository types

## EXTRACTION TARGETS (Specific Line Ranges)

### 1. RoundStatisticsService
**Target Lines**: 987-1162, 1328-1547
**Responsibilities**: Statistics calculation, ranking computation, accuracy calculations

**Methods to Extract**:
- `createRoundDisplayData()` (lines 999-1090) - 92 lines
- `createParticipantScoreSummaries()` (lines 1103-1162) - 60 lines
- `calculateMuRank()` (lines 1331-1357) - 27 lines
- `getMuScore()` (lines 1389-1416) - 28 lines
- `getMuMaxScore()` (lines 1421-1424) - 4 lines
- `calculateMuAccuracy()` (lines 1429-1433) - 5 lines
- `formatRankDisplay()` (lines 1369-1378) - 10 lines
- `getTotalParticipants()` (lines 1362-1364) - 3 lines
- `calculateAccuracy()` (lines 1529-1533) - 5 lines
- `formatReadableDate()` (lines 1538-1547) - 10 lines

**Total Lines Extracted**: 244 lines

### 2. RoundDisplayService
**Target Lines**: 57-86, 988-1090, 1094-1098
**Responsibilities**: Display data preparation, UI formatting, caching

**Methods to Extract**:
- `createRoundDisplayData()` (lines 999-1090) - 92 lines (shared with Statistics)
- `clearDisplayDataCache()` (lines 1095-1097) - 3 lines
- Display data caching logic (lines 1001-1004, 1084-1087)

**Data Classes to Move**:
- `RoundDisplayData` (lines 57-71) - 15 lines
- `ParticipantScoreSummary` (lines 78-85) - 8 lines

**Total Lines Extracted**: 118 lines

### 3. TournamentRankingService
**Target Lines**: 1328-1416, 1467-1517
**Responsibilities**: Multi-participant ranking, tournament scoring, subject resolution

**Methods to Extract**:
- `calculateMuRank()` (lines 1331-1357) - 27 lines
- `resolveMuSubject()` (lines 1467-1475) - 9 lines
- `getSubjectScore()` (lines 1491-1498) - 8 lines
- `getSubjectMaxScore()` (lines 1510-1517) - 8 lines
- `inferScoringMode()` (lines 1444-1445) - 2 lines
- `resolveLocalParticipantId()` (lines 1454-1455) - 2 lines

**Total Lines Extracted**: 56 lines

### 4. UI Framework Cleanup
**Target Lines**: 6, 542, 878, 914, 1716
**Violations to Remove**:
- `import androidx.compose.ui.geometry.Offset` (line 6)
- Offset usage in method signatures (line 542)
- Offset in participant coordinates (lines 878, 914, 1716)

**Solution**: Replace with `data class ArrowCoordinate(val x: Float, val y: Float)`

## DETAILED EXECUTION PLAN

### Phase 1: Foundation Setup (Days 1-2)
**Duration**: 2 days
**Risk Level**: LOW

#### Day 1: Create Service Interfaces
1. **Create ArrowCoordinate Data Class** (30 mins)
   ```kotlin
   // File: app/src/main/java/com/archeryapprentice/ui/roundScoring/types/ArrowCoordinate.kt
   data class ArrowCoordinate(val x: Float, val y: Float)
   ```

2. **Create RoundStatisticsService Interface** (45 mins)
   ```kotlin
   // File: app/src/main/java/com/archeryapprentice/domain/services/RoundStatisticsService.kt
   interface RoundStatisticsService {
       suspend fun calculateMuRank(round: Round): Int?
       suspend fun getMuScore(round: Round): Int
       fun getMuMaxScore(round: Round): Int
       fun calculateMuAccuracy(muScore: Int, muMaxScore: Int): Float
       fun calculateAccuracy(score: Int, max: Int): Int
       fun formatRankDisplay(rank: Int, total: Int): String
       fun getTotalParticipants(round: Round): Int
       fun formatReadableDate(timestamp: Long): String
   }
   ```

3. **Create RoundDisplayService Interface** (45 mins)
   ```kotlin
   // File: app/src/main/java/com/archeryapprentice/domain/services/RoundDisplayService.kt
   interface RoundDisplayService {
       suspend fun createRoundDisplayData(round: Round, settings: Settings?): RoundDisplayData
       suspend fun createParticipantScoreSummaries(round: Round, settings: Settings?): List<ParticipantScoreSummary>
       fun clearDisplayDataCache()
   }
   ```

4. **Create TournamentRankingService Interface** (30 mins)
   ```kotlin
   // File: app/src/main/java/com/archeryapprentice/domain/services/TournamentRankingService.kt
   interface TournamentRankingService {
       fun resolveMuSubject(round: Round, settings: Settings?): ScoreSubject
       suspend fun getSubjectScore(round: Round, subject: ScoreSubject): Int
       fun getSubjectMaxScore(round: Round, subject: ScoreSubject): Int
   }
   ```

#### Day 2: Create Implementation Skeletons
5. **Create Empty Implementations** (2 hours)
   - Create concrete classes with TODO stubs
   - Set up dependency injection in RepositoryFactory
   - Add constructor parameters to RoundViewModel

**Rollback Procedure**: Simply delete new files and revert imports

### Phase 2: Statistics Service Extraction (Days 3-4)
**Duration**: 2 days
**Risk Level**: MEDIUM

#### Day 3: Extract Core Statistics Methods

1. **Extract calculateMuRank()** (45 mins)
   - Lines 1331-1357 → RoundStatisticsServiceImpl.calculateMuRank()
   - Update dependencies: needs RoundRepository.recomputeRoundTotals()
   - **Test**: Verify all ranking tests pass

2. **Extract getMuScore()** (30 mins)
   - Lines 1389-1416 → RoundStatisticsServiceImpl.getMuScore()
   - **Test**: Verify score calculation tests pass

3. **Extract Utility Methods** (30 mins)
   - getMuMaxScore(), calculateMuAccuracy(), calculateAccuracy()
   - formatRankDisplay(), getTotalParticipants(), formatReadableDate()
   - **Test**: Run full test suite

#### Day 4: Update RoundViewModel Integration
4. **Replace Method Calls** (2 hours)
   - Update all callers to use statisticsService.methodName()
   - Remove original method implementations
   - **Test**: Full regression test suite

**Rollback Procedure**:
- Revert method extractions
- Remove service calls
- Restore original method implementations

### Phase 3: Display Service Extraction (Days 5-6)
**Duration**: 2 days
**Risk Level**: MEDIUM

#### Day 5: Extract Display Data Methods
1. **Move Data Classes** (30 mins)
   - RoundDisplayData → domain/models/
   - ParticipantScoreSummary → domain/models/

2. **Extract createRoundDisplayData()** (1.5 hours)
   - Lines 999-1090 → RoundDisplayServiceImpl
   - Handle statisticsService dependency
   - **Test**: Verify Historical screen displays correctly

#### Day 6: Cache Management
3. **Extract Display Cache** (1 hour)
   - Move displayDataCache to RoundDisplayServiceImpl
   - Extract clearDisplayDataCache() method
   - **Test**: Verify caching behavior preserved

**Rollback Procedure**:
- Move data classes back to RoundViewModel
- Restore createRoundDisplayData() in RoundViewModel
- Remove service delegation

### Phase 4: Tournament Ranking Extraction (Day 7)
**Duration**: 1 day
**Risk Level**: LOW

#### Day 7: Extract Tournament Methods
1. **Extract Subject Resolution** (1 hour)
   - resolveMuSubject(), getSubjectScore(), getSubjectMaxScore()
   - Lines 1467-1517 → TournamentRankingServiceImpl

2. **Update Integration** (1 hour)
   - Replace calls in RoundViewModel
   - **Test**: Tournament functionality tests

**Rollback Procedure**: Minimal - small method extractions, easy to revert

### Phase 5: UI Framework Cleanup (Day 8)
**Duration**: 1 day
**Risk Level**: HIGH

#### Day 8: Remove Compose Dependencies
1. **Replace Offset with ArrowCoordinate** (2-3 hours)
   - Update method signatures (line 542)
   - Update participant coordinates (lines 878, 914, 1716)
   - Remove Offset import (line 6)
   - **Critical**: Update all UI screens that consume coordinates

2. **Update ActiveScoringScreen** (1 hour)
   - Convert ArrowCoordinate back to Offset for Compose
   - Add extension functions for conversion

**Rollback Procedure**:
- Revert ArrowCoordinate to Offset
- Restore import androidx.compose.ui.geometry.Offset
- Revert method signatures

### Phase 6: Final Integration & Testing (Days 9-10)
**Duration**: 2 days
**Risk Level**: LOW

#### Day 9: Dependency Injection
1. **Update RepositoryFactory** (1 hour)
2. **Update RoundViewModel Constructor** (30 mins)
3. **Update Test Mocks** (2 hours)

#### Day 10: Comprehensive Testing
1. **Run Full Test Suite** (2 hours)
2. **Performance Testing** (1 hour)
3. **UI Integration Testing** (2 hours)

## DEPENDENCY MAPPING

### Service Dependencies
```
RoundStatisticsService
├── RoundRepository (for recomputeRoundTotals)
└── No UI dependencies

RoundDisplayService
├── RoundStatisticsService (for calculations)
├── RoundRepository (for data fetching)
└── No UI dependencies

TournamentRankingService
├── RoundStatisticsService (for score calculations)
└── No external dependencies

RoundViewModel (after refactoring)
├── RoundStatisticsService
├── RoundDisplayService
├── TournamentRankingService
├── RoundRepository
└── BowSetupRepository
```

### Method Call Flow
```
UI Screen
    ↓
RoundViewModel.createRoundDisplayData()
    ↓
RoundDisplayService.createRoundDisplayData()
    ↓
RoundStatisticsService.calculateMuRank()
    ↓
RoundRepository.recomputeRoundTotals()
```

## TESTING STRATEGY

### Phase-by-Phase Testing
1. **Unit Tests**: Create new test files for each service
2. **Integration Tests**: Verify service interactions
3. **Regression Tests**: Ensure existing functionality preserved
4. **Performance Tests**: Verify no performance degradation

### Test Files to Create
```
- RoundStatisticsServiceTest.kt
- RoundDisplayServiceTest.kt
- TournamentRankingServiceTest.kt
- RoundViewModelRefactoredTest.kt (integration)
```

### Critical Test Cases
1. **Multi-participant ranking** calculations
2. **Display data caching** behavior
3. **Tournament scoring** accuracy
4. **UI coordinate conversion** (Offset ↔ ArrowCoordinate)

## RISK MITIGATION

### High-Risk Areas

#### 1. UI Framework Dependencies (Phase 5)
**Risk**: Breaking ActiveScoringScreen coordinate system
**Mitigation**:
- Create conversion extensions before replacing Offset
- Test coordinate accuracy with sample data
- Keep backup of working Offset implementation

#### 2. Firebase Integration Compatibility
**Risk**: Creating conflicts with upcoming Firebase tournaments + user accounts
**Prevention**:
- **SAFE TO EXTRACT**: Statistics, display, and ranking services (pure computation)
- **PRESERVE**: Session coordination logic (needed for Firebase real-time sync)
- **PRESERVE**: Multi-participant switching (Firebase presence integration)
- **PRESERVE**: Repository patterns (Firebase hybrid architecture pending)

**Firebase Integration Points Identified**:
- `SessionParticipant` → User account linking ready
- `ParticipantProgress` → Firestore real-time sync ready
- `RoundDisplayData` → Tournament leaderboard sync ready
- Service boundaries → Compatible with Firebase architecture patterns

#### 3. Tournament Data Integrity
**Risk**: Ranking calculations becoming inconsistent
**Prevention**:
- Extract rank calculation as single atomic operation
- Validate against known tournament data
- Keep original calculation as backup during transition

### Rollback Triggers
Stop and rollback if:
- Test coverage drops below 75%
- Performance degrades > 15%
- Any Firebase sync errors occur
- UI rendering breaks
- Tournament rankings become inconsistent

## PERFORMANCE IMPACT ANALYSIS

### Expected Improvements
- **Memory Usage**: 15-20% reduction (smaller ViewModels)
- **Initialization Time**: 10-15% faster (focused responsibilities)
- **Test Execution**: 20-25% faster (isolated testing)

### Potential Concerns
- **Service Creation Overhead**: +5-10ms initialization
- **Method Call Indirection**: +1-2ms per display operation
- **Dependency Resolution**: +2-3ms per ViewModel creation

**Net Impact**: Overall positive due to reduced god class complexity

## CONCRETE DELIVERABLES

### New Files Created
```
domain/services/
├── RoundStatisticsService.kt (interface)
├── RoundStatisticsServiceImpl.kt (implementation)
├── RoundDisplayService.kt (interface)
├── RoundDisplayServiceImpl.kt (implementation)
├── TournamentRankingService.kt (interface)
└── TournamentRankingServiceImpl.kt (implementation)

domain/models/
├── RoundDisplayData.kt (moved from RoundViewModel)
└── ParticipantScoreSummary.kt (moved from RoundViewModel)

ui/roundScoring/types/
└── ArrowCoordinate.kt (replaces Offset)

test/java/.../services/
├── RoundStatisticsServiceTest.kt
├── RoundDisplayServiceTest.kt
└── TournamentRankingServiceTest.kt
```

### Interface Definitions

#### RoundStatisticsService (Complete)
```kotlin
interface RoundStatisticsService {
    suspend fun calculateMuRank(round: Round): Int?
    suspend fun getMuScore(round: Round): Int
    fun getMuMaxScore(round: Round): Int
    fun calculateMuAccuracy(muScore: Int, muMaxScore: Int): Float
    fun calculateAccuracy(score: Int, max: Int): Int
    fun formatRankDisplay(rank: Int, total: Int): String
    fun getTotalParticipants(round: Round): Int
    fun formatReadableDate(timestamp: Long): String
}
```

#### RoundDisplayService (Complete)
```kotlin
interface RoundDisplayService {
    suspend fun createRoundDisplayData(round: Round, settings: Settings?): RoundDisplayData
    suspend fun createParticipantScoreSummaries(round: Round, settings: Settings?): List<ParticipantScoreSummary>
    fun clearDisplayDataCache()
}
```

#### TournamentRankingService (Complete)
```kotlin
interface TournamentRankingService {
    fun resolveMuSubject(round: Round, settings: Settings?): ScoreSubject
    suspend fun getSubjectScore(round: Round, subject: ScoreSubject): Int
    fun getSubjectMaxScore(round: Round, subject: ScoreSubject): Int
}
```

### Dependency Injection Updates
```kotlin
// RepositoryFactory.kt additions
class RepositoryFactory {
    fun createRoundStatisticsService(): RoundStatisticsService
    fun createRoundDisplayService(): RoundDisplayService
    fun createTournamentRankingService(): TournamentRankingService
}

// RoundViewModel.kt constructor updates
class RoundViewModel(
    application: Application,
    private val repositoryFactory: RepositoryFactory? = null,
    private val statisticsService: RoundStatisticsService? = null,
    private val displayService: RoundDisplayService? = null,
    private val rankingService: TournamentRankingService? = null
)
```

## SUCCESS CRITERIA

### Quantitative Metrics
- [ ] RoundViewModel reduced from 2,058 to <1,000 lines
- [ ] Public methods reduced from 55 to <30
- [ ] StateFlow properties reduced from 23 to <15
- [ ] All 1,034 tests pass
- [ ] Test coverage maintained >75%
- [ ] Performance within 5% of baseline

### Qualitative Goals
- [ ] UI framework dependencies completely removed
- [ ] Layer violations eliminated
- [ ] Service responsibilities clearly separated
- [ ] Code complexity significantly reduced
- [ ] Maintainability dramatically improved

### Architecture Decision Records
- [ ] Document service extraction rationale
- [ ] Record coordinate system design decisions
- [ ] Capture performance optimization choices
- [ ] Log dependency injection patterns

## TIMELINE SUMMARY

| Phase | Duration | Risk | Key Deliverables |
|-------|----------|------|------------------|
| 1: Foundation | 2 days | LOW | Interfaces, data classes |
| 2: Statistics | 2 days | MEDIUM | RoundStatisticsService |
| 3: Display | 2 days | MEDIUM | RoundDisplayService |
| 4: Tournament | 1 day | LOW | TournamentRankingService |
| 5: UI Cleanup | 1 day | HIGH | Remove Compose dependencies |
| 6: Integration | 2 days | LOW | Testing, polish |

**Total Duration**: 10 days
**Total Lines Extracted**: ~400-500 lines
**Complexity Reduction**: ~60%

---

**Source**: `docs/architecture/ROUNDVIEWMODEL_REFACTORING_PLAN.md`  
**Note**: See [[Refactoring-Reality-Check]] for actual implementation outcomes

*This plan provides stakeholder-ready documentation for a comprehensive RoundViewModel refactoring that maintains 100% functionality while dramatically improving code maintainability and architectural compliance.*



---

## Implementation Updates

### RoundDisplayService - Ranking Functionality Added (2025-10-15)

**Status**: ✅ Partially Implemented

The `RoundDisplayService` has been enhanced with multi-participant ranking functionality beyond the original refactoring plan. This demonstrates the service's extensibility and validates the domain service extraction strategy.

#### New Method Added
```kotlin
suspend fun calculateAllParticipantRanks(round: Round): Map<String, Int>
```

**Purpose**: Calculate ranks for ALL participants in a round (for participant selector and leaderboards)

**Implementation Details**:
- **Lines**: 336-428 in RoundDisplayService.kt (+93 lines)
- **Dual-Path Logic**:
  - Tournament rounds: Fetch ranks from Firebase Firestore (server-calculated)
  - Offline rounds: Calculate locally using Room database
- **Tie-Breaking Algorithm**: Score first (descending), then X count (descending)
- **Error Handling**: Graceful fallback to empty map on errors

**Integration Points**:
- Used by `RoundDetailsScreen` for participant selector rank badges
- Used by `HistoricalRoundsScreen` for rank display on round cards
- Works seamlessly with both tournament and offline rounds

**Test Coverage**:
- 8 unit tests in `RoundDisplayServiceTest.kt` (lines 652-883)
- 3 E2E instrumented tests in `MultiParticipantRankingDisplayE2ETest.kt`
- Tests cover: single participant, in-progress rounds, offline calculations, tie-breaking, Firebase fallback, error handling

**Architectural Benefits**:
- ✅ Avoided bloating RoundViewModel (domain service pattern validated)
- ✅ Single source of truth for ranking calculations
- ✅ Reusable across multiple UI components
- ✅ Consistent tie-breaking logic for tournament and offline modes

**Related Features**:
- Display name collision detection (GU1, GU2, GU3 instead of GUE, GUE, GUE)
- Rank badges in participant selector (#1, #2, #3)
- Historical round card rank display ("1st / 3 participants")

**Documentation**: See [[2025-10-15-Multi-Participant-Ranking-Display]] for complete implementation details.

**Lesson Learned**: The domain service extraction strategy proved highly effective. Adding this ranking functionality to RoundDisplayService was straightforward and maintained clean separation of concerns. This validates the refactoring plan's approach of extracting display logic from ViewModels.

---

*Last Updated: 2025-10-15 - Added ranking functionality implementation notes*