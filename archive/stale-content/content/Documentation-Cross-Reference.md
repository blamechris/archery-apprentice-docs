# Documentation Cross-Reference Index

**Purpose:** This index maps documentation between the Git repository (`docs/`) and the Obsidian vault to maintain consistency and prevent duplication.

**Last Updated:** October 15, 2025 (Session 2)

---

## Documentation Strategy

### Git Repository (docs/)
- **Purpose:** Official project documentation checked into version control
- **Audience:** Developers, contributors, CI/CD systems
- **Format:** Markdown files with clear structure and cross-references
- **Location:** `archery-apprentice/docs/`

### Obsidian Vault
- **Purpose:** Rich interconnected knowledge base with advanced linking
- **Audience:** Development team, detailed technical research
- **Format:** Markdown with Obsidian-specific features (wiki links, tags, backlinks)
- **Location:** `ArcheryApprentice-Docs/`

---

## Architecture Documentation

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| System Architecture | `docs/architecture/ARCHITECTURE.md` | `Architecture/Architecture.md` | ✅ Synced |
| RoundViewModel Status | `docs/ROUNDVIEWMODEL_STATUS.md` | `Architecture/RoundViewModel-Status.md` | ✅ Synced |
| LiveScoringViewModel Analysis | `docs/LIVESCORINGVM_ANALYSIS.md` | `Architecture/LiveScoringVM-Analysis.md` | ✅ Synced |
| Refactoring Roadmap | `docs/architecture/REFACTORING_ROADMAP.md` | `Architecture/Refactoring-Roadmap.md` | ✅ Synced |
| **RoundViewModel Refactoring Plan** | `docs/COLD_STORAGE/architecture-planning/ROUNDVIEWMODEL_REFACTORING_PLAN.md` | `Architecture/RoundViewModel-Refactoring-Plan.md` | ✅ **Updated Oct 15** |
| Technical Debt | `docs/TECH_DEBT.md` | `Tech-Debt/Tech-Debt.md` | ✅ Synced |
| MVVM Patterns | ❌ Not in Git | `Architecture/MVVM-Patterns.md` | 📝 Vault only |
| System Architecture | ❌ Not in Git | `Architecture/System-Architecture.md` | 📝 Vault only |
| Scoring Data Model | ❌ Not in Git | `Architecture/Scoring-Data-Model.md` | 📝 Vault only |

## Archived Plans (COLD_STORAGE)

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| TournamentSyncService Extraction Plan | `docs/COLD_STORAGE/architecture-planning/TOURNAMENTSYNCSERVICE_EXTRACTION_PLAN.md` | `Analysis/TournamentSyncService-Extraction-Plan.md` | ✅ Completed & Archived (Oct 15) |
| RoundViewModel Architectural Audit | `docs/COLD_STORAGE/architecture-planning/RoundViewModel_Architectural_Audit.md` | ❌ Not in vault | 📦 Archived |
| RoundViewModel Audit | `docs/COLD_STORAGE/architecture-planning/ROUNDVIEWMODEL_AUDIT.md` | ❌ Not in vault | 📦 Archived |
| RoundViewModel Refactoring Plan | `docs/COLD_STORAGE/architecture-planning/ROUNDVIEWMODEL_REFACTORING_PLAN.md` | ❌ Not in vault | 📦 Archived |

**Note:** Archived plans are completed planning documents preserved for historical reference and to document proven extraction strategies.

## Tournament Documentation

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| Tournament README | `docs/tournament/README.md` | ❌ Not in vault | 📝 Git only |
| Phase 2 Discovery | `docs/tournament/PHASE_2_TOURNAMENT_DISCOVERY.md` | `Tournament/Phase-2-Tournament-Discovery.md` | ✅ Synced |
| Phase 4 Completion | `docs/tournament/PHASE_4_COMPLETION_REPORT.md` | ❌ Not in vault | 📝 Git only |
| Tournament UI Plan | `docs/tournament/TOURNAMENT_UI_IMPLEMENTATION_PLAN.md` | ❌ Not in vault | 📝 Git only |
| Tournament System Docs | ❌ Not in Git | `Tournament/Tournament-System-Documentation.md` | 📝 Vault only |
| Firebase Integration | `docs/firebase/FIREBASE_INTEGRATION_PLAN.md` | `Firebase/Firebase-Integration-Plan.md` | ✅ Synced |
| Firebase Setup | `docs/firebase/FIREBASE_SETUP.md` | `Firebase/Firebase-Setup.md` | ✅ Synced |

## Session Notes & Development Journals

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| Session Summaries (Historical) | `docs/COLD_STORAGE/session-summaries/` | ❌ Removed duplicates | ✅ Cleaned up |
| Current Development Sessions | ❌ Not in Git | `Development/Sessions/` (7 files) | 📝 Vault only |
| **Oct 15 Session 2: Multi-Participant Ranking** | ❌ Not in Git | `Development/Sessions/2025-10-15-Multi-Participant-Ranking-Display.md` | 📝 **NEW Oct 15** |
| Project Journals | `docs/project-journal(10-XX-25).md` | `Project-Status/Project-Journal-10-XX-25.md` | ✅ Synced |
| Implementation Status | `docs/implementation-status(10-XX-25).md` | `Project-Status/Implementation-Status-10-XX-25.md` | ✅ Synced |

## Testing Documentation

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| Test Failure Analysis | `docs/testing/TEST_FAILURE_ANALYSIS.md` | `Testing/Test-Failure-Analysis.md` | ✅ Synced |
| Test Quality Standards | ❌ Not in Git | `Testing/Test-Quality-Standards.md` | 📝 Vault only |
| Tournament Test Guide | ❌ Not in Git | `Testing/Tournament-Test-Guide.md` | 📝 Vault only |
| Adapter Migration Guide | ❌ Not in Git | `Testing/Adapter-Migration-Guide.md` | 📝 Vault only |

## Technical Notes

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| Firebase Auth State Loss Across Coroutines | ❌ Not in Git | `technical-notes/Firebase Auth State Loss Across Coroutines.md` | 📝 Vault only |
| **Multi-Participant Ranking and Tie-Breaking** | ❌ Not in Git | `technical-notes/Multi-Participant Ranking and Tie-Breaking.md` | 📝 **NEW Oct 15** |
| Room Database Entity Mapping | ❌ Not in Git | `Architecture/room-database-entity-mapping.md` | 📝 Vault only |

## Flows & Implementation Details

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| Equipment Management Flow | ❌ Not in Git | `Flows/Equipment-Management-End-to-End-Flow.md` | 📝 Vault only |
| Round Lifecycle Flow | ❌ Not in Git | `Flows/Round-Lifecycle-Flow.md` | 📝 Vault only |
| Scoring Flow | ❌ Not in Git | `Flows/Scoring-Flow.md` | 📝 Vault only |
| Service Architecture | ❌ Not in Git | `Flows/Service-Architecture.md` | 📝 Vault only |

## Development Guides

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| Contributing Guide | `docs/development/CONTRIBUTING.md` | `Development/Contributing.md` | ✅ Synced |
| Improvement Tickets | `docs/development/IMPROVEMENT_TICKETS.md` | `Development/Improvement-Tickets.md` | ✅ Synced |
| Claude Development Notes | `CLAUDE.md` (root) | `Workflow/Claude-Development-Workflow.md` | ✅ Synced |

## Status & Roadmaps

| Topic | Git Repository | Obsidian Vault | Status |
|-------|---------------|----------------|--------|
| V2 Release Roadmap | `docs/V2_RELEASE_ROADMAP.md` | ❌ Not in vault | 📝 Git only |
| Firebase Emulator E2E Plan | `docs/FIREBASE_EMULATOR_E2E_TESTING_V2_PLAN.md` | ❌ Not in vault | 📝 Git only |
| Current TODO | ❌ Not in Git | `Project-Status/Current-TODO.md` | 📝 Vault only |

---

## Cleanup Actions Completed (Oct 15, 2025)

### Phase 1: Critical Corrections
- ✅ Fixed `implementation-status(10-15-25).md` - Removed Firebase auth bug blocker
- ✅ Updated `TECH_DEBT.md` - Corrected extraction progress (3/5 services)
- ✅ Updated `V2_RELEASE_ROADMAP.md` - Added tournament settings bug fix

### Phase 2: Redundancy Elimination
- ✅ Archived 3 RoundViewModel planning docs to `COLD_STORAGE/architecture-planning/`
- ✅ Archived Phase 2 completion summary to `COLD_STORAGE/`
- ✅ Archived 2 session summaries to `COLD_STORAGE/session-summaries/`
- ✅ Updated `docs/README.md` with correct dates (2025-10-15)
- ✅ Updated `tournament/README.md` to reflect completed Phases 1-5
- ✅ Updated `LIVESCORINGVM_ANALYSIS.md` with extraction progress (60%)

### Phase 3: Obsidian Organization
- ✅ Removed duplicate Tournament session summaries from vault
- ✅ Consolidated session notes from 4 directories into `Development/Sessions/`
- ✅ Moved 3 scattered session files:
  - `daily-sessions/2025-10-09` → `Development/Sessions/`
  - `Development-Journal/2025-10-08` → `Development/Sessions/`
  - `journal/2025/10-october/2025-10-10` → `Development/Sessions/`
- ✅ Moved `Daily Journal/2025-10-11` → `Development/Sessions/`
- ✅ Created `Development/Sessions/README.md` with structure documentation
- ✅ Created this cross-reference index

### Phase 4: Archived Extraction Plans
- ✅ Archived `TOURNAMENTSYNCSERVICE_EXTRACTION_PLAN.md` to `COLD_STORAGE/architecture-planning/`
- ✅ Added completion note referencing current status in `LIVESCORINGVM_ANALYSIS.md`
- ✅ Obsidian vault version already complete with detailed completion notes

### Phase 5: Session 2 Documentation (Oct 15, 2025)
- ✅ Created `Development/Sessions/2025-10-15-Multi-Participant-Ranking-Display.md`
- ✅ Created `technical-notes/Multi-Participant Ranking and Tie-Breaking.md`
- ✅ Updated `Architecture/RoundViewModel-Refactoring-Plan.md` with implementation notes
- ✅ Updated this cross-reference index with new documentation

---

## Maintenance Guidelines

### When Adding New Documentation

1. **Decide on Location:**
   - **Git (docs/)**: Official specs, completion reports, roadmaps, contributing guides
   - **Obsidian**: Detailed flows, technical research, interconnected notes, daily journals

2. **Update This Index:**
   - Add entry to appropriate section
   - Mark status (✅ Synced, 📝 Git only, 📝 Vault only, 📦 Archived)
   - Include file paths for both locations if synced

3. **Prevent Duplication:**
   - Check this index before creating new documentation
   - If content exists elsewhere, add cross-reference instead of duplicating
   - Archive completed work to `COLD_STORAGE/` rather than deleting

### Sync Patterns

**✅ Synced Content:**
- Architecture overviews (high-level design docs)
- Refactoring status and roadmaps
- Project journals and implementation status
- Contributing guides

**📝 Git Only:**
- Official roadmaps (V2_RELEASE_ROADMAP)
- Release plans and E2E testing plans
- Phase completion reports
- README files with project structure

**📝 Vault Only:**
- Detailed technical flows (Equipment, Round Lifecycle, Scoring)
- Service architecture deep dives
- Daily development journals
- Test quality standards and guides
- Current TODO and work-in-progress tracking
- **Technical notes** (Firebase auth, ranking algorithms, entity mapping)

**📦 Archived:**
- Completed extraction plans
- Outdated planning documents
- Historical session summaries
- Superseded architecture audits

### Quarterly Review Checklist

- [ ] Check for duplicate content between Git and Vault
- [ ] Archive completed phase documentation to COLD_STORAGE
- [ ] Update this cross-reference index
- [ ] Verify file paths are correct
- [ ] Consolidate scattered notes into appropriate directories
- [ ] Update dates in README files

---

## Directory Structure Comparison

### Git Repository (docs/)
```
docs/
├── architecture/          # System architecture docs
├── development/          # Contributing guides
├── firebase/             # Firebase setup and integration
├── testing/              # Test analysis and strategies
├── tournament/           # Tournament feature docs
├── COLD_STORAGE/         # Archived historical docs
│   ├── architecture-planning/  # Completed extraction plans
│   └── session-summaries/      # Historical session notes
├── README.md             # Documentation index
├── TECH_DEBT.md          # Technical debt tracking
├── ROUNDVIEWMODEL_STATUS.md
├── LIVESCORINGVM_ANALYSIS.md
└── V2_RELEASE_ROADMAP.md
```

### Obsidian Vault
```
ArcheryApprentice-Docs/
├── Analysis/             # Code analysis and extraction plans
├── Architecture/         # System architecture (detailed)
├── Code-Graph/           # Code relationships and patterns
├── Daily Journal/        # [DEPRECATED] Moved to Development/Sessions
├── Data-Models/          # Data model documentation
├── Development/          # Development guides and sessions
│   └── Sessions/         # Consolidated session notes (7 files)
├── Features/             # Feature documentation
├── Firebase/             # Firebase integration details
├── Flows/                # End-to-end flow documentation
├── Guides/               # User and developer guides
├── Project-Overview/     # Project summaries
├── Project-Status/       # Current status and journals
├── Tech-Debt/            # Technical debt details
├── technical-notes/      # Technical reference notes (NEW)
│   ├── Firebase Auth State Loss Across Coroutines.md
│   └── Multi-Participant Ranking and Tie-Breaking.md
├── Testing/              # Testing guides and standards
├── Tournament/           # Tournament system docs
└── Workflow/             # Development workflows
```

---

**Recommendation:** Keep this index updated when adding new documentation. Use it as a reference to prevent duplication and maintain clear separation of concerns between Git repository (official specs) and Obsidian vault (detailed research and daily work).

**Recent Update (Oct 15, 2025 - Session 2):** Added 3 new documentation files for multi-participant ranking display implementation. All documentation follows standardized templates and includes comprehensive technical details, test coverage, and architectural decisions.