---
title: "Week 20-21: God Class Discovery & Repository Layer Investigation"
date: 2025-11-09
category: KMP Migration
tags: [week-20, week-21, god-class, repository-layer, ios-blocker, agent-cross-review]
importance: 🔴 CRITICAL
status: in-progress
---

# Week 20-21: God Class Discovery & Repository Layer Investigation

**Period**: November 2025
**Focus**: God class campaign launch and repository layer investigation
**Critical Finding**: 10 god classes discovered (3.2x larger than expected)

---

## Executive Summary

Week 20 launched the god class reduction campaign with conservative scoping and all 4 agents deployed. Week 21 transitions to tackling the **critical iOS blocker** (repository layer) while continuing proven quick wins.

**Week 20 Results**:
- **661 lines reduced** across 3 PRs (4.1% of 16,211 total god class lines)
- **30 logs migrated** to LoggingProvider pattern (7% of 452 total)
- **Agent cross-review system validated** - caught memory leak regression in PR #213
- **Conservative scoping proven** - all PRs merged successfully

**Critical Discovery**:
- **10 god classes identified** (previously thought to be 3)
- **Total: 16,211 lines** (3.2x larger problem than originally assessed)
- **iOS blocker discovered**: Repository layer (3,726 lines) must be refactored before iOS work can proceed
- **Timeline impact**: +8 weeks to iOS readiness

**Week 21 Strategy**:
- **Option 2 (Balanced)** approved - 3 agents active
- **Target**: 1,200-1,400 lines reduced (7.4-8.6% of total)
- **Strategic focus**: Start repository layer investigation (addresses iOS blocker)
- **Risk**: Medium (repository work is investigative, has escape hatch)

---

## Week 20 Achievements

### PRs Merged

#### PR #214: Agent 1 (AAP) - RoundViewModel Stub Cleanup
**Impact**: 55 lines removed (3.5% reduction)

**Work Completed**:
- Removed 3 deprecated ERROR-level stub methods from RoundViewModel
- RoundViewModel: 1,582 → 1,527 lines
- Methods removed:
  1. `finalizeEnd()` - 11 lines
  2. `addArrowScore()` - 10 lines
  3. `completeCurrentEnd()` - 27 lines
  4. + 6 lines of blank lines/documentation

**Risk Level**: Medium
- All methods were ERROR-level deprecations (already failing compilation)
- Test adapter routes to LiveScoringViewModel (safe)
- Build successful, no regressions

**Phase 2 Status**: ⏸️ TABLED
- COMPATIBILITY STUBS section (100-200 lines) deferred to Week 21+
- Reason: Week 20 goals achieved, focus on merging current PRs

---

#### PR #212: Agent 3 (AAA) - ActiveScoringScreen UI Extraction Phase 1
**Impact**: 235 lines removed (11.7% reduction) + 30 logs migrated

**Work Completed**:
- Extracted 3 composables from ActiveScoringScreen (2,011 → 1,776 lines)
- Components extracted:
  1. **ParticipantSelector** (~80 lines) - Participant selection dropdown
  2. **EndInputCard** (~100 lines) - Arrow scoring input card
  3. **ScoringSummary** (~55 lines) - Current end scoring summary

**LoggingProvider Demo**:
- Migrated 30 `android.util.Log` calls to LoggingProvider pattern
- Established template for bulk migration (422 remaining logs)
- Pattern: Module-level logger for KMP compatibility

**Quality**:
- Clean component boundaries with callback-based communication
- Comprehensive KDoc documentation
- 100% test coverage maintained

**Phase 2 Potential**: 600 more lines available (4 additional composables identified)

---

#### PR #213: Agent 2 (AAM) - 3 ViewModel Migrations
**Impact**: 371 lines removed (49.7% avg reduction)

**ViewModels Migrated**:
1. **RoundDisplayViewModel**: 221 → 47 lines (78.7% reduction)
2. **SettingsViewModel**: 227 → 109 lines (52.0% reduction)
3. **TournamentCreationViewModel**: 298 → 219 lines (26.5% reduction)

**Quality Gate Event**:
- Agent 3 review discovered memory leak pattern in 2/3 Presenters
- Issue: Used `asStateFlow()` instead of `stateIn()`
- Agent 2 fixed immediately (PR #213 updated)
- **Result**: Prevented Week 17-18 memory leak pattern from reaching production

**Memory Leak Fix**:
```kotlin
// ❌ WRONG (memory leak)
init {
    scope.launch {
        repository.getData().collectLatest {
            _data.value = it  // Leak!
        }
    }
}

// ✅ CORRECT (no leak)
val data: StateFlow<T> = repository.getData()
    .stateIn(scope, SharingStarted.Eagerly, initialValue)
```

**Test Coverage**: 75/75 tests passing

---

### Week 20 Summary

**Total Reduced**: 661 lines (4.1% of 16,211 total god class lines)

**Agent Contributions**:
- **Agent 1 (AAP)**: 55 lines (RoundViewModel stub cleanup)
- **Agent 2 (AAM)**: 371 lines (3 ViewModel migrations)
- **Agent 3 (AAA)**: 235 lines + 30 logs (UI extraction + LoggingProvider demo)
- **Agent D (DOC)**: 2 vault PRs merged (Weeks 17-19 summary + god class discovery)

**Quality Metrics**:
- ✅ 100% test coverage maintained (4,034+ tests passing)
- ✅ Zero regressions shipped
- ✅ Agent cross-review caught memory leak (quality gate works!)
- ✅ Conservative scoping prevented overcommitment

**Strategic Achievements**:
1. **Cross-review system validated** - Agent 3 caught memory leak in Agent 2's work
2. **LoggingProvider pattern established** - Template for 422 remaining logs
3. **UI extraction pattern proven** - 3 composables, clean boundaries, ready for Phase 2
4. **Conservative scoping effective** - All PRs merged on time

---

## Critical Discovery: 10 God Classes

### Original Assessment (Pre-Week 20)
**3 god classes identified**:
1. LiveScoringViewModel - 1,497 lines
2. RoundViewModel - 1,581 lines
3. ActiveScoringScreen - 2,011 lines

**Estimated effort**: 13 weeks
**Timeline to iOS**: 3 months

### Revised Assessment (Week 20 Discovery)
**10 god classes identified** - 3.2x larger problem!

#### Tier 1: Critical iOS Blockers (3,726 lines)
**Repository layer crisis** - blocks iOS migration

**4. FirebaseTournamentRepository - 1,912 lines** 🚨
- Blocks Firebase abstraction for KMP
- 52 public methods, 8 distinct concerns
- Must be split before iOS work can proceed
- Concerns: Discovery, CRUD, Participants, Scoring, Rounds, Settings, Sync, Deletion

**5. HybridTournamentRepository - 1,814 lines** 🚨
- Blocks iOS migration (tight coupling to Android)
- Coordinator between offline and Firebase repositories
- Requires 4 repository extractions (estimated Weeks 21-24)
- Dependencies: OfflineTournamentRepository, FirebaseTournamentRepository

**7. RoundRepository - 1,518 lines**
- Part of repository layer refactoring
- Medium priority (after Tournament repositories)

**Repository Layer Total**: 3,726 lines (23% of total god class problem)

---

#### Tier 2: Active Development Targets (4,489 lines)
**Currently being reduced in Weeks 20-21**

**1. LiveScoringViewModel - 1,497 lines**
- 5 services already extracted (Week 15-16)
- Remaining: 2 services to extract (Arrow scoring, Participant state)
- Target: Reduce to 600-800 lines

**2. RoundViewModel - 1,581 lines** (1,527 after Week 20)
- Week 20: 55 lines removed (Phase 1)
- Week 21 planned: 100-200 more lines (Phase 2 - COMPATIBILITY STUBS)
- Target: Reduce to 500-600 lines via ViewModel split

**3. ActiveScoringScreen - 2,011 lines** (1,776 after Week 20)
- Week 20: 235 lines extracted (3 composables)
- Week 21 planned: 600 more lines (4 composables)
- Target: Reduce to <1,000 lines

---

#### Tier 3: Future Targets (8,996 lines)
**To be addressed after repository layer and active targets**

6. TournamentDetailsScreen - 1,725 lines
8. TournamentDetailsViewModel - 1,418 lines
9. RoundDetailsScreen - 1,215 lines
10. RoundScoringEntryScreen - 1,011 lines

---

### Impact Analysis

**Total God Class Lines**: 16,211 lines (was thought to be ~5,000)

**Breakdown by Layer**:
- **Repository Layer** (Tier 1): 3,726 lines (23%) - **iOS BLOCKER**
- **ViewModel Layer**: 7,496 lines (46%)
- **UI Layer**: 4,989 lines (31%)

**Timeline Revision**:
- Original estimate: 13 weeks (pre-discovery)
- Revised estimate: +8 weeks (repository layer blocker)
- **New iOS readiness target**: Week 26 (projected)

**Why +8 Weeks?**
- Repository layer must be refactored before iOS Firebase abstraction
- 3,726 lines is complex work (8 distinct concerns across 2 repositories)
- Cannot parallelize (dependencies between repositories)
- Week 21 starts investigation, Weeks 22-25 execute extraction plan

---

## iOS Blocker Identified

### The Problem

**Firebase Abstraction Blocked**:
- iOS development requires `RemoteDataSource` interfaces (KMP-compatible)
- Current code: Direct Firebase Android SDK usage in repository layer
- **Blocker**: FirebaseTournamentRepository (1,912 lines) and HybridTournamentRepository (1,814 lines) are tightly coupled to Firebase Android SDK

**Why This Blocks iOS**:
1. Firebase Android SDK is not KMP-compatible
2. iOS Firebase integration requires abstracted `RemoteDataSource` interfaces
3. Repository layer has 8 distinct concerns (Discovery, CRUD, Participants, etc.)
4. Cannot create clean `RemoteDataSource` until repository is split

**Code Example** (current problem):
```kotlin
// ❌ Current: Direct Firebase usage (Android-specific)
class FirebaseTournamentRepository(
    private val firestore: FirebaseFirestore,  // Android SDK
    private val auth: FirebaseAuth             // Android SDK
) {
    suspend fun getTournaments(): List<Tournament> {
        return firestore.collection("tournaments")
            .get()  // Android-specific call
            .await()
            .toObjects(Tournament::class.java)
    }
}
```

**What's Needed** (iOS-compatible):
```kotlin
// ✅ Target: Abstracted RemoteDataSource (KMP-compatible)
interface TournamentRemoteDataSource {
    suspend fun getTournaments(): List<Tournament>
}

// Android implementation
class FirebaseTournamentDataSource(
    private val firestore: FirebaseFirestore
) : TournamentRemoteDataSource {
    // ... Android Firebase implementation
}

// iOS implementation
class IOSTournamentDataSource(
    // ... iOS Firebase SDK
) : TournamentRemoteDataSource {
    // ... iOS Firebase implementation
}
```

---

### The Solution

**Week 21 Strategy** (Agent 3):
- **Phase 1**: Investigate HybridTournamentRepository (1,814 lines)
- **Phase 2**: Extract 1-2 safe repositories (TournamentDiscoveryRepository OR TournamentSettingsRepository)
- **Phase 3**: Document full repository split roadmap for Weeks 22-25

**Repository Split Plan** (estimated Weeks 21-24):
1. **Week 21**: TournamentDiscoveryRepository (400-600 lines)
2. **Week 22**: TournamentSettingsRepository (300-500 lines)
3. **Week 23**: TournamentParticipantRepository (400-600 lines)
4. **Week 24**: Remaining concerns (scoring, rounds, sync, deletion)

**When Complete**:
- FirebaseTournamentRepository reduced from 1,912 → ~500 lines
- HybridTournamentRepository reduced from 1,814 → ~500 lines
- Clean `RemoteDataSource` interfaces available for iOS
- iOS Firebase abstraction unblocked

**Escape Hatch**:
- If extraction proves too complex in Week 21, deliver investigation + roadmap only
- Week 22+ can execute extraction with more time

---

## Week 21 Strategy: Option 2 (Balanced)

### Overview

**Scope**: 28% god class reduction (estimated 1,200-1,400 lines)
**Time**: 30-35 hours/week
**Risk**: Medium
**Agents**: 3 active (Agent 1 + Agent 2 + Agent 3)

**Why Option 2?**
1. **Addresses iOS blocker** - Agent 3 starts repository layer work
2. **Proven patterns** - Extends Week 20 successes (UI extraction, stub cleanup)
3. **Balanced workload** - Each agent has 1 clear focus
4. **Risk management** - Repository work has escape hatch (doc-only if complex)
5. **Maintains quality** - Agent cross-review continues

---

### Agent Assignments

#### Agent 1 (AAP): RoundViewModel Phase 2 Stub Cleanup
**Target**: 100-200 lines removed
**Time**: 8-10 hours
**Risk**: Low

**Task**: Complete COMPATIBILITY STUBS assessment (tabled in Week 20)

**Scope**:
- RoundViewModel.kt lines 1174-1520+ (COMPATIBILITY STUBS section)
- Remove deprecated stub methods marked for cleanup
- Continue preparing for RoundCreationViewModel extraction

**Success Criteria**:
- ✅ 100-200 lines removed
- ✅ Build passing
- ✅ Tests passing (adapter routing verified)
- ✅ PR created with clear migration notes

**Week 20 Precedent**: Phase 1 removed 55 lines (3 stubs) successfully

---

#### Agent 2 (AAM): ActiveScoringScreen UI Extraction Phase 2
**Target**: 600 lines removed
**Time**: 15-18 hours
**Risk**: Medium

**Task**: Extract 3-4 more composables from ActiveScoringScreen

**Week 20 Baseline**:
- ActiveScoringScreen: 2,011 → 1,776 lines (235 lines extracted)

**Week 21 Target**:
- ActiveScoringScreen: 1,776 → 1,176 lines (600 lines extracted, 34% reduction)

**Candidate Components**:
1. **ParticipantTabs** (~150 lines) - Tab navigation for multi-participant rounds
2. **RoundProgressHeader** (~200 lines) - Round info, progress, stats display
3. **ScoringControls** (~150 lines) - Arrow input buttons and controls
4. **EndSummaryCard** (~100 lines) - Completed end summary display

**Success Criteria**:
- ✅ 3-4 composables extracted to `components/` package
- ✅ 600 lines reduction (34% additional reduction)
- ✅ Clean component boundaries (no tight coupling)
- ✅ Build passing
- ✅ Comprehensive KDoc documentation

**Week 20 Precedent**: Phase 1 extracted 3 composables (235 lines) successfully

---

#### Agent 3 (AAA): Repository Layer Investigation 🚨 CRITICAL
**Target**: 400-600 lines extracted + roadmap
**Time**: 14-18 hours
**Risk**: Medium-High

**Task**: Investigate HybridTournamentRepository + extract 1-2 safe repositories

**Phase 1: Investigation (6-8 hours)**
- Analyze HybridTournamentRepository (1,814 lines)
- Identify concerns (Discovery, CRUD, Participants, Scoring, Rounds, Settings)
- Map dependencies (OfflineTournamentRepository, FirebaseTournamentRepository)
- Identify 1-2 safe extractions with minimal risk

**Phase 2: Extraction (6-8 hours)**
- Extract TournamentDiscoveryRepository OR TournamentSettingsRepository
- Target: 400-600 lines extracted
- Create comprehensive tests
- Document remaining work for Weeks 22-25

**Phase 3: Documentation (2-3 hours)**
- Create repository split roadmap
- Document god class reduction strategy for all 10 classes
- Update investigation findings

**Success Criteria**:
- ✅ 400-600 lines extracted from HybridTournamentRepository
- ✅ Comprehensive roadmap for repository layer refactoring
- ✅ Tests passing for extracted repository
- ✅ Documented plan for FirebaseTournamentRepository (1,912 lines)

**Escape Hatch**: If extraction proves too complex, deliver investigation + roadmap only (documentation deliverable)

**Strategic Importance**: This work addresses the **iOS blocker** and de-risks the critical path to iOS readiness.

---

### Success Metrics

**Quantitative Targets**:
- **Lines Reduced**: 1,200-1,400 lines (UI + RoundViewModel + Repository)
- **God Class Progress**: 7.4-8.6% of total 16,211 lines reduced
- **Repository Investigation**: iOS blocker assessed, roadmap created

**Qualitative Targets**:
- ✅ Agent cross-review continues (quality gate)
- ✅ Repository layer de-risked (investigation complete)
- ✅ Proven patterns extended (UI extraction Phase 2)
- ✅ All PRs merged with zero regressions

**Strategic Targets**:
- ✅ **iOS blocker addressed** - Repository layer work started
- ✅ **Weeks 22-25 roadmap** - Clear path forward
- ✅ **Conservative pace** - Sustainable velocity proven

---

## Week 21 Execution (2025-11-09)

**Status:** ✅ **COMPLETE**

**Strategy:** Option 2 (Balanced) - 3 agents active

### Actual Results

**Agent 2 (AAM) - ActiveScoringScreen Phase 2:**
- ✅ PR #216 merged
- Extracted: 3 composables (495 lines)
  - StatisticsSummaryCard.kt (363 lines)
  - EndOfRoundCard.kt (165 lines)
  - RoundCompleteCard.kt (177 lines)
- ActiveScoringScreen: 1,784 → 1,289 lines (27.7% reduction)
- Cumulative (Phase 1+2): 730 lines total (38.4% of original 2,011 lines)
- **Innovation:** Component reuse pattern established (StatItem shared across components)

**Agent 3 (AAA) - Repository Investigation:**
- ✅ PR #217 merged
- Investigation documents: 2,500+ lines
  - HybridTournamentRepository: 1,878 lines, 50+ methods, 8 concerns
  - Identified: 1,010 lines extractable (54%)
  - Prioritized: 6 repositories (Settings, Discovery, Sync, Rounds, Utils, Moderation)
  - Test estimates: 75-91 tests across all extractions
- Weeks 22-25 roadmap created (1,200+ lines)
- iOS blocker fully assessed (3,726 lines)

**Agent 1 (AAP) - Investigation + LoggingProvider:**
- ✅ PR #218 merged
- **Investigation:** COMPATIBILITY STUBS analysis (333 lines)
  - Finding: Active compatibility layer (374 lines), not deprecated stubs
  - Categories: 7 identified (Round Management, Creation, Live Scoring, etc.)
  - Recommendation: Defer to Phase 3 (Weeks 22-23, 20-30 hours)
- **LoggingProvider migration:** 134 logs (30.5% of codebase)
  - RoundRepository.kt: 45 logs
  - LiveScoringViewModel.kt: 89 logs
  - Zero android.util.Log calls remaining in migrated files
  - Remaining: 306 logs (Week 22 target: ~120 logs)

**Week 21 Totals:**
- **Lines reduced:** 495 lines (ActiveScoringScreen god class reduction)
- **Logs migrated:** 134 logs (30.5% of codebase → LoggingProvider pattern)
- **Documentation:** 2,500+ lines (repository investigation + Weeks 22-25 roadmap)
- **Strategic value:** iOS blocker de-risked, clear execution path for 4 weeks

**Success Metrics:**
- ✅ 495 lines extracted (41% of 1,200-1,400 line target - revised scope with investigation work)
- ✅ 30.5% of logging migration complete (134/440 logs)
- ✅ Repository layer fully assessed (3,726 lines mapped)
- ✅ Weeks 22-25 roadmap created with line-level extraction guides
- ✅ Component reuse pattern established (first cross-component reuse)

### Week 22 Readiness

**Agent 2 (AAM) - Repository Extractions:**
1. TournamentSettingsRepository (~80 lines, 10-12 tests, 3-5 hours)
2. TournamentDiscoveryRepository (~280 lines, 15-18 tests, 6-8 hours)
3. Shared helpers extraction (ID mapping, merge helpers)
4. Total: ~360 lines, 10-12 hours

**Agent 1 (AAP) - LoggingProvider Batch 2:**
1. TournamentDetailsViewModel.kt (52 logs, ~2 hours)
2. EndCompletionService.kt (36 logs, ~1.5 hours)
3. ActiveScoringScreen.kt (32 logs, ~1.5 hours)
4. Total: ~120 logs, ~5 hours

**iOS Blocker Status:**
- Investigation: ✅ Complete
- Extraction: Starting Week 22
- Timeline: 4 weeks (Weeks 22-25) to complete repository layer refactoring

**Cross-Review Quality:** 100% approval rate
- Agent 3 approved PR #216 (Agent 2)
- Agent 2 approved PR #217 (Agent 3)
- Agent 2 approved PR #218 (Agent 1)

---

## Lessons Learned

### Week 20 Lessons

**1. Cross-Review Quality Gate Works**
- Agent 3 reviewed Agent 2's PR #213
- Found 2/3 Presenters using `asStateFlow()` instead of `stateIn()`
- Blocked merge, required fix, prevented memory leak in production
- **Lesson**: Multi-agent validation prevents regressions

**2. Conservative Scoping Prevents Overcommitment**
- Week 20 targeted 661 lines (conservative)
- Result: All 3 PRs merged successfully
- Alternative: Aggressive scoping would have risked incomplete work
- **Lesson**: Better to under-promise and over-deliver

**3. Proven Patterns Replicate Well**
- UI extraction pattern (Week 20) proven successful
- ViewModel migration pattern (Weeks 17-19) continues to work
- Agent 1's stub cleanup pattern effective
- **Lesson**: Validate patterns before scaling

**4. Documentation-First Discovery Works**
- Agent 3 analyzed codebase and discovered 7 additional god classes
- Total problem 3.2x larger than originally thought
- Early discovery allows timeline adjustment
- **Lesson**: Invest in analysis before committing to timelines

---

### Week 21 Lessons

> **Note**: This section will be updated after Week 21 execution.

[To be filled with lessons learned from Week 21 work]

---

## Weeks 22-25 Preview

> **Note**: This section will be updated after Agent 3 completes repository investigation.

### Projected Roadmap

**Week 22**: Repository Layer Phase 2
- [Based on Agent 3's investigation findings]
- Estimated: 400-600 lines reduced

**Week 23**: Repository Layer Phase 3
- [Based on Agent 3's roadmap]
- Estimated: 400-600 lines reduced

**Week 24**: Repository Layer Phase 4
- [Complete repository split]
- Estimated: 400-600 lines reduced

**Week 25**: iOS Readiness Validation
- Firebase abstraction complete
- RemoteDataSource interfaces defined
- iOS work unblocked

**iOS Timeline**: Week 26+ (projected)

---

## Cumulative Progress Tracking

### Week 20 Baseline (After PRs Merged)
- **ActiveScoringScreen**: 1,776 lines (was 2,011)
- **RoundViewModel**: 1,527 lines (was 1,582)
- **LiveScoringViewModel**: 1,497 lines (unchanged Week 20)
- **HybridTournamentRepository**: 1,814 lines (unchanged)
- **FirebaseTournamentRepository**: 1,912 lines (unchanged)

### Week 21 Targets
- **ActiveScoringScreen**: 1,776 → 1,176 lines (600 lines reduced, 34%)
- **RoundViewModel**: 1,527 → 1,327 lines (200 lines reduced, 13%)
- **HybridTournamentRepository**: 1,814 → 1,214-1,414 lines (400-600 lines reduced, 22-33%)

### Cumulative God Class Progress
- **Week 20**: 661 lines reduced (4.1% of 16,211 total)
- **Week 21 Target**: 1,200-1,400 additional lines (7.4-8.6%)
- **Cumulative (Weeks 20-21)**: 1,861-2,061 lines (11.5-12.7% of total)

**Remaining**: 14,150-14,350 lines (87.3-88.5% of total)

**Projected Completion** (at current pace):
- Average: ~1,300 lines/week
- Remaining weeks: ~11 weeks
- **iOS readiness**: Week 26 (late November 2025)

---

## Agent Cross-Review Protocol

### Week 20 Protocol (Established)

**Agent 3 reviews Agent 2** (ViewModel migrations):
- Check memory leak prevention pattern (`stateIn` vs `collectLatest`)
- Verify test coverage (all tests passing)
- Validate KMP compatibility (no Android imports in Presenters)
- Confirm pattern consistency

**Agent 2 reviews Agent 1** (if needed):
- Verify stub removal safety
- Check test adapter routing
- Validate build success

**Result**: Caught memory leak regression in PR #213 before merge

### Week 21 Protocol (Planned)

**Cross-review assignments**:
- Agent 2 reviews Agent 1's PR (RoundViewModel Phase 2)
- Agent 3 reviews Agent 2's PR (ActiveScoringScreen Phase 2)
- Agent 1 reviews Agent 3's PR (Repository extraction, if applicable)

**Quality Gate**: No PR merges without cross-review approval

---

## Risk Assessment

### Week 21 Risks

**1. Repository Layer Complexity (Agent 3)** - Medium-High
- HybridTournamentRepository has 8 concerns
- Dependency on OfflineTournamentRepository and FirebaseTournamentRepository
- **Mitigation**: Investigation phase first, escape hatch to documentation-only

**2. ActiveScoringScreen Complexity (Agent 2)** - Medium
- Composables may have tight coupling
- **Mitigation**: Week 20 proved extraction works, follow same pattern

**3. RoundViewModel Compatibility Layer (Agent 1)** - Low
- Stubs may still be in use by UI code
- **Mitigation**: Grep analysis before removal, adapter pattern proven in Week 20

**4. Cross-Agent Dependencies** - Low
- Agent 2 and Agent 3 both need Agent 1's context for reviews
- **Mitigation**: Agent 1 completes work first, Agent 2/3 cross-review each other

**Overall Risk Level**: Medium

Week 20 proved conservative scoping works. Option 2 extends proven patterns with one investigative task (Agent 3 repository work) that has an escape hatch.

---

## Related Documentation

- [[week-20-god-class-discovery|Week 20 God Class Discovery]] - Detailed analysis of all 10 god classes
- [[week-17-19-summary|Weeks 17-19 Overview]] - ViewModel migration campaign
- [[memory-leak-prevention|Memory Leak Prevention Pattern]] - `stateIn` vs `collectLatest`
- [[combined-pr-strategy|Combined PR Strategy]] - When to merge multiple weeks
- [[agent-2-week-17-19|Agent 2 Week 17-19 Summary]] - ViewModel migration velocity
- [[agent-3-week-17-19|Agent 3 Week 17-19 Summary]] - Quality gate validation

---

## References

### Source Documents
- `docs/AGENT_MESSAGES/WEEK_21/ORCHESTRATOR_WEEK_21_PLANNING.md` - Week 21 strategy
- `docs/AGENT_MESSAGES/WEEK_20/AGENT_1_CREATE_PR.md` - Agent 1 Week 20 work
- `docs/AGENT_MESSAGES/WEEK_20/AGENT_3_REVIEW_PR_213.md` - Cross-review findings
- `docs/AGENT_MESSAGES/WEEK_20/AGENT_2_FIX_PR_213_MEMORY_LEAKS.md` - Memory leak fix

### Main Repo References
- `GOD_CLASS_EXTRACTION_PLANS.md` - Detailed extraction plans for all 10 classes
- `WEEK_15_20_INVESTIGATION_FINDINGS.md` - Investigation findings (to be created/updated)

---

## Tags

#week-20 #week-21 #god-class #repository-layer #ios-blocker #agent-cross-review #firebase-abstraction #kmp-migration #conservative-scoping #quality-gate

---

## Status

- **Week 20**: ✅ COMPLETE - 661 lines reduced, 3 PRs merged
- **Week 21**: 🔄 IN PROGRESS - Agents executing Option 2 (Balanced)
- **Documentation**: 🔄 IN PROGRESS - Will finalize after Week 21 results

**Last Updated**: 2025-11-09 (Week 21 start)
