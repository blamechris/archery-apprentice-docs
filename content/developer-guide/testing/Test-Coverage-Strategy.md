---
title: "Test Coverage Strategy"
description: "Comprehensive test coverage strategy and philosophy for Archery Apprentice"
category: "development"
audience: ["developers"]
difficulty: "intermediate"
status: "active"
last_updated: "2025-10-09"
tags:
  - testing
  - coverage
  - strategy
  - quality
  - best-practices
related_docs:
  - title: "Test Quality Standards"
    path: "/Development/Testing/Test-Quality-Standards.md"
    relationship: "related"
  - title: "Test Failure Analysis"
    path: "/Development/Testing/Test-Failure-Analysis.md"
    relationship: "related"
---

[Home](/) > [Development](/Development/) > [Testing](/Development/Testing/) > Test Coverage Strategy

---

# Test Coverage Strategy

**Last Updated:** 2025-10-09
**Overall Coverage:** 99%
**Status:** 🟢 Excellent

## Coverage Philosophy

### Priority-Based Testing
Focus testing efforts on high-value, high-risk areas:

1. **Critical Business Logic** (Priority 1)
   - Rank display calculations
   - Sorting algorithms
   - Score calculations
   - Auto-selection logic

2. **State Management** (Priority 2)
   - ViewModel state transitions
   - Service state synchronization
   - Lifecycle handling

3. **Edge Cases** (Priority 3)
   - Boundary conditions
   - Null handling
   - Unusual input patterns

4. **Happy Path** (Priority 4)
   - Basic functionality
   - Standard user flows

## Recent Achievements

### Oct 9, 2025 - RoundViewModel Coverage Expansion
**Coverage Increase:** 50.99% → >60% (~+10%)
**Tests Added:** 25 new tests

#### formatRankDisplay (13 tests)
Tests comprehensive rank suffix logic:
- Basic suffixes: 1st, 2nd, 3rd, 4th-10th
- Teen exceptions: 11th, 12th, 13th (not 11st, 12nd, 13rd)
- Pattern continuation: 21st, 22nd, 23rd
- Large numbers: 111th, 1001st, 1012th
- Singular/plural: "participant" vs "participants"

**Key Learning:** Teen numbers (11-13) use "th" suffix, not standard rules

#### getSortedEndsForDisplay (4 tests)
Tests multi-participant end sorting:
- Single-participant: chronological order
- Multi-participant: end number → participant ID
- Null handling
- Empty list handling

**Key Learning:** Multi-participant rounds need stable sorting for consistent display

#### isScoringSystemAutoSelected (8 tests)
Tests auto-selection logic for scoring systems:
- All target sizes (40cm, 60cm, 80cm, 122cm)
- Null target size handling
- Integration with getAvailableScoringSystems
- Edge case handling

**Key Discovery:** All target sizes have 4 valid scoring systems (method always returns false)

## Test Organization Patterns

### Focused Test Files
Split large test classes by functional area:

```
RoundViewModelTestBase (abstract)
├── RoundViewModelHelperMethodsTest
│   ├── formatRankDisplay (13 tests)
│   └── getSortedEndsForDisplay (4 tests)
├── RoundViewModelInputValidationTest
│   └── isScoringSystemAutoSelected (8 tests)
├── RoundViewModelScoreCalculationTest
│   └── Score calculation tests
└── RoundViewModelProgressTest
    └── Progress tracking tests
```

**Benefits:**
- Easier navigation (grouped by function)
- Faster execution (run specific areas)
- Clear organization
- Shared setup via base class

### Test Naming Convention
Use descriptive test names that serve as documentation:

```kotlin
@Test
fun `formatRankDisplay - formats 11th place correctly (exception to rule)`() {
    // Test name explains both behavior and WHY it's important
}
```

**Pattern:** `methodName - describes behavior (optional context)`

## Edge Case Testing

### Common Edge Cases to Test

#### Numeric Handling
- **Teen Numbers:** 11th, 12th, 13th (exception to suffix rules)
- **Large Numbers:** 111th, 1001st (pattern continuation)
- **Boundary Values:** 0, 1, Integer.MAX_VALUE

#### Collections
- **Empty Collections:** Empty list, empty map
- **Single Item:** List with one element
- **Null Items:** Null elements in collection
- **Large Collections:** Stress test with many items

#### State Management
- **Null State:** State fields that might be null
- **Initial State:** Before any user interaction
- **Invalid State:** Combinations that shouldn't happen
- **Transition States:** Mid-change states

### Example: Teen Number Edge Case
```kotlin
@Test
fun `formatRankDisplay - formats 11th place correctly (exception to rule)`() {
    // When
    val result = viewModel.formatRankDisplay(11, 20)

    // Then - 11th uses "th" not "st"
    assertEquals("11th / 20 participants", result)
}
```

**Rationale:** Users expect "11th" not "11st" - tests document this exception

## Test Data Generation

### Helper Methods for Complex Objects
Create reusable helpers for test data:

```kotlin
private fun createEndScoreWithArrows(
    endNumber: Int,
    totalScore: Int = 50,
    participantId: String? = null,
    arrowScores: List<Int> = listOf(8, 9, 10, 10, 9, 4)
): EndScoreWithArrows {
    val endScore = EndScore(
        id = endNumber,
        roundId = 1,
        endNumber = endNumber,
        totalScore = arrowScores.sum(),
        participantId = participantId
    )
    val arrows = arrowScores.mapIndexed { index, score ->
        ArrowScore(
            id = (endNumber * 10 + index).toLong(),
            endScoreId = endNumber.toLong(),
            arrowNumber = index + 1,
            scoreValue = score,
            isX = false,
            participantId = participantId
        )
    }
    return EndScoreWithArrows(endScore, arrows)
}
```

**Benefits:**
- Reduces duplication
- Consistent test data
- Easy to modify
- Clear intent

## Coverage Goals

### Current Status
- **Overall Project:** 99%
- **RoundViewModel:** >60%
- **EndCompletionService:** 100%
- **TournamentSyncService:** 100%
- **ScoreConflictResolutionService:** 100%

### Near-term Goals
- **RoundViewModel:** Target 70%+
- **LiveScoringViewModel:** Maintain current coverage through refactoring
- **New Services:** 100% coverage on extraction

### Long-term Goals
- **Overall Project:** Maintain 99%+
- **Critical Paths:** 100% coverage
- **Edge Cases:** Comprehensive coverage
- **Integration Tests:** All service interactions

## Tools and Metrics

### JaCoCo Coverage Reports
- Run: `./gradlew testDebugUnitTest jacocoTestReport`
- Location: `app/build/reports/jacoco/`
- Review: HTML report for visual coverage

### Test Execution
```bash
# All tests
./gradlew testDebugUnitTest

# Specific test file
./gradlew :app:testDebugUnitTest --tests="*RoundViewModel*"

# Specific test method
./gradlew :app:testDebugUnitTest --tests="*.formatRankDisplay*"
```

## Best Practices

### 1. Test First When Possible
Write failing test → Implement → Verify
- Documents expected behavior
- Prevents over-engineering
- Ensures testability

### 2. Test Edge Cases, Not Just Happy Path
- Teen numbers (11th, 12th, 13th)
- Boundary values (0, 1, max)
- Null states
- Empty collections

### 3. Use Descriptive Test Names
```kotlin
// ✅ Good: Describes behavior and context
fun `formatRankDisplay - formats 11th place correctly (exception to rule)`()

// ❌ Bad: Unclear intent
fun testRankFormat()
```

### 4. Keep Tests Focused
One assertion per test when possible:
- Easier to diagnose failures
- Clear test intent
- Better documentation

### 5. Maintain Test Organization
- Group related tests in focused files
- Use shared base classes
- Keep test files manageable size (<500 lines)

## Exclusions

### Justified Coverage Exclusions
Some code doesn't need/benefit from unit tests:

1. **Pure Compose UI Components**
   - Example: NetworkStatusBanner.kt (0% - green apple icon)
   - Reason: UI testing better suited to instrumented tests

2. **Generated Code**
   - Example: Dagger/Hilt generated code
   - Reason: Generated by tools, not manual code

3. **Simple Getters/Setters**
   - Example: Data class property accessors
   - Reason: No business logic to test

4. **Deprecated Methods**
   - Example: Methods marked for removal
   - Reason: Will be deleted, not worth test investment

## Anti-Patterns to Avoid

### ❌ Testing Framework Code
Don't test the framework itself:
```kotlin
// ❌ Bad: Testing StateFlow itself
@Test
fun `StateFlow emits values`() {
    val flow = MutableStateFlow(1)
    flow.value = 2
    assertEquals(2, flow.value)
}
```

### ❌ Over-Mocking
Too many mocks hide real behavior:
```kotlin
// ❌ Bad: Mocking everything
every { mock.method1() } returns value1
every { mock.method2() } returns value2
every { mock.method3() } returns value3
// ... 20 more mocks
```

### ❌ Testing Implementation Details
Test behavior, not implementation:
```kotlin
// ❌ Bad: Testing private method
viewModel.privateHelperMethod()

// ✅ Good: Testing public API
val result = viewModel.publicMethod()
assertEquals(expected, result)
```

## Success Metrics

### Quantitative
- **Coverage Percentage:** >99% overall
- **Test Count:** ~2,000+ tests
- **Test Success Rate:** 100%
- **Build Time:** <2 minutes for unit tests

### Qualitative
- **Confidence:** Safe to refactor business logic
- **Documentation:** Tests explain expected behavior
- **Regression Prevention:** Bugs caught before production
- **Maintainability:** Clear test organization

---

## Related Documentation

- [Test Quality Standards](/Development/Testing/Test-Quality-Standards.md)
- [Test Failure Analysis](/Development/Testing/Test-Failure-Analysis.md)
- [Coverage Guide](/Development/Testing/Coverage-Guide.md)

---

**Document Info:**
- **Version:** 1.0
- **Last Updated:** 2025-10-09
- **Migrated:** 2025-10-29 (Phase 2A)
- **Original Location:** `Testing/Test-Coverage-Strategy.md`
