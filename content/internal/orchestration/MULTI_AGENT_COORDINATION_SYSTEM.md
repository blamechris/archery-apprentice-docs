# Multi-Agent Coordination System - Technical Overview

**Last Updated:** 2025-11-11 (Week 24)
**System Version:** 2.1 (Agent-Coordination Branch Protocol)
**Audience:** Technical reference for all stakeholders

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         User                                 │
│                                                              │
│  Says: "Check your assignment on agent-coordination branch" │
└────────┬────────────────────────────────────────────────────┘
         │
         ├──────────────┬──────────────┬──────────────┬──────────────┐
         │              │              │              │              │
         ▼              ▼              ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  Agent 1    │ │  Agent 2    │ │  Agent 3    │ │  Agent D    │ │  Agent O    │
│   (AAP)     │ │   (AAM)     │ │   (AAA)     │ │   (Docs)    │ │(Orchestrator)│
│             │ │             │ │             │ │             │ │             │
│ Platform &  │ │ Modules &   │ │ Analysis &  │ │Documentation│ │Coordination │
│Architecture │ │ Data Layer  │ │ Validation  │ │   & Vault   │ │  & Planning │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
         │              │              │              │              │
         └──────────────┴──────────────┴──────────────┴──────────────┘
                        │
                        ▼
         ┌──────────────────────────────────────────────────┐
         │   agent-coordination Branch (git-tracked)        │
         │                                                  │
         │  • ACTIVE_ASSIGNMENTS.md (Status table)         │
         │  • agent-1-current.md (Bidirectional)           │
         │  • agent-2-current.md (Bidirectional)           │
         │  • agent-3-current.md (Bidirectional)           │
         │  • agent-d-current.md (Bidirectional)           │
         │  • orchestrator-current.md (Self-coordination)  │
         │  • COORDINATION_README.md (Protocol docs)       │
         └──────────────────────────────────────────────────┘
```

---

## Core Components

### 1. agent-coordination Branch

**Purpose:** Dedicated git branch for bidirectional agent-orchestrator communication

**Branch:** `agent-coordination` (lives in main repository)

**Characteristics:**
- **Git-tracked communication** - All assignments and status updates versioned
- **Local during session** - Fast, low-overhead agent fetching via relative paths
- **Remote at session end** - Pushed to origin for backup and resumability
- **Bidirectional** - Orchestrator assigns tasks, agents report status
- **Resumable** - Agents can fetch assignments on fresh context/session restart

**How agents fetch:**
```bash
# Agents fetch from main repo via relative path (fast, local)
git fetch ../archery-apprentice agent-coordination:agent-coordination
git checkout agent-coordination
cat agent-X-current.md
```

**Session end workflow (Orchestrator):**
```bash
# Update all coordination files
git add agent-*.md orchestrator-current.md ACTIVE_ASSIGNMENTS.md
git commit -m "orchestrator: Update assignments for next session"

# Merge any main updates
git merge main

# Push to remote (backup + resumability)
git push origin agent-coordination
```

---

### 2. ACTIVE_ASSIGNMENTS.md

**Purpose:** Single source of truth for agent status

**Location:** `ACTIVE_ASSIGNMENTS.md` on `agent-coordination` branch

**Structure:**
```markdown
# Active Agent Assignments

**Last Updated:** YYYY-MM-DD (Week X)

## Current Assignments

| Agent | Status | Task | Branch | Instructions |
|-------|--------|------|--------|--------------|
| Agent 1 | 🟢 Active | [Task] | [Branch] | [Link] |
| Agent 2 | 🟡 Pending Review | [Task] | [Branch] | [Link] |
| Agent 3 | ⏸️ Standby | - | - | - |

## Week X Overview
[Context for current week]
```

**Status Indicators:**
- 🟢 **Active** - Agent should work on this task
- 🟡 **Pending Review** - PR created, awaiting review/merge
- ⏸️ **Standby** - No active assignment
- ✅ **Complete** - Task finished and merged

**Read by:** All agents when user says "Check active assignments"

**Updated by:** Orchestrator (Agent O) or user

---

### 3. Agent Status Files (Bidirectional)

**Purpose:** Detailed task instructions AND agent status reporting

**Location:** `agent-X-current.md` on `agent-coordination` branch

**Files:**
- `agent-1-current.md` - Agent 1 (AAP) assignment & status
- `agent-2-current.md` - Agent 2 (AAM) assignment & status
- `agent-3-current.md` - Agent 3 (AAA) assignment & status
- `agent-d-current.md` - Agent D (Docs) assignment & status

**Bidirectional Flow:**

**Orchestrator → Agent (Assign):**
```markdown
**Status:** ASSIGNED
**Week:** 24
**Task:** Extract TournamentSyncService

[Detailed instructions...]
```

**Agent → Orchestrator (Report):**
```markdown
**Status:** COMPLETED
**Summary:** Extracted TournamentSyncService (250 lines)
**PR:** #224
**Discoveries:** [Findings...]
**Next Steps:** [Recommendations...]
```

**Status Values:**
- `AWAITING_ASSIGNMENT` - Ready for work
- `ASSIGNED` - Orchestrator assigned task
- `IN_PROGRESS` - Agent working on it
- `BLOCKED` - Agent stuck, needs help
- `COMPLETED` - Task done, PR created

**Characteristics:**
- **Predictable location** - Always same filename on agent-coordination branch
- **Bidirectional** - Orchestrator writes assignments, agents update with status
- **Comprehensive** - 300-500 lines with code examples and context
- **Self-contained** - All context needed to execute task
- **Git-tracked** - Version history of all assignments and status updates

---

### 4. orchestrator-current.md (Self-Coordination)

**Purpose:** Orchestrator tracks own session state for resumability

**Location:** `orchestrator-current.md` on `agent-coordination` branch

**Structure:**
```markdown
**Status:** WEEK X LAUNCHED
**Current Week:** X
**Last Session:** [Description]
**Last Updated:** YYYY-MM-DD

## Next Actions (During Week X Execution)
- [ ] Monitor agent progress
- [ ] Review PRs
- [ ] Update coordination files

## Session Start Checklist
[Steps for resuming orchestration...]
```

**Benefits:**
- **Resumable** - Orchestrator can pick up where it left off
- **Context preservation** - No need for long prompts on resumption
- **Self-documenting** - Session history tracked in git
- **Next actions clear** - Always know what to do next

**Added:** Week 24 (2025-11-11)

---

### 5. Agent CLAUDE.md Protocol

**Purpose:** Each agent knows how to find assignments + agent identity

**Location:** `CLAUDE.md` in each agent's worktree

**Two key sections:**

**A. Agent Identity Section (Added Week 24)**
```markdown
## 🤖 AGENT IDENTITY

**Agent Name:** Agent 1 (AAP - Archery Apprentice Platform)
**Role:** Platform abstractions, architectural patterns, cross-platform concerns
**Working Directory:** C:\Users\...\archery-agent-platform
**Main Repository:** ../archery-apprentice

When starting a fresh context, immediately fetch your assignment:
```bash
git fetch ../archery-apprentice agent-coordination:agent-coordination
git checkout agent-coordination
cat agent-1-current.md
```
```

**Benefits:**
- **Immediate context** - Agent knows identity on fresh session
- **Self-service** - Clear instructions to fetch assignment
- **No prompt needed** - User just says "Check your assignment"

**B. Multi-Agent Coordination Protocol**
```markdown
## Multi-Agent Coordination Protocol

**Standard Command:** User says "Check your assignment on agent-coordination branch"

**Procedure:**
1. Fetch: git fetch ../archery-apprentice agent-coordination:agent-coordination
2. Checkout: git checkout agent-coordination
3. Read: cat agent-X-current.md
4. Check status:
   - ASSIGNED → Begin work
   - IN_PROGRESS → Continue work
   - AWAITING_ASSIGNMENT → Wait for orchestrator
5. Report status by updating agent-X-current.md and pushing back
```

**Key insight:** No skills, no MCP, just file reading and git via relative paths

**Added:** Agent identity section in Week 24 (2025-11-11)

---

### 4. Historical Records

**Purpose:** Preserve assignment history

**Location:** `docs/AGENT_MESSAGES/WEEK_X/` and `docs/agent-instructions/archive/`

**Structure:**
```
docs/
├── AGENT_MESSAGES/
│   └── WEEK_X/
│       ├── ORCHESTRATOR_WEEK_X_PLANNING.md
│       ├── AGENT_1_[TASK]_PROMPT.md
│       ├── AGENT_2_[TASK]_PROMPT.md
│       └── AGENT_3_[TASK]_PROMPT.md
└── agent-instructions/
    └── archive/
        └── week-X/
            ├── agent-1-current.md
            ├── agent-2-current.md
            └── agent-3-current.md
```

**Used for:** Reference, session resumption, historical analysis

---

## Data Flow

### Starting New Week

```
1. Orchestrator creates planning doc
   └─> docs/AGENT_MESSAGES/WEEK_X/ORCHESTRATOR_WEEK_X_PLANNING.md

2. Orchestrator creates 3 detailed prompts
   ├─> docs/AGENT_MESSAGES/WEEK_X/AGENT_1_[TASK]_PROMPT.md
   ├─> docs/AGENT_MESSAGES/WEEK_X/AGENT_2_[TASK]_PROMPT.md
   └─> docs/AGENT_MESSAGES/WEEK_X/AGENT_3_[TASK]_PROMPT.md

3. Orchestrator copies to current assignments
   ├─> cp to docs/agent-instructions/agent-1-current.md
   ├─> cp to docs/agent-instructions/agent-2-current.md
   └─> cp to docs/agent-instructions/agent-3-current.md

4. Orchestrator updates status table
   └─> docs/ACTIVE_ASSIGNMENTS.md

5. User starts agents
   ├─> "Check active assignments" → Agent 1
   ├─> "Check active assignments" → Agent 2
   └─> "Check active assignments" → Agent 3

6. Agents read and begin work
   ├─> Agent 1 reads ACTIVE_ASSIGNMENTS.md
   │   └─> Sees 🟢 Active
   │       └─> Reads agent-1-current.md
   │           └─> Begins work
   ├─> Agent 2 [same pattern]
   └─> Agent 3 [same pattern]
```

---

### Agent Completion Flow

```
1. Agent completes work
   └─> Creates PR #XXX
       └─> Reports back to user

2. User or Orchestrator updates status
   └─> ACTIVE_ASSIGNMENTS.md: 🟢 Active → 🟡 Pending Review

3. Cross-review assigned (if applicable)
   └─> Agent 3 reviews PR #XXX

4. PR merged
   └─> ACTIVE_ASSIGNMENTS.md: 🟡 Pending Review → ✅ Complete

5. Week X complete
   └─> Archive assignments to archive/week-X/
       └─> Ready for Week X+1
```

---

## Technical Implementation

### No Skills Required

**Question:** Are Claude Code skills being used?

**Answer:** **NO**

The system uses:
- ✅ File reading (Read tool)
- ✅ Relative paths (../archery-apprentice/)
- ✅ CLAUDE.md protocol (built-in context)
- ❌ No skills
- ❌ No MCP for agents (only orchestrator uses MCP for vault)
- ❌ No custom tools

**Why this works:**
- Agents share filesystem (worktrees are siblings)
- Predictable file locations
- Simple bash commands (cat, ls)

---

### File System Layout

```
C:\Users\chris_3zal3ta\StudioProjects\
├── archery-apprentice/                 # Main repo
│   ├── CLAUDE.md                        # Orchestrator context
│   ├── docs/
│   │   ├── AGENT_MESSAGES/WEEK_XX/      # Historical prompts
│   │   └── AGENT_CONTEXTS/              # Agent reference docs
│   ├── [agent-coordination branch]      # ⭐ Coordination branch
│   │   ├── ACTIVE_ASSIGNMENTS.md        # ⭐ Status table
│   │   ├── agent-1-current.md           # ⭐ Agent 1 bidirectional
│   │   ├── agent-2-current.md           # ⭐ Agent 2 bidirectional
│   │   ├── agent-3-current.md           # ⭐ Agent 3 bidirectional
│   │   ├── agent-d-current.md           # ⭐ Agent D bidirectional
│   │   ├── orchestrator-current.md      # ⭐ Orchestrator self-coord
│   │   └── COORDINATION_README.md       # Protocol documentation
│   └── [project files]
│
├── archery-agent-platform/             # Agent 1 worktree
│   ├── CLAUDE.md                        # Agent 1 identity + protocol
│   └── [same project files]
│
├── archery-agent-modules/              # Agent 2 worktree
│   ├── CLAUDE.md                        # Agent 2 identity + protocol
│   └── [same project files]
│
└── archery-agent-analysis/             # Agent 3 worktree
    ├── CLAUDE.md                        # Agent 3 identity + protocol
    └── [same project files]
```

**Key insights:**
- All worktrees share same git history, different working trees
- agent-coordination branch lives in main repo, all agents fetch from it
- No Agent D worktree (documentation agent works in docs repo)

---

## Agent Roles

### Agent 1 (AAP - Platform & Architecture)

**Specialization:**
- Platform abstractions (iOS/Android/KMP)
- Architectural patterns
- Logging, dependency injection
- Cross-platform concerns

**Worktree:** `archery-agent-platform`

**Common tasks:**
- LoggingProvider migrations
- Presenter pattern extractions
- Platform-specific implementations

---

### Agent 2 (AAM - Modules & Data Layer)

**Specialization:**
- Repository layer
- Database operations
- Module structure
- Data flow

**Worktree:** `archery-agent-modules`

**Common tasks:**
- Repository extractions
- Database migrations
- Entity modeling
- Module refactoring

---

### Agent 3 (AAA - Analysis & Validation)

**Specialization:**
- Code analysis
- Investigation
- Testing
- Quality gate (>80% coverage enforcement)

**Worktree:** `archery-agent-analysis`

**Common tasks:**
- God class investigations
- Cross-reviews with coverage validation
- Test coverage analysis
- Roadmap creation
- Quality gate enforcement

**Quality Gate Role (Week 23-24):**
- Reviews all PRs from Agents 1 & 2
- Enforces >80% minimum coverage (90% gold standard)
- Provides detailed feedback via agent-coordination files
- Blocks merge until quality standards met

---

### Agent D (Documentation)

**Specialization:**
- Documentation
- Vault management
- Knowledge base maintenance
- Session wrap-up documentation

**Worktree:** None (works in docs repo: `archery-apprentice-docs`)

**Common tasks:**
- Update Obsidian vault with session learnings
- Document coordination protocols
- Maintain technical reference docs
- Archive historical session data

**Added:** Week 24 (2025-11-11)

---

### Agent O (Orchestrator)

**Specialization:**
- Multi-agent coordination
- Planning
- Documentation
- Session management

**Worktree:** Main repo (no separate worktree)

**Tasks:**
- Create weekly assignments
- Update ACTIVE_ASSIGNMENTS.md
- Coordinate cross-reviews
- Maintain documentation

---

## Session Management

### Stateless Design

**Agents are stateless across sessions:**
- No memory of previous conversations
- Read CLAUDE.md every session
- Read assignments from files

**Orchestrator has limited statefulness:**
- Can read historical docs for context
- Relies on ACTIVE_ASSIGNMENTS.md for current state
- User provides context when resuming

---

### Resumption Strategy

**For Agents:**
```
User: "Check active assignments"
Agent: [Reads current state from files]
Agent: [Continues where left off]
```

**For Orchestrator:**
```
User: "We're in Week X, continue coordination"
Orchestrator: [Reads ACTIVE_ASSIGNMENTS.md]
Orchestrator: [Reads WEEK_X planning docs]
Orchestrator: [Asks for user's immediate need]
```

**See:** `SESSION_RESUMPTION.md` for detailed strategies

---

## Scalability

### Current: 3 Agents

System handles 3 agents well with:
- Simple status table
- Predictable file locations
- Parallel execution

---

### Future: 5-10 Agents

System scales to 10+ agents by:
- Adding rows to ACTIVE_ASSIGNMENTS.md table
- Creating more agent-X-current.md files
- Grouping agents by specialization
- Potentially adding sub-teams

**No architectural changes needed**

---

## Quality Gate Process (Week 23-24)

### Overview

**Purpose:** Enforce high code quality standards before merge

**Owner:** Agent 3 (AAA - Analysis & Validation)

**Standards:**
- **Minimum:** >80% coverage on modified lines (acceptable)
- **Gold Standard:** >90% coverage on modified lines (project goal)
- **Zero regressions:** All existing tests must pass
- **Build passing:** CI checks must succeed

---

### Workflow

**1. Agent Completes Work**
```
Agent X: Finishes implementation
Agent X: Runs tests locally
Agent X: Creates PR #XXX
Agent X: Updates agent-X-current.md with COMPLETED status
```

**2. Agent 3 Reviews PR**
```
Agent 3: Fetches agent-coordination branch
Agent 3: Sees COMPLETED status
Agent 3: Reviews PR #XXX
Agent 3: Checks Codecov coverage report
Agent 3: Validates test quality
```

**3. Decision Path**

**If coverage >90% (Gold Standard):**
```
Agent 3: Approves PR
Agent 3: Updates agent-X-current.md: "✅ APPROVED (90%+ coverage)"
Orchestrator: Merges PR
```

**If coverage 80-89% (Acceptable):**
```
Agent 3: Requests justification
Agent X: Provides reasoning OR adds more tests
Agent 3: Approves if justified
```

**If coverage <80% (Insufficient):**
```
Agent 3: CHANGES REQUESTED
Agent 3: Updates agent-X-current.md with detailed feedback:
  - Current coverage percentage
  - Files needing attention
  - Specific test cases to add
  - Example test patterns
Agent X: Adds tests to reach >80%
Agent X: Pushes fixes
Agent 3: Re-reviews
```

---

### Week 24 Examples

**PR #228 (Agent 1 - LoggingProvider Batch 4):**
- **Initial coverage:** 74.00% ❌
- **Agent 3 feedback:** "Add 8-10 logger verification tests"
- **Target files:** AnonymousParticipantCleanupService (28.57%), ParticipantValidationService (20.00%)
- **Status:** Changes requested via agent-1-current.md
- **Outcome:** Agent 1 working on fixes

**PR #229 (Agent 2 - Repository Extractions Batch 2):**
- **Initial coverage:** 79.43% ❌
- **Agent 3 feedback:** "Just short of 80% - add 2-3 edge case tests"
- **Target:** TournamentLifecycleRepository tests
- **Status:** Changes requested via agent-2-current.md
- **Outcome:** Agent 2 working on fixes

**Benefits Demonstrated:**
- ✅ Caught insufficient coverage before merge
- ✅ Provided actionable feedback
- ✅ Agents autonomously fixing issues
- ✅ No manual intervention needed
- ✅ Quality standards maintained

---

### Communication Pattern

**Via agent-coordination branch files:**

**Agent 3 → Agent X (agent-X-current.md):**
```markdown
**Status:** IN_PROGRESS (Coverage insufficient - 74.00% → 90% target)

## Required Coverage Fixes

**HIGH PRIORITY:**
1. AnonymousParticipantCleanupService.kt - 28.57% patch coverage
   - Add logger verification tests for cleanup flows
2. ParticipantValidationService.kt - 20.00% patch coverage
   - Add logger verification tests for validation logic

### How to Fix
[Code examples and patterns...]

### Success Criteria
- ✅ Boost patch coverage to >80%
- ✅ All tests passing
```

**Agent X acknowledges by:**
- Reading updated agent-X-current.md
- Implementing fixes
- Updating status to indicate progress

---

### Agent Autonomy

**Week 24 demonstrations:**

**Agent 1 Discovery:**
- Assigned LoggingProvider batch 4 with specific files
- Discovered 2 files already migrated
- Proposed revised target in agent-1-current.md
- Orchestrator approved via coordination file

**Agent 2 Check-in:**
- Completed 50% of repository extractions
- Asked orchestrator whether to continue or pause
- Updated agent-2-current.md with progress
- Orchestrator provided guidance

**Agent 3 Validation:**
- Autonomously reviewed both PRs
- Provided detailed feedback without prompting
- Updated agent coordination files proactively
- No orchestrator intervention needed for review process

**Key Insight:** File-based coordination enables true agent autonomy

---

## Week 23-24 Success Metrics

### Week 23 Results

**Primary Focus:** iOS Blocker Reduction + LoggingProvider Migration

**Agent 1 (AAP):** ✅ COMPLETE
- Task: LoggingProvider batch 3 (TournamentSyncService, RoundViewModel)
- Result: 35 logs migrated
- PR #225: Merged
- Coverage: >90%
- Duration: 1 hour

**Agent 2 (AAM):** ✅ COMPLETE
- Task: Repository extractions (TournamentSettingsRepository, TournamentDiscoveryRepository)
- Result: HybridTournamentRepository 1,877 → 1,805 lines (72 lines reduced)
- Tests: 92 tests added
- PR #226: Merged
- Coverage: >80%
- Duration: ~14 hours

**Agent 3 (AAA):** ✅ COMPLETE
- Task: Cross-review both PRs
- Result: Both PRs approved after coverage validation
- Quality gate: Enforced >80% standard
- Duration: ~4 hours

**Total Week 23:**
- Duration: ~20 hours (completed in 1 day with 3 agents in parallel)
- PRs merged: 2
- Tests added: 97
- Lines reduced: 107
- Coverage: >80% maintained
- Regressions: Zero
- Process: File-based coordination validated successfully

---

### Week 24 Status (In Progress)

**Primary Focus:** Continue iOS Blocker Reduction - Reach 80% LoggingProvider + Continue Repository Extractions

**Agent 1 (AAP):** 🔴 IN PROGRESS
- Task: LoggingProvider batch 4 (LiveScoringViewModel, TournamentDetailsViewModel, RoundDisplayViewModel)
- PR #228: Created, changes requested (coverage 74.00% → needs 90%)
- Status: Adding tests to reach gold standard

**Agent 2 (AAM):** 🔴 IN PROGRESS
- Task: Repository extractions batch 2 (TournamentLifecycleRepository, TournamentParticipantRepository)
- PR #229: Created, changes requested (coverage 79.43% → needs 80%+)
- Status: Adding edge case tests

**Agent 3 (AAA):** ⏸️ AWAITING
- Task: Quality gate validation
- Status: Provided feedback on both PRs, waiting for agents to fix
- Quality gate: Working as intended

**Agent D:** 🟢 ASSIGNED
- Task: Document file-based coordination protocol
- Status: Creating vault documentation for Week 23-24 refinements

**Current Status:** Quality gate process demonstrating value by catching coverage issues before merge

---

## Advantages Over Previous System

### v1.0 (Copy/Paste Prompts - Weeks 15-21)

**Workflow:**
1. Orchestrator creates prompts
2. Orchestrator writes delimited sections
3. **User copy/pastes each section to each agent** ❌

**Problems:**
- High user friction (3+ copy/paste operations)
- Error-prone (paste to wrong agent)
- No persistence (prompts lost after paste)
- Session resumption unclear

---

### v2.0 (File-Based - Week 22)

**Workflow:**
1. Orchestrator creates prompts
2. Orchestrator copies to agent-instructions/
3. Orchestrator updates ACTIVE_ASSIGNMENTS.md
4. **User says "check active assignments" (3x)** ✅

**Benefits:**
- ✅ Minimal user friction (one command per agent)
- ✅ Error-resistant (agents read own file)
- ✅ Persistent (files in git)
- ✅ Session resumption clear (re-read files)
- ✅ Searchable history (archive/)
- ✅ Scalable (add more agent-X-current.md files)

---

### v2.1 (Agent-Coordination Branch - Week 23+)

**Workflow:**
1. Orchestrator updates agent-coordination branch
2. Orchestrator commits assignments to agent-X-current.md files
3. Orchestrator updates orchestrator-current.md for own state
4. **User says "check your assignment on agent-coordination" (4x)** ✅
5. Agents fetch from ../archery-apprentice (local, fast)
6. Agents update their files and push status back

**New Benefits (over v2.0):**
- ✅ **Bidirectional** - Agents report status autonomously
- ✅ **Orchestrator self-coordination** - orchestrator-current.md for resumability
- ✅ **Agent identity** - CLAUDE.md sections for immediate context
- ✅ **Quality gate integration** - Agent 3 feedback via coordination files
- ✅ **Local during session** - No GitHub clutter until session end
- ✅ **Backup on session end** - Push to remote for resumability
- ✅ **True agent autonomy** - Agents make decisions and report proactively

**Week 23-24 Validation:**
- 2 PRs merged in Week 23 with zero copy-paste
- Quality gate caught 2 coverage issues in Week 24
- Agents autonomously updated status and requested guidance
- Orchestrator resumed Week 24 by reading orchestrator-current.md
- System working exceptionally well

---

## Security Considerations

### File Access

**All agents can access main repo:**
- Worktrees share filesystem
- No authentication needed
- Trust model: All agents are collaborative

**Vault access:**
- Only orchestrator uses Obsidian MCP
- Agents don't need vault access
- Vault documentation is reference only

---

### Git Isolation

**Agents work in separate branches:**
- No merge conflicts
- Independent PRs
- User controls merges

**Worktrees prevent conflicts:**
- Each agent has own working tree
- Simultaneous work possible
- Clean git history

---

## Monitoring & Observability

### Current Status Check

**Option 1:** Read ACTIVE_ASSIGNMENTS.md directly
**Option 2:** Ask Agent O: "What's the status?"
**Option 3:** Check GitHub for PRs

**What to look for:**
- How many agents 🟢 Active?
- Any agents 🟡 Pending Review?
- Expected completion timeline?

---

### Progress Tracking

**Per Week:**
- Week start: All agents 🟢 Active
- Week middle: Some 🟡 Pending Review
- Week end: All ✅ Complete

**Historical:**
- Archive in `docs/agent-instructions/archive/`
- Planning in `docs/AGENT_MESSAGES/WEEK_X/`
- Git log shows commits per agent

---

## Troubleshooting

### Agent Can't Find Assignment

**Symptom:** Agent says "File not found"

**Check:**
1. Is agent in correct worktree?
2. Does `../archery-apprentice/docs/ACTIVE_ASSIGNMENTS.md` exist?
3. Are worktrees siblings in filesystem?

**Fix:** Verify directory structure matches expected layout

---

### Status Out of Sync

**Symptom:** ACTIVE_ASSIGNMENTS.md shows 🟢 Active but PR created

**Check:**
1. When was file last updated?
2. Did orchestrator/user forget to update?

**Fix:** Update status manually or ask orchestrator

---

### Old Assignment Loaded

**Symptom:** Agent reads Week X-1 instructions instead of Week X

**Check:**
1. Was `agent-X-current.md` overwritten?
2. Does ACTIVE_ASSIGNMENTS.md show correct week?

**Fix:** Verify copy operation succeeded, ask agent to re-read

---

## Future Enhancements (Optional)

### Potential v3.0 Features

**If needed:**
- Automated status updates (git hooks)
- Web dashboard for status visualization
- Slack/Discord notifications on PR creation
- AI-powered assignment generation
- Cross-agent message passing (if collaboration needed)

**Current assessment:** v2.0 is sufficient for current scale (3-4 agents)

---

## Related Documentation

- **For User:** `USER_GUIDE.md` (vault)
- **For Orchestrator:** `ORCHESTRATOR_PLAYBOOK.md` (vault)
- **Session Resumption:** `SESSION_RESUMPTION.md` (vault)
- **Quick Reference:** `docs/QUICK_START_MULTI_AGENT.md` (main repo)

---

## Appendix: Command Reference

### Agent Commands

```bash
# Check current assignment
cat ../archery-apprentice/docs/ACTIVE_ASSIGNMENTS.md

# Read detailed instructions
cat ../archery-apprentice/docs/agent-instructions/agent-1-current.md

# Fallback: Find latest prompt manually
cd ../archery-apprentice
ls docs/AGENT_MESSAGES/WEEK_*/AGENT_1_*.md | sort | tail -1
```

### Orchestrator Commands

```bash
# Create new week assignments
mkdir -p docs/AGENT_MESSAGES/WEEK_X
# [create planning and prompt files]

# Copy to current assignments
cp docs/AGENT_MESSAGES/WEEK_X/AGENT_1_*.md docs/agent-instructions/agent-1-current.md
cp docs/AGENT_MESSAGES/WEEK_X/AGENT_2_*.md docs/agent-instructions/agent-2-current.md
cp docs/AGENT_MESSAGES/WEEK_X/AGENT_3_*.md docs/agent-instructions/agent-3-current.md

# Update status table
# [edit docs/ACTIVE_ASSIGNMENTS.md]

# Archive completed week
mkdir -p docs/agent-instructions/archive/week-X
cp docs/agent-instructions/agent-*.md docs/agent-instructions/archive/week-X/
```

---

**System designed for simplicity, scalability, and minimal user friction.**
