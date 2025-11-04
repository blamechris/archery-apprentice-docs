---
title: "Test Quality Standards"
description: "test quality standards and practices"
category: "development"
audience:
  - "developers"
difficulty: "intermediate"
status: "active"
last_updated: "2025-10-29"
tags:
  - "testing"
  - "quality"
  - "guide"
---

[Home](/) > [Development](/Development/) > [Testing](/Development/Testing/) > Test Quality Standards

---


# Test Quality Standards

**Status:** ✅ **IMPLEMENTED** (Oct 13, 2025)  
**Impact:** Test Readability ↑ | Test Reliability ↑ | Maintainability ↑

## Overview

This document defines quality standards for unit tests in the Archery Apprentice project, established on Oct 13, 2025 after identifying and fixing test quality issues in RoundViewModel and RoundDisplayService test suites.

## Core Principles

### 1. No Magic Numbers

**Principle:** All non-obvious numeric values must use named constants with comprehensive documentation.

**Why:** Magic numbers make tests harder to understand and maintain. Future developers (or yourself in 6 months) won't understand why specific values were chosen.

**Pattern:**
```kotlin
// ❌ BAD - Magic number with no context
coEvery { roundRepo.getAllArrowsForRound(roundId) } returns (1..31).map {
    mockk(relaxed = true) {
        every { scoreValue } returns 10
    }
}
assertEquals(310, result.score)  // Why 310? Not obvious!

// ✅ GOOD - Named constant with comprehensive documentation
// Create 31 arrows (5 complete ends + 1 arrow = 5*6 + 1) to simulate in-progress round
// This yields 310 total points (31 arrows * 10 points each) for the Main User
// Note: Full round would be 6 ends * 6 arrows = 36 arrows
val numMockArrows = 31
coEvery { roundRepo.getAllArrowsForRound(roundId) } returns (1..numMockArrows).map {
    mockk(relaxed = true) {
        every { scoreValue } returns 10
    }
}
// Expected: 310 total points (31 arrows * 10 each)
assertEquals(310, result.score)
```

**Documentation Components:**
1. **Named constant** - `val numMockArrows = 31`
2. **Calculation comment** - "5 complete ends + 1 arrow = 5*6 + 1"
3. **Expected outcome** - "yields 310 total points (31 arrows * 10 each)"
4. **Context** - "Full round would be 6 ends * 6 arrows = 36 arrows"

### 2. Timezone-Independent Tests

**Principle:** Use relative time calculations instead of absolute timestamps to ensure tests work across all timezones.

**Why:** Hardcoded timestamps format differently across timezones, causing tests to pass in one region but fail in another.

**Pattern:**
```kotlin
// ❌ BAD - Hardcoded absolute timestamp (timezone-dependent)
val timestamp = 1704067200000L // Jan 1, 2024 UTC (may vary by timezone)
// In UTC: formats as "Jan 1, 2024"
// In PST (-8h): formats as "Dec 31, 2023"
// Test assertions on specific dates will fail in some timezones!

// ✅ GOOD - Relative time calculation (timezone-independent)
val timestamp = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(30) // 30 days ago
// Works in ANY timezone - relative offset is consistent
```

**Import Required:**
```kotlin
import java.util.concurrent.TimeUnit
```

**Common Patterns:**
```kotlin
val thirtyDaysAgo = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(30)
val oneWeekAgo = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(7)
val twoHoursAgo = System.currentTimeMillis() - TimeUnit.HOURS.toMillis(2)
val fiveMinutesAgo = System.currentTimeMillis() - TimeUnit.MINUTES.toMillis(5)
```

**Benefits:**
- Works on all CI/CD runners (UTC, regional)
- Works for developers worldwide (no timezone surprises)
- Self-documenting ("30 days ago" clearer than "1704067200000L")
- No fragile date string assertions needed

### 3. Self-Documenting Tests

**Principle:** Tests should explain "why" not just "what". Intent must be immediately clear.

**Why:** Tests serve as documentation for future developers. If someone needs to modify behavior, they need to understand the original intent.

**Pattern:**
```kotlin
// ❌ BAD - What only
@Test
fun `test calculates score`() {
    val round = createRound(id = 1, ends = 6, arrows = 6)
    mockArrows(31, 10)
    
    val result = viewModel.calculateScore(round)
    
    assertEquals(310, result)
}

// ✅ GOOD - What + Why
@Test
fun `display data multi-participant uses MU-only score for in-progress round`() {
    // Given - multi-participant round with 6 ends × 6 arrows = 36 total arrows
    val multi = createMultiParticipantRound(
        id = 6,
        numEnds = 6,
        numArrows = 6,
        totalScore = 680  // Combined score (MU + Guest)
    )
    
    // Create 31 arrows (5 complete ends + 1 arrow = 5*6 + 1) to simulate in-progress round
    // This yields 310 total points (31 arrows * 10 points each) for the Main User
    // Note: Full round would be 6 ends * 6 arrows = 36 arrows
    val numMockArrows = 31
    mockArrowsForUser("local_user", numMockArrows, scoreValue = 10)
    
    // When - creating display data for multi-participant round
    val dd = viewModel.createRoundDisplayData(multi, null)
    advanceUntilIdle()
    
    // Then - should show MU score (310) NOT combined total (680)
    assertEquals(310, dd.muScore)  // MU-only: 31 arrows * 10 points
    assertEquals(360, dd.muMaxScore)  // Full round potential: 36 arrows * 10 points
    assertEquals(86, dd.muAccuracy.toInt())  // 310/360 = 86%
}
```

**Documentation Components:**
1. **Given-When-Then** - Structure shows test flow
2. **Inline comments** - Explain non-obvious values and calculations
3. **Descriptive test name** - Clearly states what behavior is tested
4. **Expected values** - Document what result means and why

## Real-World Examples

### Example 1: Magic Number Fix (Oct 13, 2025)

**Location:** `RoundViewModelDisplayDataTest.kt:175-178`

**Before:**
```kotlin
coEvery { roundRepo.getAllArrowsForRound(multi.id.toLong()) } returns (1..31).map {
    mockk(relaxed = true) {
        every { participantId } returns "local_user"
        every { scoreValue } returns 10
    }
}
```

**After:**
```kotlin
// Create 31 arrows (5 complete ends + 1 arrow = 5*6 + 1) to simulate in-progress round
// This yields 310 total points (31 arrows * 10 points each) for the Main User
// Note: Full round would be 6 ends * 6 arrows = 36 arrows
val numMockArrows = 31
coEvery { roundRepo.getAllArrowsForRound(multi.id.toLong()) } returns (1..numMockArrows).map {
    mockk(relaxed = true) {
        every { participantId } returns "local_user"
        every { scoreValue } returns 10
    }
}
```

**Impact:**
- Test intent crystal clear - simulating in-progress round
- Calculation visible - 5 complete ends (5×6) + 1 arrow in 6th end
- Expected score documented - 310 points (31 arrows × 10 each)
- Context provided - full round would be 36 arrows

### Example 2: Timezone Fix (Oct 13, 2025)

**Location:** `RoundDisplayServiceTest.kt:240-241, 910`

**Before:**
```kotlin
val createdAt = 1704067200000L, // Jan 1, 2024 UTC (may vary by timezone)
val updatedAt = 1704153600000L  // Jan 2, 2024 UTC (may vary by timezone)

// Later assertion:
assert(result.contains("202")) // Year 2023 or 2024 depending on timezone ⚠️
```

**After:**
```kotlin
import java.util.concurrent.TimeUnit

val createdTimestamp = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(30) // 30 days ago
val updatedTimestamp = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(29) // 29 days ago

// Later assertion (simplified - no fragile year checking):
assert(result.isNotBlank() && result != "Unknown")
```

**Impact:**
- Works in all timezones - no more "passes in UTC, fails in PST" issues
- Self-documenting - "30 days ago" clearer than epoch timestamp
- CI/CD stable - passes on all regional runners
- No fragile assertions - removed year-specific string checks

## Checklist for New Tests

Before submitting a test, verify:

### Magic Numbers
- [ ] All numeric values either self-explanatory (0, 1, 100) or documented
- [ ] Named constants used for non-obvious values
- [ ] Calculation comments show breakdown
- [ ] Expected outcomes documented
- [ ] Context provided (what would full/normal case be?)

### Timestamps
- [ ] No hardcoded absolute timestamps (epoch milliseconds)
- [ ] Use `System.currentTimeMillis() - TimeUnit.DAYS.toMillis(N)` pattern
- [ ] TimeUnit import added
- [ ] Relative time descriptions in comments ("30 days ago")
- [ ] No fragile date string assertions (checking for specific years/dates)

### Documentation
- [ ] Test name clearly describes behavior being tested
- [ ] Given-When-Then structure used
- [ ] Inline comments explain "why" not just "what"
- [ ] Non-obvious test data choices explained
- [ ] Expected values connected to test data (show calculation)

### General Quality
- [ ] Test intent immediately clear to new developer
- [ ] No assumptions about reader's context
- [ ] Easy to modify if requirements change
- [ ] Test failure would be easy to debug

## Benefits Achieved

### From Oct 13, 2025 Implementation

**Before Standards:**
- Tests had magic number 31 with no context
- Tests used hardcoded timestamps causing timezone issues
- Test failures hard to debug
- Maintenance required deep code knowledge

**After Standards:**
- Test intent crystal clear from named constants and comments
- Tests work reliably across all timezones
- Test failures easy to debug from documentation
- New developers can understand and modify tests immediately

**Metrics:**
- **Test Readability**: Significantly improved (named constants + comprehensive comments)
- **Test Reliability**: 100% across timezones (relative time calculations)
- **Maintainability**: Much easier (self-documenting code)
- **Test Pass Rate**: 100% (61/61 tests passing)

## Related Documentation

- [[Test-Coverage-Strategy]] - Overall testing approach and coverage goals
- [[Test-Coverage-Guide]] - Guide for writing tests and improving coverage
- [[RoundViewModel-Testing]] - Specific RoundViewModel test patterns and structure
- [[System-Architecture#Test Quality Metrics]] - Project-wide quality metrics

## Future Work

### Potential Standards to Add

1. **Mock Setup Patterns** - Standard patterns for MockK usage
2. **Test Data Builders** - Reusable builders for common test data
3. **Assertion Messages** - Standards for assertion failure messages
4. **Test Organization** - File structure and grouping conventions
5. **Performance Testing** - Standards for performance-sensitive tests

### Ongoing Improvement

- Apply standards to all new tests (starting Priority 2 RoundViewModel tests)
- Gradually refactor existing tests to meet standards
- Update standards as new patterns emerge
- Track quality metrics (readability, reliability, maintainability)

---

**Last Updated:** Oct 13, 2025  
**Status:** ✅ Active - Applied to all new tests  
**Next Review:** After Priority 2 test completion  
**Owner:** Development Team
