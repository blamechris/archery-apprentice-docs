# Agent D - Session 2 Kickoff: Documentation Cleanup & Live Site Fixes

**Date:** 2025-11-01
**Session:** Week 12 Day 6 (Documentation continuation)
**Agent:** Agent D (Documentation)
**Orchestrator:** Agent O

---

## Mission Overview

Continue documentation transformation with **URGENT live site fixes** discovered by user, then proceed with planned Session 2 improvements.

---

## PRIORITY 0: Live Site Critical Fixes (NEW - 4 hours)

**Problem:** User identified issues on https://www.blamechris.com/archery-apprentice-docs/

### Issue 1: Explorer Dropdown - Capitalization Inconsistency

**Location:** Left sidebar "Explorer" dropdown (appears to be Table of Contents)

**Issues Found:**
- "bugs" - lowercase (should be "Bugs")
- "projects" - lowercase (should be "Projects")
- Others appear properly capitalized

**Root Cause:** Likely filename or frontmatter title inconsistency

**Fix:**
1. Find files for "bugs" and "projects" sections
2. Check if issue is:
   - Filename capitalization (bugs.md vs Bugs.md)?
   - Frontmatter `title:` field?
   - Directory name?
3. Standardize to proper capitalization
4. Test in local Quartz build
5. Verify fix on live site after deployment

### Issue 2: Explorer Dropdown - Orphaned Links

**Problem:** Top-level Explorer has loose links not organized into subsections:

**Orphaned Links Found:**
- Build Quality Patterns and Test Best Practices
- CI/CD Infrastructure - Self-Hosted Runners
- Documentation-Cross-Reference
- Next Session Focus
- Performance-Optimization
- settings-architecture
- V2.0 Release Completion - Session 2025-10-18
- WikiLinks

**Expected:** These should be grouped under logical subsections (not floating at top level)

**Investigation Needed:**
1. Where do these files actually live? (check file paths)
2. Why aren't they grouped under user-guide/, developer-guide/, or internal/?
3. Are they missing frontmatter that would place them correctly?

**Potential Causes:**
- Missing or incorrect frontmatter
- Files in wrong directory
- Quartz configuration issue (Explorer plugin settings)

**Fix Strategy:**
1. Locate each orphaned file
2. Determine correct category (user/developer/internal)
3. Move to appropriate directory OR update frontmatter
4. Add to relevant index.md navigation
5. Test Explorer rendering

### Issue 3: Confusing Top-Level Categories

**User Questions:**
- "What is Analysis for?" - Unclear purpose
- "What does Meta group contain?" - Not self-explanatory
- "Project-Overview vs projects?" - Naming collision/confusion

**Fix Strategy:**
1. Review current top-level structure in Explorer
2. Rename ambiguous categories:
   - "Analysis" → Clarify purpose or move content
   - "Meta" → Rename to "Documentation Meta" or similar
   - Resolve "Project-Overview" vs "projects" collision
3. Update index.md files with clear descriptions
4. Consider consolidation if categories overlap

### Issue 4: Subsection Organization Inconsistency

**Problem:** Explorer has subsections with sub-pages, but many don't

**Example:** User-guide/, developer-guide/, internal/ have nested structure, but loose pages don't

**Expected:** All major sections should have consistent organization

**Investigation:**
1. Audit all top-level Explorer items
2. Identify which SHOULD have subsections but don't
3. Group related content
4. Create index.md landing pages where missing

---

## PRIORITY 1-4: Session 2 Planned Work (26 hours)

**Refer to:** `NEXT-SESSION-DOCS-IMPROVEMENTS.md` for full details

### Priority 1 (was Priority 6): Bulk Rename to kebab-case (8 hours)
- Standardize ALL directory/file names to kebab-case
- ~100 directories affected
- Create migration script with dry-run mode
- Execute in batches, test after each

### Priority 2 (was Priority 7): Consolidate Duplicates (12 hours)
- Move ALL content from root/ to content/ (single source of truth)
- Resolve Testing/, Architecture/, Flows/, Firebase/ duplicates
- Update cross-references

### Priority 3 (was Priority 8): Flatten Technical Reference (6 hours)
- Reduce max depth to 3 levels everywhere
- Flatten technical-reference/API/DAOs/ → technical-reference/api/daos/
- Flatten Code-Examples structure

### Priority 4 (was Priority 9): Consolidate Internal Sprawl (8 hours)
- Reduce 16 internal/ folders → 6-8 categories
- Create archive/ for stale content
- Move technical-notes/ to developer-guide/

---

## Recommended Execution Order

**Day 1 (4 hours):**
1. **URGENT:** Investigate live site Explorer issues
2. Fix capitalization (bugs, projects)
3. Categorize orphaned links
4. Clarify ambiguous categories (Analysis, Meta, projects)
5. Create PR for live site fixes
6. Deploy and verify

**Day 2-3 (8 hours):**
7. Priority 1: Bulk rename to kebab-case (create script, dry-run, execute in batches)

**Day 3-5 (12 hours):**
8. Priority 2: Consolidate duplicates (root/ → content/)

**Day 5 (6 hours):**
9. Priority 3: Flatten technical reference (max 3 levels)

**Day 6-7 (8 hours):**
10. Priority 4: Consolidate internal sprawl (16 → 6-8 folders)

**Total Estimated Time:** 30 hours (4 hours urgent + 26 hours planned)

---

## Investigation Checklist (Live Site Issues)

**For Capitalization:**
- [ ] Check `content/bugs.md` or `content/bugs/index.md` (or similar)
- [ ] Check frontmatter `title:` field
- [ ] Check directory name casing
- [ ] Check Quartz Explorer plugin configuration
- [ ] Test local build
- [ ] Verify on live site

**For Orphaned Links:**
- [ ] Use `find` or `grep` to locate each orphaned file
- [ ] Check frontmatter for categorization clues
- [ ] Determine if file should move OR frontmatter should update
- [ ] Verify not caused by missing index.md
- [ ] Test Explorer rendering after fixes

**For Category Confusion:**
- [ ] List all top-level Explorer categories
- [ ] Document purpose of each (Analysis, Meta, etc.)
- [ ] Identify naming collisions (Project-Overview vs projects)
- [ ] Propose renames for clarity
- [ ] Update index.md descriptions

---

## Testing Requirements

**After each change:**
- [ ] Run `npx quartz build` - must succeed
- [ ] Check for broken links (grep)
- [ ] Verify Git history preserved (git log --follow)
- [ ] Review local Obsidian vault navigation
- [ ] Check Explorer dropdown structure
- [ ] Commit with clear message (NO attribution)

**Before creating PR:**
- [ ] All tests passing
- [ ] No broken links
- [ ] Explorer renders correctly
- [ ] Capitalization consistent
- [ ] No orphaned links
- [ ] Clear category names

---

## Success Criteria

**Live Site Fixes (Priority 0):**
- [ ] "bugs" and "projects" properly capitalized
- [ ] All orphaned links categorized into subsections
- [ ] Ambiguous categories renamed/clarified
- [ ] Consistent subsection organization
- [ ] User can navigate intuitively

**Session 2 Improvements (Priority 1-4):**
- [ ] 100% kebab-case naming (no PascalCase)
- [ ] Single source of truth (all in content/)
- [ ] Max 3 levels deep everywhere
- [ ] internal/ reduced to 6-8 categories
- [ ] All tests passing

---

## Key Files to Reference

**For Live Site Investigation:**
- `quartz.config.ts` - Explorer plugin configuration
- `content/index.md` - Main landing page
- `content/*/index.md` - Category landing pages
- Check frontmatter in all orphaned files

**For Session 2 Work:**
- `NEXT-SESSION-DOCS-IMPROVEMENTS.md` - Full execution plan
- Previous session analysis (7,000+ word report)
- PR #30 (merged Quick Wins) for reference

---

## Important Reminders

**Git Workflow:**
- ✅ Create feature branch: `docs/session-2-live-site-fixes`
- ✅ Make changes, commit in logical batches
- ✅ Create PR (NO attribution anywhere!)
- ✅ Wait for user review and merge
- ✅ GitHub Actions auto-deploys to live site

**Style Guidelines:**
- NO attribution in commits (ZERO ATTRIBUTION POLICY)
- Use kebab-case for all files and folders
- Max 3 levels deep
- index.md only (no README.md)
- YAML frontmatter preferred

**Communication:**
- Ask user for clarification if:
  - Intended category for orphaned files is unclear
  - Duplicate content resolution needs decision
  - Archive policy age threshold needed
- Document all decisions in PR description

---

## Ready to Start!

**Your first actions:**
1. Create feature branch: `docs/session-2-live-site-fixes`
2. Investigate Explorer capitalization issues
3. Locate orphaned link files
4. Analyze category confusion
5. Create findings report for user review
6. Implement fixes in Priority 0 order
7. Create PR for live site fixes

**After Priority 0 complete:**
8. Resume Session 2 planned work (Priority 1: kebab-case)

---

## Context Carryover from Session 1

**Completed (PR #30 - MERGED):**
- ✅ 61 stub README.md files deleted
- ✅ Redundant nesting flattened
- ✅ Project tracking consolidated
- ✅ User features organized
- ✅ KMP migration index created

**Impact:** 91 files changed, -531 lines, cleaner structure

**Outstanding PRs (not blocking):**
- PR #28: Navigation improvements (awaiting user review)
- PR #29: Week 12 vault update (awaiting user review)

---

**Orchestrator Notes:**
- Agent D is primary for this work
- No dependencies on other agents
- User will review all PRs before merge
- Auto-deployment happens on merge to main
- Estimated total time: 30 hours over 1-2 weeks

Good luck! 🚀
