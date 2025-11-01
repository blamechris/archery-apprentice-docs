---
title: "ADR-[NUMBER]: [Decision Title]"
description: "Brief description (max 160 chars)"
category: "architecture-decision"
status: "proposed | accepted | deprecated | superseded"
date: "YYYY-MM-DD"
deciders: ["Person 1", "Person 2"]
consulted: ["Person 3"]
informed: ["Team"]
tags:
  - adr
  - [topic]
supersedes: "ADR-XXX"  # If applicable
superseded_by: "ADR-YYY"  # If applicable
---

# ADR-[NUMBER]: [Decision Title]

**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-XXX]
**Date:** YYYY-MM-DD
**Deciders:** [List of people involved in the decision]

---

## Table of Contents
- [Context](#context)
- [Decision](#decision)
- [Rationale](#rationale)
- [Consequences](#consequences)
- [Alternatives Considered](#alternatives-considered)
- [Implementation](#implementation)
- [Validation](#validation)

---

## Context

### Problem Statement

[Describe the problem or situation that requires a decision. Include:]
- What challenge are we facing?
- Why does this need to be decided now?
- What are the constraints?
- What are the requirements?

### Background

[Provide relevant background information:]
- Current state of the system
- Previous attempts or approaches
- Related decisions or technical debt
- Business drivers

### Key Stakeholders

| Stakeholder | Role | Interest |
|-------------|------|----------|
| [Name/Team] | [Role] | [What they care about] |
| [Name/Team] | [Role] | [What they care about] |

---

## Decision

### What We Will Do

[Clear, concise statement of the decision]

We will [action/approach] by [method/implementation].

### Scope

**What's Included:**
- [Scope item 1]
- [Scope item 2]
- [Scope item 3]

**What's NOT Included:**
- [Out of scope item 1]
- [Out of scope item 2]

### Timeline

- **Decision Date:** YYYY-MM-DD
- **Implementation Start:** YYYY-MM-DD
- **Expected Completion:** YYYY-MM-DD
- **Review Date:** YYYY-MM-DD (if applicable)

---

## Rationale

### Why This Decision

[Explain the reasoning behind the decision. Include:]

1. **[Reason 1]:** [Detailed explanation]
   - Supporting evidence
   - Metrics or data if available

2. **[Reason 2]:** [Detailed explanation]
   - Supporting evidence
   - Trade-offs considered

3. **[Reason 3]:** [Detailed explanation]

### Alignment with Principles

This decision aligns with our architectural principles:
- **[Principle 1]:** [How it aligns]
- **[Principle 2]:** [How it aligns]

### Supporting Data

[Include any metrics, benchmarks, or research that support the decision]

| Metric | Current State | Expected State | Improvement |
|--------|---------------|----------------|-------------|
| [Metric 1] | [Value] | [Value] | [%] |
| [Metric 2] | [Value] | [Value] | [%] |

---

## Consequences

### Positive Consequences

✅ **[Benefit 1]:** [Description]
- [Detail]
- [Impact]

✅ **[Benefit 2]:** [Description]
- [Detail]
- [Impact]

✅ **[Benefit 3]:** [Description]

### Negative Consequences

❌ **[Trade-off 1]:** [Description]
- [Detail]
- [Mitigation strategy]

❌ **[Trade-off 2]:** [Description]
- [Detail]
- [Mitigation strategy]

### Neutral Consequences

🔄 **[Change 1]:** [Description]
- [Impact on team/process]

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Risk 1] | High/Medium/Low | High/Medium/Low | [Strategy] |
| [Risk 2] | High/Medium/Low | High/Medium/Low | [Strategy] |

---

## Alternatives Considered

### Alternative 1: [Approach Name]

**Description:** [What this alternative would involve]

**Pros:**
- ✅ [Pro 1]
- ✅ [Pro 2]

**Cons:**
- ❌ [Con 1]
- ❌ [Con 2]

**Why We Rejected It:**
[Explanation]

---

### Alternative 2: [Approach Name]

**Description:** [What this alternative would involve]

**Pros:**
- ✅ [Pro 1]
- ✅ [Pro 2]

**Cons:**
- ❌ [Con 1]
- ❌ [Con 2]

**Why We Rejected It:**
[Explanation]

---

### Alternative 3: Do Nothing

**Description:** Keep the current approach

**Pros:**
- ✅ No implementation cost
- ✅ No learning curve

**Cons:**
- ❌ [Problem persists]
- ❌ [Technical debt grows]

**Why We Rejected It:**
[Explanation]

---

## Implementation

### High-Level Approach

[Describe the general implementation strategy]

### Implementation Phases

#### Phase 1: [Phase Name]

**Duration:** [Timeframe]

**Tasks:**
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

**Deliverables:**
- Deliverable 1
- Deliverable 2

---

#### Phase 2: [Phase Name]

**Duration:** [Timeframe]

**Tasks:**
- [ ] Task 1
- [ ] Task 2

**Deliverables:**
- Deliverable 1

---

### Technical Details

```kotlin
// Example code showing the approach
class Example {
    // Implementation sketch
}
```

### Migration Strategy

[If replacing existing functionality]

**Steps:**
1. [Migration step 1]
2. [Migration step 2]
3. [Migration step 3]

**Backward Compatibility:**
[How we'll handle existing code/data]

### Testing Strategy

**Unit Tests:**
- [ ] [Test requirement 1]
- [ ] [Test requirement 2]

**Integration Tests:**
- [ ] [Test requirement 1]

**Performance Tests:**
- [ ] [Test requirement 1]

---

## Validation

### Success Criteria

How we'll know this decision was successful:

1. **[Criterion 1]:** [Measurable outcome]
   - Metric: [Specific metric]
   - Target: [Target value]

2. **[Criterion 2]:** [Measurable outcome]
   - Metric: [Specific metric]
   - Target: [Target value]

### Monitoring

**Metrics to Track:**
- [Metric 1]: [How to measure]
- [Metric 2]: [How to measure]

**Review Schedule:**
- **Initial Review:** [Date] - Check immediate impact
- **Follow-up Review:** [Date] - Assess long-term effects
- **Final Assessment:** [Date] - Determine if goals met

### Rollback Plan

If this decision proves problematic:

1. [Rollback step 1]
2. [Rollback step 2]
3. [Rollback step 3]

**Rollback Triggers:**
- [Trigger 1]
- [Trigger 2]

---

## Related Decisions

### Supersedes
- [ADR-XXX: Previous Decision Title](/Architecture-Decisions/ADR-XXX.md) - [Why this supersedes it]

### Related ADRs
- [ADR-YYY: Related Decision](/Architecture-Decisions/ADR-YYY.md) - [Relationship]
- [ADR-ZZZ: Another Related Decision](/Architecture-Decisions/ADR-ZZZ.md) - [Relationship]

### Dependencies
- [ADR-AAA: Prerequisite Decision](/Architecture-Decisions/ADR-AAA.md) - [Why this is needed]

---

## References

### Documentation
- [Internal Doc 1](/path/to/doc.md)
- [Internal Doc 2](/path/to/doc.md)

### External Resources
- [Article/Blog](URL) - [Brief description]
- [Research Paper](URL) - [Brief description]
- [Tool Documentation](URL) - [Brief description]

### Discussion Threads
- [GitHub Discussion #123](URL)
- [Slack Thread](URL or summary)

---

## Discussion Notes

### Key Points Raised

**[Topic 1]:**
- [Point raised by Person A]
- [Counterpoint by Person B]
- [Resolution]

**[Topic 2]:**
- [Discussion summary]

### Open Questions

- [ ] [Question 1] - Assigned to [Person] - Due [Date]
- [ ] [Question 2] - Assigned to [Person] - Due [Date]

---

## Approval

| Role | Name | Decision | Date |
|------|------|----------|------|
| Lead Developer | [Name] | ✅ Approved / ❌ Rejected | YYYY-MM-DD |
| Architect | [Name] | ✅ Approved / ❌ Rejected | YYYY-MM-DD |
| Product Owner | [Name] | ✅ Approved / ❌ Rejected | YYYY-MM-DD |

### Approval Notes

[Any conditions or notes from approvers]

---

## Updates

### Update 1: [YYYY-MM-DD]

**Changed By:** [Name]

**Changes:**
- [Change description]

**Reason:**
[Why the update was made]

---

## Feedback

Questions or feedback on this decision? [Start a discussion](https://github.com/blamechris/archery-apprentice/discussions)

---

**Document Info:**
- **ADR Number:** [NUMBER]
- **Version:** 1.0
- **Last Updated:** YYYY-MM-DD
- **Status:** [Current status]
