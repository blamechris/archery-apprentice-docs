---
title: "System Flows"
description: "User flows, system flows, and integration patterns"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - flows
  - architecture
  - user-flows
  - system-flows
  - integration
---

[Home](/) > [Technical Reference](../) > Flows

---

# System Flows

Complete reference for user workflows, system processes, and integration patterns in Archery Apprentice.

## Overview

Archery Apprentice implements complex workflows spanning user interactions, internal processes, and external integrations. This guide provides a comprehensive overview of all major flows in the application.

**Flow Documentation Organization:**

- **[User Flows](User-Flows/)** - User interaction patterns and workflows
- **[System Flows](System-Flows/)** - Internal system processes and state machines
- **[Integration Flows](Integration-Flows/)** - External service integrations and data exchange

**Related Documentation:**

- [System Architecture](../../developer-guide/architecture/system-architecture/) - Overall architecture patterns
- [MVVM Patterns](../../developer-guide/architecture/mvvm-patterns/) - State management approach
- [Database Overview](../Database/) - Data persistence layer

---

## Documented Flows

Comprehensive flow documentation is maintained in the [Developer Guide Technical Reference](../../developer-guide/technical-reference/flows/). The following flows are fully documented with sequence diagrams, code references, and implementation details:

### 1. Scoring Flow

**Status:** ✅ Fully Documented (565 lines)
**Documentation:** [Scoring Flow](../../developer-guide/technical-reference/flows/scoring-flow/)
**Scope:** Arrow input → End completion → Statistics calculation → Tournament sync

**Key Components:**

- ActiveScoringScreen.kt - UI entry point for live scoring
- LiveScoringViewModel.kt (2,808 lines) - God class managing scoring state
- EndCompletionService.kt - Extracted service for end finalization
- TournamentSyncService.kt - Async Firebase synchronization
- RoundRepository.kt - Data persistence layer

**Flow Highlights:**

- StateFlow-based reactive state management
- Multi-participant scoring support
- Validation and error handling at end completion
- Async tournament score submission with retry logic
- Score conflict detection and resolution

**Typical Flow:**

```
User Input → ViewModel State Update → UI Recomposition → End Completion →
Validation → Statistics Calculation → Local DB Save → Tournament Sync (Async)
```

---

### 2. Round Lifecycle Flow

**Status:** ✅ Fully Documented (1,168 lines)
**Documentation:** [Round Lifecycle Flow](../../developer-guide/technical-reference/flows/round-lifecycle-flow/)
**Scope:** Round creation → Active scoring → Pausing → Completion → Historical viewing

**Key Components:**

- RoundViewModel.kt (2,177 lines) - God class undergoing refactoring
- RoundRepository.kt - Round CRUD operations
- RoundDao.kt - Database access layer
- HistoricalRoundsScreen.kt - Historical viewing with caching
- BowSetupRepository.kt - Equipment selection integration

**State Machine:**

```
PLANNED → IN_PROGRESS ⇄ PAUSED → COMPLETED/CANCELLED
```

**Flow Highlights:**

- Multi-participant progress tracking
- Round status state machine with validation
- Equipment snapshot creation for historical accuracy
- Statistics aggregation across all ends
- Historical viewing with smart caching (1 week TTL)
- Ranking calculation with tie-breaking rules
- Round archival and deletion

**Performance Considerations:**

- Lazy loading for historical rounds (cached for 1 week)
- Pagination for large round lists
- Indexed queries on `status` and `createdAt` columns

---

### 3. Equipment Management End-to-End Flow

**Status:** ✅ Fully Documented (1,949 lines with Mermaid diagrams)
**Documentation:** [Equipment Management Flow](../../developer-guide/technical-reference/flows/equipment-management-end-to-end-flow/)
**Scope:** Bow setup creation → Component management → Versioning → Round selection → Performance tracking

**Key Components:**

- BowSetupViewModel.kt - Bow setup orchestration
- BowSetupRepository.kt - Equipment CRUD with versioning
- EquipmentStatsDao.kt - Performance snapshot tracking
- BowSetupDetailScreen.kt - Equipment configuration UI
- 10+ component-specific ViewModels (Arrow, Sight, Rest, etc.)

**Flow Highlights:**

- 10+ equipment component types (Arrow, Sight, Rest, Stabilizer, etc.)
- Equipment versioning for historical accuracy
- Guest participant auto-setup creation (duplicate with naming)
- Smart caching strategy (5 minutes TTL for stats)
- Equipment snapshots embedded in rounds
- Performance statistics aggregation by equipment ID
- CSV export for equipment data

**Versioning Strategy:**

```
Bow Setup v1 → Component Added → Bow Setup v2 → Round References v2 →
Historical Round Still Uses v2 Snapshot → Live Setup Continues to v3
```

**Multi-Participant Equipment:**

- Guests get auto-created equipment duplicates with naming (e.g., "Guest 1's Bow")
- Equipment ownership tracked per participant
- Independent equipment selection for each participant

---

### 4. Data Sync Flow

**Status:** ✅ Fully Documented (1,399 lines)
**Documentation:** [Data Sync Flow](../../developer-guide/technical-reference/flows/data-sync-flow/)
**Scope:** Offline-first architecture → Firebase sync → Conflict resolution → Caching

**Key Components:**

- HybridTournamentRepository.kt (1,813 lines) - Offline-first hybrid pattern
- TournamentSyncService.kt (556 lines) - Score submission with retry
- ScoreConflictResolutionService.kt - Conflict detection and resolution
- TournamentScoreCacheService.kt - Smart caching with TTL
- NetworkCallback - Connectivity monitoring

**Flow Highlights:**

- Offline-first architecture (local DB as source of truth)
- Real-time Firebase listeners for tournament updates
- Exponential backoff retry for score submissions (up to 5 attempts)
- Conflict detection (timestamp-based + latest-write-wins)
- Smart caching (5 minutes TTL for leaderboards)
- Batch operations for initial tournament data loading
- Network connectivity monitoring

**Sync Patterns:**

```
Read Flow:  Cache → Local DB → Firebase → Cache Update
Write Flow: Local DB → Firebase (Async) → Retry on Failure → Conflict Check
```

**Conflict Resolution:**

- Last-write-wins strategy for tournament scores
- Timestamp-based conflict detection
- Automatic merge for non-conflicting fields
- User notification on conflict resolution

---

### 5. Settings Architecture

**Status:** ✅ Fully Documented (493 lines)
**Documentation:** [Settings Architecture](../../developer-guide/technical-reference/flows/settings-architecture/)
**Scope:** Device settings management → User preferences → StateFlow propagation

**Key Components:**

- Settings.kt - Room entity (single-row singleton pattern)
- SettingsDao.kt - Settings persistence
- SettingsViewModel.kt - Settings state management
- SettingsPage.kt - Compose UI for settings
- UserIdentityResolver.kt - User identity resolution

**Flow Highlights:**

- Single-row singleton pattern (only one Settings row per device)
- StateFlow-based reactive updates (settings changes propagate immediately)
- Measurement system preferences (metric vs imperial)
- User identity resolution (local vs Firebase user)
- Equipment default tracking (last used equipment)
- Target zoom behavior preferences
- Settings initialization on first launch

**Settings Propagation:**

```
User Input → ViewModel Update → Repository Save → StateFlow Emission →
UI Recomposition → All Consumers Updated
```

**Settings Categories:**

- **Display:** Target zoom behavior, measurement units
- **User:** Default user name, Firebase user ID
- **Equipment:** Last used bow setup ID
- **App Behavior:** First launch flag, onboarding completion

---

## Missing Flow Documentation

The following flows are referenced in the codebase but not yet comprehensively documented. These are prioritized based on architectural importance and user impact.

### High Priority (Next 1-2 Weeks)

#### 1. Tournament Participation Flow

**Status:** ⚠️ Not Documented
**Planned Subsection:** [User Flows](User-Flows/)

**Should Cover:**

- Tournament discovery and browsing
- Join tournament flow (Firebase authentication required)
- Tournament registration approval
- Guest participant creation for tournaments
- Real-time leaderboard viewing
- Tournament score updates from other participants
- Tournament completion and final rankings

**Key Files:**

- TournamentViewModel.kt
- TournamentDiscoveryScreen.kt
- TournamentLeaderboardScreen.kt
- FirebaseTournamentRepository.kt
- TournamentParticipant.kt model

**Why High Priority:** Critical for understanding multi-user features and Firebase integration patterns.

---

#### 2. Analytics Viewing Flow

**Status:** ⚠️ Not Documented
**Planned Subsection:** [User Flows](User-Flows/)

**Should Cover:**

- Round analytics dashboard navigation
- Performance trends calculation and visualization
- Equipment performance comparison
- Distance-specific statistics aggregation
- Fatigue detection visualization
- Shot grouping analysis
- Export analytics data (CSV)

**Key Files:**

- RoundAnalyticsViewModel.kt
- EquipmentAnalyticsHubScreen.kt
- EquipmentComparisonScreen.kt
- StatisticsCalculationService.kt
- EquipmentPerformanceStats.kt models

**Why High Priority:** Key user value proposition for improving archery performance.

---

#### 3. Navigation Patterns

**Status:** ⚠️ Not Documented
**Planned Subsection:** [System Flows](System-Flows/)

**Should Cover:**

- Bottom navigation structure
- Screen transitions and navigation graph
- Deep linking support
- Back stack management
- Navigation state preservation across configuration changes
- Cross-feature navigation (e.g., equipment → rounds → scoring)
- Parameter passing between screens

**Key Files:**

- Navigation graph setup files
- NavHost configuration
- Screen-specific navigation logic
- Deep link handlers

**Why High Priority:** Foundational for understanding application structure and developer onboarding.

---

### Medium Priority (Next Month)

#### 4. Authentication/Authorization Flow

**Status:** ⚠️ Partially Documented (mentioned in Data Sync Flow)
**Planned Subsection:** [Integration Flows](Integration-Flows/)

**Should Cover:**

- Firebase anonymous sign-in flow
- User authentication state management
- Scoring permission checks (tournament owner, participant, guest)
- Tournament ownership verification
- Local vs network participant permission model

**Key Files:**

- FirebaseAuth integration
- ScoringPermissionService.kt
- UserIdentityResolver.kt
- Participant ownership logic

**Why Medium Priority:** Important for security but limited user-facing impact (mostly Firebase anonymous auth).

---

#### 5. State Management Flow

**Status:** ⚠️ Scattered Across Existing Docs
**Planned Subsection:** [System Flows](System-Flows/)

**Should Cover:**

- StateFlow vs LiveData usage patterns
- State derivation and composition (combining multiple StateFlows)
- State persistence across configuration changes
- Shared state between ViewModels (e.g., scoring state)
- State update optimization strategies (avoiding unnecessary recomposition)

**Key Files:**

- ScoringSessionState management
- RoundInputState patterns
- Equipment state coordination
- Tournament state synchronization

**Why Medium Priority:** Essential for maintainability and developer onboarding, but patterns are already demonstrated in existing flow docs.

---

#### 6. Error Handling Flow

**Status:** ⚠️ Mentioned in Individual Flows but Not Unified
**Planned Subsection:** [System Flows](System-Flows/)

**Should Cover:**

- Validation errors (UI-level input validation)
- Database operation failures
- Network/sync errors (Firebase timeouts, connectivity loss)
- Conflict resolution errors
- User-facing error messages and notifications
- Error recovery strategies (retry, fallback, rollback)

**Key Files:**

- Error types and classification
- SaveResult pattern usage
- TournamentSyncStatus error states
- Retry mechanisms (exponential backoff)

**Why Medium Priority:** Important for quality and user experience, but patterns are already demonstrated in existing docs.

---

### Low Priority (Next Quarter)

#### 7. Data Export/Import Flow

**Status:** ⚠️ Mentioned in Equipment Docs but Not Detailed
**Planned Subsection:** [Integration Flows](Integration-Flows/)

**Should Cover:**

- CSV export for rounds and statistics
- JSON export for equipment configurations
- Backup and restore functionality
- Share functionality (Android intents)
- Import validation and error handling

**Key Files:**

- EquipmentExportScreen.kt
- Export service implementations
- Data format specifications (CSV schemas, JSON schemas)

**Why Low Priority:** User-requested features but limited developer impact.

---

## Flow Documentation Standards

All flow documentation in Archery Apprentice follows consistent standards for quality and maintainability:

### Required Sections

1. **Overview** - High-level description of the flow, key components, entry points
2. **Mermaid Diagrams** - Sequence diagrams, flow diagrams, state machines
3. **Detailed Call Chains** - Step-by-step code execution with file paths and line numbers
4. **State Changes** - StateFlow emissions, UI recomposition triggers
5. **Key Classes and Methods** - Primary code locations with file paths
6. **Error Handling** - Failure scenarios and recovery strategies
7. **Performance Considerations** - Optimization strategies, caching, pagination
8. **Testing** - Test files, test scenarios, instrumentation tests
9. **Related Documentation** - Cross-references to architecture, database, and API docs

### Diagram Standards

- **Mermaid Syntax** - All diagrams use Mermaid for consistency and version control
- **Sequence Diagrams** - For showing component interactions over time
- **Flow Diagrams** - For showing decision trees and branching logic
- **State Diagrams** - For showing state machines and lifecycle management

### Code Reference Standards

- **Absolute File Paths** - Use absolute paths relative to repository root
- **Line Numbers** - Include line numbers for large files (e.g., god classes)
- **Method Signatures** - Include full method signatures with parameter types
- **Timestamps** - Document file size and line counts for context

### Example Documentation Quality

See [Equipment Management End-to-End Flow](../../developer-guide/technical-reference/flows/equipment-management-end-to-end-flow/) (1,949 lines) for an example of comprehensive flow documentation with:

- Multiple Mermaid sequence diagrams
- Detailed code call chains with file paths
- Performance considerations and caching strategies
- Testing examples with instrumentation tests
- Cross-references to related documentation

---

## Flow Categories

### User Flows

User-facing workflows that span multiple screens and user interactions.

**Documented:**

- ✅ Scoring Flow (arrow input → end completion)
- ✅ Round Lifecycle Flow (creation → completion)
- ✅ Equipment Management Flow (setup → selection → tracking)
- ✅ Settings Architecture (user preferences)

**Missing:**

- ⚠️ Tournament Participation Flow
- ⚠️ Analytics Viewing Flow

**See:** [User Flows](User-Flows/) for detailed user workflow documentation.

---

### System Flows

Internal system processes, state machines, and background operations.

**Documented:**

- ✅ Round Status State Machine (PLANNED → IN_PROGRESS → COMPLETED)
- ✅ Equipment Versioning Flow (snapshot creation)
- ✅ Statistics Calculation Flow (aggregation across ends)
- ✅ Settings Propagation Flow (StateFlow updates)

**Missing:**

- ⚠️ Navigation Patterns
- ⚠️ State Management Flow (unified patterns)
- ⚠️ Error Handling Flow (unified error recovery)

**See:** [System Flows](System-Flows/) for detailed system process documentation.

---

### Integration Flows

External service integrations, data exchange, and synchronization.

**Documented:**

- ✅ Data Sync Flow (offline-first → Firebase)
- ✅ Tournament Sync Flow (score submission with retry)
- ✅ Conflict Resolution Flow (timestamp-based)
- ✅ Caching Strategy (TTL-based smart caching)

**Missing:**

- ⚠️ Authentication/Authorization Flow (Firebase auth details)
- ⚠️ Data Export/Import Flow (CSV/JSON export)

**See:** [Integration Flows](Integration-Flows/) for detailed integration patterns.

---

## Architecture Context

Flow documentation is tightly integrated with the overall system architecture:

### MVVM Architecture

All flows follow MVVM patterns with Clean Architecture principles:

- **View Layer** - Jetpack Compose UI, observes StateFlows
- **ViewModel Layer** - State management, business logic orchestration
- **Repository Layer** - Data source abstraction, caching
- **Data Layer** - Room database, Firebase, SharedPreferences

See [MVVM Patterns](../../developer-guide/architecture/mvvm-patterns/) for detailed architecture documentation.

### KMP Migration

Flows are impacted by ongoing Kotlin Multiplatform (KMP) migration:

- **Week 11 Status:** Equipment DAO migration complete
- **Shared Modules:** common, domain, database, data, presentation, di
- **Migration Patterns:** 5 migration patterns for gradual transition

See [KMP Migration Architecture](../../developer-guide/kmp-migration/) for migration status and patterns.

### God Class Refactoring

Several key flows are impacted by ongoing god class refactoring:

- **LiveScoringViewModel.kt** (2,808 lines) → Extracting EndCompletionService, TournamentSyncService
- **RoundViewModel.kt** (2,177 lines) → Extracting StatisticsCalculationService, RoundStatusService
- **HybridTournamentRepository.kt** (1,813 lines) → Extracting CacheService, ConflictResolutionService

See [System Architecture](../../developer-guide/architecture/system-architecture/) for refactoring plans and technical debt tracking.

---

## Related Documentation

- **[Database Overview](../Database/)** - Database schema, migrations, and data models
- **[Data Models](../Data-Models/)** - Entity models, relationships, and constraints
- **[System Architecture](../../developer-guide/architecture/system-architecture/)** - Overall architecture patterns and principles
- **[MVVM Patterns](../../developer-guide/architecture/mvvm-patterns/)** - State management and UI patterns
- **[KMP Migration](../../developer-guide/kmp-migration/)** - Kotlin Multiplatform migration status
- **[API Reference](../../api-reference/)** - ViewModels, Repositories, DAOs, Services

---

## Contributing Flow Documentation

To add new flow documentation:

1. **Research the Flow** - Trace code execution from entry point to completion
2. **Create Mermaid Diagrams** - Visualize sequence, flow, and state changes
3. **Document Call Chains** - Include file paths, line numbers, and method signatures
4. **Add Code Examples** - Show key code snippets with context
5. **Document Error Handling** - Cover failure scenarios and recovery strategies
6. **Add Performance Notes** - Document caching, pagination, optimization
7. **Cross-Reference** - Link to related architecture, database, and API docs
8. **Test Examples** - Include test files and test scenarios

**New Flow Checklist:**

- [ ] Overview with key components and entry points
- [ ] Mermaid sequence/flow diagrams
- [ ] Detailed call chains with file paths and line numbers
- [ ] State changes and StateFlow emissions
- [ ] Error handling and recovery strategies
- [ ] Performance considerations (caching, pagination, optimization)
- [ ] Testing examples (unit, integration, instrumentation)
- [ ] Related documentation cross-references
- [ ] Code examples with file paths
- [ ] User-facing impact description

---

**Last Updated:** 2025-11-04
**Documentation Coverage:** 5 flows fully documented (5,574 total lines), 7 flows pending
