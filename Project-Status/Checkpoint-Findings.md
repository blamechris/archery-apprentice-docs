---
title: Checkpoint Investigation Findings
tags:
  - status
  - analysis
  - performance
  - investigation
created: 2025-10-08
source: docs/CHECKPOINT_FINDINGS.md
investigation-date: 2025-10-04
status: complete
---

# Archery Apprentice - Checkpoint Investigation Findings

**Investigation Date:** October 4, 2025
**Current Project Status:** 97% Complete
**Purpose:** Pre-next-epoch architecture and documentation audit

## Executive Summary

**Status:** Investigation complete (Phases 1-5 complete)
**Critical Findings:** 7 major architectural issues identified
**Recommendation:** Address critical tech debt before next major features

### Critical Issues Summary

1. 🚨 **LiveScoringViewModel: 2,808 lines (+60% growth)** - URGENT extraction needed
2. 🚨 **RoundViewModel refactoring created NEW god class** (LiveScoringViewModel)
3. 🚨 **Documentation severely outdated** (10+ files claiming complete features are "planned")
4. 🚨 **N+1 query pattern confirmed** (31 queries for 30-end round instead of 1)
5. 🚨 **Repository god classes** (5,959 total lines across TournamentRepository + RoundRepository)
6. 🚨 **Tie-breaking NOT implemented** (docs claim complete, but xCount/tenCount fields missing)
7. 🚨 **Average score always 0.0** (calculation never executed during scoring)

### Phase Progress

- ✅ Phase 1: Documentation Audit - COMPLETE
- ✅ Phase 2: Database Architecture - COMPLETE
- ✅ Phase 3: God Class Analysis (LiveScoringViewModel) - COMPLETE
- ✅ Phase 4: Feature Validation - COMPLETE
- ✅ Phase 5: Tech Debt Consolidation - COMPLETE

## 🚨 CRITICAL #1: LiveScoringViewModel Explosive Growth

**Current State:** 2,808 lines (+1,055 lines from baseline, +60% growth)
**Baseline (CLAUDE.md):** 1,753 lines
**Impact:** SEVERE - Maintainability crisis, high bug risk
**Root Cause:** Tournament features added without extraction
**Recommendation:** URGENT refactoring required before next feature work

**Evidence:**
```
LiveScoringViewModel.kt: 2,808 lines
RoundViewModel.kt: 2,079 lines (+21 from baseline)
ActiveScoringScreen.kt: 1,958 lines (+62 from baseline)
Total God Class Lines: 6,845 lines
```

**ANALYSIS COMPLETE:** See [[LiveScoringVM-Analysis]] for comprehensive breakdown!

**Key Findings:**
- **12 distinct architectural domains** identified (should be 2-3!)
- **66 methods** (should be <30)
- **24 StateFlow properties** (should be <12)
- **Tournament Phases 2.2-4.1** added ~1,300 lines without refactoring
- **Complexity Score:** 9.5/10 (CRITICAL)
- **Recommended Extraction:** 5 services totaling ~1,600 lines (57% reduction!)

**Extraction Roadmap (4 weeks):**
- **Week 1:** Planning & setup
- **Week 2:** Extract TournamentSyncService (~600 lines) + ConflictResolutionService (~400 lines)
- **Week 3:** Extract EndCompletionService (~400 lines) + RoundLifecycleService (~200 lines)
- **Week 4:** Cleanup & optimization
- **Target:** Reduce to 1,200-1,400 lines (50-57% reduction)

## 🚨 CRITICAL #2: RoundViewModel Refactoring - Created NEW Problem

**MAJOR DISCOVERY:** Refactoring actually happened - just undocumented!

**What Actually Occurred:**
- **Original RoundViewModel:** ~3,000+ lines (single monolith god class)
- **Successfully extracted to 8 ViewModels:** Total 5,987 lines distributed architecture
  - RoundViewModel: 2,058 lines (core orchestration)
  - **LiveScoringViewModel: 1,753 lines** ← **NEW GOD CLASS CREATED!**
  - RoundAnalyticsViewModel: 605 lines ✅
  - RoundManagementViewModel: 495 lines ✅
  - RoundCreationViewModel: 480 lines ✅
  - RoundDisplayViewModel: 216 lines ✅
  - RoundNavigationViewModel: 192 lines ✅
  - RoundScoringViewModel: 187 lines ✅

**The Problem: Shifted, Not Solved**
- ✅ Successfully extracted 7 specialized ViewModels
- ❌ Created LiveScoringViewModel as replacement god class
- ❌ LiveScoringViewModel grew from 1,753 → 2,808 lines (+60%, +1,055 lines!)

## 🚨 CRITICAL #4: N+1 Query Pattern Confirmed

**Status:** CONFIRMED - Active performance issue
**Impact:** HIGH - Degrades performance for rounds with many ends
**Location:** `RoundRepository.kt:98-102, 138-143`

**Performance Impact:**
- 30-end round: **31 queries** (1 + 30) instead of 1
- 60-end round: **61 queries** (1 + 60) instead of 1
- Multiplied by number of participants in multi-participant rounds

**Available Solution NOT Being Used:**
```kotlin
@Query("""
    SELECT es.*, COUNT(ars.id) as arrowCount
    FROM end_scores es
    LEFT JOIN arrow_scores ars ON es.id = ars.endScoreId
    WHERE es.roundId = :roundId
    GROUP BY es.id
    ORDER BY es.endNumber
""")
suspend fun getEndScoresSummaryForRound(roundId: Int): List<EndScoreSummary>
```

**Recommendation:**
1. Refactor `getRoundWithDetails()` to use optimized JOIN queries
2. Create similar optimized query for `getEndsWithArrowsForParticipant()`
3. Estimated fix time: 1-2 hours
4. Expected improvement: 30-60x query reduction

## 🚨 CRITICAL #5: Repository God Classes

**Total Repository Code: 5,959 lines**

**Tournament Repositories:**
```
TournamentRepository.kt (interface): 395 lines, 51 methods 🚨
├── OfflineTournamentRepository.kt: 908 lines
├── FirebaseTournamentRepository.kt: 1,707 lines 🚨🚨
└── HybridTournamentRepository.kt: 1,506 lines 🚨🚨
Total: 4,516 lines
```

**Round Repository:**
```
RoundRepository.kt: 1,443 lines 🚨
```

**Comparison to Industry Standards:**
- Good repository: 200-400 lines, 10-15 methods
- TournamentRepository interface: 395 lines, **51 methods** (3.4x too many!)
- FirebaseTournamentRepository: **1,707 lines** (4.3x too large!)

**Recommended Refactoring:**

Split TournamentRepository into 4 focused repositories:
1. **TournamentCrudRepository** (~300 lines)
2. **TournamentSyncRepository** (~400 lines)
3. **TournamentScoreRepository** (~500 lines)
4. **TournamentAnalyticsRepository** (~200 lines)

## 🚨 CRITICAL #6: Tie-Breaking Not Implemented

**Status:** PLANNING DOCS CLAIM COMPLETE - ACTUALLY NOT IMPLEMENTED
**Impact:** HIGH - Tournament rankings inconsistent across devices when scores are tied

**The Problem:**
- Firestore `orderBy("currentScore")` without secondary sort key
- When two participants have same score, order is **NON-DETERMINISTIC**
- Different devices may see different order for tied participants

**Required Implementation:**
1. Add `xCount: Int` and `tenCount: Int` to TournamentParticipant model
2. Track X and 10 counts during score submission
3. Update Firestore query with composite ordering
4. Create Firestore composite indexes for multi-field sorting

## 🚨 CRITICAL #7: Average Score Always 0.0

**Status:** BUG CONFIRMED - averageScore field never updated during scoring
**Root Cause:** averageScore is never calculated or updated in FirebaseTournamentRepository

**Required Fix:**
```kotlin
val newAverageScore = if (newArrowsShot > 0) {
    newTotal.toDouble() / newArrowsShot
} else {
    0.0
}

val participantUpdateData = mapOf(
    "currentScore" to newTotal,
    "averageScore" to newAverageScore,  // ← ADD THIS
    // ... other fields
)
```

## God Class Scorecard

| Class | Current Lines | Change from Baseline | Status |
|-------|--------------|---------------------|---------|
| LiveScoringViewModel | 2,808 | +1,055 (+60%) | 🚨 CRITICAL |
| RoundViewModel | 2,079 | +21 (+1%) | 🟡 STABLE* |
| ActiveScoringScreen | 1,958 | +62 (+3%) | 🟠 HIGH |
| **TOTAL** | **6,845** | **+1,138 (+20%)** | **SEVERE** |

*RoundViewModel baseline was 2,058 AFTER successful extraction of 7 ViewModels

## Database Index Analysis

**Overall Status:** GOOD coverage, but 2 missing composite indexes

### Missing Indexes

1. **Arrow Scores Equipment Performance** (MEDIUM PRIORITY)
   - Suggested: Composite index `(bowSetupId, scoredAt)`
   - Impact: Equipment performance screen may be slow with large datasets
   - Estimated improvement: 2-5x for equipment queries

2. **Rounds Historical Queries** (LOW PRIORITY)
   - Suggested: Composite index `(status, createdAt DESC)`
   - Impact: Minor - most queries use these separately

**Index Coverage:** 90% ✅

## Documentation Status

**Files Reviewed:** 41/41 (100%) ✅

### Severely Outdated

- README.md - Stops at July 2025, omits 3 months of work
- Tournament documentation - 3 docs claim features "planned" that are COMPLETE
- Firebase/README.md - Shows features as "Planned" that are complete

**Issues Found:** 4 critical, 10+ severely outdated docs

## Related Documentation

- [[LiveScoringVM-Analysis]] - Deep dive into the 2,808-line god class
- [[Technical-Debt]] - Comprehensive tech debt tracking
- [[Refactoring-Roadmap]] - Implementation strategy
- [[System-Architecture]] - Overall system design

## Next Steps

### Priority 1: URGENT
1. **LiveScoringViewModel Refactoring** - Extract to <1,000 lines
2. **Fix N+1 Query Pattern** - Implement optimized JOIN queries
3. **Fix Average Score Bug** - Add calculation to score submission

### Priority 2: HIGH
1. **README Major Rewrite** - Update to October 2025 state
2. **Implement Tie-Breaking** - Add xCount/tenCount fields
3. **Repository Refactoring** - Split into focused repositories

---

*Investigation Complete: October 4, 2025*
*Source: `docs/CHECKPOINT_FINDINGS.md`*