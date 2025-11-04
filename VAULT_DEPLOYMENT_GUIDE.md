# Vault Deployment Guide

**Purpose:** Standardized methodology for deploying weekly KMP migration vault entries
**Audience:** Agent D (Documentation), future documentation maintainers
**Last Updated:** 2025-11-01

---

## Overview

The **Vault** is the comprehensive archive of KMP migration work, organized by week. Each week's work is documented through individual agent summaries stored in:

```
content/internal/kmp-migration/week-X/
```

This guide ensures consistent, high-quality vault deployments for all future weeks.

---

## Vault Structure

### Directory Organization

```
content/internal/kmp-migration/
├── week-2-completion-kmp-migration.md      # Early weeks (single file)
├── week-2-final-completion.md
├── week-5-8-overall-status.md
├── week-5-service-migration.md
├── week-6-7-database-planning.md
├── week-7-8-pattern-3-implementation.md
├── week-7-8-test-coverage.md
├── week-9/                                  # Multi-agent weeks (directory)
│   ├── agent-1-aap-week-9-summary.md       # Agent 1 (Architecture)
│   ├── agent-2-aam-week-9-summary.md       # Agent 2 (Implementation)
│   ├── agent-3-aaa-week-9-summary.md       # Agent 3 (Validation)
│   └── agent-o-week-9-orchestration-summary.md  # Orchestrator
├── week-12-summary.md                       # Agent D weeks (single file)
├── week-13-14/                              # Multi-agent weeks (directory)
│   ├── agent-1-aap-week-13-14-summary.md
│   ├── agent-2-aam-week-13-14-summary.md
│   ├── agent-3-aaa-week-13-14-summary.md
│   └── agent-o-week-13-14-orchestration-summary.md
└── weeks/                                   # Future expansion (TBD)
```

### When to Use Directory vs Single File

**Use Directory Structure (`week-X/`) when:**
- Multiple agents participated (AAP, AAM, AAA, Agent O)
- Complex multi-day work requiring individual agent summaries
- Orchestration summary needed to tie work together

**Use Single File (`week-X-summary.md`) when:**
- Single agent work (e.g., Agent D documentation)
- Simple, focused task completion
- No multi-agent coordination needed

**Week 13-14 Example:** Multi-agent → directory with 4 summaries

---

## Agent Summary Format

### Required Components

Every agent summary MUST include:

1. **Header Block**
```markdown
# Agent [ID] ([Role]) - Week [X] Summary

**Agent:** Agent [ID] ([Full Role Name])
**Week:** [Week Number]
**Date:** YYYY-MM-DD
**Status:** ✅ COMPLETE / ⏳ IN PROGRESS
```

2. **Role Overview**
- Brief description of agent's role in this week
- High-level contribution summary

3. **Key Contributions**
- Major deliverables
- Specific achievements
- Quantified results where possible

4. **Collaboration & Coordination**
- How agent worked with other agents
- Communication highlights
- Handoffs and dependencies

5. **Metrics**
- Quantified performance (time, files, errors, etc.)
- Quality indicators
- Efficiency measurements

6. **Lessons Learned**
- What went well
- What could be better
- Key takeaways

7. **Related Documentation**
- Links to vault entries for other agents
- Links to technical docs
- Links to PRs or main repo docs

8. **Footer**
```markdown
---

**Last Updated:** YYYY-MM-DD
**Status:** [Current status and next steps]
**Next:** [What comes next for this agent]
```

---

## Content Guidelines

### Writing Style

**Professional and Concise:**
- Use clear, direct language
- Focus on facts and results
- Quantify when possible

**Structure Over Narrative:**
- Use sections and subsections liberally
- Bullet points for lists
- Tables for comparisons
- Code blocks for examples

**Examples:**

✅ **GOOD:**
```markdown
**Phase 1a Validation:**
- 13-check protocol executed
- Result: 13/13 PASSED
- Duration: ~1 hour
- Status: APPROVED for Phase 1c
```

❌ **BAD:**
```markdown
**Phase 1a Validation:**
The agent worked really hard on validating Phase 1a and it went really well! Everything passed and we're excited to move forward to Phase 1c.
```

### Tone

**Objective and Data-Driven:**
- Avoid subjective praise or criticism
- Let metrics speak for themselves
- Use factual language

✅ **GOOD:** "Agent 3's 699-line guidance enabled 30-minute fix time for 81 errors"

❌ **BAD:** "Agent 3 was absolutely amazing and incredible"

### Attribution

**Follow Zero Attribution Policy:**
- No "Generated with Claude Code"
- No "Co-Authored-By: Claude"
- No AI attribution of any kind
- Focus on work outcomes, not who/what created it

---

## Agent-Specific Templates

### Agent 1 (AAP) - Architecture & Planning

**Focus Areas:**
- Planning documents created
- Architecture reviews conducted
- Critical discoveries (bugs, risks, issues)
- Module dependency validation
- Technical debt assessment
- Design decisions and rationale

**Key Metrics:**
- Planning doc count
- Review duration
- Critical bugs found
- Architecture approval status

**Example Sections:**
```markdown
## Planning Documents
[List of docs created with purposes]

## Architecture Review
**Status:** APPROVED / NEEDS REVISION
**Assessment:** [Key findings]
**Rating:** [Quality assessment]

## Critical Discoveries
[Bugs, risks, issues found]

## Technical Debt Assessment
[Accepted debt + optional improvements]
```

### Agent 2 (AAM) - Implementation

**Focus Areas:**
- Code implementation details
- Files changed
- Commits made
- Import path updates
- Test error fixes
- Build and compilation status
- Implementation challenges and solutions

**Key Metrics:**
- Duration (hours)
- Files changed
- Lines added/deleted
- Commits count
- Test pass rate
- Compilation errors fixed

**Example Sections:**
```markdown
## Phase [X] Implementation
**Objective:** [What was being built]
**Changes:** [Specific changes made]
**Commits:** [List of commits]

## Test Error Resolution
**Initial Status:** [Error count]
**Categories Fixed:** [Error types]
**Result:** [Final status]

## Metrics
- Duration: X hours
- Files changed: X files
- Commits: X commits
- Test pass rate: X%
```

### Agent 3 (AAA) - Validation & Analysis

**Focus Areas:**
- Validation protocols executed
- Check results (X/X PASSED)
- Test error analysis
- Fix guidance provided
- Quality metrics
- Validation methodology

**Key Metrics:**
- Checks performed
- Pass rate
- Errors analyzed
- Fix guidance length (lines)
- Validation duration

**Example Sections:**
```markdown
## [Phase] Validation
**Protocol:** X-Check Validation
**Checks Performed:** X
**Checks Passed:** X
**Pass Rate:** X%
**Result:** APPROVED / NEEDS FIXES

## Test Error Analysis
**Errors Analyzed:** X
**Categories Created:** X
**Fix Guidance:** X lines
**Impact:** [How it helped]

## Validation Methodology
[How validation was conducted]
```

### Agent O - Orchestration

**Focus Areas:**
- Multi-agent coordination timeline
- Workflow orchestration
- Agent performance assessment
- Process improvements
- Overall session metrics
- Success criteria evaluation

**Key Metrics:**
- Session duration
- Agent count
- Parallel execution instances
- Time saved through parallelization
- Overall quality grade

**Example Sections:**
```markdown
## Timeline & Workflow
**Hour 0-X:** [Agent X doing Y]
**Hour X-Y:** [Parallel work]

## Agent Performance Summary
### Agent 1 (AAP) - [Role] ⭐⭐⭐⭐⭐
[Key contributions]
**Rating:** [Stars + rationale]

## Process Improvements
[What changed/improved]

## Success Criteria Met
✅ [Criterion 1]
✅ [Criterion 2]
```

---

## Deployment Workflow

### Step 1: Identify Source Documentation

**Locate Primary Source:**
- Main technical documentation (e.g., `week-13-14-database-cutover.md`)
- Agent coordination documents (in main repo)
- PR descriptions and commits
- Validation reports
- Planning documents

**Example:**
```
Source: content/developer-guide/architecture/week-13-14-database-cutover.md
Contains: Complete technical overview of the work
```

### Step 2: Create Vault Directory

```bash
# For multi-agent weeks
mkdir -p content/internal/kmp-migration/week-X

# Verify structure
ls content/internal/kmp-migration/week-X/
# Should be empty, ready for summaries
```

### Step 3: Write Agent Summaries

**Order of Creation:**
1. Agent 1 (AAP) - Architecture (planning/review)
2. Agent 2 (AAM) - Implementation (main work)
3. Agent 3 (AAA) - Validation (testing/verification)
4. Agent O - Orchestration (coordination summary)

**Rationale:** Build from planning → implementation → validation → orchestration

**File Naming Convention:**
```
agent-[id]-[role-abbrev]-week-[X]-summary.md
```

**Examples:**
- `agent-1-aap-week-13-14-summary.md`
- `agent-2-aam-week-13-14-summary.md`
- `agent-3-aaa-week-13-14-summary.md`
- `agent-o-week-13-14-orchestration-summary.md`

### Step 4: Extract Information Systematically

**For Each Agent:**

1. **Review Source Material**
   - Read main technical doc
   - Review PR commits
   - Check validation reports
   - Read planning docs

2. **Extract Agent-Specific Content**
   - What did THIS agent do?
   - What were THEIR specific contributions?
   - What metrics apply to THIS agent?

3. **Quantify Everything**
   - Count files, commits, errors, checks
   - Measure duration, pass rates, efficiency
   - Use concrete numbers, not vague descriptions

4. **Document Collaboration**
   - How did this agent work with others?
   - What handoffs occurred?
   - What dependencies existed?

5. **Capture Lessons**
   - What worked well for THIS agent?
   - What could THIS agent do better?
   - What did THIS agent learn?

### Step 5: Cross-Link Vault Entries

**Internal Vault Links:**
```markdown
## Related Documentation

**Implementation:**
- [[agent-2-aam-week-13-14-summary|Agent 2 Implementation Summary]]

**Validation:**
- [[agent-3-aaa-week-13-14-summary|Agent 3 Validation Summary]]

**Orchestration:**
- [[agent-o-week-13-14-orchestration-summary|Agent O Orchestration Summary]]
```

**Technical Documentation Links:**
```markdown
**Technical:**
- [[../../developer-guide/architecture/week-13-14-database-cutover|Week 13-14 Database Cutover Documentation]]
```

**External Links (Main Repo):**
```markdown
**PR:**
- PR #197: https://github.com/blamechris/archery-apprentice/pull/197
```

### Step 6: Quality Review

**Self-Check Criteria:**

✅ **Structure:**
- [ ] Header block present and complete
- [ ] All required sections included
- [ ] Footer present with status and next steps
- [ ] Consistent formatting throughout

✅ **Content:**
- [ ] Facts are accurate (verify against source)
- [ ] Metrics are quantified (no vague descriptions)
- [ ] Agent role is clear (what did THIS agent do?)
- [ ] Collaboration is documented (how did agents work together?)

✅ **Style:**
- [ ] Professional and concise writing
- [ ] Bullet points for lists
- [ ] Code blocks for examples
- [ ] Tables for comparisons

✅ **Links:**
- [ ] All internal links use wiki-link format: `[[path/to/file|Display Text]]`
- [ ] All links are valid (files exist)
- [ ] Cross-references to other agents present
- [ ] Technical doc links included

✅ **Attribution:**
- [ ] Zero Attribution Policy followed
- [ ] No "Generated with Claude Code"
- [ ] No "Co-Authored-By: Claude"
- [ ] Focus on work, not attribution

### Step 7: Test Quartz Build

```bash
# Test build
npx quartz build

# Expected output:
# - No errors
# - All links valid
# - Vault entries accessible
```

**Verify:**
- Build completes successfully
- No broken links reported
- Vault entries render correctly

### Step 8: Create PR

**Branch Naming:**
```bash
git checkout -b docs/week-X-vault-deployment
```

**Commit Message Format:**
```bash
git add content/internal/kmp-migration/week-X/
git commit -m "docs: Deploy Week X vault entries

Week X [Brief description] vault deployment with comprehensive agent summaries.

Vault Entries (4):
- Agent 1 (AAP): [Key contribution]
- Agent 2 (AAM): [Key contribution]
- Agent 3 (AAA): [Key contribution]
- Agent O: Orchestration summary

Source Documentation:
- [Main technical doc name]

Metrics:
- [Key metric 1]
- [Key metric 2]
- [Key metric 3]

Testing:
- Quartz build: passing
- Links verified: all valid
- Formatting: consistent

[Additional notes if needed]"
```

**NO ATTRIBUTION** - Follow Zero Attribution Policy

**Push and Create PR:**
```bash
git push origin docs/week-X-vault-deployment
gh pr create --title "docs: Week X Vault Deployment" --body "[Use commit message content]"
```

---

## Quality Standards

### Consistency

**All vault entries for a week should:**
- Use consistent terminology
- Reference same metrics (duration, file counts, etc.)
- Tell a cohesive story across agents
- Cross-link to each other

**Example:**
If Agent 2 says "Fixed 81 errors in 30 minutes", Agent 3 should reference the same numbers when discussing their guidance document.

### Completeness

**Required Information:**
- What was done (specific deliverables)
- How it was done (methodology)
- How long it took (duration)
- What the result was (outcome)
- How it relates to other agents (collaboration)

**Avoid:**
- Vague descriptions ("worked on migration")
- Missing metrics ("took a while")
- Unclear outcomes ("mostly done")

### Accuracy

**Verify All Facts:**
- Check file counts against actual changes
- Verify commit counts in git history
- Confirm test pass rates from build logs
- Cross-reference with source documentation

**Source of Truth:**
1. Main technical documentation (e.g., `week-13-14-database-cutover.md`)
2. PR commits and descriptions
3. Validation reports
4. Agent coordination documents

---

## Metrics to Include

### Common Metrics (All Agents)

**Duration:**
- Total session time
- Time spent on specific tasks
- Time saved through optimization

**Files:**
- Files created
- Files modified
- Files deleted

**Quality:**
- Test pass rate
- Compilation errors (before/after)
- Validation check pass rate

**Efficiency:**
- Parallel execution instances
- Time saved vs sequential approach
- Errors fixed per hour

### Agent 1 (AAP) Specific

- Planning documents created
- Review duration
- Critical bugs found
- Architecture approvals issued
- Technical debt items identified

### Agent 2 (AAM) Specific

- Commits created
- Lines added/deleted
- Import paths updated
- Entities/DAOs/Services migrated
- Build errors fixed

### Agent 3 (AAA) Specific

- Validation checks performed
- Validation pass rate
- Test errors analyzed
- Fix guidance length (lines)
- Validation protocol complexity (check count)

### Agent O Specific

- Agents coordinated
- Parallel execution instances
- Session duration (end-to-end)
- PRs created
- Overall team efficiency metrics

---

## Common Patterns

### Architecture Review (Agent 1)

```markdown
## Architecture Review

**Status:** ✅ APPROVED

**Assessment:** "Agent 2 should proceed with confidence. The architecture is solid."

**Key Findings:**
- Module boundaries clean (one-way dependency)
- No circular dependencies detected
- Data preservation strategy verified
- KMP best practices followed
- Technical debt remains LOW

**Rating:** CLEAN ARCHITECTURE ✅
```

### Implementation Details (Agent 2)

```markdown
## Phase [X] Implementation

### Entities Migrated
- `Entity1.kt` - [Purpose]
- `Entity2.kt` - [Purpose]
- `Entity3.kt` - [Purpose]

### Migration Pattern
```kotlin
// FROM (Android-only)
app/.../domain/models/Entity.kt

// TO (KMP-compatible)
shared/database/.../entities/Entity.kt
```

### Commits
1. `abc1234` - [Description]
2. `def5678` - [Description]
```

### Validation Results (Agent 3)

```markdown
## [Phase] Validation

**Protocol:** X-Check Validation

**Checks Performed:**
1. ✅ [Check 1 description]
2. ✅ [Check 2 description]
3. ✅ [Check 3 description]
[... all X checks]

**Result:** X/X checks PASSED (100%) ✅

**Status:** APPROVED for [next phase] ✅
```

### Orchestration Timeline (Agent O)

```markdown
## Timeline & Workflow

**Hour 0-1: Planning (Agent 1)**
- Created 3 planning documents
- Defined success criteria
- Established validation protocol

**Hour 1-3: Implementation (Agent 2)**
- [Specific work done]
- [X commits, Y files]

**Hour 3-4: Validation (Agent 3)**
- [Validation work]
- [Result: X/X PASSED]

**Hour 4-5: Parallel Reviews (Agent 1 + Agent 3)**
- [What each agent reviewed]
- [Time saved: ~X hour]
```

---

## Anti-Patterns to Avoid

### ❌ DON'T: Vague Descriptions

**BAD:**
```markdown
Agent 2 worked on the migration and made good progress. Things went well overall.
```

**GOOD:**
```markdown
**Phase 1c Implementation:**
- Migrated 3 entities (Round, EndScore, ArrowScore)
- Updated 151+ import paths across all modules
- Fixed 81 test compilation errors in 30 minutes
- Result: 100% test pass rate
```

### ❌ DON'T: Missing Metrics

**BAD:**
```markdown
The validation took a while but everything passed.
```

**GOOD:**
```markdown
**Validation Duration:** ~1 hour
**Checks Performed:** 13
**Checks Passed:** 13
**Pass Rate:** 100%
**Status:** APPROVED
```

### ❌ DON'T: Ignore Collaboration

**BAD:**
```markdown
[Only documents solo work, ignores other agents]
```

**GOOD:**
```markdown
## Collaboration & Coordination

### With Agent 3 (AAA)
**Fix Guidance:**
- Agent 3 created 699-line categorization
- Enabled 30-minute fix time for 81 errors
- Systematic approach proved highly effective
```

### ❌ DON'T: Break Attribution Policy

**BAD:**
```markdown
🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
```

**GOOD:**
```markdown
[No attribution whatsoever - just content]
```

---

## Troubleshooting

### Issue: Can't find agent-specific information

**Solution:**
- Read main technical doc thoroughly
- Check PR commits (git log)
- Review validation reports
- Look at planning documents
- Infer from agent role and typical responsibilities

### Issue: Metrics don't match across agents

**Solution:**
- Use source of truth (main technical doc)
- Cross-verify with git history
- Ensure all agents reference same numbers
- Update all summaries to match

### Issue: Links broken after deployment

**Solution:**
- Verify file paths are correct
- Use wiki-link format: `[[path/file|Text]]`
- Test with Quartz build before committing
- Check relative paths from vault location

### Issue: Unclear what agent did vs others

**Solution:**
- Focus on agent's specific role
- Agent 1: Planning, review, architecture
- Agent 2: Implementation, coding, commits
- Agent 3: Validation, testing, analysis
- Agent O: Coordination, process, overall metrics

---

## Checklist for Deployment

**Pre-Deployment:**
- [ ] Source documentation identified and reviewed
- [ ] Vault directory created (if multi-agent)
- [ ] Agent roles and contributions clear

**During Writing:**
- [ ] Agent 1 summary: Planning, review, critical discoveries
- [ ] Agent 2 summary: Implementation details, commits, metrics
- [ ] Agent 3 summary: Validation, test analysis, quality
- [ ] Agent O summary: Coordination, timeline, overall assessment

**Quality Review:**
- [ ] All required sections present
- [ ] Metrics quantified (no vague language)
- [ ] Cross-links to other agents included
- [ ] Zero Attribution Policy followed
- [ ] Professional, concise writing
- [ ] Code examples formatted correctly

**Testing:**
- [ ] Quartz build passes
- [ ] All links valid
- [ ] Formatting renders correctly

**Deployment:**
- [ ] Branch created (`docs/week-X-vault-deployment`)
- [ ] Commit message follows format (NO ATTRIBUTION)
- [ ] PR created with clear description
- [ ] PR title follows convention

---

## Examples

### Week 9 Vault Deployment

**Location:** `content/internal/kmp-migration/week-9/`

**Entries:**
- `agent-1-aap-week-9-summary.md` - Context-dependent service migrations
- `agent-2-aam-week-9-summary.md` - Gson → kotlinx.serialization
- `agent-3-aaa-week-9-summary.md` - Validation and prep work
- `agent-o-week-9-orchestration-summary.md` - Emergency runner incident + coordination

**Highlights:**
- Agent 3 MVP for scope reduction (5 entities → 1 entity, saved 3-4 hours)
- Emergency incident response documented
- Process improvements (PR title convention, communication protocol)

### Week 13-14 Vault Deployment

**Location:** `content/internal/kmp-migration/week-13-14/`

**Entries:**
- `agent-1-aap-week-13-14-summary.md` - Architecture planning and review
- `agent-2-aam-week-13-14-summary.md` - Big Bang Database Cutover implementation
- `agent-3-aaa-week-13-14-summary.md` - Validation and test error analysis
- `agent-o-week-13-14-orchestration-summary.md` - Multi-agent coordination

**Highlights:**
- Agent 1 critical database name bug discovery
- Agent 2 clean implementation (8 commits, 243 files)
- Agent 3 systematic error categorization (699-line guidance)
- Parallel reviews saved time
- 100% test pass rate achieved

---

## Future Improvements

**Potential Enhancements:**

1. **Automated Metrics Extraction**
   - Parse git history automatically
   - Extract file counts, line changes
   - Generate baseline metrics

2. **Template Generation**
   - Auto-generate skeleton summaries
   - Pre-fill known metrics
   - Agent fills in specifics

3. **Cross-Reference Validation**
   - Verify all agents reference same metrics
   - Check for consistency
   - Flag discrepancies

4. **Visual Diagrams**
   - Add architecture diagrams to vault
   - Timeline visualizations
   - Agent interaction diagrams

---

**This guide ensures consistent, high-quality vault deployments that preserve the complete history of the KMP migration work.**

**Last Updated:** 2025-11-01
**Maintainer:** Agent D (Documentation)
**Version:** 1.0
