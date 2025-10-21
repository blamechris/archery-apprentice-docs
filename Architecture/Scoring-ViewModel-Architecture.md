---
tags: [architecture, viewmodel, delegate-pattern, refactoring, scoring, roundviewmodel, livescoringviewmodel]
created: 2025-01-22
related:
  - "[[Architecture]]"
  - "[[RoundViewModel-Audit]]"
  - "[[RoundViewModel-Refactoring-Plan]]"
  - "[[Refactoring-Reality-Check]]"
  - "[[Refactoring-Roadmap]]"
---

# Scoring ViewModel Architecture

## Overview

The ScoringViewModelDelegate serves as the **production entry point** that coordinates between UI components and the underlying ViewModels in the archery scoring system. This delegate pattern ensures proper separation of concerns while maintaining backward compatibility during the refactor from RoundViewModel to LiveScoringViewModel.

## Architecture Pattern

```
UI Components → ScoringViewModelDelegate → [RoundViewModel | LiveScoringViewModel]
```

### Core Principle
**The delegate owns NO state** - it is a pure coordination layer that routes method calls to the appropriate ViewModel based on functionality.

## Method Routing Table

| Method Category | Delegate Method | Target ViewModel | Rationale |
|----------------|----------------|------------------|-----------|
| **Session Management** | | | |
| | `getRoundById()` | RoundViewModel | Data loading responsibility |
| | `getRoundWithDetails()` | RoundViewModel | Data loading responsibility |
| | `startScoringSession()` | Both (complex) | Requires coordination between both |
| | `loadScoringSession()` | Delegates to startScoringSession | Consistency |
| | `resumeScoringSession()` | Delegates to startScoringSession | Consistency |
| **Scoring Operations** | | | |
| | `addArrowScore()` | LiveScoringViewModel | New scoring authority |
| | `addArrowScoreWithCoordinate()` | LiveScoringViewModel | New scoring authority |
| | `updateArrowScore()` | LiveScoringViewModel | New scoring authority |
| | `editArrowScore()` | LiveScoringViewModel | New scoring authority |
| | `removeLastArrowScoreWithCoordinate()` | LiveScoringViewModel | New scoring authority |
| | `canEditArrow()` | LiveScoringViewModel | Scoring state authority |
| | `setCurrentArrow()` | LiveScoringViewModel | Scoring state authority |
| | `clearCurrentEndWithCoordinates()` | LiveScoringViewModel | Scoring state authority |
| **End Management** | | | |
| | `completeCurrentEnd()` | LiveScoringViewModel | End logic authority |
| | `getCurrentEndArrowPlacements()` | LiveScoringViewModel | Current end state |
| **Participant Management** | | | |
| | `switchParticipant()` | LiveScoringViewModel | Multi-participant authority |
| **State Access** | | | |
| | `scoringSession` | LiveScoringViewModel | Single source of truth |
| | `isProcessingScore` | LiveScoringViewModel | Scoring state |
| | `isLoading` | RoundViewModel | Legacy loading state |
| | `errorMessage` | RoundViewModel | Legacy error handling |
| **Statistics & Progress** | | | |
| | `participantLiveStats()` | LiveScoringViewModel | Real-time statistics |
| | `leaderboardTotals()` | LiveScoringViewModel | Current totals |
| | `currentParticipantProgress()` | LiveScoringViewModel | Progress tracking |
| | `currentParticipantEndNumber()` | LiveScoringViewModel | Current state |
| | `currentParticipantEndsCompleted()` | LiveScoringViewModel | Progress tracking |
| | `currentParticipantPoints()` | LiveScoringViewModel | Current scoring |
| | `currentParticipantMaxPoints()` | LiveScoringViewModel | Scoring calculations |
| **Event Flows** | | | |
| | `endCompleteEvent` | LiveScoringViewModel | Event emission authority |
| | `roundCompleteEvent` | LiveScoringViewModel | Event emission authority |
| | `sessionStateEvent` | LiveScoringViewModel | Event emission authority |
| **Error Handling** | | | |
| | `clearError()` | RoundViewModel | Legacy error handling |

## State Ownership Patterns

### LiveScoringViewModel Owns:
- **Scoring Session State**: All current round data, arrows, participants
- **Real-time Progress**: Current end, arrow count, completion status
- **Event Emission**: End completion, round completion, state changes
- **Scoring Logic**: Arrow validation, score calculations
- **Multi-participant State**: Participant switching, progress tracking

### RoundViewModel Owns:
- **Data Loading**: Round data, statistics, historical data
- **Navigation State**: Loading states, error messages
- **Legacy Compatibility**: Backward compatibility during transition

### ScoringViewModelDelegate Owns:
- **Nothing** - Pure delegation layer with no state storage

## Complex Coordination: startScoringSession()

The most complex method in the delegate is `startScoringSession()`, which requires coordination between both ViewModels:

```kotlin
suspend fun startScoringSession(roundId: Int) {
    // 1. Load round data via RoundViewModel
    val round = roundViewModel.getRoundById(roundId)

    // 2. Initialize LiveScoringViewModel context
    liveScoringViewModel.setCurrentRound(round)

    // 3. Load existing session data via RoundViewModel
    roundViewModel.loadScoringSession(roundId)
    val sessionState = roundViewModel.scoringSession.value

    // 4. Transfer complete state to LiveScoringViewModel
    liveScoringViewModel.loadSessionFromRoundData(
        round = round,
        roundWithDetails = sessionState.currentRound,
        // ... all participant data
    )

    // 5. Clean up loading state
    roundViewModel.clearLoadingState()
}
```

This pattern ensures:
- Data integrity during the transition
- Proper state initialization for complex multi-participant scenarios
- Backward compatibility with existing persistence layer

## Testing Strategy

### High Priority Tests
1. **Delegation Verification**: Ensure each method calls the correct target ViewModel
2. **State Routing**: Verify state access goes to the correct source
3. **Complex Coordination**: Test `startScoringSession()` flow thoroughly
4. **Error Handling**: Verify error propagation and handling

### Medium Priority Tests
1. **Event Flow**: Verify events are properly exposed from LiveScoringViewModel
2. **State Consistency**: Ensure no state leakage between ViewModels
3. **Edge Cases**: Null handling, invalid data scenarios

### Test Architecture
- **Mock both ViewModels**: Verify delegation without business logic
- **Verify call sequences**: Especially for complex coordination methods
- **Test state access patterns**: Ensure proper routing of state queries

## Future Refactoring Notes

### Phase 1 (Current): Delegation Pattern
- ✅ All scoring operations route to LiveScoringViewModel
- ✅ Data loading remains with RoundViewModel
- ✅ State access primarily through LiveScoringViewModel

### Phase 2 (Future): Complete Migration
- **Goal**: Eliminate delegate, use LiveScoringViewModel directly
- **Requirements**:
  - Migrate data loading to LiveScoringViewModel or separate service
  - Consolidate error handling
  - Update all UI components to use LiveScoringViewModel directly

### Phase 3 (Long-term): Service Layer
- **Goal**: Extract data operations to dedicated services
- **Benefits**: Clear separation between ViewModels and data layer
- **Pattern**: UI → ViewModel → Service → Repository

## Key Architectural Decisions

1. **No State in Delegate**: Maintains clean separation and prevents state duplication
2. **LiveScoringViewModel as Authority**: All scoring operations and real-time state
3. **Gradual Migration**: Allows incremental refactoring without breaking changes
4. **Event-Driven Communication**: ViewModels communicate through events, not direct calls

## Testing Patterns Discovered

### Effective Testing Strategies

1. **Property Delegation Testing**
   - **Challenge**: Flow objects from MockK don't have stable equality comparison
   - **Solution**: Verify access via MockK verification + test actual values from mock StateFlows
   - **Pattern**: `verify(exactly = 1) { mockViewModel.property }` + `assertEquals(expectedValue, delegate.property.value)`

2. **Event Flow Testing**
   - **Challenge**: Event flows return different types (EndCompletionResult, SessionStateEvent, Unit)
   - **Solution**: Mock with correct flow types + verify access + null checks
   - **Pattern**: Set up `MutableSharedFlow<CorrectType>()` in test setup

3. **Complex Coordination Testing**
   - **Focus**: Verify method call sequences rather than internal state changes
   - **Pattern**: Use MockK `verify` with specific call order verification
   - **Coverage**: Achieved through systematic testing of each delegation path

4. **Compilation Error Resolution**
   - **Data Type Mismatches**: Ensure test data uses correct enum values (RoundStatus.IN_PROGRESS vs ACTIVE)
   - **Constructor Parameters**: Some data classes require all parameters (SessionParticipant.LocalUser needs displayName)
   - **Return Type Consistency**: Match actual ViewModel return types exactly

### Coverage Achievement

**Target**: >80% coverage for production-critical delegate layer
**Result**: **93% instruction coverage** (442 total instructions, 29 missed)

- **Branch Coverage**: 75% (8 branches, 2 missed)
- **Line Coverage**: 94% (110 lines, 6 missed)
- **Method Coverage**: 97% (35 methods, 1 missed)

### Test Architecture Success Factors

1. **Comprehensive Method Coverage**: 36 tests covering all delegate functionality
2. **Mock Strategy**: Separate ViewModels with relaxed mocking + specific return values
3. **Error Handling**: Tests handle deprecated methods gracefully
4. **Data Setup**: Realistic test data matching production patterns

## Testing Considerations

- **Mock Verification**: Critical for ensuring proper delegation
- **State Isolation**: Tests must verify no cross-ViewModel state contamination
- **Complex Flows**: Special attention to `startScoringSession()` coordination
- **Future-Proofing**: Tests should make it easy to remove delegate layer later
- **Type Safety**: Ensure all Flow types match actual implementation types
- **Compilation Safety**: Test data must match exact data class constructors

---

**Source**: `docs/architecture/scoring-viewmodel-architecture.md`  
**Implementation**: `app/src/main/java/com/archeryapprentice/ui/roundScoring/delegate/ScoringViewModelDelegate.kt`

This architecture enables the transition from legacy RoundViewModel to modern LiveScoringViewModel while maintaining production stability and providing a clear path for future consolidation.