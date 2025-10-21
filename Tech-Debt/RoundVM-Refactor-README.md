---
tags: [refactoring, roundviewmodel, god-class, viewmodel-extraction, tech-debt, checklist]
created: 2025-01-22
related:
  - "[[RoundViewModel-Audit]]"
  - "[[RoundViewModel-Refactoring-Plan]]"
  - "[[Refactoring-Reality-Check]]"
  - "[[Tech-Debt]]"
  - "[[Architecture]]"
---

# RoundViewModel Refactor Plan

## Overview
The RoundViewModel.kt is a 3,013-line god class that needs safe, incremental refactoring while maintaining runtime behavior.

## Current Package Layout

### Main Implementation
- `app/src/main/java/com/archeryapprentice/ui/roundScoring/RoundViewModel.kt` (3,013 lines)

### Test Files
- `app/src/test/java/com/archeryapprentice/ui/roundScoring/RoundViewModelTest.kt`
- `app/src/test/java/com/archeryapprentice/ui/roundScoring/RoundViewModelTestBase.kt`
- `app/src/test/java/com/archeryapprentice/ui/roundScoring/RoundViewModelDisplayDataTest.kt`
- `app/src/test/java/com/archeryapprentice/ui/roundScoring/RoundViewModelMuScoreTest.kt`
- `app/src/test/java/com/archeryapprentice/ui/roundScoring/RoundViewModelMuMaxScoreTest.kt`
- `app/src/test/java/com/archeryapprentice/ui/roundScoring/RoundViewModelTeamScaffoldingTest.kt`
- `app/src/test/java/com/archeryapprentice/rounds/RoundViewModelHelperTest.kt`
- `app/src/androidTest/java/com/archeryapprentice/ui/roundScoring/RoundViewModelMp2x3SanityTest.kt`

## Target Package Layout

### Core ViewModels (New)
```
com.archeryapprentice.ui.roundScoring.viewmodels/
├── RoundViewModel.kt                    # Main coordinator (reduced size)
├── RoundCreationViewModel.kt           # Round setup and creation
├── RoundScoringViewModel.kt            # Arrow scoring logic
├── RoundNavigationViewModel.kt         # End/participant navigation
├── RoundDisplayViewModel.kt            # UI state and formatting
├── RoundStatisticsViewModel.kt         # Statistics calculations
└── RoundTeamViewModel.kt               # Multi-participant support
```

### State Management
```
com.archeryapprentice.ui.roundScoring.state/
├── RoundInputState.kt                  # Form input state
├── RoundDisplayState.kt                # UI display state
├── RoundScoringState.kt                # Scoring state
└── RoundNavigationState.kt             # Navigation state
```

### Business Logic
```
com.archeryapprentice.ui.roundScoring.domain/
├── RoundCreationUseCase.kt
├── ScoringUseCase.kt
├── StatisticsUseCase.kt
└── ValidationUseCase.kt
```

## Refactor Checklist

### Phase 1: Infrastructure Setup ✓
- [x] Create this documentation
- [x] Add RefactorFlags.kt with USE_NEW_VMS = false
- [x] Add :reportCoverage Gradle alias
- [x] Add CONTRIBUTING notes for coverage

### Phase 2: Extract State Classes
- [ ] Move RoundInputState to separate file
- [ ] Extract RoundDisplayState from main class
- [ ] Create RoundScoringState
- [ ] Create RoundNavigationState
- [ ] Update tests for extracted states

### Phase 3: Extract Use Cases
- [ ] Create RoundCreationUseCase
- [ ] Create ScoringUseCase
- [ ] Create StatisticsUseCase
- [ ] Create ValidationUseCase
- [ ] Update main ViewModel to use cases
- [ ] Update tests

### Phase 4: Extract Specialized ViewModels
- [ ] Create RoundCreationViewModel
- [ ] Create RoundScoringViewModel
- [ ] Create RoundNavigationViewModel
- [ ] Create RoundDisplayViewModel
- [ ] Create RoundStatisticsViewModel
- [ ] Create RoundTeamViewModel

### Phase 5: Integration and Cleanup
- [ ] Update UI components to use new ViewModels (gated by RefactorFlags.USE_NEW_VMS)
- [ ] Comprehensive testing of new architecture
- [ ] Enable RefactorFlags.USE_NEW_VMS = true
- [ ] Remove old RoundViewModel code
- [ ] Clean up unused imports and dependencies

## Rules

1. **No Runtime Behavior Changes**: Each step must maintain identical external behavior
2. **Test Coverage**: Run coverage reports before/after each phase
3. **Feature Flags**: Use RefactorFlags to gate UI migrations
4. **Incremental**: One logical unit at a time
5. **Validation**: All existing tests must pass after each step

## Success Metrics

- [ ] Reduce main RoundViewModel.kt from 3,013 lines to <500 lines
- [ ] Maintain or improve test coverage (currently at baseline)
- [ ] All existing functionality preserved
- [ ] Improved code maintainability and readability
- [ ] Clear separation of concerns

---

**Source**: `techdebt/README_RoundVM_Refactor.md`  
**Status**: Phase 1 complete, remaining phases planned  
**See Also**: [[RoundViewModel-Audit]] for detailed analysis, [[Refactoring-Reality-Check]] for actual outcomes