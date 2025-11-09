# Combined PR Strategy: When to Merge Multiple Weeks of Work

**Category**: Best Practices
**Area**: Git Workflow, PR Management, Release Strategy
**Importance**: 🟡 MEDIUM - Improves atomic deployments
**Established**: Week 17-18 (November 2025)

## Overview

When working on sequential, related work across multiple weeks, consider combining the work into a **single Pull Request** for atomic deployment. This strategy works well when fixes or improvements discovered in Week N+1 should be applied retroactively to Week N.

**Key Principle**: If Week N+1 discovers issues that affect Week N, merge Week N+1 into Week N branch and create a single combined PR.

## The Pattern

### Standard Workflow (Separate PRs)

**Normal case**: Each week gets its own PR
```
main ← PR #1 (Week 17) ← feat/week-17-work
main ← PR #2 (Week 18) ← feat/week-18-work
main ← PR #3 (Week 19) ← feat/week-19-work
```

**When to use**:
- Work is independent
- No retroactive fixes needed
- Clean separation of concerns

### Combined PR Workflow

**Special case**: Week 17+18 merged into single PR
```
main ← PR #211 (Week 17+18 combined) ← feat/week-17-work
                                          ↑
                                          feat/week-18-work (merged into Week 17)
```

**When to use**:
- Sequential, related work
- Retroactive fixes discovered in Week N+1
- Atomic deployment desired

## Week 17+18 Case Study

### Background

**Week 17** (6 ViewModels migrated):
- LimbsViewModel, RiserViewModel, WeightViewModel
- RestViewModel, StabilizerViewModel, AccessoryViewModel
- Branch: `feat/week-17-viewmodel-presenter-migration`
- PR #211 created but NOT merged yet

**Week 18** (3 ViewModels migrated):
- ArrowViewModel, BowStringViewModel, SightViewModel
- Branch: `feat/week-18-viewmodel-presenter-migration`
- PR #209 created

### Problem Discovered

During Week 18, **memory leak pattern discovered in ALL Presenters**:

```kotlin
// ❌ Memory leak found in Week 17 AND Week 18 Presenters
private fun loadItems() {
    scope.launch {
        repository.getItems().collectLatest { _items.value = it }
    }
}
```

**Impact**:
- Week 17: 6 Presenters affected
- Week 18: 3 Presenters affected
- Total: 9 Presenters need fixing

### Decision Point

**Option A: Separate PRs (Standard)**
- Fix Week 17 Presenters in PR #211
- Fix Week 18 Presenters in PR #209
- Merge PR #211 → Merge PR #209
- **Problem**: Two PRs both fixing same memory leak pattern (redundant)

**Option B: Combined PR (Chosen)**
- Merge `feat/week-18-work` into `feat/week-17-work` branch
- Fix ALL 9 Presenters in single PR #211
- PR #209 auto-closes when PR #211 merges
- **Benefit**: Atomic deployment of memory leak fix

### Implementation

**Step 1: Merge Week 18 into Week 17 Branch**
```bash
git checkout feat/week-17-viewmodel-presenter-migration
git merge feat/week-18-viewmodel-presenter-migration
# Commit: a2c86aa1 (Week 18 merged into Week 17)
```

**Step 2: Fix ALL 9 Presenters**
```bash
# Fix Week 17 Presenters (6 files)
# Fix Week 18 Presenters (3 files)
# Commit: a8de4784 (Memory leak fixes for all Presenters)
```

**Step 3: Update PR #211 Title and Description**
```
Title: Week 17+18: ViewModel → Presenter Migration (9 ViewModels)

Description:
Combined Week 17 and Week 18 work for atomic deployment of memory leak fixes.

Week 17 (6 ViewModels):
- LimbsViewModel, RiserViewModel, WeightViewModel
- RestViewModel, StabilizerViewModel, AccessoryViewModel

Week 18 (3 ViewModels):
- ArrowViewModel, BowStringViewModel, SightViewModel

Memory Leak Fixes:
- All 9 Presenters updated to stateIn pattern
- Fixes applied retroactively to Week 17 Presenters
```

**Step 4: Merge PR #211**
```bash
# PR #211 merged to main (commit 1babf967)
# Result: PR #209 auto-closed (all commits already in main)
```

### Outcome

**✅ Benefits Achieved**:
- **Atomic Deployment**: All 9 Presenters fixed in single merge
- **Clean Git History**: One commit for memory leak fix across all Presenters
- **No Redundancy**: Single PR description documents all work
- **Logical Grouping**: Week 17+18 work closely related (same pattern)

**Trade-offs**:
- Larger PR (9 ViewModels instead of 6)
- PR #209 auto-closed (can confuse if not documented)
- More complex PR description

**Overall**: ✅ SUCCESS - Combined PR strategy worked well

## When to Use Combined PR Strategy

### ✅ Good Candidates

1. **Retroactive Fixes Discovered**
   - Week N+1 discovers bug in Week N
   - Fix should be applied to both weeks
   - Example: Week 18 memory leak affected Week 17

2. **Sequential, Related Work**
   - Week N+1 builds directly on Week N
   - Same pattern, same files, same team
   - Example: Week 17+18 ViewModel migrations

3. **Atomic Deployment Desired**
   - All work should go to production together
   - Partial deployment creates inconsistency
   - Example: Memory leak fix must apply to all Presenters

4. **Small-to-Medium PRs**
   - Week N: 6 ViewModels (acceptable PR size)
   - Week N+1: 3 ViewModels (small addition)
   - Combined: 9 ViewModels (still reasonable)
   - **Threshold**: <1000 lines changed total

### ❌ Bad Candidates

1. **Unrelated Work**
   - Week N: ViewModel migrations
   - Week N+1: Database schema changes
   - **Problem**: Mixed concerns, hard to review

2. **Large PRs**
   - Week N: 10 ViewModels (large PR)
   - Week N+1: 10 more ViewModels (large PR)
   - Combined: 20 ViewModels (too large!)
   - **Threshold**: >1500 lines changed

3. **Independent Deployments**
   - Week N can deploy independently
   - Week N+1 can deploy independently
   - **Benefit**: Deploy Week N early, Week N+1 later

4. **Different Teams**
   - Week N: Team A
   - Week N+1: Team B
   - **Problem**: Ownership confusion, review complexity

## Decision Framework

Use this flowchart to decide:

```
Does Week N+1 discover issues in Week N?
├─ YES → Is the fix needed in both weeks?
│         ├─ YES → Consider combined PR
│         └─ NO → Separate PRs (fix Week N retroactively)
└─ NO → Is work sequential and related?
          ├─ YES → Is combined PR size reasonable?
│                 ├─ YES → Consider combined PR
│                 └─ NO → Separate PRs (too large)
          └─ NO → Separate PRs (unrelated work)
```

### Example Decisions

**Scenario 1: Memory Leak Discovery**
- Week N+1 discovers memory leak in Week N ✅
- Fix needed in both weeks ✅
- Work is related (same pattern) ✅
- Combined PR size reasonable (9 ViewModels) ✅
- **Decision**: ✅ COMBINE (Week 17+18 case)

**Scenario 2: Independent Features**
- Week N: ViewModel migrations
- Week N+1: New Firebase feature
- Work is unrelated ❌
- **Decision**: ❌ SEPARATE (independent features)

**Scenario 3: Large Sequential Work**
- Week N: 10 ViewModels
- Week N+1: 10 more ViewModels
- Combined size: 20 ViewModels (too large) ❌
- **Decision**: ❌ SEPARATE (PR too large)

**Scenario 4: Refactoring Discovery**
- Week N+1 discovers better pattern
- Wants to apply to Week N code ✅
- Work is related ✅
- Combined size reasonable ✅
- **Decision**: ✅ COMBINE (pattern consistency)

## Implementation Steps

### Step 1: Assess Whether to Combine

**Checklist**:
- [ ] Week N+1 discovered issue in Week N? OR
- [ ] Work is sequential and related?
- [ ] Atomic deployment desired?
- [ ] Combined PR size reasonable (<1000 lines)?
- [ ] Same team/agent working on both?

**If 3+ YES**: Consider combined PR
**If <3 YES**: Use separate PRs

### Step 2: Merge Week N+1 into Week N Branch

```bash
# Checkout Week N branch
git checkout feat/week-N-work

# Merge Week N+1 branch
git merge feat/week-N+1-work

# Resolve any conflicts
git add .
git commit -m "Merge Week N+1 into Week N for combined PR"

# Push updated Week N branch
git push origin feat/week-N-work
```

### Step 3: Apply Fixes to Both Weeks

```bash
# Fix issues discovered in Week N+1
# Apply fixes to both Week N and Week N+1 code

git add .
git commit -m "Fix [issue] in Week N and Week N+1 Presenters"

git push origin feat/week-N-work
```

### Step 4: Update PR Description

**PR Title**: `Week N+N+1: [Feature] ([N1+N2] items)`

**PR Description**:
```markdown
Combined Week N and Week N+1 work for atomic deployment.

## Week N (X items)
- Item 1
- Item 2
...

## Week N+1 (Y items)
- Item 3
- Item 4
...

## Fixes Applied
- [Issue discovered in Week N+1]
- Applied retroactively to Week N
- Total impact: [N1+N2 items]

## Why Combined
- [Reason for combining, e.g., "Atomic deployment of memory leak fix"]

## Testing
- All tests passing: [test count]
- Code reduction: [percentage]
- No regressions
```

### Step 5: Merge PR

```bash
# Merge PR N (contains both Week N and Week N+1)
# Result: PR N+1 auto-closes (all commits already in main)
```

### Step 6: Document in Session Wrap-Up

**Include in wrap-up**:
- Why PRs were combined
- What issue triggered combination
- Outcome (benefits vs trade-offs)
- Whether strategy should be repeated

## Git History Considerations

### Combined PR Git History

```
* 1babf967 (main) Merge PR #211: Week 17+18 ViewModel migrations
│
* a8de4784 Fix memory leaks in Week 17+18 Presenters (9 files)
│
* a2c86aa1 Merge Week 18 into Week 17 branch
│
* [Week 18 commits]
│
* [Week 17 commits]
```

**Benefits**:
- Clear merge commit shows combined work
- Single deployment point (1babf967)
- Memory leak fix visible as single commit (a8de4784)

**Trade-offs**:
- Week 18 commits appear in Week 17 branch
- PR #209 shows as "closed" (not merged)
- Requires good PR description to explain

### Alternative: Separate PRs

```
* [commit] (main) Merge PR #209: Week 18 ViewModel migrations
│
* [commit] Merge PR #211: Week 17 ViewModel migrations + memory leak fix
│
* [Week 18 commits]
│
* [Week 17 commits]
```

**Benefits**:
- Clear separation of Week 17 and Week 18
- Both PRs show as "merged"
- Standard workflow

**Trade-offs**:
- Memory leak fix split across two PRs
- Two deployment points (potential for partial deployment)
- More complex to track retroactive fixes

## Review Process

### Reviewer Considerations

**When reviewing combined PRs**:

1. **Check PR Description**
   - [ ] Clearly explains why PRs were combined
   - [ ] Lists all work from both weeks
   - [ ] Documents fixes applied retroactively

2. **Verify Atomic Deployment**
   - [ ] All related fixes included in single PR
   - [ ] No partial deployment possible
   - [ ] Logical grouping of work

3. **Assess PR Size**
   - [ ] Combined PR is reasonable size (<1000 lines)
   - [ ] Not too large to review effectively
   - [ ] Could be split if needed

4. **Confirm Testing**
   - [ ] All tests passing (both weeks)
   - [ ] No regressions introduced
   - [ ] Test coverage maintained

### Approval Criteria

**Approve combined PR if**:
- ✅ Combination is justified (retroactive fixes OR sequential work)
- ✅ PR size is reasonable (<1000 lines)
- ✅ PR description clearly explains combination
- ✅ All work tested and passing
- ✅ Atomic deployment makes sense

**Request separation if**:
- ❌ PR too large (>1500 lines)
- ❌ Work is unrelated
- ❌ Independent deployment preferred
- ❌ Combination not justified in PR description

## Metrics & Analysis

### Week 17+18 Combined PR Metrics

**PR #211 (Combined Week 17+18)**:
- **Files changed**: ~50 files
- **Lines changed**: ~800 lines (within reasonable range)
- **Review time**: Standard (2-3 hours)
- **Merge time**: Same day
- **Issues found in review**: 0 (already validated by Agent 3)

**Comparison to Hypothetical Separate PRs**:

| Metric | Combined PR | Separate PRs | Difference |
|--------|-------------|--------------|------------|
| PRs created | 1 | 2 | -1 PR |
| Merge commits | 1 | 2 | -1 commit |
| Memory leak fix commits | 1 | 2 | -1 commit |
| Review time | 2-3 hours | 3-4 hours | -1 hour |
| Deployment points | 1 | 2 | -1 deployment |
| Git history clarity | High | Medium | Clearer |

**Conclusion**: Combined PR was more efficient and clearer

## Common Scenarios

### Scenario 1: Pattern Fix Discovery

**Week N**: Implement pattern
**Week N+1**: Discover pattern bug

**Solution**: Combine PRs, fix pattern across both weeks
**Example**: Week 17+18 memory leak fix

### Scenario 2: Refactoring Opportunity

**Week N**: Implement feature
**Week N+1**: Discover better approach

**Solution**: Combine PRs if refactoring applies to both weeks
**Example**: Extract shared logic discovered in Week N+1

### Scenario 3: Dependency Fix

**Week N**: Add dependency usage
**Week N+1**: Discover dependency bug, need to fix Week N

**Solution**: Combine PRs, fix dependency across both weeks
**Example**: KMP library update affecting both weeks

### Scenario 4: Sequential Feature Work

**Week N**: Implement feature part 1
**Week N+1**: Implement feature part 2 (builds on part 1)

**Solution**: Consider combining if feature is cohesive
**Example**: Multi-step feature implementation

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Combining Unrelated Work

**Bad**: Week N (ViewModel migrations) + Week N+1 (Firebase features)
**Why**: Unrelated work, different concerns, hard to review
**Fix**: Keep separate PRs

### ❌ Anti-Pattern 2: Combining Too Many Weeks

**Bad**: Week N + Week N+1 + Week N+2 (3 weeks in one PR)
**Why**: PR too large, review complexity, deployment risk
**Fix**: Limit to 2 weeks maximum

### ❌ Anti-Pattern 3: Combining After PRs Merged

**Bad**: Merge Week N, then try to "combine" Week N+1 retroactively
**Why**: Too late, Week N already deployed
**Fix**: Combine BEFORE merging Week N

### ❌ Anti-Pattern 4: Poor PR Description

**Bad**: Combined PR with description "Week 17+18 work"
**Why**: Doesn't explain why combined, what's included
**Fix**: Detailed PR description (see Step 4)

## Best Practices Summary

### ✅ DO

1. **Combine for Retroactive Fixes**
   - Week N+1 discovers bug in Week N
   - Fix both weeks in single atomic PR

2. **Combine Sequential, Related Work**
   - Same pattern, same files, same team
   - Logical grouping for atomic deployment

3. **Keep PR Size Reasonable**
   - <1000 lines changed (guideline)
   - If too large, split into separate PRs

4. **Document Clearly**
   - Explain why combined in PR description
   - List all work from both weeks
   - Document retroactive fixes

5. **Test Thoroughly**
   - All tests passing (both weeks)
   - No regressions introduced
   - Code coverage maintained

### ❌ DON'T

1. **Don't Combine Unrelated Work**
   - Different features, different concerns
   - Keep separate for clarity

2. **Don't Combine Too Many Weeks**
   - Limit to 2 weeks maximum
   - >2 weeks = PR too large

3. **Don't Combine After Merge**
   - Combine BEFORE merging Week N
   - Can't retroactively combine

4. **Don't Skimp on PR Description**
   - Explain why combined
   - List all work clearly
   - Document fixes

## Related Documentation

- [[week-17-19-summary|Weeks 17-19 Overview]]
- [[agent-2-week-17-19|Agent 2 Week 17-19 Summary]]
- [[memory-leak-prevention|Memory Leak Prevention Pattern]]

## Tags

#best-practice #git-workflow #pr-strategy #combined-pr #atomic-deployment #week-17-18

## Summary

**When to Combine PRs**:
- Retroactive fixes discovered in Week N+1 affecting Week N
- Sequential, related work (same pattern, same team)
- Atomic deployment desired
- Combined PR size reasonable (<1000 lines)

**Benefits**:
- Atomic deployment (all fixes together)
- Clean git history (single merge commit)
- No partial deployments
- Clear logical grouping

**How**:
1. Merge Week N+1 into Week N branch
2. Apply fixes to both weeks
3. Update PR description (explain why combined)
4. Merge single PR (Week N+1 PR auto-closes)

**Week 17+18 Case Study**: ✅ SUCCESS - Memory leak fix deployed atomically across 9 Presenters
