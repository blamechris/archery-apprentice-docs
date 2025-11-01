# Documentation Reorganization Plan

**Created:** 2025-10-31
**Agent:** Agent D (Documentation)
**Purpose:** Transform archery-apprentice-docs into a professional, consumer/developer-ready knowledge base

---

## Executive Summary

This plan addresses the current organizational issues in the archery-apprentice-docs repository and provides a clear path to a professional documentation structure. The repository has grown organically during the KMP migration, resulting in:

- **268 markdown files** across 35 directories
- **8 duplicate journal folders** (4 in root + 4 in content/)
- **18 loose files in root** (not including README.md)
- **Unclear separation** between consumer, developer, and internal content
- **Duplicate folder structures** between root and content/ directory

**Goal:** Create a clean, professional structure that serves three audiences:
1. **Consumers** - Users who want to understand and use the app
2. **Developers** - Contributors who want to build/extend the app
3. **Internal** - Agent coordination and architecture insights

---

## Part 1: Current State Audit

### 1.1 File Inventory Summary

**Total Files:** 268 markdown files

**Root Directory Issues:**
- 35 directories (many duplicates)
- 18 loose files (*.md, *.py, *.txt) excluding README.md
- 5 Python migration scripts
- 13 loose markdown files

**Key Findings:**
1. **4 empty journal folders in root:**
   - `Daily Journal/` (0 files)
   - `daily-sessions/` (0 files)
   - `Development-Journal/` (0 files)
   - `journal/` (0 files, has empty `2025/` subdirectory)

2. **4 more duplicate journal folders in content/:**
   - `content/Daily Journal/`
   - `content/daily-sessions/`
   - `content/Development-Journal/`
   - `content/journal/`

3. **Major content folders:**
   - `Development/` - 51 files (well-structured)
   - `content/` - 48 files (mixed content)
   - `Technical-Reference/` - 29 files
   - `Architecture/` - 18 files
   - `projects/` - 16 files
   - `User-Guide/` - 13 files (well-structured)
   - `Testing/` - 10 files
   - `Meta/` - 10 files

### 1.2 File Count by Directory

```
Development/                 51 files  ✅ Well-structured (developer docs)
content/                     48 files  ⚠️ Mixed/duplicate content
Technical-Reference/         29 files  ✅ Good structure
Architecture/                18 files  ⚠️ Should be in Development/Architecture/
projects/                    16 files  ⚠️ KMP migration content (internal)
User-Guide/                  13 files  ✅ Well-structured (consumer docs)
Testing/                     10 files  ⚠️ Should be in Development/Testing/
Meta/                        10 files  ✅ Good for internal docs
Project-Management/           6 files  ⚠️ Could be in docs/internal/
Project-Status/               6 files  ⚠️ Duplicate of Project-Management?
Firebase/                     6 files  ⚠️ Should be in Technical-Reference/
Flows/                        6 files  ⚠️ Should be in Technical-Reference/
Analysis/                     4 files  ⚠️ Internal content
Code-Graph/                   4 files  ⚠️ Internal content
Tournament/                   4 files  ⚠️ Should be in Technical-Reference/
assets/                       4 files  ✅ Good
Features/                     3 files  ⚠️ Should be in User-Guide/Features/
Guides/                       2 files  ⚠️ Duplicate of Development/Guides/?
Data-Models/                  2 files  ⚠️ Should be in Technical-Reference/
Tech-Debt/                    2 files  ⚠️ Internal content
technical-notes/              2 files  ⚠️ Internal content
.trash/                       2 files  🗑️ Can be deleted
Architecture-Decisions/       1 file   ✅ Good structure
bugs/                         1 file   🗑️ Should use GitHub Issues
experiments/                  1 file   ⚠️ Internal content
Development Patterns/         1 file   ⚠️ Should be in Development/
Getting-Started/              1 file   ✅ Good structure
Project-Overview/             1 file   ⚠️ Should be in docs/
Workflow/                     1 file   ⚠️ Internal content

Empty Folders (0 files):
Daily Journal/                0 files  🗑️ DELETE (duplicate, empty)
daily-sessions/               0 files  🗑️ DELETE (duplicate, empty)
Development-Journal/          0 files  🗑️ DELETE (duplicate, empty)
journal/                      0 files  🗑️ DELETE (duplicate, empty)
.github/                      0 md files (has workflows)
.obsidian/                    0 md files (Obsidian config)
.quartz-cache/                0 md files (build cache)
public/                       0 md files (build output)
quartz/                       0 md files (Quartz framework)
node_modules/                 0 md files (dependencies)
```

### 1.3 Loose Files in Root (18 files)

**Markdown Files (13):**
1. `Build Quality Patterns and Test Best Practices.md` - Developer content
2. `Documentation-Cross-Reference.md` - Meta content
3. `INDEX.md` - ✅ Keep (navigation hub)
4. `Next Session Focus.md` - Internal/archive
5. `Performance-Optimization.md` - Developer content
6. `PHASE-2-FIX-HANDOFF.md` - Internal/archive
7. `PR-23-REVIEW.md` - Internal/archive (Agent 1 report)
8. `README.md` - ✅ Keep (landing page)
9. `settings-architecture.md` - Developer content
10. `V2.0 Release Completion - Session 2025-10-18.md` - Internal/archive
11. `VALIDATION-SUMMARY.md` - Internal/archive
12. `WEEK-12-DAY-1-AGENT-1-REPORT.md` - Internal/archive
13. `WikiLinks.md` - Meta content

**Python Scripts (5):**
1. `create-readmes.py` - Migration tool
2. `execute-phase2a-migration.py` - Migration tool
3. `migrate-content.py` - Migration tool
4. `migrate-content-fixed.py` - Migration tool
5. `validate-migration.py` - Migration tool

**Action:** Move to `scripts/migration/` and `archive/internal/`

### 1.4 Duplicate Folders Analysis

**Pattern:** Many folders exist in BOTH root AND content/

**Confirmed Duplicates:**
- `Analysis/` vs `content/Analysis/`
- `Architecture/` vs `content/Architecture/`
- `Code-Graph/` vs `content/Code-Graph/`
- `Daily Journal/` vs `content/Daily Journal/`
- `daily-sessions/` vs `content/daily-sessions/`
- `Development/` vs `content/Development/`
- `Development-Journal/` vs `content/Development-Journal/`
- `Features/` vs `content/Features/`
- `Firebase/` vs `content/Firebase/`
- `Flows/` vs `content/Flows/`
- `Guides/` vs `content/Guides/`
- `journal/` vs `content/journal/`

**Investigation Needed:**
- Is `content/` a symlink or a separate directory?
- Which has the authoritative content?
- Is Quartz configured to read from content/?

---

## Part 2: Content Categorization by Audience

### 2.1 Consumer Documentation (Users)

**Purpose:** Help users understand and use the app

**Current Locations:**
- `User-Guide/` - 13 files ✅ Well-structured
  - Features/ (Analytics, Equipment, Scoring, Sync)
  - How-To/ (Data-Management, Equipment-Tasks, Scoring-Scenarios)
  - Quick-Start/
  - Reference/
  - Troubleshooting/
- `Getting-Started/` - 1 file ✅
- `Features/` - 3 files (should be in User-Guide/Features/)
- `Tournament/` - 4 files (could be User-Guide or Technical-Reference)

**Status:** Mostly well-organized, minor consolidation needed

### 2.2 Developer Documentation (Contributors)

**Purpose:** Help developers build, extend, and contribute to the app

**Current Locations:**
- `Development/` - 51 files ✅ Excellent structure
  - Architecture/ (Diagrams, Layers, Patterns)
  - CI-CD/ (Patterns)
  - Contributing/
  - Getting-Started/
  - Guides/ (Adding-Features, Best-Practices, Working-With)
  - Sessions/
  - Testing/
  - Tools/
- `Architecture/` - 18 files (DUPLICATE of Development/Architecture/)
- `Testing/` - 10 files (DUPLICATE of Development/Testing/)
- `Technical-Reference/` - 29 files ✅
- `Architecture-Decisions/` - 1 file ✅
- Loose files:
  - `Build Quality Patterns and Test Best Practices.md`
  - `Performance-Optimization.md`
  - `settings-architecture.md`

**Status:** Good structure, needs consolidation to eliminate duplicates

### 2.3 Internal Documentation (Agent Coordination)

**Purpose:** Track KMP migration, agent work, retrospectives, experiments

**Current Locations:**
- `projects/` - 16 files (mostly kmp-migration/)
- `Meta/` - 10 files
- `Project-Management/` - 6 files
- `Project-Status/` - 6 files
- `Analysis/` - 4 files
- `Code-Graph/` - 4 files
- `experiments/` - 1 file
- `Tech-Debt/` - 2 files
- `technical-notes/` - 2 files
- `bugs/` - 1 file (should be GitHub Issues)
- `Workflow/` - 1 file
- Loose files:
  - `Next Session Focus.md`
  - `PHASE-2-FIX-HANDOFF.md`
  - `PR-23-REVIEW.md`
  - `VALIDATION-SUMMARY.md`
  - `WEEK-12-DAY-1-AGENT-1-REPORT.md`

**Status:** Scattered, needs consolidation into docs/internal/

### 2.4 Archive (Old/Obsolete Content)

**Purpose:** Keep historical content but out of main navigation

**Candidates:**
- All 8 journal folders (empty)
- `.trash/` - 2 files
- `bugs/` - 1 file (use GitHub Issues instead)
- Migration scripts (5 .py files)
- Old session notes
- Obsolete planning docs

---

## Part 3: Investigation Findings

### 3.1 content/ Folder Analysis

**Investigation Status:** ✅ COMPLETE

**Key Findings:**

1. **Is content/ a symlink?**
   - **Answer:** NO - content/ is a real directory (NOT a symlink)
   - **Note:** README.md incorrectly claims it's a symlink

2. **What's in content/?**
   - 48 markdown files
   - Same folder names as root (Analysis/, Code-Graph/, Firebase/, etc.)
   - Same loose files as root (Build Quality Patterns..., WikiLinks.md, etc.)

3. **Is content/ a duplicate of root?**
   - **Answer:** PARTIALLY - content/ contains OUTDATED versions of root files
   - **Evidence:**
     - `content/index.md`: 36 lines (last updated 2025-10-22)
     - `INDEX.md` (root): 289 lines (current, comprehensive)
     - `Build Quality Patterns...` differs by 30+ lines (root has Week 7-8 updates)

4. **Which is authoritative?**
   - **Answer:** ROOT is authoritative (current content)
   - content/ is **STALE** and should be archived

5. **Does Quartz read from content/?**
   - **Answer:** NO - Quartz 4 default reads from ROOT
   - No custom content directory configured in quartz.config.ts
   - content/ is effectively **NOT PUBLISHED** by Quartz

**Decision:** Archive content/ entirely - it's outdated and not used by Quartz

### 3.2 Quartz Configuration

**Investigation Status:** ✅ COMPLETE

**Findings from quartz.config.ts:**
- Quartz reads from ROOT (default Quartz 4 behavior)
- No custom content directory specified
- Ignores: `.obsidian`, `quartz`, `node_modules`, config files
- Uses Explorer component for navigation (file tree)
- Uses Breadcrumbs component

**Findings from quartz.layout.ts:**
- Explorer navigation (automatic from folder structure)
- No hardcoded navigation menu
- Breadcrumbs enabled

**Implications:**
- Reorganizing ROOT structure will automatically update Quartz navigation
- No hardcoded paths to update (Explorer auto-discovers)
- Can safely reorganize folders without breaking navigation

### 3.3 Phase 1 Infrastructure Assessment

**Status:** ✅ Reviewed by Agent 1 (PR #23)

**Key Findings from PR #23 Review:**
- 68 folders created in Phase 1
- 62 README files (placeholders)
- 4 comprehensive templates
- Quality Score: 96% (Grade A - Excellent)
- Approved for merge

**Phase 1 Structure Created:**
```
Getting-Started/
User-Guide/ (13 subfolders)
Development/ (13 subfolders)
Technical-Reference/ (24 subfolders)
Architecture-Decisions/
Project-Management/ (6 subfolders)
Meta/ (2 subfolders)
assets/ (11 subfolders)
```

**Status:** Phase 1 structure is excellent foundation, BUT:
- Old content not yet migrated
- Many duplicate folders from pre-Phase-1 exist
- Root is still messy

---

## Part 4: Proposed Professional Structure

### 4.1 Target Directory Structure

```
ArcheryApprentice-Docs/
├── README.md                    # Landing page (professional, audience-focused)
├── CONTRIBUTING.md              # How to contribute to docs
├── INDEX.md                     # Main navigation hub (keep current)
│
├── .github/                     # GitHub workflows (keep as-is)
├── .obsidian/                   # Obsidian config (keep as-is)
│
├── docs/                        # 📚 MAIN DOCUMENTATION
│   │
│   ├── user-guide/              # Consumer Documentation
│   │   ├── README.md
│   │   ├── getting-started.md
│   │   ├── features/
│   │   │   ├── scoring.md
│   │   │   ├── equipment.md
│   │   │   ├── analytics.md
│   │   │   └── sync.md
│   │   ├── how-to/
│   │   │   ├── scoring-scenarios.md
│   │   │   ├── equipment-tasks.md
│   │   │   └── data-management.md
│   │   ├── reference.md
│   │   └── troubleshooting.md
│   │
│   ├── developer-guide/         # Developer Documentation
│   │   ├── README.md
│   │   ├── setup.md
│   │   ├── architecture/
│   │   │   ├── overview.md
│   │   │   ├── layers.md
│   │   │   ├── patterns.md
│   │   │   └── diagrams/
│   │   ├── guides/
│   │   │   ├── adding-features.md
│   │   │   ├── best-practices.md
│   │   │   ├── testing.md
│   │   │   └── working-with/
│   │   ├── api-reference/
│   │   │   ├── repositories.md
│   │   │   ├── viewmodels.md
│   │   │   └── daos.md
│   │   └── contributing.md
│   │
│   └── internal/                # Internal Documentation (Agent Coordination)
│       ├── README.md
│       ├── kmp-migration/
│       │   ├── overview.md
│       │   ├── week-01-to-11/
│       │   └── week-12-tournament/
│       ├── agents/
│       │   ├── agent-reports/
│       │   └── coordination/
│       ├── retrospectives/
│       ├── experiments/
│       └── analysis/
│
├── assets/                      # Media & Resources
│   ├── images/
│   │   ├── screenshots/
│   │   └── diagrams/
│   ├── videos/
│   └── downloads/
│
├── archive/                     # Historical Content
│   ├── old-journals/
│   ├── migration-artifacts/
│   ├── phase-1-planning/
│   └── deprecated-docs/
│
├── scripts/                     # Utility Scripts
│   ├── migration/
│   │   ├── migrate-content.py
│   │   ├── validate-migration.py
│   │   └── create-readmes.py
│   └── validation/
│
├── quartz/                      # Quartz Framework (keep as-is)
├── node_modules/                # Dependencies (keep as-is)
├── public/                      # Build output (keep as-is)
│
├── quartz.config.ts             # Quartz configuration
├── quartz.layout.ts             # Quartz layout
└── package.json                 # Dependencies

```

### 4.2 Key Design Principles

1. **Clear Audience Separation**
   - `docs/user-guide/` - For consumers
   - `docs/developer-guide/` - For contributors
   - `docs/internal/` - For agent coordination

2. **Single Source of Truth**
   - No duplicate folders
   - One canonical location for each topic
   - Clear content ownership

3. **Flat Hierarchy**
   - Maximum 3 levels deep
   - Easier navigation
   - Better for search

4. **Professional Root**
   - Only README, CONTRIBUTING, config files
   - All content in docs/
   - All scripts in scripts/
   - All old content in archive/

5. **Descriptive Names**
   - kebab-case for consistency
   - No abbreviations
   - Self-documenting structure

---

## Part 5: Migration Strategy

### 5.1 Migration Phases

**Phase 1: Investigation & Planning** ✅ COMPLETE
- ✅ Audit current structure
- ✅ Identify duplicates
- ✅ Categorize by audience
- ✅ Check Quartz configuration
- ✅ Compare duplicate folder contents (content/ vs root)
- ✅ Finalize migration plan

**Phase 2: Archive & Safety**
- Create archive/ directory structure:
  - archive/old-journals/
  - archive/migration-scripts/
  - archive/internal-reports/
  - archive/stale-content/
- Move 8 empty journal folders to archive/old-journals/
- Move 5 .py migration scripts to scripts/migration/
- Move content/ folder entirely to archive/stale-content/ (it's outdated)
- Move .trash/ to archive/
- Move bugs/ to archive/ (use GitHub Issues instead)
- Commit: "Archive old content (Phase 2)"

**Phase 3: Create New Structure**
- Create docs/ hierarchy
- Create docs/user-guide/
- Create docs/developer-guide/
- Create docs/internal/
- Commit: "Create new docs structure (Phase 3)"

**Phase 4: Migrate Consumer Content**
- Move User-Guide/ → docs/user-guide/
- Move Getting-Started/ → docs/user-guide/getting-started.md
- Move Features/ → docs/user-guide/features/
- Update internal links
- Commit: "Migrate consumer docs (Phase 4)"

**Phase 5: Migrate Developer Content**
- Consolidate Architecture/ into Development/Architecture/
- Consolidate Testing/ into Development/Testing/
- Move Development/ → docs/developer-guide/
- Move Technical-Reference/ → docs/developer-guide/api-reference/
- Update internal links
- Commit: "Migrate developer docs (Phase 5)"

**Phase 6: Migrate Internal Content**
- Move projects/ → docs/internal/kmp-migration/
- Move Meta/ → docs/internal/
- Move Project-Management/ → docs/internal/
- Move Agent reports → docs/internal/agents/
- Update internal links
- Commit: "Migrate internal docs (Phase 6)"

**Phase 7: Update Quartz Configuration**
- Update quartz.config.ts (navigation)
- Update quartz.layout.ts (structure)
- Test build locally
- Commit: "Update Quartz configuration (Phase 7)"

**Phase 8: Update README & Navigation**
- Rewrite README.md (professional landing page)
- Create CONTRIBUTING.md
- Update INDEX.md (if needed)
- Test all links
- Commit: "Update navigation (Phase 8)"

**Phase 9: Quality Assurance**
- Test Quartz build
- Test local preview
- Validate all links
- Check mobile responsiveness
- Final review
- Commit: "Final QA (Phase 9)"

### 5.2 Migration Safety Measures

**Git Safety:**
1. Work in branch: `docs/professional-reorganization`
2. Commit after each phase
3. Keep detailed MIGRATION_LOG.md
4. Can rollback any phase if needed

**Content Safety:**
1. Archive, don't delete (initially)
2. Keep MIGRATION_LOG.md mapping old → new
3. Test Quartz build after each phase
4. Validate links after migrations

**Rollback Plan:**
- Each phase is a separate commit
- Can revert individual commits
- Archive preserves original content
- MIGRATION_LOG enables manual restoration

---

## Part 6: Next Steps (Immediate Actions)

### 6.1 Investigation ✅ COMPLETE

**Completed Actions:**
1. ✅ Read quartz.config.ts
2. ✅ Read quartz.layout.ts
3. ✅ Compare content/ vs root folders
4. ✅ Determine content/ purpose (STALE, not used by Quartz)
5. ✅ Finalize migration approach (archive content/ entirely)

**Key Decision:** content/ folder will be archived as it contains outdated content and is not published by Quartz.

### 6.2 Create Migration Scripts (NEXT STEP - 1 hour)

**Scripts Needed:**
1. `archive-old-content.sh` - Move to archive/
2. `create-new-structure.sh` - Create docs/ hierarchy
3. `update-links.py` - Fix internal links after moves
4. `validate-structure.py` - Check structure compliance

### 6.3 Begin Phase 2: Archive (1 hour)

**Immediate Wins:**
1. Delete 8 empty journal folders
2. Move 5 .py scripts to scripts/migration/
3. Move .trash/ to archive/
4. Move bugs/ to archive/ (use GitHub Issues)
5. Create archive/internal/ for old agent reports

---

## Part 7: Resolved Questions & Final Decisions

### 7.1 Quartz Configuration (RESOLVED ✅)

**Q1: Where does Quartz read content from?**
- **Answer:** ROOT directory (default Quartz 4 behavior)
- **Impact:** Can reorganize root, Quartz will auto-discover new structure

**Q2: Is content/ a Quartz requirement?**
- **Answer:** NO - content/ is not used by Quartz
- **Decision:** Archive content/ as it's outdated

**Q3: How is navigation configured?**
- **Answer:** Explorer component (auto-discovery from folder structure)
- **Impact:** No hardcoded navigation to update

### 7.2 Content Strategy (RESOLVED ✅)

**Q1: What to do with content/ folder?**
- **Decision:** Archive entirely to archive/stale-content/
- **Rationale:** Contains outdated versions of root files, not published by Quartz

**Q2: Merge Development/Architecture/ with Architecture/?**
- **Investigation Needed:** Compare contents before deciding
- **Likely Decision:** Consolidate into docs/developer-guide/architecture/
- **Action:** Phase 4 migration will determine if they're duplicates

**Q3: Keep Phase 1 structure or use proposed structure?**
- **Decision:** Use proposed docs/ structure (Part 4.1)
- **Rationale:** Clearer audience separation, professional organization
- **Approach:** Migrate Phase 1 content into docs/ structure

### 7.3 Migration Timeline Questions

**Q1: Should we migrate incrementally or all at once?**
- Incremental: Lower risk, testable, reversible
- All-at-once: Faster, but riskier
- **Recommendation:** Incremental (by phase)

**Q2: When to update Quartz config?**
- Before migration: Risky (breaks current site)
- After migration: Safer (old content still works)
- **Recommendation:** After content migration (Phase 7)

---

## Part 8: Success Criteria

### 8.1 Professional Structure Achieved

- ✅ Clean root (only README, CONTRIBUTING, config files)
- ✅ Clear audience separation (user-guide, developer-guide, internal)
- ✅ No duplicate folders
- ✅ Maximum 3 levels deep
- ✅ All content categorized correctly

### 8.2 Navigation & Discoverability

- ✅ Professional README.md (landing page)
- ✅ CONTRIBUTING.md created
- ✅ Quartz navigation updated
- ✅ All links working
- ✅ Search functionality works

### 8.3 Quality Assurance

- ✅ Quartz build succeeds
- ✅ Local preview works
- ✅ All internal links valid
- ✅ Mobile-responsive
- ✅ Fast load times
- ✅ No broken images

### 8.4 Documentation

- ✅ REORGANIZATION_PLAN.md (this document)
- ✅ MIGRATION_LOG.md (detailed move tracking)
- ✅ Migration scripts documented
- ✅ Rollback procedures documented

---

---

## Part 9: Summary & Next Actions

### 9.1 Audit Completion Summary

**Phase 1 Investigation: ✅ COMPLETE**

**Key Findings:**
1. **268 markdown files** across messy structure
2. **8 duplicate empty journal folders** (can be deleted)
3. **content/ folder is OUTDATED** and not used by Quartz (archive it)
4. **Quartz reads from ROOT** (auto-discovery navigation)
5. **Well-structured folders exist:** User-Guide/, Development/, Technical-Reference/
6. **18 loose files in root** need organization
7. **Professional structure needed:** docs/ with user-guide, developer-guide, internal

**Major Decisions Made:**
- ✅ Archive content/ entirely (outdated, not published)
- ✅ Delete 8 empty journal folders
- ✅ Use proposed docs/ structure (Part 4.1)
- ✅ Migrate incrementally by phase (safer)
- ✅ Move scripts to scripts/migration/

### 9.2 Immediate Next Steps (Day 1 Remaining)

**Current Status:** Investigation complete, ready for execution

**Next Actions (2-3 hours):**

1. **Create migration scripts** (1 hour)
   - archive-old-content.sh
   - create-new-structure.sh
   - update-links.py
   - validate-structure.py

2. **Execute Phase 2: Archive** (1-2 hours)
   - Create archive/ structure
   - Move content/ to archive/stale-content/
   - Move 8 empty journal folders to archive/old-journals/
   - Move 5 .py scripts to scripts/migration/
   - Move .trash/, bugs/ to archive/
   - Commit & push

**Day 1 Deliverable:** REORGANIZATION_PLAN.md ✅ + Archive completed

---

## Status: Phase 1 (Investigation) - ✅ COMPLETE

**Investigation Completed:**
- ✅ File inventory (268 files cataloged)
- ✅ Content categorization (Consumer/Developer/Internal)
- ✅ Duplicate identification (8 journal folders + content/)
- ✅ Quartz configuration analysis
- ✅ Professional structure design
- ✅ Migration strategy defined

**Next Phase:** Phase 2 (Archive & Safety)

**Timeline:**
- ✅ Investigation: COMPLETE (2-3 hours actual)
- 🔄 Scripts: 1 hour (NEXT)
- 🔄 Phase 2 Archive: 1-2 hours
- **Total Day 1:** 4-6 hours (audit + investigation + scripts + archive)

---

**Created by:** Agent D (Documentation)
**Date:** 2025-10-31
**Version:** 1.0 (Investigation Complete)
**Status:** ✅ Investigation Complete - Ready for Migration Scripts & Archive Phase
