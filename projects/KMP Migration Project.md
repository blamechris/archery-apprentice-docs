# KMP Migration Project - Archery Apprentice

**Status:** Week 1 in progress  
**Started:** 2025-10-18  
**Goal:** Migrate Android app to Kotlin Multiplatform to enable iOS development  
**Tags:** #kmp #kotlin-multiplatform #ios #migration #architecture

---

## Project Overview

### Mission
Migrate the Archery Apprentice Android app to Kotlin Multiplatform (KMP) to enable code sharing between Android and iOS platforms. This is a strategic architectural transformation to expand the app from Android-only to cross-platform.

### Key Objectives
- [ ] Extract platform-agnostic business logic into shared modules
- [ ] Create platform abstractions for Android-specific dependencies
- [ ] Refactor god classes to enable better code organization
- [ ] Maintain 80% test coverage throughout migration
- [ ] Enable iOS development with shared codebase

---

## Strategic Approach: Parallel Agent Migration

### Why Parallel Agents?
Traditional sequential migration would take weeks of blocking work. By using 3 parallel agents working in Git worktrees, we can:
- Complete Week 1 in ~3 days instead of 3+ weeks
- Maintain app stability (agents work on branches, not main)
- Minimize merge conflicts through strategic merge ordering
- Enable experimentation without risk to production code

### Three-Agent Strategy

**Agent 1 (AAP) - Platform Abstractions**
- **Branch:** `kmp-migration/platform-abstractions`
- **Mission:** Remove Android `Context` dependencies from domain layer
- **Deliverables:**
  - Platform abstraction interfaces (PreferenceStorage, NetworkMonitor, TournamentModeProvider)
  - Android implementations in app module
  - Clean domain layer (no Android SDK dependencies)
  - Updated test mocks for platform abstractions

**Agent 2 (AAM) - Module Setup**
- **Branch:** `kmp-migration/module-setup` (MERGED)
- **Mission:** Create KMP shared modules structure
- **Deliverables:**
  - 6 shared modules (common, domain, data, database, presentation, di)
  - Room KMP 2.8.1 configuration
  - Gradle build scripts for multiplatform
  - MODULE_ARCHITECTURE.md and DI_STRATEGY.md documentation

**Agent 3 (AAA) - Code Analysis**
- **Branch:** `kmp-migration/code-analysis` (MERGED)
- **Mission:** Analyze god classes and create extraction plans
- **Deliverables:**
  - GOD_CLASS_EXTRACTION_PLANS.md (3 god classes analyzed)
  - VIEWMODEL_INVENTORY.md (25 ViewModels catalogued)
  - WEEK_5_8_PLAN.md (service extraction roadmap)
  - Refactoring priority recommendations

---

## Week 1 Progress

### ✅ Completed
1. **Agent 3 (AAA)** - Code analysis complete, PR merged
   - Identified 3 god classes (LiveScoringViewModel: 2,015 lines, HybridTournamentRepository: 1,808 lines, RoundViewModel: 2,177 lines)
   - Created extraction roadmaps for Weeks 5-8
   - Catalogued all 25 ViewModels in the app

2. **Agent 2 (AAM)** - Module setup complete, PR merged
   - Created shared KMP module structure
   - Configured Room KMP 2.8.1 with KSP
   - Documented DI strategy (manual DI via SharedModuleFactory)
   - Integrated with existing Android app gradle structure

### ⏳ In Progress
3. **Agent 1 (AAP)** - Platform abstractions (raising code coverage)
   - Created 3 platform abstractions
   - Removed Context from 6 domain layer files
   - Fixed 96 test occurrences across 15 files
   - Currently raising test coverage to meet 80% threshold

---

## Week 3 Progress (2025-10-25)

### Agent 1 (AAP) - Coverage Improvements ✅ COMPLETE
**Status:** PR #139 created, 80% goal exceeded (81% achieved)

**Accomplishments:**
- Overall coverage: 77% → 81% (+4 points)
- Repository layer: 59% → 70% (+11 points)
- 50 strategic tests added
- **Critical fix:** JaCoCo configuration bug (.exec file was 0 bytes)

**Impact:**
- All future coverage measurements now accurate
- Repository layer significantly improved
- Infrastructure improvement benefits entire project

**Files:**
- [PR #139](https://github.com/blamechris/archery-apprentice/pull/139)
- [Agent 1 Context](https://github.com/blamechris/archery-apprentice/blob/main/docs/AGENT_CONTEXTS/AGENT_1_AAP.md)

### Agent 2 (AAM) - Data Migration 🔄 IN PROGRESS
**Status:** Days 1-5 complete (768 lines migrated), Days 6-7 in progress

**Completed:**
- TournamentRound, TournamentScore migrations
- TournamentSettings (269 lines, most complex)
- Security models (182 lines)
- All tests passing (3,860+)

**Remaining:**
- Days 6-7: Restore OfflineTournamentRepository
- Day 8: Final verification + PR

### Agent 3 (AAA) - Service Extraction ✅ COMPLETE
**Status:** PR created, <1,500 goal exceeded

**Accomplishments:**
- LiveScoringViewModel: 1,691 → 1,493 lines
- Services: EndStateTransitionService + ProgressUpdateService
- 33 tests added (100% passing)
- Zero failures, zero regressions

**Cumulative (Week 2+3):**
- Total reduction: 522 lines (25.9%)
- Services extracted: 11 total
- Tests added: 116+

---

## Critical Technical Decisions

### 1. Git Worktrees Over Docker
**Decision:** Use Git worktrees for parallel agent work  
**Rationale:**
- Setup time: 30 seconds vs 2 hours for Docker
- No learning curve vs 3-4 hours for Docker
- Native performance (no overhead)
- Perfect for our use case (same machine, different branches)

**Impact:** All 3 agents working efficiently in parallel without conflicts

### 2. Manual DI Over Hilt/Koin
**Decision:** Extend existing RepositoryFactory pattern to SharedModuleFactory  
**Rationale:**
- Project already uses manual DI successfully
- No learning curve for existing patterns
- Easier incremental migration
- KMP DI libraries less mature than Android equivalents

**Impact:** Consistent DI approach across Android and shared code

### 3. Merge Order: Agent 3 → Agent 2 → Agent 1
**Decision:** Strategic merge ordering based on risk  
**Rationale:**
1. Agent 3: Documentation only (safest, no code conflicts)
2. Agent 2: New modules (additive, no existing code changes)
3. Agent 1: Modifies existing code (needs clean base from Agent 2's modules)

**Impact:** Minimized merge conflicts, enabled continuous parallel work

---

## Technical Challenges Resolved

### Challenge 1: Kotlin Version Conflict
**Problem:** Room KMP 2.8.1 pulled Kotlin 2.1.20-dev, project uses 2.0.21  
**Error:** `Incompatible ABI version. Current: '1.8.0', found: '1.201.0'`  
**Solution:** Force resolution in shared/di/build.gradle.kts
```kotlin
configurations.all {
    resolutionStrategy {
        force("org.jetbrains.kotlin:kotlin-stdlib:2.0.21")
        force("org.jetbrains.kotlin:kotlin-stdlib-common:2.0.21")
    }
}
```

### Challenge 2: Test Failures from Platform Abstractions
**Problem:** 21+ test failures after removing Context parameters  
**Root Cause:** `RepositoryFactory.createTournamentRepository()` checks `PlatformProvider.isInitialized()`, falls back to `OfflineTournamentRepository` when false  
**Solution:** Created MockPlatformProviders.kt, mocked PlatformProvider in all affected tests  
**Smart Fix:** Fixed `RoundViewModelTestBase.kt` which cascaded to 19 child test files

### Challenge 3: Worktree Isolation
**Problem:** Agents can't see each other's files (expected worktree behavior)  
**Solution:** Strategic merge order - Agent 3 merges first, others pull main to get docs  
**Lesson:** Coordination requires explicit merge strategy

---

## Architecture Foundation

### Current Android App
- **Type:** Single-module Android app
- **Build System:** Gradle with version catalog (libs.versions.toml)
- **DI:** Manual (RepositoryFactory pattern)
- **Database:** Room (migrating to Room KMP)
- **UI:** Jetpack Compose
- **Target SDK:** compileSdk=36, minSdk=31
- **JVM:** Java 11
- **Kotlin:** 2.0.21

### Target KMP Architecture
```
shared/
├── common/          # Common utilities, expect/actual
├── domain/          # Business logic (platform-agnostic)
├── data/            # Repository implementations
├── database/        # Room KMP database
├── presentation/    # ViewModels, UI state
└── di/              # Dependency injection
```

### Platform Abstractions Created
1. **PreferenceStorage** - SharedPreferences wrapper (was using Context.getSharedPreferences)
2. **NetworkMonitor** - ConnectivityManager wrapper (was using Context.getSystemService)
3. **TournamentModeProvider** - Build config access (was using Context for debug/release detection)

---

## Test Coverage Strategy

### Coverage Requirements
- **Threshold:** 80% (enforced in CI/CD)
- **Current Tests:** 238 unit tests + 51 instrumented tests
- **Strategy:** Maintain coverage throughout migration

### Testing Approach for Migration
- Each agent must maintain/raise test coverage
- Platform abstractions require comprehensive test mocking
- Shared module tests must be platform-agnostic
- Use MockPlatformProviders.kt for platform dependency mocking

---

## Week 2 Planning (Pending Week 1 Completion)

### Prerequisites
- [ ] Agent 1 CI/CD passes
- [ ] Agent 1 PR merged to main
- [ ] All agents pull latest main
- [ ] Week 1 retrospective completed

### Week 2 Focus Areas
1. **Code Migration** - Move domain logic into shared modules
2. **Refactoring** - Begin god class extraction based on Agent 3's plans
3. **Testing** - Ensure shared code has comprehensive test coverage
4. **Integration** - Verify Android app works with shared modules

---

## Success Metrics

### Week 1 (Foundation)
- ✅ Platform abstractions created
- ✅ KMP module structure established
- ✅ God class extraction plans documented
- ⏳ All changes merged to main with passing CI/CD

### Week 2-4 (Migration)
- Domain layer code moved to shared modules
- Platform-specific implementations in app module
- Test coverage maintained at 80%+

### Week 5-8 (Refactoring)
- God classes extracted into services
- Improved architecture and maintainability
- Ready for iOS development

### Week 9+ (iOS Development)
- iOS app created
- Shared modules integrated
- Cross-platform feature parity

---

## Resources

### Documentation
- `docs/AGENT_CONTEXTS/AGENT_O_ORCHESTRATOR.md` - Coordination context
- `docs/MODULE_ARCHITECTURE.md` - KMP module structure (Agent 2)
- `docs/DI_STRATEGY.md` - Dependency injection approach (Agent 2)
- `docs/GOD_CLASS_EXTRACTION_PLANS.md` - Refactoring roadmap (Agent 3)
- `docs/VIEWMODEL_INVENTORY.md` - Complete ViewModel catalogue (Agent 3)

### Git Setup
```bash
# List current worktrees
git worktree list

# Agent worktrees (Week 1)
archery-apprentice/          # Main repo
archery-agent-platform/      # Agent 1 (AAP)
archery-agent-modules/       # Agent 2 (AAM) - MERGED
archery-agent-analysis/      # Agent 3 (AAA) - MERGED
```

---

## Next Steps

1. **Immediate:** Wait for Agent 1 code coverage work to complete
2. **Short-term:** Merge Agent 1 PR after CI/CD passes
3. **Week 1 Closeout:** Retrospective on parallel agent workflow
4. **Week 2 Kickoff:** Define next missions for all 3 agents

---

**Last Updated:** 2025-10-19  
**Next Review:** Week 1 completion (after Agent 1 merge)