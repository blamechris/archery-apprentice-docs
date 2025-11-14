# CLAUDE.md Conflict Prevention Protocol

**Status:** Active (Week 26+)
**Last Updated:** 2025-11-13 (Week 26 - PR #238 conflict resolution incident)
**Related:** [[Multi-Agent Coordination Protocol v2.0]], [[Agent Worktree Structure]]

---

## Problem Statement

CLAUDE.md serves two competing roles in the multi-agent workflow, creating a systemic conflict risk:

1. **Coordination Document** - Agents read it for current project state, patterns, and critical issues
2. **Living Documentation** - Agents update it frequently with new discoveries, patterns, and status changes

**Consequences:**
- Multiple agents work in parallel → frequent conflicts
- High write frequency: Almost every PR touches CLAUDE.md
- Manual conflict resolution required → human error risk
- Lost changes when conflicts resolved incorrectly

**Impact:** Week 26 alone had 3 CLAUDE.md conflicts across PRs #237, #238, and agent coordination work.

---

## Root Cause

CLAUDE.md conflicts stem from the standard git workflow pattern when multiple PRs are in flight:

1. **PR Creation:** PRs are created from point-in-time snapshots of `main`
2. **Parallel Work:** CLAUDE.md changes frequently while PRs are being reviewed
3. **Merge Order:** When PR A merges before PR B, PR B now has stale CLAUDE.md
4. **Conflict Resolution:** Requires judgment calls about which version to keep
5. **Human Error:** Orchestrator must manually resolve conflicts → mistakes happen

**The Core Issue:** CLAUDE.md is both high-value (coordination critical) and high-churn (updated frequently), creating maximum conflict potential.

---

## Week 26 Incident Example

### The Setup

**PR #237 (Orchestrator - Copilot Fix):**
- **Change:** Generic reference: "Assessment documentation pending finalization"
- **Reason:** Avoid cross-repo file references (docs repo may not exist in all contexts)
- **Status:** Merged first ✅

**PR #238 (Agent D - Reframing):**
- **Change:** Specific reference: "See docs/assessments/FIREBASE_REPOSITORY_ASSESSMENT.md for details"
- **Reason:** Better reframing language from "Incident #2" to "Assessment"
- **Status:** Created from earlier snapshot, conflicts with main

### The Error

**Conflict Resolution Decision:**
```diff
<<<<<<< HEAD (main - PR #237's version)
- Assessment documentation pending finalization
=======
- See docs/assessments/FIREBASE_REPOSITORY_ASSESSMENT.md for details
>>>>>>> PR #238
```

**Orchestrator's Choice:** Kept PR #238's version (specific file reference)
**Reasoning:** "Better reframing language"
**Mistake:** Lost the Copilot fix that intentionally made it generic

**Impact:**
- Cross-repo file reference added back to CLAUDE.md
- Broke Copilot's guideline about avoiding absolute paths
- Required additional commit to fix (reintroduced generic reference)

### Root Cause of Decision Error

**Prioritization Failure:** Focused on "reframing" language quality, not on "cross-repo reference" architectural principle.

**Missing Context:** Orchestrator didn't recall WHY PR #237 made it generic (Copilot's guidance).

**Process Gap:** No checklist to verify both versions' intentions before choosing.

---

## Prevention Protocol (3-Tier Approach)

### Tier 1: Immediate Actions (Week 26+)

#### Pre-Merge Sync Protocol

**For ANY PR touching CLAUDE.md:**

```bash
# Step 1: Sync with main BEFORE creating PR
git checkout your-feature-branch
git fetch origin main:main
git merge main

# If conflicts: Resolve NOW (easier with full context)
# If no conflicts: You're good to create PR

# Step 2: If PR already exists and main has changed
git fetch origin main:main
git rebase main  # or merge main, depending on preference

# Step 3: Force push to update PR (if rebase used)
git push --force-with-lease origin your-feature-branch
```

**Benefits:**
- Conflicts happen BEFORE PR creation, not during merge
- Agent has full context to resolve correctly
- Orchestrator doesn't have to guess intent later

#### Conflict Resolution Rules

**When conflicts occur in CLAUDE.md:**

1. **Default Rule:** ALWAYS prefer `main`'s version UNLESS you have explicit reason to override
2. **Override Criteria:**
   - Your change fixes a bug in main's version
   - Your change adds net-new information not in main
   - Your change is required for your PR to make sense
3. **Document Decision:** If overriding main, add commit message explaining WHY

**Example Good Override:**
```bash
git commit -m "docs: Keep PR #238 reframing in CLAUDE.md

Conflict resolution: Kept PR #238's assessment framing over main's
incident framing because:
1. Reframing from 'Incident' to 'Assessment' is the entire point of PR
2. Main's version has old 'Incident #2' language that needs updating
3. This doesn't conflict with any recent fixes in main

Verified: No recent Copilot fixes or architectural changes in main's version"
```

#### Cross-Repo Reference Convention

**CLAUDE.md is in the main repo.** References to docs repo files will break in contexts where docs repo isn't available.

```markdown
# ❌ NEVER (broken in isolation):
- See docs/INCIDENTS/INCIDENT_002_FIREBASE_REPOSITORY_GOD_CLASS.md
- See docs/assessments/FIREBASE_REPOSITORY_ASSESSMENT.md
- Located at: vault/sessions/week-25-retrospective.md

# ✅ ALWAYS (works everywhere):
- Assessment documentation pending finalization
- See Week 26 assessment in docs repo
- See vault for detailed retrospective
- Documented in published vault (search: "Week 25 Retrospective")
```

**Rationale:**
- CLAUDE.md may be read in contexts without docs repo mounted
- Generic references work across all contexts
- Specific paths belong in docs repo's own documentation

#### Orchestrator Checklist (CLAUDE.md PRs)

Before merging ANY PR touching CLAUDE.md:

- [ ] Has `main` been merged into this PR recently? (within last 4 hours)
- [ ] Are there any cross-repo file references? (must be generic)
- [ ] Are there other in-flight PRs touching CLAUDE.md? (check for conflicts)
- [ ] If conflicts occurred, have both versions been carefully compared?
- [ ] Was the override decision documented in commit message?

### Tier 2: Short-Term Actions (Week 27+)

#### CLAUDE.md Section Ownership

Reduce collision zones by limiting who can update which sections:

**Section Ownership Map:**
```
### Critical God Classes
Owner: Agent 2 (AAM) or Orchestrator
Reason: Architecture extraction work

### Common Patterns & Anti-Patterns
Owner: Agent 1 (AAP) or Orchestrator
Reason: Pattern discovery from code analysis

### Testing Strategy & Coverage
Owner: Agent 3 (AAA) or Orchestrator
Reason: Test coverage and quality assurance

### Multi-Agent Coordination
Owner: Orchestrator ONLY
Reason: Coordination protocol changes affect all agents

### Performance Priorities
Owner: Agent 2 (AAM) or Orchestrator
Reason: Architecture and optimization work

### Critical Bugs & Incidents
Owner: Any agent, Orchestrator approves
Reason: Bugs discovered by any agent, tracked centrally
```

**Enforcement:**
- Agents can READ any section
- Agents should ONLY write to their owned sections
- Orchestrator can write anywhere (final authority)
- Exceptions require Orchestrator approval

**Benefits:**
- Reduces parallel writes to same section
- Clear accountability for section accuracy
- Easier to track why sections change

#### Mandatory Pre-Merge Sync

**Add to all agent workflows:**

```markdown
## Before Creating PR (if touching CLAUDE.md)

**MANDATORY: Sync with main**
1. `git fetch origin main:main`
2. `git merge main` (or `git rebase main`)
3. Resolve any conflicts NOW (not later)
4. Verify your changes still make sense after merge
5. THEN create PR

**Why:** Prevents stale snapshots from creating conflicts at merge time
```

**Enforcement:** Add to agent coordination file templates and orchestrator checklists.

### Tier 3: Long-Term Options (Week 28+ if needed)

#### Split CLAUDE.md (Evaluate Week 27-28)

**If Tier 1 & 2 don't eliminate conflicts, consider splitting:**

```
Current (high conflict risk):
- CLAUDE.md (everything, ~1,200 lines, high churn)

Proposed (lower conflict risk):
- CLAUDE.md → Core patterns/architecture (stable, ~600 lines, low churn)
- docs/STATUS_WEEK_XX.md → Weekly status (high churn, archived weekly)
- docs/AGENT_CONTEXTS/ → Agent-specific context (no cross-agent conflicts)
```

**Benefits:**
- Separate high-churn content from stable documentation
- Weekly status archived → conflicts don't accumulate
- Agent contexts isolated → agents work independently

**Costs:**
- More files to maintain
- Information spread across multiple locations
- Requires clear conventions about what goes where

**Decision Criteria (Week 27-28):**
- If >2 CLAUDE.md conflicts per week despite Tier 1 & 2: Consider split
- If <2 conflicts per week: Keep unified (simpler)
- Evaluate based on actual data, not prediction

---

## Success Metrics

### Immediate (Week 27)
- **Target:** Zero CLAUDE.md conflicts requiring manual orchestrator resolution
- **Measure:** Count conflicts per week
- **Success:** ≤1 conflict per week (down from 3+ in Week 26)

### Short-Term (Weeks 27-28)
- **Target:** 100% correct conflict resolution when conflicts occur
- **Measure:** Zero "lost changes" incidents
- **Success:** No regressions like PR #238 Copilot fix loss

### Long-Term (Evaluate Week 28)
- **Target:** Determine if CLAUDE.md split is needed
- **Measure:** Week 27-28 conflict rate and resolution quality
- **Success:** Data-driven decision (split if >2 conflicts/week persist)

---

## Related Documents

### Multi-Agent Coordination
- [[Multi-Agent Coordination Protocol v2.0]] - Overall coordination framework
- [[Agent Worktree Structure]] - Repository setup and paths
- [[File-Based Coordination Protocol]] - Agent coordination file system

### Session Documentation
- [[Week 26 Retrospective]] - Full context of CLAUDE.md conflicts
- [[Week 26 ULTRATHINK Analysis]] - Deep dive on conflict prevention

### Main Repository
- `CLAUDE.md` - The subject of this protocol
- `docs/AGENT_MESSAGES/WEEK_26/agent-d-vault-claude-md-conflicts.md` - Original task spec

---

## Appendix: Common Conflict Scenarios

### Scenario 1: Parallel Feature PRs

**Setup:**
- Agent 1 PR: Adds logging pattern to CLAUDE.md
- Agent 2 PR: Adds repository extraction pattern to CLAUDE.md
- Both created from same main snapshot

**Prevention:**
- Both agents merge main before creating PR (Tier 1)
- Conflict resolves early with full context

**If conflict happens anyway:**
- Both changes are valid → Keep BOTH
- Merge sections, don't choose one over the other

### Scenario 2: Quick Fix vs Feature PR

**Setup:**
- Orchestrator PR: Quick Copilot fix to CLAUDE.md (merges fast)
- Agent D PR: Large documentation update (slower review)

**Prevention:**
- Agent D rebases on main after Copilot fix merges
- Incorporates Copilot fix before PR finalized

**If conflict happens anyway:**
- Default: Keep main's version (Copilot fix)
- Override only if Agent D's change IMPROVES on the fix

### Scenario 3: Reframing/Refactoring

**Setup:**
- Large-scale reframing of CLAUDE.md sections
- Conflicts with everything in flight

**Prevention:**
- Announce reframing intent in coordination
- Other agents hold CLAUDE.md updates until reframing merges
- OR: Rebase all in-flight PRs after reframing merges

**If conflict happens anyway:**
- Default: Keep reframing version (it's the intentional change)
- Verify no critical fixes lost in the reframe

---

**Protocol Owner:** Orchestrator (Agent O)
**Review Cycle:** Every 2 weeks (Weeks 28, 30, 32...)
**Next Review:** Week 28 (evaluate Tier 2 effectiveness, consider Tier 3)
