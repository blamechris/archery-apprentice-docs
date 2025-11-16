# Audit Verification Process

## Purpose

Extract value from external code audits (Claude Code Web, GitHub Copilot, automated tools) while maintaining attribution policy compliance and ensuring independent verification.

## When to Use

This process applies when:
- External tool produces comprehensive audit findings
- Audit contains valuable insights but attribution concerns exist
- Audit claims need independent verification before action
- Knowledge should be captured for future reference

**Do NOT use for:**
- Simple bug reports (handle directly)
- Feature requests (use normal backlog process)
- Internal agent analysis (already compliant)

## Process Overview

```
External Audit → Orchestrator Review → Multi-Agent Verification → Documentation Capture
```

**Timeline:** Typically 1 day for verification, 2-3 hours for documentation

## Detailed Workflow

### Phase 1: Orchestrator Review

**Owner:** Orchestrator (or senior agent)
**Duration:** 30-60 minutes

**Steps:**

1. **Read Audit Findings**
   - Review complete audit document
   - Identify key claims and findings
   - Note audit methodology and evidence

2. **Assess Audit Quality**
   - Verify claims are specific (not vague)
   - Check for concrete evidence (file paths, line numbers, metrics)
   - Evaluate actionability (can findings be addressed?)

3. **Determine Verification Scope**
   - Select critical/high-value findings
   - Exclude low-value or vague claims
   - Prioritize actionable items

4. **Plan Agent Distribution**
   - Map findings to agent specializations
   - Balance workload across agents
   - Identify verification methods (grep, file reads, builds)

**Deliverable:** Agent verification prompts (one per agent)

### Phase 2: Multi-Agent Verification

**Owners:** Specialized agents (typically 2-4 agents)
**Duration:** 4-8 hours (parallel execution)

**Agent Assignments (Standard):**

- **Agent 1 (AAP):** Platform/infrastructure gaps
  - Production readiness
  - Build configuration
  - CI/CD pipeline analysis
  - Dependency management

- **Agent 2 (AAM):** Database/architecture findings
  - God class verification
  - Repository structure
  - Data model analysis
  - Service extraction opportunities

- **Agent 3 (AAA):** Test coverage/quality gaps
  - Test file counting
  - Coverage gap identification
  - Performance test validation
  - Testing roadmap development

- **Agent D:** Documentation capture (post-verification)

**Verification Guidelines:**

**DO:**
- ✅ Use grep, file reads, line counts (READ-ONLY operations)
- ✅ Provide evidence (commands run, file paths, output snippets)
- ✅ Write analysis in own words (synthesize, don't copy)
- ✅ Verify metrics independently (re-count, re-measure)
- ✅ Note discrepancies (audit incorrect? verify why)
- ✅ Provide concrete recommendations

**DON'T:**
- ❌ Copy text from audit document
- ❌ Trust audit claims without verification
- ❌ Make changes to codebase (verification only)
- ❌ Skip evidence gathering (always show work)
- ❌ Assume audit is correct (verify everything)

**Deliverable (per agent):** Analysis document (500-800 lines) with:
- Executive summary
- Verification results (claim by claim)
- Evidence and commands used
- Recommendations and roadmaps
- Success criteria for remediation

### Phase 3: Orchestrator Consolidation

**Owner:** Orchestrator
**Duration:** 1-2 hours

**Steps:**

1. **Review Agent Deliverables**
   - Verify all agents completed verification
   - Check for consistent findings across agents
   - Note any contradictions or gaps

2. **Update CLAUDE.md**
   - Add concise summary of findings (not full text)
   - Update relevant metrics (god class sizes, test counts)
   - Add references to detailed analysis docs
   - Keep CLAUDE.md focused (avoid duplication)

3. **Archive Detailed Docs**
   - Move agent analyses to `docs/` directory
   - Preserve for future reference
   - Link from CLAUDE.md summaries

4. **Close External Audit PR**
   - Acknowledge audit value
   - Explain verification process used
   - Reference archived findings
   - Close PR (cannot merge due to attribution)

**Deliverable:** Updated CLAUDE.md, archived analyses, closed audit PR

### Phase 4: Documentation Capture (Vault)

**Owner:** Agent D
**Duration:** 2-3 hours

**Steps:**

1. **Create Session Note**
   - Document the verification session
   - Summarize key findings from all agents
   - Capture value extracted from audit
   - Record lessons learned

2. **Create/Update Concept Notes**
   - Extract timeless concepts (production readiness, god classes)
   - Synthesize findings across sessions
   - Provide actionable guidance

3. **Create/Update Code Notes**
   - Document specific files analyzed (ViewModels, repositories)
   - Include extraction plans and metrics
   - Cross-link with related notes

4. **Update Indexes**
   - Add to god class index
   - Update technical debt tracking
   - Maintain discovery timeline

5. **Create/Update Process Notes**
   - Document reusable workflows
   - Capture process improvements
   - Provide templates for future use

**Deliverable:** 3-5 vault notes with cross-links and tags

## Example: PR #245 Verification (2025-11-15)

### Context
- **Audit Source:** Claude Code Web (11 specialized agents)
- **Audit Size:** Comprehensive codebase analysis
- **Attribution Issue:** Could not merge PR due to AI attribution
- **Decision:** Extract value through independent verification

### Execution

**Phase 1: Orchestrator Review**
- Identified 3 critical finding areas: production readiness, test coverage, god class discovery
- Created verification prompts for 3 agents
- Defined success criteria (evidence-based analysis)

**Phase 2: Agent Verification (7 hours parallel)**

**Agent 1 (AAP):**
- Verified 4 production gaps (crash reporting, obfuscation, monitoring, dependencies)
- Created 760-line analysis with solutions and roadmap
- ROI: $150K-550K risk mitigation

**Agent 2 (AAM):**
- Discovered TournamentDetailsViewModel (1,421 lines, not previously documented)
- Created extraction plan (4 services, 40-55% reduction)
- Corrected audit metric (35 methods, not 85)

**Agent 3 (AAA):**
- Verified equipment repository gaps (4/7 untested)
- Verified UI screen coverage (23/26 untested)
- Discovered N+1 optimization already complete (audit outdated)

**Phase 3: Consolidation**
- Updated CLAUDE.md with god class metrics
- Archived 3 analysis docs in `docs/`
- Closed PR #245 with acknowledgment

**Phase 4: Documentation**
- Created session note (this example)
- Created production-readiness-gaps concept note
- Created TournamentDetailsViewModel code note
- Updated god-classes index
- Created audit-verification-process note

### Outcome

**Value Retained:** ~70% of critical audit findings preserved
**Effort:** 10 hours total (7 hours verification + 3 hours documentation)
**Deliverables:** 3 agent analyses (1,950 lines), 5 vault notes, updated CLAUDE.md

**Critical Discoveries:**
- ✅ Production deployment blockers identified
- ✅ New god class discovered
- ✅ Quick wins identified (equipment tests, 4 hours)
- ✅ Roadmaps created for future work

## Benefits

### Value Extraction
- ✅ Leverage external audit intelligence
- ✅ Focus on critical/actionable findings
- ✅ Avoid wasted audit effort

### Attribution Compliance
- ✅ Independent verification (not copying)
- ✅ Own words, own analysis
- ✅ Evidence-based conclusions
- ✅ Higher trust (verified claims)

### Knowledge Capture
- ✅ Findings preserved in vault
- ✅ Reusable for future planning
- ✅ Cross-referenced with related work
- ✅ Historical context maintained

### Multi-Agent Coordination
- ✅ Parallel execution (faster)
- ✅ Specialized expertise applied
- ✅ Multiple perspectives reduce bias
- ✅ Comprehensive coverage

## Success Criteria

### Verification Quality
- [ ] All critical claims independently verified
- [ ] Evidence provided (commands, file paths, metrics)
- [ ] Discrepancies noted and explained
- [ ] Recommendations are actionable
- [ ] Effort estimates provided

### Attribution Compliance
- [ ] No text copied from audit
- [ ] Analysis written in own words
- [ ] Independent verification methods used
- [ ] Agent conclusions based on own investigation

### Documentation Quality
- [ ] Session note captures key findings
- [ ] Concept notes synthesize timeless knowledge
- [ ] Code notes provide actionable plans
- [ ] Indexes updated for discoverability
- [ ] Cross-links maintain knowledge graph

### Value Extraction
- [ ] Critical findings preserved
- [ ] Actionable roadmaps created
- [ ] Quick wins identified
- [ ] ROI/effort estimates provided
- [ ] Future planning enabled

## Common Pitfalls

### Insufficient Verification
**Problem:** Trusting audit claims without verification
**Solution:** Always re-count, re-grep, re-measure independently

### Copy-Paste Documentation
**Problem:** Copying audit text into vault notes
**Solution:** Synthesize in own words, focus on key insights

### Verification Scope Creep
**Problem:** Trying to verify every audit claim
**Solution:** Focus on critical/actionable items only

### Missing Attribution
**Problem:** Accidentally including AI attribution in commits
**Solution:** Review all git operations before committing

### Poor Agent Distribution
**Problem:** Overloading one agent, underutilizing others
**Solution:** Balance workload by expertise area

## Tools & Templates

### Verification Commands (Examples)

**File Metrics:**
```bash
# Line count
wc -l path/to/file.kt

# Method count
grep -c "fun " path/to/file.kt

# Responsibility count
grep -E "^class|^object|^interface" path/to/file.kt
```

**Search Operations:**
```bash
# Find files by pattern
find app/src -name "*Repository.kt"

# Search for dependency
grep -r "firebase-crashlytics" .

# Count test files
find app/src/test -name "*Test.kt" | wc -l
```

**Build Analysis:**
```bash
# Check build config
cat app/build.gradle.kts | grep -A 5 "isMinifyEnabled"

# List dependencies
cat gradle/libs.versions.toml | grep "alpha\|beta"
```

### Agent Prompt Template

```markdown
## Task: Verify [FINDING AREA] from External Audit

**Context:**
External audit claimed [SPECIFIC CLAIMS]. Independently verify these claims.

**Your Mission:**
1. Verify claim 1: [SPECIFIC VERIFICATION]
2. Verify claim 2: [SPECIFIC VERIFICATION]
3. Verify claim 3: [SPECIFIC VERIFICATION]

**Requirements:**
- Use READ-ONLY operations (grep, file reads, counts)
- Provide evidence (commands, output, file paths)
- Write analysis in own words (do NOT copy audit)
- Note discrepancies if audit is incorrect

**Deliverable:**
Analysis document (500-800 lines) with:
- Verification results (claim by claim)
- Evidence for each claim
- Recommendations and roadmap
- Effort estimates

**Duration:** ~2-3 hours
```

## Future Improvements

### Process Enhancements
- Standardize agent verification checklists
- Create verification command library
- Develop audit quality rubric
- Automate common verification tasks

### Tooling Opportunities
- Script for common file metrics
- Automated god class detection
- Test coverage gap scanner
- Dependency security checker

### Documentation Templates
- Session note template (standardize structure)
- Concept note template (ensure completeness)
- Code note template (extraction plans)
- Process note template (reusable workflows)

## References

- **Example Session:** [[2025-11-15-audit-verification-session|Audit Verification Session]]
- **Related Concepts:** [[production-readiness-gaps|Production Readiness]], [[god-classes|God Classes]]
- **Agent Coordination:** [[orchestration/ORCHESTRATOR_PLAYBOOK|Orchestrator Playbook]]

## Tags

#process #verification #audit #quality-assurance #multi-agent #workflow
