---
tags: [tech-debt, refactoring, god-class, performance, livescoringviewmodel, repository, tracking]
created: 2025-10-05
related:
  - "[[RoundViewModel-Audit]]"
  - "[[RoundViewModel-Refactoring-Plan]]"
  - "[[Refactoring-Roadmap]]"
  - "[[LiveScoringVM-Analysis]]"
  - "[[Checkpoint-Findings]]"
  - "[[Improvement-Tickets]]"
note: "This is a condensed version. Full source: docs/TECH_DEBT.md (767 lines)"
---

# Technical Debt Master Document

**Last Updated:** October 5, 2025  
**Investigation:** Checkpoint-1 comprehensive codebase audit  
**Status:** 6 critical issues, 2 medium issues, 5 low-priority items  
**Recent Win:** ✅ TournamentSyncService extraction complete (420 lines, 15% LiveScoringViewModel reduction)

---

## Executive Summary

**Project Health:** 97% feature complete, but carrying significant architectural debt

**Total Estimated Effort to Address:** 12-15 weeks of focused work

**Primary Concerns:**
- **God class antipattern** across ViewModels (LiveScoringViewModel: 2,808 lines)
- **Repository bloat** (5,959 lines across 5 files violating SRP)
- **N+1 query pattern** degrading database performance
- **Incomplete features** marked as "complete" in documentation
- **Documentation chaos** (10+ severely outdated files)

**Recommended Strategy:** Incremental extraction over 3 months, prioritized by user impact

---

## Priority Matrix

### 🚨 CRITICAL (P0) - Address Before Next Feature Epoch

| Issue | Impact | Effort | Status |
|-------|--------|--------|--------|
| N+1 Query Pattern | HIGH | 2 hours | ✅ DONE |
| Average Score Bug | MEDIUM | 30 min | ✅ DONE |
| TournamentSyncService Extraction | HIGH | 1 week | ✅ DONE |
| ScoreConflictResolution Extraction | HIGH | 1 week | ✅ DONE |
| Tie-Breaking Implementation | HIGH | 4-8 hours | ✅ DONE |
| EndCompletionService Extraction | HIGH | 1 week | ✅ DONE |
| LiveScoringViewModel Extraction | CRITICAL | 2-3 weeks | 🔄 IN PROGRESS (3/5 done) |

### 🟡 HIGH (P1) - Next 2-3 Months

| Issue | Impact | Effort | Priority Score |
|-------|--------|--------|----------------|
| Repository God Classes | HIGH | 6-7 weeks | ⭐⭐⭐ |
| Documentation Cleanup | MEDIUM | 1 week | ⭐⭐⭐ |
| Missing Indexes | MEDIUM | 2 hours | ⭐⭐ |

---

## Critical Issues (P0)

### 1. N+1 Query Pattern ✅ **FIXED**

**File:** `RoundRepository.kt:97-99, 194-196` | `RoundDao.kt:558-624`  
**Impact:** 30-end round = 31 database queries instead of 1 (3000% overhead!)  
**Status:** ✅ COMPLETED - October 4, 2025

**Solution:** Single optimized LEFT JOIN query  
**Performance Gain:** 85-95% reduction (31 queries → 1 query)  
**Commit:** `698e634`

---

### 2. Average Score Always Shows 0.0 ✅ **FIXED**

**File:** `FirebaseTournamentRepository.kt:1115-1137`  
**Impact:** All tournament leaderboards show "Avg 0.0" (100% of users affected)  
**Status:** ✅ COMPLETED - October 4, 2025

**Solution:** Added averageScore calculation (totalScore / endsCompleted)  
**Commit:** `698e634`

---

### 3. TournamentSyncService Extraction ✅ **COMPLETE**

**Status:** ✅ COMPLETED - October 5, 2025  
**Commit:** `b810eea`

**Extracted:** 556 lines from LiveScoringViewModel  
**New Service:** TournamentSyncService with 5 StateFlows for tournament state

**Benefits:**
- ✅ Clear separation of concerns
- ✅ Easier to test tournament sync in isolation
- ✅ Foundation for future service extractions
- ✅ Proof-of-concept for ViewModel refactoring strategy

---

### 4. ScoreConflictResolutionService Extraction ✅ **COMPLETE**

**Status:** ✅ COMPLETED - October 2025  
**Commit:** `4d38c7b`

**Extracted:** 262 lines from LiveScoringViewModel  
**New Service:** ScoreConflictResolutionService with conflict detection logic

**Features:**
- Multiple resolution strategies (LOCAL_WINS, REMOTE_WINS, HIGHEST_WINS, LATEST_WINS)
- Version-based conflict detection with timestamps
- Comprehensive unit tests for conflict scenarios

---

### 5. Tie-Breaking ✅ **COMPLETE**

**Files:**
- `TournamentParticipant.kt:38-39` - xCount & tenCount fields added
- `FirebaseTournamentRepository.kt:1179-1180` - Multi-field ordering implemented

**Status:** ✅ COMPLETED - October 2025  
**Commit:** `4d38c7b`

**Implementation:**
1. Added xCount & tenCount fields
2. Firestore query with composite ordering: Score → X count → 10 count
3. Fair competition with standard archery rules compliance

---

### 6. LiveScoringViewModel God Class 🔄 **IN PROGRESS**

**File:** `LiveScoringViewModel.kt` (2,304 lines, down from 2,808)  
**Impact:** High bug risk, difficult maintenance, slow feature development  
**Status:** 🔄 3 of 5 services extracted (1,218 lines extracted, 61% reduction progress)

**Current Metrics:**
- **Lines:** 2,304 (target: <1,500) - ⬇️ 504 lines from start
- **Services Extracted:** 3/5 complete
  - ✅ TournamentSyncService (556 lines)
  - ✅ ScoreConflictResolutionService (262 lines)
  - ✅ EndCompletionService (400 lines)
- **Remaining Extractions:** 2 services (~350 lines estimated)

**Extraction Roadmap:**
- ✅ Priority 1: TournamentSyncService (556 lines) - COMPLETE
- ✅ Priority 2: ScoreConflictResolutionService (262 lines) - COMPLETE
- ✅ Priority 3: EndCompletionService (400 lines) - COMPLETE
- 🔲 Priority 4: TournamentRoundLifecycleService (~200 lines, 3 days) - TODO
- 🔲 Priority 5: StatisticsAggregationService (~150 lines, 2 days) - TODO

**Progress:**
- **Extracted:** 1,218 lines (3/5 services)
- **Remaining:** ~350 lines (2/5 services)
- **Final Target:** ~1,900 lines (healthy coordinator size)

**Remaining Effort:** 1-2 weeks (2 services remaining)

---

## High Priority (P1)

### 7. Repository God Classes 🟡

**Files:**
- `FirebaseTournamentRepository.kt`: 1,707 lines
- `HybridTournamentRepository.kt`: 1,506 lines
- `RoundRepository.kt`: 1,443 lines
- `TournamentRepository.kt` (interface): 395 lines, 51 methods

**Total:** 5,959 lines violating Single Responsibility Principle  
**Standard:** 200-400 lines, 10-15 methods per repository

**Refactoring Plan:**

**Split TournamentRepository → 4 repositories:**
1. TournamentCrudRepository (~300 lines)
2. TournamentSyncRepository (~400 lines)
3. TournamentScoreRepository (~500 lines)
4. TournamentAnalyticsRepository (~200 lines)

**Split RoundRepository → 3 repositories:**
1. RoundCrudRepository (~400 lines)
2. RoundScoringRepository (~500 lines)
3. RoundStatisticsRepository (~400 lines)

**Effort:** 6-7 weeks

---

### 8. Documentation Chaos 🟡

**Status:** 10+ files severely outdated, claiming features "planned" that are complete

**Critical Documentation Issues:**
1. tournament/README.md - Claims "In Progress" for features that are DONE
2. TOURNAMENT_SYSTEM_DOCUMENTATION.md - 8-9 months old
3. README.md (project root) - 3 months outdated

**Solution:**
1. Archive old files to `docs/COLD_STORAGE/`
2. Update critical docs
3. Remove misleading planning docs

**Effort:** 1 week (8-10 hours)

---

### 9. Missing Database Indexes 🟡

**Missing Index 1: Equipment Performance Query (MEDIUM)**
```sql
CREATE INDEX idx_arrow_scores_equipment_time
ON arrow_scores(bowSetupId, scoredAt DESC)
```

**Missing Index 2: Historical Queries (LOW)**
```sql
CREATE INDEX idx_rounds_status_date
ON rounds(status, createdAt DESC)
```

**Effort:** 2 hours

---

## Implementation Roadmap

### Phase A: Quick Wins ✅ **COMPLETE**

**Week 1-2:** ✅ **COMPLETE**
- ✅ Fix N+1 query pattern
- ✅ Fix average score bug
- ✅ Implement tie-breaking
- ✅ Extract TournamentSyncService
- ✅ Extract ScoreConflictResolutionService

**Completed Impact:**
- ✅ Major user-facing bug fixed
- ✅ 85-95% performance improvement
- ✅ Fair competition with tie-breaking
- ✅ 818 lines extracted from LiveScoringViewModel

---

### Phase B: LiveScoringViewModel Extraction 🔄 **IN PROGRESS**

**Week 1-2:** ✅ COMPLETE - TournamentSyncService (556 lines)  
**Week 3:** ✅ COMPLETE - ScoreConflictResolutionService (262 lines)  
**Week 4:** ✅ COMPLETE - EndCompletionService (400 lines)  
**Week 5:** 🔲 TODO - Remaining 2 services (~350 lines)  
**Week 6:** 🔲 TODO - Integration & Testing

**Progress:** 3/5 services complete (1,218 lines extracted, 61% progress)

---

### Phase C: Repository Refactoring (6-7 weeks)

**Weeks 1-3:** TournamentRepository Split  
**Weeks 4-5:** RoundRepository Split  
**Weeks 6-7:** Testing & Validation

---

## Success Metrics

### Performance Targets
- **Database Queries:** <50ms for 60-end round
- **Cache Hit Rate:** >70%
- **Firestore Reads:** 50-90% reduction

### Code Quality Targets
- **ViewModel Size:** <1,500 lines per ViewModel
- **Repository Size:** <500 lines per repository
- **Method Count:** <30 methods per class

### User Experience Targets
- **Leaderboard Consistency:** 100% devices show same ranking
- **Average Score Display:** 100% accuracy
- **Tie-Breaking:** Standard archery rules compliance

---

## Lessons Learned

### Pattern: "Planning != Implementation"
**Problem:** Multiple features marked "complete" in docs with zero implementation  
**Solution:** Definition of Done requires code merged + tests passing + docs updated

### Pattern: "Incremental Addition Without Extraction"
**Problem:** Tournament features added ~1,300 lines without refactoring  
**Solution:** Line count thresholds with pre-commit hooks, mandatory extraction at 1,500 lines

### Pattern: "Documentation Drift"
**Problem:** 10+ files claiming features "planned" that are complete  
**Solution:** Documentation update as part of Definition of Done, quarterly audits

---

**Source**: `docs/TECH_DEBT.md` (767 lines total)  
**See Also**: [[Checkpoint-Findings]], [[LiveScoringVM-Analysis]], [[Refactoring-Reality-Check]]

*This is a condensed overview. See source file for full analysis, implementation details, risk assessment, and related documents.*