# Documentation Structure Improvements - Session 2 Prompt

**Date Created:** 2025-11-01
**Previous Session:** Quick Wins (PR #30) ✅ MERGED
**Current Phase:** Short-Term Improvements (Week 2-3 work)
**Estimated Effort:** 26 hours

---

## Context: What We've Accomplished

### Comprehensive Structure Analysis Completed ✅

We conducted a thorough exploration of the entire documentation structure (268 markdown files, 35 directories) and identified 23 prioritized improvements. Full analysis available in session context.

**Key Findings:**
- Three-tier structure (user/developer/internal) is sound
- Execution issues: duplication, naming chaos, empty stubs, structural sprawl
- 80% of subsections are empty stubs
- Significant duplication between root/ and content/
- Mixed naming conventions (kebab-case, PascalCase, lowercase)

### Quick Wins Implementation ✅ (PR #30 - MERGED)

**Completed in Session 1 (~2 hours):**

1. **Deleted 61 stub README.md files** - Using index.md only
2. **Flattened redundant nesting** - Fixed kmp-migration/kmp-migration/, Data-Models/Data-Models/, analysis/Analysis/
3. **Consolidated project tracking** - Renamed project-status/ → project-tracking/
4. **Organized user features** - Created equipment/, scoring/, sync/ subdirectories with kebab-case names
5. **Created kmp-migration/index.md** - Comprehensive 180-line navigation hub

**Impact:** 91 files changed, -531 lines of redundant content, much cleaner structure

---

## Your Mission: Short-Term Improvements (Week 2-3)

Continue the documentation transformation by implementing the next 4 high-priority fixes. These are more involved than Quick Wins but have massive impact.

### Priority 6: Bulk Rename to kebab-case (8 hours)

**Problem:** Inconsistent naming across ~100 directories
- Mix of kebab-case (`api-reference`), PascalCase (`Code-Examples`, `Data-Models`), lowercase (`architecture`)
- Creates unpredictable URLs, hard to navigate, Git case-sensitivity issues

**Task:** Standardize ALL directory and file names to kebab-case

**Approach:**
1. Create migration script: `scripts/migration/rename-to-kebab-case.py`
   - Scan all directories in content/
   - Detect non-kebab-case names
   - Generate rename commands (git mv)
   - Update all markdown links automatically
   - Dry-run mode for preview

2. Execute renames in batches:
   - Batch 1: developer-guide/ directories (~50 dirs)
   - Batch 2: internal/ directories (~30 dirs)
   - Batch 3: user-guide/ directories (~20 dirs)

3. Test after each batch:
   - Check Quartz build
   - Verify no broken links
   - Git commit

**Examples:**
- `Code-Examples` → `code-examples`
- `Data-Models` → `data-models`
- `Common-Patterns` → `common-patterns`
- `Project-Management` → `project-management` (already done!)
- `Testing-Examples` → `testing-examples`

**Important Notes:**
- Use `git mv` to preserve history
- Update ALL links in markdown files (grep + sed)
- Test Quartz build after changes
- Commit in batches (not all at once)

### Priority 7: Consolidate Duplicates (12 hours)

**Problem:** Content exists in both root/ and content/ directories
- Testing/ in root vs developer-guide/testing/
- Architecture/ in root vs developer-guide/architecture/
- Flows/ in root vs developer-guide/technical-reference/Flows/
- Firebase/ in root vs developer-guide/technical-reference/ (needs creation)

**Task:** Move ALL content to content/ only (single source of truth)

**Approach:**
1. **Testing/ consolidation:**
   ```bash
   # Move root Testing/ → content/developer-guide/testing/
   git mv Testing/*.md content/developer-guide/testing/
   # Update frontmatter if needed
   # Delete empty Testing/ in root
   ```

2. **Architecture/ consolidation:**
   ```bash
   # Move root Architecture/ → content/developer-guide/architecture/
   # Check for duplicates (some may already exist)
   # Merge or keep newer version
   ```

3. **Flows/ consolidation:**
   ```bash
   # Already in content/developer-guide/technical-reference/Flows/
   # Move root Flows/ content if any exists
   ```

4. **Firebase/ consolidation:**
   ```bash
   # Create developer-guide/technical-reference/firebase/
   # Move root Firebase/ content
   ```

**Important Notes:**
- Check for duplicates before moving (same filename in both locations)
- If duplicate exists, compare content and keep better version
- Update all cross-references
- Add frontmatter to migrated files if missing

### Priority 8: Flatten Technical Reference (6 hours)

**Problem:** Max depth is 4+ levels, violates 3-level rule
- `technical-reference/API/DAOs/` (4 levels)
- `technical-reference/Code-Examples/Common-Patterns/` (4 levels)

**Task:** Reduce max depth to 3 levels everywhere

**Approach:**
1. **Flatten API structure:**
   ```
   Before: technical-reference/API/DAOs/
   After:  technical-reference/api/daos/

   Before: technical-reference/API/Repositories/
   After:  technical-reference/api/repositories/
   ```

2. **Flatten Code-Examples:**
   ```
   Before: technical-reference/Code-Examples/Common-Patterns/
   After:  technical-reference/code-examples/
   (use tags or file naming for categorization)
   ```

3. **Update navigation:**
   - Update developer-guide/index.md with new structure
   - Create index.md files for flattened sections

**Important Notes:**
- This combines with kebab-case standardization (Priority 6)
- Do kebab-case FIRST, then flatten
- Use tags in frontmatter for categorization instead of deep nesting

### Priority 9: Consolidate Internal Sprawl (8 hours)

**Problem:** 16 top-level folders in internal/ with overlapping purposes

**Task:** Reduce to 6-8 categories

**Approach:**
1. **Create archive/ folder:**
   ```bash
   mkdir content/internal/archive
   # Move stale content:
   git mv content/internal/experiments/ content/internal/archive/
   git mv content/internal/sessions/ content/internal/archive/ (older than 3 months)
   git mv content/internal/tech-debt/ content/internal/archive/
   ```

2. **Consolidate similar folders:**
   ```bash
   # technical-notes/ + development-patterns/ → Should be in developer-guide/
   # Move to developer-guide/how-to/best-practices/

   # code-graph/ → archive/ (old analysis)
   ```

3. **Final internal/ structure:**
   ```
   internal/
   ├── kmp-migration/ (keep - well organized)
   ├── agents/ (keep)
   ├── project-tracking/ (keep - already consolidated)
   ├── retrospectives/ (keep)
   ├── meta/ (keep - add archive/ sessions here)
   └── archive/ (create - experiments, stale analysis, old sessions)
   ```

**Important Notes:**
- Create internal/archive/README.md explaining archive policy
- Move technical-notes/ and development-patterns/ to developer-guide/
- Keep only active, relevant content in internal/

---

## Execution Plan

### Step 1: Bulk Rename to kebab-case (Day 1-2)
1. Write rename script with dry-run mode
2. Test on developer-guide/ first
3. Execute in batches, test after each
4. Commit with detailed message

### Step 2: Consolidate Duplicates (Day 2-3)
1. Compare root/ vs content/ versions
2. Move content to content/
3. Update cross-references
4. Test Quartz build

### Step 3: Flatten Technical Reference (Day 3)
1. Reduce depth to max 3 levels
2. Update navigation
3. Create missing index.md files

### Step 4: Consolidate Internal Sprawl (Day 3-4)
1. Create archive/
2. Move stale content
3. Relocate technical-notes/ to developer-guide/
4. Update internal/index.md

---

## Testing Checklist

After each major change:
- [ ] Run `npx quartz build` - must succeed
- [ ] Check for broken links (grep for moved files)
- [ ] Verify Git history preserved (git log --follow)
- [ ] Review Obsidian vault navigation
- [ ] Commit with clear message (NO attribution)

---

## Success Criteria

**By end of Session 2:**
- [ ] 100% kebab-case naming (no PascalCase or mixed case)
- [ ] Single source of truth (all content in content/ only)
- [ ] Max 3 levels deep everywhere
- [ ] internal/ reduced to 6-8 categories
- [ ] All tests passing (Quartz build, no broken links)

**Metrics:**
- Estimated ~100 directories renamed
- ~50 files moved from root/ to content/
- ~10 internal/ folders consolidated
- Total: ~150-200 file operations

---

## Important Files to Reference

**Analysis Report:** In previous session context (7,000+ word comprehensive analysis)
- 13 sections covering all aspects
- 23 prioritized recommendations
- Before/after structure proposals

**Key Documentation:**
- `content/index.md` - Main landing page
- `content/user-guide/index.md` - User guide landing (99 lines)
- `content/developer-guide/index.md` - Developer guide landing (147 lines)
- `content/internal/index.md` - Internal landing (143 lines)
- `content/internal/kmp-migration/index.md` - KMP migration hub (180 lines) ✨ NEW

**Previous PR:**
- PR #30: Quick Wins - Structure Improvements (MERGED)
- 91 files changed, -531 lines

---

## Script Templates

### Rename Script Outline (rename-to-kebab-case.py)

```python
#!/usr/bin/env python3
"""
Rename all directories to kebab-case and update markdown links.
Usage: python rename-to-kebab-case.py [--dry-run]
"""

import os
import re
import subprocess
from pathlib import Path

def to_kebab_case(name):
    """Convert PascalCase or Mixed-Case to kebab-case"""
    # Handle PascalCase: CodeExamples → code-examples
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1-\2', name)
    # Handle acronyms: APIReference → api-reference
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1-\2', s1)
    # Lowercase and clean up
    return s2.lower().replace('_', '-')

def find_non_kebab_dirs(root_path):
    """Find all directories that aren't kebab-case"""
    non_kebab = []
    for dirpath, dirnames, filenames in os.walk(root_path):
        for dirname in dirnames:
            kebab = to_kebab_case(dirname)
            if dirname != kebab and dirname.lower() != dirname:
                full_path = os.path.join(dirpath, dirname)
                non_kebab.append((full_path, kebab))
    return non_kebab

def update_markdown_links(old_path, new_path):
    """Update all markdown files that reference the old path"""
    # Find all .md files
    # Search for references to old path
    # Replace with new path
    # Use git mv for history preservation
    pass

def main():
    import sys
    dry_run = '--dry-run' in sys.argv

    root = Path('content')
    non_kebab = find_non_kebab_dirs(root)

    print(f"Found {len(non_kebab)} directories to rename:")
    for old_path, new_name in non_kebab:
        print(f"  {old_path} → {new_name}")

    if not dry_run:
        # Execute renames with git mv
        # Update markdown links
        # Commit
        pass

if __name__ == '__main__':
    main()
```

---

## Commit Message Template

```
docs: [Phase] - [What was done]

[Detailed description of changes]

Changes:
- [Specific change 1]
- [Specific change 2]
- [Specific change 3]

Impact: [Number] files changed
- [Renames, moves, deletions, creations]

Testing:
- Quartz build: passing
- Broken links: none found
- Git history: preserved

Part of documentation transformation project.
Next phase: [What's next]
```

---

## Questions to Ask User (If Needed)

1. **Kebab-case edge cases:**
   - Should acronyms be lowercase? (API → api or keep API?)
   - Component names in examples: ViewModel → view-model or ViewModel?

2. **Duplicate content resolution:**
   - If root/ and content/ have same file but different content, which to keep?
   - Merge both versions or choose newer?

3. **Archive policy:**
   - How old before archiving? (3 months? 6 months?)
   - Keep session docs or archive all?

4. **Technical notes migration:**
   - Move to developer-guide/how-to/ or developer-guide/technical-reference/?

---

## Additional Context

**Repository Status:**
- Branch: `main` (PR #30 merged)
- Previous branch: `docs/quick-wins-structure-fixes`
- Open PRs: #28 (Day 4 navigation), #29 (Week 12 completion)

**Current Structure:**
- 207 markdown files in content/ (after stub deletion)
- ~35 directories
- Quartz 4.5.2 static site generator
- Obsidian vault for editing

**Style Guidelines:**
- NO attribution in commits (ZERO ATTRIBUTION POLICY)
- Use kebab-case for all files and folders
- Max 3 levels deep
- index.md only (no README.md)
- YAML frontmatter preferred

---

## Ready to Resume!

**Your next message should be:**

"Agent D - Session 2: Short-Term Documentation Improvements

I'm continuing the documentation transformation project. Today's focus: kebab-case standardization, duplicate consolidation, flattening technical reference, and consolidating internal sprawl.

Starting with Priority 6: Bulk rename to kebab-case. I'll create the migration script first, run in dry-run mode for review, then execute in batches.

Let me begin by analyzing the current directory naming..."

---

**Session 1 Summary:**
- Comprehensive analysis: 268 files, 23 recommendations
- Quick Wins (PR #30): 5 high-impact fixes, 91 files changed
- Time: ~2 hours
- Result: Much cleaner, navigable structure

**Session 2 Goals:**
- Short-Term improvements: 4 priorities
- Estimated: 26 hours work (spread over 3-4 days)
- Expected: 100% kebab-case, single source of truth, max 3 levels

**Total Transformation Progress:**
- ✅ Quick Wins: Complete (5 of 23 recommendations)
- 🔄 Short-Term: In progress (4 of 23 recommendations)
- ⏭️ Medium-Term: Planned (8 of 23 recommendations)
- ⏭️ Long-Term: Planned (6 of 23 recommendations)

**Estimated Total Effort:** 180 hours (4.5 weeks)
**Completed So Far:** 2 hours (~1%)
**Next Phase:** 26 hours (~14%)

Good luck! 🚀
