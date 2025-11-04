---
tags: [testing, migration, viewmodel, refactoring, adapter-pattern]
created: 2025-10-08
status: reference
migration-files: 8
completed-examples: 1
related:
  - "[[Test-Failure-Analysis]]"
  - "[[Service-Architecture]]"
---

[Home](/) > [Development](/Development/) > [Testing](/Development/Testing/) > ---

---


# RoundViewModelTestAdapter Migration Guide

## Purpose
This guide helps migrate tests from deprecated RoundViewModel scoring methods to LiveScoringViewModel using the test adapter pattern.

## Quick Migration Steps

### 1. Add Imports
```kotlin
import com.archeryapprentice.test.support.RoundViewModelTestAdapter
import com.archeryapprentice.test.support.ViewModelFactory
```

### 2. Add LiveScoringViewModel and Adapter Setup
```kotlin
class YourTest {
    private lateinit var viewModel: RoundViewModel
    private lateinit var liveScoringViewModel: LiveScoringViewModel
    private lateinit var testAdapter: RoundViewModelTestAdapter

    @Before
    fun setup() {
        // ... existing setup ...

        viewModel = RoundViewModel(
            application = mockk(relaxed = true),
            repositoryFactory = mockRepositoryFactory
        )

        // Create LiveScoringViewModel for new scoring architecture
        liveScoringViewModel = ViewModelFactory.createLiveScoringViewModel(
            application = mockk(relaxed = true),
            roundRepository = mockRoundRepository
        )

        // Create test adapter to route deprecated methods to LiveScoringViewModel
        testAdapter = RoundViewModelTestAdapter(viewModel, liveScoringViewModel)
    }
}
```

### 3. Replace Deprecated Method Calls

| Old (Deprecated) | New (Adapter) |
|------------------|---------------|
| `viewModel.addArrowScore(10, false)` | `testAdapter.addArrowScore(10, false)` |
| `viewModel.completeCurrentEnd()` | `testAdapter.completeCurrentEnd()` |
| `viewModel.finalizeEnd(participantId, endNumber)` | `testAdapter.finalizeEnd(participantId, endNumber)` |

### 4. Access State Through Adapter
```kotlin
// State access remains the same
val session = testAdapter.scoringSession.value
val progress = testAdapter.roundVM.someOtherProperty
```

## Files That Need Migration

Based on analysis of deprecated method usage:

1. **PostRefactorIntegrationTest.kt** - 7 calls
2. **EndCompletionBehaviorComparisonTest.kt** - 5 calls
3. **GuAdvancementTest.kt** - 5 calls
4. **MultiParticipantIntegrationTest.kt** - 3 calls
5. **EndSummaryKeyUniquenessTest.kt** - (count needed)
6. **FailingTestDebugTest.kt** - (count needed)
7. **MPEndCompletionFlowValidationTest.kt** - (count needed)
8. **LiveScoringViewModelTest.kt** - (count needed)

## Example Migration (Already Complete)

`SingleParticipantFinalEndCompletionRegressionTest.kt` has been migrated as a reference example:

**Before:**
```kotlin
viewModel.addArrowScore(10, false)
viewModel.addArrowScore(9, false)
viewModel.addArrowScore(8, false)
viewModel.completeCurrentEnd()
```

**After:**
```kotlin
testAdapter.addArrowScore(10, false)
testAdapter.addArrowScore(9, false)
testAdapter.addArrowScore(8, false)
testAdapter.completeCurrentEnd()
```

## Benefits of Adapter Pattern

1. **Incremental Migration**: Tests can be migrated one at a time
2. **Working State**: Each migration leaves tests in working condition
3. **Clear Path**: Obvious migration path to eventual LiveScoringViewModel usage
4. **Rollback Safety**: Easy to revert changes if needed
5. **Testing New Architecture**: Validates LiveScoringViewModel functionality in test context

## Future Cleanup

After all tests are migrated to the adapter:
1. Remove deprecated methods from RoundViewModel
2. Gradually replace adapter usage with direct LiveScoringViewModel calls
3. Remove adapter when no longer needed
4. Complete the ViewModel refactoring

## Notes

- Tests should continue to pass after migration (existing failures may remain)
- Adapter provides same interface as original deprecated methods
- LiveScoringViewModel state and RoundViewModel state may differ during transition
- Focus on mechanical replacement first, logic validation second

---

**Related Documentation:**
- See [[Test-Failure-Analysis]] for state synchronization issues
- See [[Service-Architecture]] for ViewModel refactoring architecture
