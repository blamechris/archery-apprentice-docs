# Claude Development Notes - Archery Apprentice Docs

Essential guidelines for working with Claude on the archery-apprentice-docs repository.

## 🚨 CRITICAL: Zero Attribution Policy

**This applies to ALL commits, PRs, and git operations in this repository:**

### ❌ NEVER Include:
- "Generated with Claude Code" (anywhere in git history)
- "Generated with Claude" (anywhere in git history)
- "Co-Authored-By: Claude" (in commits)
- "Co-Authored-By: Agent D" (in commits)
- "Co-Authored-By: Agent [any]" (in commits)
- Any AI/Claude/Agent attribution in commits
- Any AI/Claude/Agent attribution in PR descriptions
- Any AI/Claude/Agent attribution in PR titles
- Emojis like 🤖 associated with AI generation

### ✅ What This Means:
- **User is the SOLE AUTHOR** of all documentation and commits
- Claude/Agents prepare changes, user commits them
- All git history shows user as author, period
- This is non-negotiable across ALL repositories

### ✅ Correct Commit Message Format:
```
docs: Brief description of what changed

Detailed explanation of changes:
- Specific change 1
- Specific change 2
- Specific change 3

Impact: X files changed, outcome achieved

Testing:
- Quartz build: passing
- Broken links: none found
- Navigation: verified
```

### ✅ Correct PR Description Format:
```
Brief summary of what this PR accomplishes.

Changes:
- List of changes made
- Impact metrics (files changed, lines added/removed)

Testing:
- Quartz build status
- Link verification results
- Navigation verification

Next steps: What comes after this PR
```

### ❌ Incorrect Examples:
**WRONG - Commit message**
```
docs: Update navigation

Fixed navigation issues.

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**WRONG - PR description**
```
This PR fixes navigation.

Generated with Claude Code assistance.
```

---

## Documentation Guidelines

### Naming Conventions
- **Files and directories:** kebab-case only
  - ✅ `kmp-migration-overview.md`
  - ❌ `KMP-Migration-Overview.md`
  - ❌ `kmp_migration_overview.md`

### Structure Rules
- **Max depth:** 3 levels (content/category/subcategory/)
- **Index files:** Use `index.md` only (no README.md)
- **Frontmatter:** YAML format preferred

### Quartz-Specific
- Test builds after changes: `npx quartz build`
- Verify no broken links
- Check Explorer rendering
- Test on live site after deployment

---

## Git Workflow

### Branch Naming
```
docs/<description>
```

Examples:
- `docs/fix-navigation-issues`
- `docs/reorganize-internal-structure`
- `docs/add-kmp-migration-guide`

### Commit Process
1. Make changes in feature branch
2. Test Quartz build (`npx quartz build`)
3. Commit with NO attribution (see above)
4. Push to origin
5. Create PR with NO attribution (see above)
6. Wait for user review and merge

### PR Workflow
1. Create PR in docs repo
2. User reviews (no CI checks required)
3. User merges when ready
4. GitHub Actions auto-deploys to https://www.blamechris.com/archery-apprentice-docs/
5. Wait 2-3 minutes for deployment
6. Verify changes on live site

---

## Enforcement

**If you add ANY form of attribution:**
- User will ask you to fix it
- You'll need to amend commit and force-push
- This wastes time - get it right the first time

**Check EVERY:**
- Commit message (no attribution in body or footer)
- PR description (no attribution anywhere)
- PR title (no attribution)
- Branch name (should not reference AI/agents)

**When in doubt:** NO ATTRIBUTION

---

## Repository Structure

```
archery-apprentice-docs/
├── content/                    # Main content (single source of truth)
│   ├── user-guide/            # User-facing documentation
│   ├── developer-guide/       # Developer documentation
│   └── internal/              # Internal notes and tracking
├── quartz.config.ts           # Quartz configuration
├── package.json               # Dependencies
└── CLAUDE.md                  # This file
```

---

## Testing Checklist

Before creating PR:
- [ ] Quartz build passes (`npx quartz build`)
- [ ] No broken links (grep verification)
- [ ] Git history preserved (for renames: `git log --follow`)
- [ ] Explorer navigation works
- [ ] Commit message has NO attribution
- [ ] PR description has NO attribution

---

## Common Tasks

### Rename Files (Preserve History)
```bash
git mv old-name.md new-name.md
# NOT: rm + touch (loses history)
```

### Test Quartz Build
```bash
npx quartz build
# Expected: BUILD SUCCESSFUL
```

### Verify No Broken Links
```bash
# After build, check public/ directory
find public/ -name "*.html" -exec grep -l "404" {} \;
# Expected: (no results)
```

---

## Emergency Commands

### Clean Rebuild
```bash
rm -rf public .quartz-cache
npx quartz build
```

### Fix Broken Git History
```bash
# If you committed with attribution by mistake:
git commit --amend  # Remove attribution lines
git push --force-with-lease origin <branch-name>
```

---

**Last Updated:** 2025-11-01
**Zero attribution policy established - applies to ALL git operations**
