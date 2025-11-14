# Week 27 Process Refinements

**Week:** 27
**Date:** 2025-11-14
**Status:** Active Protocols
**Related:** [[CLAUDE.md Conflict Prevention]], [[Multi-Agent Coordination Protocol v2.0]], [[Week 27 Session Summary]]

---

## Overview

Week 27 established four critical process refinements based on Week 26-27 operational experience. These refinements address systemic issues discovered during multi-agent workflows and establish protocols to prevent future occurrences.

**Refinements:**
1. CLAUDE.md Orchestrator-Only Ownership (CRITICAL)
2. Coordination File Protocol Enforcement
3. Windows File Lock Standard Handling
4. Cross-Repo Reference Convention

---

## 1. CLAUDE.md Orchestrator-Only Ownership (CRITICAL)

### Problem Discovered

**Week 26 Incident:**
- PR #238 (Agent D): Modified CLAUDE.md with reframing changes
- PR #237 (Orchestrator): Modified CLAUDE.md with Copilot fix (generic reference)
- **Conflict:** PR #238 conflicted with merged PR #237
- **Error:** Merge resolution chose PR #238's version, **lost Copilot fix**
- **Root Cause:** Multiple agents modifying same file → inevitable conflicts

**Pattern Recognition:**
- CLAUDE.md is high-value (coordination critical) + high-churn (updated frequently)
- Multiple agents working in parallel on same file
- Manual conflict resolution prone to human error
- Lost changes and wasted effort

### Solution Implemented

**New Rule:** **Only Orchestrator (Agent O) may modify CLAUDE.md**

**Rationale:**
- **Single Writer Principle:** One writer eliminates conflicts entirely
- **Coordination Role:** Orchestrator has full context of all agent work
- **Final Authority:** Orchestrator is best positioned to maintain CLAUDE.md consistency

**Agent Responsibility:**
Agents report needed CLAUDE.md updates via coordination files:
```markdown
## CLAUDE.md Update Needed

**Section:** Critical God Classes
**Change:** Add FirebaseTournamentRepository (1,909 lines)
**Reason:** Week 26 assessment complete

**Proposed Text:**
5. **FirebaseTournamentRepository.kt** - 1,909 lines, 48 methods
   - Week 26 Assessment: Natural follow-up after Hybrid extraction
   - See docs repo for detailed assessment
```

Orchestrator reviews and makes the change.

### Enforcement

**During PR Review:**
- User catches violations
- Agent reminded of protocol
- PR either rejected or Orchestrator removes CLAUDE.md changes

**Exception Process:**
- If urgent change needed and Orchestrator unavailable
- Agent creates issue/note documenting change
- Orchestrator reviews and approves post-facto

### Documentation

**CLAUDE.md Section Added (PR #237):**
```markdown
## CLAUDE.md Ownership Protocol

**Rule:** Only Orchestrator (Agent O) may modify this file

**Why:** Single writer eliminates conflicts entirely

**Agents:** Report needed updates via coordination files
```

**Vault Document Created (PR #53):**
- [[CLAUDE.md Conflict Prevention]] - Comprehensive protocol documentation
- 3-Tier approach (Immediate, Short-term, Long-term)
- Conflict resolution decision trees
- Common scenario playbook

### Related: Cross-Repo Reference Convention

Part of CLAUDE.md ownership includes maintaining correct cross-repo references (see Section 4 below).

---

## 2. Coordination File Protocol Enforcement

### Problem Discovered

**Week 27 Incident:**
- Agent 1 completed Week 27 LoggingProvider migration
- **Did NOT update `agent-1-current.md`** during or after work
- Orchestrator learned about completion via **direct user message** (not coordination files)
- User had to manually relay information instead of checking files

**Protocol Violation:**
Agent 1 should have updated coordination file at:
1. **Work Start:** Change status ASSIGNED → IN_PROGRESS
2. **Milestone Completion:** Document completed files, commit and push
3. **When Blocked:** Document issue (e.g., file locks), commit and push
4. **PR Creation:** Add PR number, change status to AWAITING_CI, commit and push

### Why This Matters

**Coordination Files are Source of Truth:**
- Enable session resumption (new session can read state)
- Orchestrator tracks progress without manual updates
- User can check files instead of receiving verbal reports
- Historical record of work progression

**Protocol v2.0 Requirement:**
Multi-Agent Coordination Protocol v2.0 mandates coordination file updates at key checkpoints. This is not optional.

### Reminder Given

**Message to Agent 1:**
> All agents MUST update their coordination files at key checkpoints. This is mandatory per Protocol v2.0. Coordination files are how Orchestrator and future sessions understand progress.

**Checkpoints:**
1. Assignment accepted: Update status to IN_PROGRESS
2. File/task completed: Add to completion list, commit
3. Blocked/Issue encountered: Document issue, commit
4. PR created: Add PR link, update status, commit

### Enforcement

**Orchestrator Responsibility:**
- Call out violations when discovered
- Remind agents of protocol requirements
- Verify coordination file updates before marking work complete

**Agent Responsibility:**
- Update coordination file at each checkpoint
- Commit and push updates (not just local edits)
- Treat coordination file as live status dashboard

**User Responsibility:**
- Check coordination files for status (not ask agents directly)
- Remind agents of protocol if violations observed
- Trust coordination files as source of truth

---

## 3. Windows File Lock Standard Handling

### Problem Discovered

**Week 27 Incident:**
- Agent 1 encountered Windows file locks preventing local Gradle build
- Gradle daemon holding JARs in `shared/` modules
- Unable to run tests locally

**Common Windows Issue:**
Windows doesn't release file locks as aggressively as Unix systems. Long-running processes (like Gradle daemon) hold locks on JAR files.

### Standard Protocol Established

**Three Options (in priority order):**

#### Option 1: Restart Computer (Cleanest)
```
Restart Windows machine
```
- **Pros:** Guaranteed to clear all locks
- **Cons:** Time-consuming, disruptive
- **When to use:** If Options 2 & 3 don't work

#### Option 2: Kill Java Processes (Error-Prone)
```
Task Manager → Details → Find Java processes → End Task
```
- **Pros:** Faster than restart
- **Cons:** Risk killing wrong process, may not release all locks
- **When to use:** If Option 3 doesn't work and restart too disruptive

#### Option 3: Proceed with PR Anyway (RECOMMENDED) ✅
```
Code changes complete → Push PR → CI validates
```
- **Pros:** Efficient, standard workflow, CI validates in clean environment
- **Cons:** Can't verify locally before push
- **When to use:** **ALWAYS (default)**

### Decision: Always Use Option 3

**Rationale:**
1. **Code is Complete:** Work is done and verified manually
2. **CI Validates:** GitHub Actions runs in clean environment (no file locks)
3. **Historical Precedent:** Week 26 PR #234 same issue, CI passed, merged successfully
4. **Standard Workflow:** Push code → CI validates → merge if green is normal process

**Week 27 Example:**
- Agent 1 completed migration, couldn't run local build
- Pushed PR #240 anyway
- CI ran successfully, all tests passed
- PR merged without issues

### Documentation

Already documented in `CLAUDE.md` under "Troubleshooting Self-Hosted Runners":
> If Windows file locks prevent local build, proceed with PR anyway. CI validates in clean environment.

---

## 4. Cross-Repo Reference Convention

### Problem

**Week 26 Incident:**
- Agent D's PR #238 added specific file reference to CLAUDE.md:
  ```markdown
  See docs/assessments/FIREBASE_REPOSITORY_ASSESSMENT.md for details
  ```
- **Issue:** CLAUDE.md is in `main repo`, assessment is in `docs repo`
- **Result:** Broken link (file doesn't exist in main repo context)

**Root Cause:**
Main repo and docs repo are separate Git repositories. File paths don't resolve across repos.

### Convention Established

**Rule:** CLAUDE.md (main repo) must use **generic references** to docs repo files

```markdown
# ❌ NEVER (broken reference):
- See docs/INCIDENTS/INCIDENT_002_FIREBASE_REPOSITORY_GOD_CLASS.md
- See docs/assessments/FIREBASE_REPOSITORY_ASSESSMENT.md
- Located at: vault/sessions/week-25-retrospective.md

# ✅ ALWAYS (generic, works across repos):
- Assessment documentation pending finalization
- See Week 26 assessment in docs repo
- See vault for detailed retrospective
- Documented in published vault (search: "Week 25 Retrospective")
```

### Rationale

**Context Independence:**
- CLAUDE.md may be read in contexts where docs repo isn't mounted
- CI/CD pipelines may only have main repo cloned
- Developers may only clone main repo initially

**Works Everywhere:**
- Generic references provide direction without broken links
- Users know where to look (docs repo, vault, etc.)
- No assumptions about repository structure

**Specific Paths Belong in Docs Repo:**
- Docs repo's own documentation can use absolute paths
- Internal links work within docs repo
- Main repo references remain generic

### Enforcement

**Part of CLAUDE.md Ownership:**
- Orchestrator enforces this convention when maintaining CLAUDE.md
- Agents report generic references in coordination files
- Orchestrator ensures compliance before merging

**Example Correct Reference:**
```markdown
5. **FirebaseTournamentRepository.kt** - 1,909 lines, 48 methods
   - Week 26 Assessment: Natural follow-up after Hybrid extraction
   - Coverage gap observation: ~200+ uncovered lines
   - See docs repo for detailed assessment
```

---

## Implementation Status

### Active Protocols (Week 27+)

1. ✅ **CLAUDE.md Orchestrator-Only Ownership**
   - Rule established
   - CLAUDE.md section added
   - Vault documentation created (PR #53)
   - Enforcement active

2. ✅ **Coordination File Protocol**
   - Reminder given to Agent 1
   - Protocol v2.0 reference reinforced
   - Orchestrator monitoring compliance

3. ✅ **Windows File Lock Standard**
   - Option 3 (CI-first) established as default
   - Week 27 PR #240 validated approach
   - Documentation updated in CLAUDE.md

4. ✅ **Cross-Repo Reference Convention**
   - Convention documented
   - Part of CLAUDE.md ownership enforcement
   - Week 26 PR #238 example corrected

### Monitoring & Review

**Week 28 Check:**
- Monitor CLAUDE.md conflict rate (target: 0)
- Verify coordination file discipline (all agents updating)
- Validate CI-first approach continues working

**Month 2 Review (Week 32):**
- Evaluate protocol effectiveness
- Refine as needed based on operational data
- Document any additional patterns discovered

---

## Related Documents

### Multi-Agent Coordination
- [[CLAUDE.md Conflict Prevention]] - Comprehensive conflict prevention protocol
- [[Multi-Agent Coordination Protocol v2.0]] - Overall coordination framework
- [[File-Based Coordination Protocol]] - Coordination file system

### Session Documentation
- [[Week 27 Session Summary]] - Full Week 27 achievements
- [[Week 27 Lessons Learned]] - What went well, improvements needed
- [[Week 26 Retrospective]] - Background context for protocol needs

### Main Repository
- `CLAUDE.md` - "CLAUDE.md Ownership" section
- `docs/AGENT_MESSAGES/WEEK_26/agent-d-vault-claude-md-conflicts.md` - Original conflict analysis

---

**Protocol Owner:** Orchestrator (Agent O)
**Enforcement:** Active (Week 27+)
**Review Cycle:** Every 4 weeks (Weeks 28, 32, 36...)
**Next Review:** Week 28 (evaluate initial effectiveness)
