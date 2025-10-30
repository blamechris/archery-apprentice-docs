---
tags: [testing, coverage, kmp-migration, week-10, metrics]
date: 2025-10-27
status: current
agent: Agent-3-AAA
related: [[KMP Migration Tracking]], [[Database Migration Plan]], [[Testing Strategy]]
---

[Home](/) > [Development](/Development/) > [Testing](/Development/Testing/) > ---

---


# Test Coverage State - Week 10 (Post-Entity Migration)

**Snapshot Date:** 2025-10-27
**Migration Context:** After Week 9 entity migrations (ArrowEquipmentSnapshot, EquipmentStatsCache), before Week 10-11 equipment entity and DAO migrations
**Agent:** Agent 3 (AAA - Archery Apprentice Analysis)

---

## Executive Summary

**Overall Coverage:** 82% (2,051+ tests, ~90s execution)
**Health:** ✅ Stable baseline maintained
**Critical Gaps:** Repository layer (74%), Round Scoring UI (70%)

**Key Finding:** Data layer coverage is strong (88-97%), but integration layer (repositories) needs improvement.

---

## Coverage Breakdown

### Overall Metrics

| Metric | Coverage | Status |
|--------|----------|--------|
| **Instructions** | 82% (55,096 / 66,900) | ✅ Target met |
| **Branches** | 68% (2,718 / 3,956) | ⚠️ Below 75% target |
| **Lines** | 86% (7,889 / 9,178) | ✅ Good |
| **Methods** | 80% (2,148 / 2,685) | ✅ Good |
| **Classes** | 95% (260 / 273) | ✅ Excellent |

**Test Count:** 2,051+ unit tests, 51 instrumented tests

---

## Critical Gaps (<75% Coverage)

### 1. Repository Layer - 74% ⚠️

**Package:** `com.archeryapprentice.data.repository.impl`
**Impact:** HIGH - Core data access layer
**Files:** 4 repository classes

**Why This Matters:**
- Repositories bridge ViewModels and DAOs
- Critical for offline-first architecture ([[Offline-First Architecture]])
- Integration point for Firebase sync ([[Tournament Sync]])

**Recommendation:** Priority 1 for Week 11-12 improvement
**Estimated Effort:** ~4 hours (repository integration tests)

**Related:** [[HybridTournamentRepository]], [[OfflineTournamentRepository]]

---

### 2. Round Scoring UI - 70% ⚠️

**Package:** `com.archeryapprentice.ui.roundScoring`
**Impact:** HIGH - Core user-facing feature
**Branch Coverage:** Only 50%! (364 / 732 branches)

**Why This Matters:**
- Primary scoring workflow
- Complex state management (885 cyclomatic complexity)
- Critical user path

**Recommendation:** Priority 2 for Week 13-14 (after repository improvements)
**Estimated Effort:** ~3 hours (UI state tests + branch coverage)

**Related:** [[ActiveScoringScreen]], [[RoundViewModel]]

---

## High Coverage Areas (>90%)

✅ **Authentication** - 98% (robust!)
✅ **Data Services** - 95%
✅ **Equipment Component ViewModels** - 94%
✅ **Equipment Models** - 92%
✅ **Domain Models** - 100% (perfect!)
✅ **Settings UI** - 100% (perfect!)
✅ **Database Migrations** - 92%

**Insight:** Data models and services have excellent coverage. The gap is in integration (repositories) and complex UI (round scoring).

---

## Coverage by Layer

### Data Layer (Strong! 88-97%)

| Component | Coverage | Status |
|-----------|----------|--------|
| **Entities** | 97% | ✅ Excellent |
| **Equipment Models** | 92% | ✅ Good |
| **DAOs** | 88% | ✅ Good |
| **Type Converters** | 88% | ✅ Good |

**Related:** [[Database Migration Plan]], [[Entity Migration]]

---

### Integration Layer (Needs Work - 74%)

| Component | Coverage | Status |
|-----------|----------|--------|
| **Repositories** | 74% | ⚠️ Below target |
| **Services** | 84% | ✅ Good |
| **Authentication** | 98% | ✅ Excellent |

**Gap:** Repository layer needs integration tests (DAO + Repository workflows)

**Related:** [[Repository Pattern]], [[Offline-First Architecture]]

---

### UI Layer (Mixed - 70-94%)

| Component | Coverage | Status |
|-----------|----------|--------|
| **Equipment ViewModels** | 94% | ✅ Excellent |
| **Round Scoring** | 70% | ⚠️ Needs improvement |
| **Tournament UI** | 84% | ✅ Good |
| **Settings UI** | 100% | ✅ Perfect |

**Gap:** Round scoring UI has low branch coverage (50%)

**Related:** [[ActiveScoringScreen]], [[God Classes]]

---

## Flaky Tests

### Known Issues

**Compose UI Tests (Excluded from Release):**
1. `ActiveScoringScreenExtendedTest` - Robolectric incompatibility
2. `ParticipantTabsTest` - Robolectric incompatibility
3. `RoundProgressHeaderTest` - Robolectric incompatibility

**Mitigation:** Excluded from release builds, run only in debug builds
**Long-term Fix:** Migrate to instrumented tests (Espresso + Compose)

**Related:** [[Testing Strategy]], [[Compose UI Testing]]

---

### Scroll Reliability (Philosophy)

**3-Layer Testing Approach:**
- **Layer 1 (80%):** `assertExists()` for data verification (scroll-safe)
- **Layer 2 (5%):** Master scroll tests validate infrastructure
- **Layer 3 (15%):** `assertIsDisplayed()` only for user interactions

**Why:** Android scroll reliability causes `assertIsDisplayed()` failures for off-screen items

**Related:** [[Instrumented Testing]], [[E2E Testing]]

---

## Test Performance

**Baseline:** ~90 seconds for 2,051+ tests ✅
**Target:** <2 minutes (already meeting!)
**Platform:** Windows PowerShell

**No performance issues detected.** Test execution is efficient.

---

## Improvement Roadmap

### Phase 1: Critical Gaps (Week 11-12)

**Focus:** Repository layer integration tests

**Tasks:**
1. OfflineTournamentRepository integration tests (~2 hours)
2. HybridTournamentRepository integration tests (~2 hours)
3. EquipmentRepository integration tests (~1 hour)

**Target:** Repository layer to 90%+ coverage
**Estimated Effort:** ~5 hours

**Related:** [[Database Migration Plan]] (Week 11-12 DAO migration timing)

---

### Phase 2: Data Layer Coverage (Week 13)

**Focus:** Comprehensive data layer testing

**Tasks:**
1. Entity test coverage (all 22 entities) (~2 hours)
2. Mapper test coverage (round-trip tests) (~2 hours)
3. DAO test coverage enhancements (~2 hours)

**Target:** Data layer to 90%+ coverage
**Estimated Effort:** ~6 hours

**Related:** [[Entity Migration]], [[DAO Migration]]

---

### Phase 3: UI Layer (Week 14)

**Focus:** Round scoring UI branch coverage

**Tasks:**
1. Round scoring state tests (~2 hours)
2. Branch coverage improvements (~1 hour)
3. Complex UI workflow tests (~2 hours)

**Target:** Round scoring UI to 80%+ coverage, branches to 70%+
**Estimated Effort:** ~5 hours

**Related:** [[ActiveScoringScreen]], [[RoundViewModel]]

---

### Phase 4: E2E & Integration (Week 15)

**Focus:** End-to-end user flows

**Tasks:**
1. Equipment lifecycle E2E test (~3 hours)
2. Offline/online sync E2E test (~4 hours)
3. Multi-device tournament E2E test (~3 hours)

**Target:** 75+ integration tests (current: 51)
**Estimated Effort:** ~10 hours

**Related:** [[E2E Testing]], [[Tournament Sync]], [[Firebase Integration]]

---

## Success Metrics

### Coverage Targets

| Metric | Current (Week 10) | Target (Week 15) | Priority |
|--------|-------------------|------------------|----------|
| **Overall Coverage** | 82% | 85% | 🎯 Target |
| **Repository Coverage** | 74% | 90% | 🚨 Critical |
| **Round Scoring UI** | 70% | 80% | ⚠️ High |
| **Branch Coverage** | 68% | 75% | 🎯 Target |

---

### Test Count Targets

| Category | Current | Target | Priority |
|----------|---------|--------|----------|
| **Unit Tests** | 2,051+ | 2,200+ | 🎯 Target |
| **Integration Tests** | 51 | 75+ | 🚨 Critical |
| **E2E Tests** | ~5 | 10+ | ⚠️ High |

---

## Insights & Observations

### 1. Data Layer Strength ✅

**Observation:** Entities (97%), equipment models (92%), and DAOs (88%) have excellent coverage.

**Why:** Week 3 data layer migration included comprehensive test updates. Entity tests are straightforward (data classes, simple logic).

**Implication:** Solid foundation for Week 10-12 DAO migrations. Low risk of regressions.

**Related:** [[Week 3 Data Layer Migration]]

---

### 2. Repository Integration Gap ⚠️

**Observation:** Repositories at 74% (below 80% target), despite DAOs at 88%.

**Why:** Repository tests focus on unit-level mocking, not integration with actual DAOs. Integration tests (DAO + Repository) are sparse.

**Implication:** Higher risk of integration issues during DAO migrations (Week 11-12). Repository layer should be priority for improvement.

**Recommendation:** Add repository integration tests BEFORE DAO migrations complete.

**Related:** [[Repository Pattern]], [[HybridTournamentRepository]]

---

### 3. UI Branch Coverage Challenge ⚠️

**Observation:** Round scoring UI has 70% instruction coverage but only 50% branch coverage.

**Why:** Complex UI state management with many conditional branches. Tests focus on happy paths, not edge cases.

**Implication:** Edge case bugs may exist in production. Error handling, validation, and state transitions under-tested.

**Recommendation:** Add negative tests, edge case tests, and state transition tests for round scoring UI.

**Related:** [[ActiveScoringScreen]], [[State Management]]

---

### 4. God Classes Risk 🚨

**Observation:** [[RoundViewModel]] (2,177 lines) and [[LiveScoringViewModel]] (2,015 lines) are god classes with high complexity.

**Coverage Impact:** Large classes with many methods are harder to test comprehensively. Branch coverage suffers.

**Recommendation:** Continue god class extraction efforts ([[God Classes]] refactoring). Smaller classes are easier to test thoroughly.

**Related:** [[RoundViewModel]], [[Service Extraction]]

---

## Cross-References

### Related Vault Entries

- [[KMP Migration Tracking]] - Overall migration timeline and status
- [[Database Migration Plan]] - Week 9-12 entity and DAO migrations
- [[Testing Strategy]] - Testing philosophy and 3-layer approach
- [[God Classes]] - RoundViewModel and LiveScoringViewModel refactoring
- [[Repository Pattern]] - Offline-first repository architecture
- [[E2E Testing]] - TournamentLifecycleE2ETest and instrumented tests
- [[Compose UI Testing]] - Robolectric limitations and flaky tests
- [[Offline-First Architecture]] - Hybrid repository sync strategy

---

### Code Repository References

**Detailed Technical Analysis:**
- `docs/testing/TEST_COVERAGE_IMPROVEMENT_PLAN.md` (comprehensive 6-part analysis)
- `app/build/reports/jacoco/jacocoTestReport/html/index.html` (live coverage report)

**CLAUDE.md Entries:**
- Testing Strategy (3-layer architecture)
- Instrumented Test Protocol
- Emulator Management
- Flaky Tests (Compose UI, scroll reliability)

---

## Action Items

### Immediate (Week 11-12)

1. ⚠️ **Add repository integration tests** (5 hours, Priority 1)
   - Target: Repository layer to 90%+
   - Focus: OfflineTournamentRepository, HybridTournamentRepository
   - Timing: During DAO migration (validates migration quality)

2. 🎯 **Monitor DAO migration impact on test coverage** (ongoing)
   - Week 11-12: DAO migrations to shared:database
   - Ensure coverage doesn't regress during migration
   - Baseline: Current 88% DAO coverage

---

### Future (Week 13-15)

3. 🎯 **Improve round scoring UI branch coverage** (5 hours, Week 14)
   - Target: 70% → 80% instruction, 50% → 70% branch
   - Add negative tests, edge cases, state transitions

4. 🎯 **Add E2E integration tests** (10 hours, Week 15)
   - Equipment lifecycle E2E
   - Offline/online sync E2E
   - Multi-device tournament E2E

---

## Next Review

**Scheduled:** After Week 12 DAO migration completes
**Focus:** Validate DAO migration didn't regress coverage, assess repository integration test additions
**Owner:** Agent 3 (AAA)

---

## Metadata

**Created:** 2025-10-27
**Agent:** Agent 3 (AAA - Archery Apprentice Analysis)
**Context:** Week 10 KMP migration (post-entity migration, pre-DAO migration)
**Coverage Baseline:** 82% (2,051+ tests)
**Status:** Current snapshot for improvement planning

**Change Log:**
- 2025-10-27: Initial coverage analysis (Week 10 baseline)

---

**Tags:** #testing #coverage #kmp-migration #week-10 #metrics #repository-gap #ui-branch-coverage
