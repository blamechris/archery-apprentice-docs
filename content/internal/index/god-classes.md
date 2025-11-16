# God Class Index

## Overview

This index tracks god classes in the Archery Apprentice codebase - files that have grown too large and taken on too many responsibilities, violating the Single Responsibility Principle.

**Definition:** A god class is a file that:
- Exceeds 1,000 lines of code
- Contains 40+ methods
- Manages 5+ distinct responsibilities
- Creates maintenance and testing challenges

## Current God Classes (2025-11-15)

### Active God Classes

| Rank | File | Lines | Methods | Severity | Status | Priority |
|------|------|-------|---------|----------|--------|----------|
| 1 | FirebaseTournamentRepository | 1,909 | 48 | 🔴 High | Assessment deferred | P2 |
| 2 | RoundViewModel | 1,508 | 81 | 🔴 High | Test coverage enhanced | P3 |
| 3 | LiveScoringViewModel | 1,500 | 59 | 🔴 High | Extraction in progress | P1 |
| 4 | **TournamentDetailsViewModel** | **1,421** | **35** | 🟡 **Medium-High** | **Extraction planned** | **P2** |
| 5 | ActiveScoringScreen | 1,289 | 38 | 🟡 Medium | Monitoring | P3 |

**Total:** 5 god classes identified

### Severity Legend
- 🔴 **High (9-10/10):** Urgent extraction needed
- 🟡 **Medium-High (7-8/10):** Extraction recommended within 2-3 months
- 🟢 **Medium (5-6/10):** Monitor, extract opportunistically

## Extraction Progress

### Successfully Reduced

| File | Original Size | Current Size | Reduction | Services Extracted |
|------|--------------|--------------|-----------|-------------------|
| RoundViewModel | 2,177 lines | 1,508 lines | **31%** ✅ | Score calculation logic |
| LiveScoringViewModel | 2,808 lines | 1,500 lines | **47%** ✅ | 5 services (TournamentSync, ScoreConflict, EndCompletion, Lifecycle, Statistics) |
| ActiveScoringScreen | 1,896 lines | 1,289 lines | **32%** ✅ | UI component separation |

**Total Reduction:** 2,184 lines removed through refactoring

### Planned Extractions

#### TournamentDetailsViewModel (NEW - 2025-11-15)
**Discovery:** Identified during audit verification session
**Current Size:** 1,421 lines, 35 methods, 9 responsibilities
**Target Reduction:** 600-800 lines (40-55%)
**Extraction Plan:** 4 services

**Service Candidates:**
1. **ParticipantManagementService** (~300 lines)
   - Effort: 1 week
   - Complexity: High (async sync, guest logic)

2. **ScoringRoundService** (~280 lines)
   - Effort: 1 week
   - Complexity: High (participant conversion)

3. **UserIdentityService** (~130 lines)
   - Effort: 1-2 days
   - Complexity: Medium (reusable)

4. **TournamentSettingsService** (~100 lines)
   - Effort: 2-3 days
   - Complexity: Medium

**Timeline:** 7 weeks for full extraction (or 4-5 days for minimal viable extraction)
**Priority:** Medium-high (after iOS work completes)

## God Class Details

### 1. FirebaseTournamentRepository (1,909 lines)
**Type:** Repository
**Responsibilities:** Firebase operations, tournament CRUD, participant management, sync coordination
**Status:** Assessment deferred pending KMP migration completion
**Severity:** 🔴 High
**Note:** Complex Firebase integration makes extraction challenging

### 2. RoundViewModel (1,508 lines)
**Type:** ViewModel
**Responsibilities:** Round scoring, participant management, statistics, weather, notes
**Status:** Test coverage enhanced (19 test files, 6,189 lines)
**Severity:** 🔴 High (but improving)
**Progress:** 31% reduction achieved, critical methods 100% tested

**Test Coverage Enhancement (2025-10-14):**
- `recomputeRoundTotals()`: 0% → 100% (6 tests)
- `updateWeatherConditions()`: 0% → 100% (2 tests)
- `updateNotes()`: 0% → 100% (2 tests)
- `debugEndInfo()`: 0% → 100% (2 tests)

### 3. LiveScoringViewModel (1,500 lines)
**Type:** ViewModel
**Responsibilities:** Live scoring, tournament sync, conflict resolution, statistics
**Status:** Extraction in progress (47% reduction achieved)
**Severity:** 🔴 High (but improving)

**Services Extracted:**
- ✅ TournamentSyncService (~400 lines)
- ✅ ScoreConflictResolutionService (~150 lines)
- ✅ EndCompletionService (~100 lines)
- ✅ TournamentRoundLifecycleService (~80 lines)
- ✅ StatisticsAggregationService (~100 lines) - Oct 2025

**Lessons Learned:**
- Incremental extraction works well
- Start with smallest, clearest responsibility
- Comprehensive test coverage for each service
- Clear StateFlow ownership (service owns, ViewModel observes)

### 4. TournamentDetailsViewModel (1,421 lines) - NEW
**Type:** ViewModel
**Responsibilities:** User identity, tournament lifecycle, participants, scoring rounds, equipment, settings, real-time updates, data loading, UI state
**Status:** Extraction planned (Week 29+)
**Severity:** 🟡 Medium-High (7/10)
**Discovery Date:** 2025-11-15

**Why 7/10:**
- Large size (1,421 lines)
- Multiple responsibilities (9 areas)
- Complex async logic (participant management, join sync)
- Better structured than older god classes (mitigating factor)

**See:** [[tournament-details-viewmodel|TournamentDetailsViewModel]] for full extraction plan

### 5. ActiveScoringScreen (1,289 lines)
**Type:** Compose UI
**Responsibilities:** Active scoring UI, arrow input, end management, display logic
**Status:** Monitoring (32% reduction achieved)
**Severity:** 🟡 Medium
**Note:** UI files naturally larger; size more acceptable for Compose screens

## Extraction Patterns & Guidelines

### Service Extraction Pattern

**When to Extract:**
1. Responsibility can be isolated (clear boundary)
2. Logic is reusable across ViewModels
3. Testing would benefit from isolation
4. Size exceeds 200 lines for single responsibility

**How to Extract:**
1. Identify cohesive responsibility (user identity, sync, settings)
2. Create service class with single focus
3. Move methods and StateFlows to service
4. ViewModel observes service StateFlows
5. Add comprehensive service tests
6. Verify no regressions

**Best Practices:**
- Start with smallest, clearest responsibility
- Test each extraction independently
- Clear StateFlow ownership (service owns, ViewModel observes)
- Incremental approach (can stop after quick wins)
- Avoid circular dependencies
- Maintain or improve test coverage

### Success Metrics

**File Size:**
- ViewModel: Target <700 lines (ideal <500)
- Service: Target <300 lines
- Repository: Target <800 lines (challenging with Firebase)

**Method Size:**
- Target: <50 lines per method
- Critical: No methods >100 lines

**Complexity:**
- Cyclomatic complexity: <10 per method
- Responsibilities per class: 1-3 max

**Test Coverage:**
- Maintain >80% coverage during extraction
- Each service gets dedicated test file
- No behavioral regressions

## Prevention Guidelines

### Code Review Checklist
- [ ] File size <1,000 lines?
- [ ] Single responsibility maintained?
- [ ] Method count <40?
- [ ] No methods >100 lines?
- [ ] Could logic be extracted to service?

### Red Flags
- 🚩 File approaching 1,000 lines
- 🚩 Multiple unrelated StateFlows in ViewModel
- 🚩 Method exceeds 100 lines
- 🚩 Class name includes "And", "Manager", "Helper"
- 🚩 Difficulty writing focused tests

### Proactive Refactoring
- Extract early (don't wait for 2,000+ lines)
- Create services for reusable logic
- Review quarterly: "Which files are growing fastest?"
- Celebrate reductions (track progress like debt paydown)

## Historical Context

### God Class Campaign (Weeks 20-21, 2025)
Major refactoring effort that reduced god classes significantly:
- RoundViewModel: 2,177 → 1,508 lines (31% reduction)
- LiveScoringViewModel: 2,808 → 1,500 lines (47% reduction)
- ActiveScoringScreen: 1,896 → 1,289 lines (32% reduction)

**Total Impact:** 2,184 lines removed, better testability, clearer architecture

### Audit Verification Discovery (2025-11-15)
TournamentDetailsViewModel discovered during independent verification of external audit findings. Demonstrates value of periodic codebase analysis.

## Related Concepts

- [[service-extraction-pattern|Service Extraction Pattern]]
- [[mvvm-patterns|MVVM Patterns]]
- [[technical-debt|Technical Debt Management]]
- [[refactoring-roadmap|Refactoring Roadmap]]
- [[solid-principles|SOLID Principles]]

## References

- **Week 20-21:** God class discovery and campaign
- **2025-10-14:** RoundViewModel test coverage enhancement
- **2025-11-15:** TournamentDetailsViewModel discovered
- **CLAUDE.md:** Main codebase god class tracking

## Tags

#god-class #refactoring #architecture #technical-debt #viewmodel #index
