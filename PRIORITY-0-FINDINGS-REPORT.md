# Priority 0: Live Site Issues - Findings Report

**Date:** 2025-11-01
**Agent:** Agent D (Documentation)
**Branch:** docs/session-2-live-site-fixes
**Live Site:** https://www.blamechris.com/archery-apprentice-docs/

---

## Executive Summary

Investigation of the live site Explorer dropdown has revealed **4 critical issues** affecting user navigation:

1. **"bugs" and "projects" appearing in lowercase** - Archive directory not excluded from build
2. **8 orphaned links floating at top level** - 2 empty files, 3 archived files, 3 correctly migrated
3. **Ambiguous category names** - Missing index.md files and unclear purposes
4. **Inconsistent subsection organization** - 20 of 20 level-2 directories missing index.md

All issues are **fixable in a single PR** with high confidence of success.

---

## Issue 1: Explorer Capitalization - "bugs" and "projects"

### Problem

The Explorer dropdown shows "bugs" and "projects" in lowercase when they should be capitalized or not appear at all.

### Root Cause

**The `archive/` directory is NOT excluded from the Quartz build process.**

**Evidence:**
- `archive/stale-content/content/bugs/` exists with 1 file (tournament-settings-persistence-bug.md)
- `archive/stale-content/content/projects/` exists with 4 files (KMP Migration docs)
- `quartz.config.ts` line 20 ignorePatterns does NOT include "archive"
- These directories should NOT be visible on the live site

**Current ignorePatterns:**
```typescript
ignorePatterns: [
  "private",
  "templates",
  ".obsidian",
  "quartz",
  "node_modules",
  "package*.json",
  "tsconfig.json",
  "*.config.ts",
  "*.layout.ts"
],
// ❌ MISSING: "archive"
```

### Solution

**Add "archive" to the ignorePatterns array:**

```typescript
ignorePatterns: [
  "private",
  "templates",
  ".obsidian",
  "quartz",
  "node_modules",
  "archive",  // ← ADD THIS LINE
  "package*.json",
  "tsconfig.json",
  "*.config.ts",
  "*.layout.ts"
],
```

### Verification

After fix:
1. Run `npm run build`
2. Verify `public/bugs/` does NOT exist
3. Verify `public/projects/` does NOT exist
4. Check Explorer dropdown - "bugs" and "projects" should be gone

**Confidence:** 100% - This will completely resolve the issue

---

## Issue 2: Orphaned Links in Explorer

### Problem

The Explorer has 8 loose links not organized into logical subsections.

### Complete Orphaned Files Inventory

| # | File Name | Current Location | Status | Action Required |
|---|---|---|---|---|
| 1 | Build Quality Patterns and Test Best Practices | `content/developer-guide/guides/best-practices/` | ✅ MIGRATED | None - properly categorized |
| 2 | CI/CD Infrastructure - Self-Hosted Runners | Split across `content/developer-guide/ci-cd/` | ✅ REORGANIZED | None - properly split into modular files |
| 3 | Documentation-Cross-Reference | `content/internal/meta/` | ✅ MIGRATED | None - correctly placed |
| 4 | Next Session Focus | `archive/internal-reports/` | ⚠️ ARCHIVED | None - correctly archived |
| 5 | Performance-Optimization | `content/developer-guide/technical-reference/Performance/` | ❌ EMPTY FILE (0 bytes) | **DELETE or restore content** |
| 6 | settings-architecture | `content/developer-guide/architecture/` | ✅ MIGRATED | None - correctly placed |
| 7 | V2.0 Release Completion - Session 2025-10-18 | `archive/internal-reports/` | ⚠️ ARCHIVED | None - correctly archived |
| 8 | WikiLinks | `content/internal/meta/` | ❌ EMPTY FILE (0 bytes) | **DELETE or restore content** |

### Critical Empty Files

**Performance-Optimization.md:**
- Location: `content/developer-guide/technical-reference/Performance/Performance-Optimization.md`
- Size: 0 bytes
- Archive version: Also 0 bytes
- **Recommendation:** DELETE - no content to restore

**WikiLinks.md:**
- Location: `content/internal/meta/WikiLinks.md`
- Size: 0 bytes
- Archive version: Also 0 bytes
- **Recommendation:** DELETE - no content to restore

### Solution

1. **Delete empty files:**
   ```bash
   git rm content/developer-guide/technical-reference/Performance/Performance-Optimization.md
   git rm content/internal/meta/WikiLinks.md
   ```

2. **Verify archived files remain in archive:**
   - Next Session Focus.md ✓
   - V2.0 Release Completion - Session 2025-10-18.md ✓

3. **Confirm migrated files are properly placed:**
   - All 3 migrated files are correctly categorized ✓

**Note:** After archive/ is excluded from build (Issue 1), the orphaned links issue will be largely resolved automatically.

---

## Issue 3: Confusing Top-Level Categories

### Problem

Users reported confusion about category purposes:
- "What is Analysis for?"
- "What does Meta group contain?"
- "Project-Overview vs projects?" (naming collision)

### Analysis Category

**Current State:**
- Directory: `content/internal/analysis/`
- Has 4 files: Checkpoint-Findings.md, Data-Layer-Architecture.md, LiveScoringVM-Analysis.md, TournamentSyncService-Extraction-Plan.md
- ❌ **NO index.md file**
- Purpose IS documented in `content/internal/index.md` line 82-98: "Technical analysis and architectural investigations"

**Problem:** Directory has no index.md, so Explorer shows folder name without context

**Solution:** Create `content/internal/analysis/index.md` with clear description:

```markdown
# Technical Analysis

In-depth technical investigations and architectural assessments conducted during development.

## Contents

- **[Checkpoint Findings](Checkpoint-Findings.md)** - Pre-epoch architecture audit
- **[Data Layer Architecture](Data-Layer-Architecture.md)** - Data layer design analysis
- **[LiveScoringVM Analysis](LiveScoringVM-Analysis.md)** - ViewModel investigation
- **[TournamentSyncService Extraction Plan](TournamentSyncService-Extraction-Plan.md)** - Service extraction strategy
```

### Meta Category

**Current State:**
- Directory: `content/internal/meta/`
- Has 6 files + 1 subdirectory
- ❌ **NO index.md file**
- Purpose is NOT clearly documented anywhere

**Problem:** "Meta" is vague and unclear

**Solution:** Create `content/internal/meta/index.md` AND consider renaming to `documentation-meta`:

```markdown
# Documentation Metadata

Documentation about documentation - meta-level information, cross-references, and content audits.

## Contents

- **[Documentation Cross-Reference](Documentation-Cross-Reference.md)** - Maps docs between Git repo and Obsidian vault
- **[Phase 2 Content Audit](Phase-2-Content-Audit.md)** - Content reorganization analysis
- **[Phase 2 Summary](Phase-2-Summary.md)** - Phase 2 migration summary
- **[Phase 2A Migration Report](Phase-2A-Migration-Report.md)** - Detailed migration report
- **[Infrastructure Setup Complete](Infrastructure-Setup-Complete.md)** - Setup completion report
```

### Project-Overview vs projects

**Investigation Results:**
- ❌ NO "Project-Overview" directory exists in `content/`
- ✓ "projects" directory exists ONLY in `archive/stale-content/content/projects/`
- ✓ "project-tracking" directory exists in `content/internal/project-tracking/`

**Conclusion:** The confusion is caused by:
1. Archive "projects" appearing in Explorer (Issue 1)
2. "project-tracking" not having an index.md

**Solution:**
1. Fix Issue 1 (exclude archive) - eliminates "projects"
2. Create `content/internal/project-tracking/index.md`

```markdown
# Project Tracking

Internal project status tracking, implementation journals, and TODO lists.

## Contents

- **[Current TODO](Current-TODO.md)** - Active task list
- **[Checkpoint Findings](Checkpoint-Findings.md)** - Project checkpoint analysis
- **[ViewModel Refactoring Progress](ViewModel-Refactoring-Progress.md)** - ViewModel migration status
- **[Implementation Status (Oct 7)](Implementation-Status-10-07-25.md)** - October 7 status snapshot
- **[Implementation Status (Oct 9)](Implementation-Status-10-09-25.md)** - October 9 status snapshot
- **[Project Journal (Oct 7)](Project-Journal-10-07-25.md)** - Development journal
```

---

## Issue 4: Subsection Organization Inconsistency

### Problem

Explorer has inconsistent subsection organization - some directories have index.md landing pages, most don't.

### Analysis

**Total directories:** 45
**Directories with index.md:** 5 (11%)
**Directories WITHOUT index.md:** 40 (89%)

**Level-2 directories missing index.md (20 total):**

**developer-guide/ subdirectories:**
- architecture/ - MISSING index.md
- ci-cd/ - MISSING index.md
- contributing/ - MISSING index.md
- guides/ - MISSING index.md
- technical-reference/ - MISSING index.md
- testing/ - MISSING index.md

**internal/ subdirectories:**
- agents/ - MISSING index.md
- analysis/ - MISSING index.md ← **Priority 0 fix**
- code-graph/ - MISSING index.md
- development-patterns/ - MISSING index.md
- experiments/ - MISSING index.md
- guides/ - MISSING index.md
- meta/ - MISSING index.md ← **Priority 0 fix**
- project-tracking/ - MISSING index.md ← **Priority 0 fix**
- retrospectives/ - MISSING index.md
- sessions/ - MISSING index.md
- tech-debt/ - MISSING index.md
- technical-notes/ - MISSING index.md
- workflow/ - MISSING index.md

**user-guide/ subdirectories:**
- features/ - MISSING index.md

### Priority 0 Focus

For this PR, create index.md files ONLY for the ambiguous categories:

1. `content/internal/analysis/index.md` ← Clarifies "Analysis"
2. `content/internal/meta/index.md` ← Clarifies "Meta"
3. `content/internal/project-tracking/index.md` ← Clarifies project tracking

**Remaining index.md files:** Address in Priority 1-4 work (Session 2)

### Solution

Create 3 index.md files with clear descriptions and file listings (templates provided in Issue 3).

---

## Summary of Fixes

### Files to Modify

1. **quartz.config.ts** - Add "archive" to ignorePatterns (line 20)
2. **content/internal/analysis/index.md** - CREATE
3. **content/internal/meta/index.md** - CREATE
4. **content/internal/project-tracking/index.md** - CREATE

### Files to Delete

5. **content/developer-guide/technical-reference/Performance/Performance-Optimization.md** - DELETE (empty)
6. **content/internal/meta/WikiLinks.md** - DELETE (empty)

**Total changes:** 6 files (1 modified, 3 created, 2 deleted)

### Testing Checklist

After implementing fixes:

- [ ] Run `npx quartz build` - must succeed
- [ ] Verify `public/bugs/` does NOT exist
- [ ] Verify `public/projects/` does NOT exist
- [ ] Verify 3 new index.md files render correctly
- [ ] Check Explorer dropdown structure - no orphaned links
- [ ] Verify "Analysis", "Meta", and "project-tracking" have clear purposes
- [ ] Test live site after deployment

---

## Impact Assessment

**Before:**
- ❌ 2 stale directories (bugs, projects) visible in Explorer
- ❌ 2 empty files serving no purpose
- ❌ 3 categories with unclear purposes
- ❌ 20 directories without landing pages

**After:**
- ✅ Archive content completely excluded from live site
- ✅ All files have content or are removed
- ✅ Clear category descriptions via index.md
- ✅ 3 new landing pages for better navigation
- ⏭️ 17 remaining index.md files deferred to Priority 1-4

**User Experience:**
- Clear, unambiguous category names
- No stale content polluting navigation
- Consistent organization across major sections
- Improved discoverability

---

## Next Steps

1. **User Review:** Review this findings report
2. **Implement Fixes:** Create/modify 6 files
3. **Test Locally:** Verify Quartz build succeeds
4. **Create PR:** Submit for review
5. **Deploy:** Merge and auto-deploy to live site
6. **Verify:** Check live site Explorer

**Estimated Time:** 30-60 minutes implementation + testing

---

## Questions for User

Before implementing, please confirm:

1. **Empty files:** OK to delete Performance-Optimization.md and WikiLinks.md? Or should content be restored?
2. **Meta category:** Keep as "meta" or rename to "documentation-meta" for clarity?
3. **Index.md scope:** Create only 3 index.md files now, or all 20?

Awaiting your feedback to proceed!

---

**Report Status:** Complete
**Ready for Implementation:** Yes (pending user confirmation)
**Confidence Level:** High (95%+)
