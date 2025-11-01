---
title: Pre-KMP Architecture State (Week 10 Snapshot)
tags:
  - architecture
  - kmp-migration
  - snapshot
  - week-10
  - god-classes
  - services
  - platform-abstractions
created: 2025-10-27
source: docs/architecture/PRE_KMP_ARCHITECTURE_SNAPSHOT.md
last-updated: 2025-10-27
status: snapshot
---

# Pre-KMP Architecture State (Week 10)

**Snapshot Date:** October 27, 2025
**Context:** Week 10 of KMP migration - After entity migrations, before DAO migrations
**Purpose:** Capture architecture insights at critical migration milestone

---

## Executive Summary

**Migration Progress:** 28% god class reduction achieved (6,798 → 4,891 lines)

**Key Metrics:**
- **Services Extracted:** 19 services (~4,400 lines from god classes)
- **Platform Abstractions:** 4 complete (PreferenceStorage, ResourceProvider, FileSystemProvider, LoggingProvider)
- **God Classes Remaining:** 3 (LiveScoringViewModel 1,497 lines, RoundViewModel 1,581 lines, HybridTournamentRepository 1,813 lines)
- **KMP Modules:** 6 shared modules active

**Critical Finding:** Services are harder to migrate than DAOs
- DAOs: Zero Android dependencies (ready for Week 11-12)
- Services: Multiple blockers (DI framework, data layer, FirebaseAuth)

---

## God Class Evolution

### LiveScoringViewModel: 47% Reduction ✅

**Before:** 2,808 lines (monolithic tournament + scoring logic)
**After:** 1,497 lines
**Extracted:** 1,311 lines (8 services)

**Key Services Extracted:**
1. TournamentSyncService (515 lines) - Firebase sync orchestration
2. EndCompletionService (366 lines) - End finalization logic
3. ScoreConflictResolutionService (267 lines) - Conflict detection
4. StatisticsAggregationService (254 lines) - Stats calculation
5. TournamentRoundLifecycleService (222 lines) - Round state management

**Remaining Extraction Potential:** ~500 lines
- Arrow scoring logic (~200 lines)
- Session state queries (~150 lines)
- Session initialization (~100 lines)

**Status:** 🟢 Good progress, on track to <1,000 line target

See: [[Architecture/LiveScoringVM-Analysis]] for detailed extraction roadmap

---

### RoundViewModel: 27% Reduction 🟡

**Before:** 2,177 lines
**After:** 1,581 lines
**Extracted:** 596 lines (mostly via refactoring, not service extraction)

**Why Less Progress?**
- Focus prioritized LiveScoringViewModel (tournament is higher risk)
- Some reduction from code cleanup, not extraction
- Service extraction not yet started systematically

**Remaining Extraction Potential:** ~600 lines
- Round display delegation (~300 lines to existing RoundDisplayService)
- Round statistics service (~200 lines)
- Round state management (~150 lines)

**Status:** 🟡 Partial progress, needs systematic extraction

---

### HybridTournamentRepository: 0% Reduction 🔴

**Current:** 1,813 lines (no extraction started)

**Why Blocked?**
- Data layer not yet in shared modules (prerequisite)
- Orchestrates between offline and Firebase repositories
- Complex sync logic with bidirectional data flow

**Planned Split (Week 13+):**
1. TournamentRepository (~450 lines) - CRUD operations
2. TournamentParticipantRepository (~450 lines) - Participant management
3. TournamentScoringRepository (~450 lines) - Score submission
4. TournamentAnalyticsRepository (~450 lines) - Leaderboard calculation

**Status:** 🔴 Not started, deferred to Week 13+ (after DAO migration)

See: [[Architecture/Technical-Debt#Repository-God-Classes]] for refactoring plan

---

## Service Extraction Insights

### What Worked (Weeks 1-9)

**Proven Pattern:** Copy → Delegate → Validate
1. Copy methods to new service
2. Update ViewModel to delegate calls
3. Validate all tests pass (zero regressions)
4. Success rate: 100% (8/8 services)

**Service Categories:**
- **Tournament Services (5):** TournamentSyncService, EndCompletionService, ScoreConflictResolutionService, TournamentRoundLifecycleService, StatisticsAggregationService
- **Calculation Services (4):** AccuracyCalculationService, ProgressCalculationService, RankingCalculationService, StatisticsCalculationService
- **State Services (3):** EndStateTransitionService, ProgressUpdateService, ParticipantStateService
- **Business Logic (7):** RoundDisplayService, ParticipantValidationService, AnonymousParticipantCleanupService, ArrowScoringDomainService, ScoringPermissionService, ParticipantStateQueryService, SessionStateBuilderService

**Total Impact:** ~4,400 lines extracted from god classes

---

### What's Blocking (Week 10 Discovery)

**Service Migration to shared:domain Blocked By:**

**1. DI Framework Dependency (🔴 Critical)**
- All services use `@Inject` and `@Singleton` (Hilt/Dagger)
- Hilt is Android-only (not KMP-compatible)
- Solution: Manual DI (SharedModuleFactory pattern) or Koin
- Timeline: Week 13+ (after DAO migration)

**2. Data Layer Dependencies (🟡 Medium)**
- Services depend on data models still in app module
- Entity migration in progress (Agent 2, Week 10)
- DAO migration planned (Week 11-12)
- Solution: Wait for data layer to move to shared modules
- Timeline: Week 13+ (after DAO migration)

**3. FirebaseAuth Dependencies (🟡 Medium)**
- 3 services use `FirebaseAuth.getInstance().currentUser`
- FirebaseAuth is Android-specific
- Solution: Create FirebaseAuthProvider abstraction OR pass user ID explicitly
- Timeline: Can implement now (2-3 hours) OR defer to Week 13+

**4. Service Interdependencies (🟡 Medium)**
- Services depend on other services (complex graph)
- EndCompletionService → TournamentSyncService
- TournamentRoundLifecycleService → TournamentSyncService
- Solution: Migrate in dependency order (bottom-up)

**Recommendation:** Defer full service migration to Week 13+ (after DAO migration resolves blockers)

See: [[Architecture/Platform-Abstractions-Status#Service-Migration-Status]] for current progress

---

## Platform Abstractions (Pattern 3 Success)

### Completed Abstractions (4 total)

**1. PreferenceStorage** ✅
- **Replaces:** SharedPreferences (Android)
- **API:** get/put for String, Int, Long, Boolean, Float
- **Usage:** 3 services (UpgradeRepairManager, TournamentModeProvider, Settings)
- **Test Coverage:** 100% (21 tests)

**2. ResourceProvider** ✅
- **Replaces:** context.getString() (Android)
- **API:** getString(), getStringArray(), format args
- **Usage:** 1-2 services (low adoption - opportunity)
- **Test Coverage:** 100% (11 tests)

**3. FileSystemProvider** ✅
- **Replaces:** context.filesDir/cacheDir (Android)
- **API:** read/write text/binary, directory management
- **Usage:** 2 services (ExportUtils, OfflineScoreQueueManager)
- **Test Coverage:** 100% (21 tests)
- **Success:** ExportUtils migrated to shared:domain using FileSystemProvider ✅

**4. LoggingProvider** ✅
- **Replaces:** android.util.Log (Android)
- **API:** d(), w(), e() with tag + message
- **Usage:** 0 services (created but not yet adopted)
- **Blocker:** 7 services ready to use, but DI framework blocks migration
- **Test Coverage:** 100% (18 tests)

**Pattern 3 Validation:** ✅ SUCCESSFUL
- Clean abstractions (minimal API surface)
- Easy to test (fakes are simple)
- KMP-compatible (zero Android dependencies in shared:domain)
- Proven workflow (7 steps)

See: [[Architecture/Platform-Abstractions-Status]] for implementation details

---

## Data Layer Migration Status

### Completed (Weeks 1-9)

**Domain Models (Week 2):**
- ✅ Round, EndScore, ArrowScore (scoring models)
- ✅ Settings, BowSetup (user preferences)
- ✅ Distance, TargetSize, ScoringSystem (configuration)
- ✅ DomainColor (KMP-compatible color)

**Data Models (Week 9):**
- ✅ TournamentRound, TournamentScore, TournamentSettings (768 lines)
- ✅ Security models (AccountLinking, AuthMethod, LinkedAccount)
- ✅ kotlinx.serialization: 25+ models
- ✅ Room TypeConverters for serialization

**Database Entities (Week 9):**
- ✅ ArrowEquipmentSnapshot, EquipmentStatsCache
- ✅ kotlinx.serialization annotations added

---

### In Progress (Week 10)

**Agent 2 (AAM) - Primary Focus:**
- 🟢 Equipment entity migration (12 entities to shared:database)
- 🟢 Entity foreign key relationships
- 🟢 Import path updates across codebase

**Expected Completion:** End of Week 10

---

### Planned (Week 11-12)

**DAO Migration (Agent 1 Primary):**
- ⏳ 19 DAOs to shared:database module
- ⏳ Critical finding: ZERO Android dependencies in DAOs ✅
- ⏳ Pattern 4 (DAO migration workflow) designed
- ⏳ Critical path: RoundDao (872 lines, 37% of all DAO code)
- ⏳ Estimated: 18-26 hours over 2 weeks

**Why DAOs Before Services?**
- DAOs are KMP-ready (only androidx.room.* dependency)
- Services have multiple blockers (DI, data layer, FirebaseAuth)
- DAO migration unblocks repository migration (Week 13+)

See: [[Architecture/Database-Migration-Status]] for entity migration tracking

---

## Dependency Graph Insights

### Current Architecture (Week 10)

```
ViewModels (app module)
├── LiveScoringViewModel (1,497 lines)
│   ├── Services: 8 extracted services
│   ├── Repositories: RoundRepository, HybridTournamentRepository
│   └── Platform: FirebaseAuth, TournamentModeProvider, NetworkMonitor
│
├── RoundViewModel (1,581 lines)
│   ├── Services: 3 calculation services
│   ├── Repositories: RoundRepository, EquipmentRepository, BowSetupRepository
│   └── Platform: PreferenceStorage, ResourceProvider
│
└── Other ViewModels (smaller, healthy size)

Services Layer
├── app/services (19 services, ~4,400 lines)
│   └── Blockers: DI framework, data layer, FirebaseAuth
│
└── shared:domain/services (1 service)
    └── ProgressTrackingService (KMP-compatible)

Repository Layer
├── HybridTournamentRepository (1,813 lines) 🔴 God Class
├── OfflineTournamentRepository (uses 19 DAOs)
├── FirebaseTournamentRepository (Firebase SDK)
├── RoundRepository (uses RoundDao)
└── Other Repositories (smaller)

Data Layer
├── Entities (migrating to shared:database)
├── DAOs (19 DAOs, ALL IN APP MODULE) 🔴
│   └── Week 11-12: Migration to shared:database
└── Database (ArcheryDatabase in app module)
```

---

## Migration Timeline & Strategy

### Completed (Weeks 1-9)

**Week 1:** Room KMP 2.8.1 + Kotlin 2.2.0 configuration ✅
**Week 2:** Core domain models migrated ✅
**Week 3-5:** Service extraction begins (8 services) ✅
**Week 7-9:** Pattern 3 (platform abstractions) complete ✅
**Week 9:** Data model migration + kotlinx.serialization ✅

---

### Current (Week 10)

**Agent 2 (Primary):** Equipment entity migration (12 entities)
**Agent 1 (Secondary):** DAO migration planning + architecture snapshot
**Status:** Entity migration in progress, DAO planning complete

---

### Planned (Week 11+)

**Week 11-12: DAO Migration (Agent 1 Primary)**
- 19 DAOs to shared:database
- Pattern 4 workflow (7 steps)
- Critical path: RoundDao (872 lines, 2 days)
- Estimated: 18-26 hours over 2 weeks

**Week 13+: Repository Migration**
- Split HybridTournamentRepository (1,813 → 4 repositories)
- Move repositories to shared:data
- Pattern 5 (repository migration workflow) - TBD
- Estimated: 3-4 weeks

**Week 13+: Service Migration Revisited**
- Resolve DI framework blocker (manual DI)
- Migrate 7 services using android.util.Log
- Create FirebaseAuthProvider abstraction (if needed)
- Estimated: 2-3 weeks

**Week 15-24: God Class Completion**
- Complete LiveScoringViewModel extraction (<1,000 lines)
- Complete RoundViewModel extraction (<1,000 lines)
- Estimated: 9-10 weeks

---

## Key Insights & Lessons

### Insight 1: Services More Complex Than DAOs

**Discovery:** Week 10 analysis revealed unexpected complexity difference

**DAOs:**
- Zero Android dependencies (only androidx.room.*)
- Simple file moves + import updates
- Ready for migration immediately

**Services:**
- Multiple blockers (DI, data layer, FirebaseAuth)
- Complex dependency graphs
- Deferred to Week 13+

**Lesson:** Prioritize unblocked work (DAOs) over complex work (services)

---

### Insight 2: Pattern 3 Validation Success

**Success Metrics:**
- 4 abstractions created (100% implemented)
- 4 test fakes (100% testable)
- 71 tests total (100% coverage)
- 1 service migrated to shared:domain (ExportUtils)

**What Made Pattern 3 Work:**
- Minimal API surface (5-10 methods per abstraction)
- Clear separation (platform-specific vs platform-agnostic)
- Test fakes are simple (in-memory implementations)
- 7-step workflow is repeatable

**Application:** Pattern 4 (DAO migration) based on Pattern 3 success

---

### Insight 3: Service Extraction Velocity

**Extraction Velocity:**
- Weeks 1-9: ~1,900 lines extracted (~211 lines/week)
- Target: ~1,900 more lines to extract
- Projected: 9-10 more weeks to complete

**Acceleration Opportunities:**
- Batch similar extractions (5 calculation services → 1 week)
- Reuse proven patterns (copy-delegate-validate)
- Parallel extraction (multiple services simultaneously)

**Blocker Impact:**
- Service migration delay frees capacity for other work
- DAO migration (Week 11-12) can proceed without waiting

---

### Insight 4: DI Framework is Major Blocker

**Problem:**
- All injectable services use Hilt/Dagger (`javax.inject.*`)
- Hilt is Android-specific (not KMP-compatible)
- shared:domain cannot use Android DI frameworks

**Solutions Evaluated:**
1. **Manual DI** (SharedModuleFactory pattern) - Simple, no framework
2. **Koin for KMP** - KMP-compatible, but different API
3. **Defer migration** - Keep services in app module until Week 13+

**Decision:** Option 3 (defer) chosen for Week 10-12
- Focus on unblocked work (DAOs)
- Revisit DI strategy in Week 13 (after data layer in shared modules)

---

## Recommendations

### High Priority (Next 2-3 Weeks)

**1. Complete DAO Migration (Week 11-12)**
- Execute Pattern 4 workflow (7 steps)
- Migrate all 19 DAOs to shared:database
- Focus on RoundDao (critical path)
- Estimated: 18-26 hours

**2. Monitor Service Extraction Progress**
- Continue LiveScoringViewModel extraction (2 services remaining)
- Arrow scoring logic (~200 lines)
- Session state queries (~150 lines)
- Estimated: 1-2 weeks

**3. Plan Repository Split (Week 13 Prep)**
- Design 4 focused repositories (TournamentRepository split)
- Define repository boundaries
- Identify shared abstractions needed

---

### Medium Priority (Week 13+)

**4. Define DI Strategy for Shared Modules**
- Evaluate manual DI vs Koin
- Design SharedModuleFactory pattern (if manual DI)
- Document service instantiation approach

**5. Create FirebaseAuthProvider Abstraction**
- Abstract `FirebaseAuth.getInstance().currentUser`
- OR refactor to explicit user ID passing (simpler)
- Unblocks 3 services for migration

**6. Begin Repository Migration**
- Split HybridTournamentRepository (1,813 → 4 repositories)
- Move repositories to shared:data
- Update dependency injection

---

### Low Priority (Week 14+)

**7. Complete God Class Refactoring**
- LiveScoringViewModel: Extract remaining ~500 lines
- RoundViewModel: Systematic extraction (~600 lines)
- Target: Both <1,000 lines

**8. Performance Optimization**
- Add database indexes (tournament queries)
- Implement LRU caching (statistics)
- Already completed: N+1 query fix ✅

---

## Cross-References

**Related Architecture:**
- [[Architecture/Platform-Abstractions-Status|Platform Abstractions Status]] - Pattern 3 implementation details
- [[Architecture/Shared-Domain-Status|shared:domain Module Status]] - KMP module structure
- [[Architecture/LiveScoringVM-Analysis|LiveScoringVM Analysis]] - God class extraction roadmap
- [[Architecture/Technical-Debt|Technical Debt]] - Priority matrix and refactoring plan
- [[Architecture/MVVM-Patterns|MVVM Patterns]] - ViewModel best practices
- [[Architecture/System-Architecture|System Architecture]] - High-level architecture overview

**Migration Planning:**
- [[Project-Status/Implementation-Status-10-09-25|Implementation Status]] - Weekly progress tracking
- [[Architecture/Refactoring-Roadmap|Refactoring Roadmap]] - Long-term architecture vision
- [[Architecture/Database-Migration-Status|Database Migration Status]] - Entity and DAO migration tracking

**Technical Details:**
- Source: `docs/architecture/PRE_KMP_ARCHITECTURE_SNAPSHOT.md` (1,160 lines technical documentation)
- Week 10 Planning: `docs/kmp-migration/WEEK_11_12_DAO_MIGRATION_PLAN.md`
- Service Blockers: `docs/kmp-migration/SERVICE_MIGRATION_BLOCKERS.md`
- DAO Complexity: `docs/kmp-migration/DAO_MIGRATION_COMPLEXITY_MATRIX.md`
- Pattern 4 Workflow: `docs/kmp-migration/PATTERN_4_DAO_MIGRATION_WORKFLOW.md`

---

**Last Updated:** October 27, 2025
**Status:** Week 10 snapshot - Baseline for future progress tracking
**Next Update:** After Week 12 DAO migration completes

