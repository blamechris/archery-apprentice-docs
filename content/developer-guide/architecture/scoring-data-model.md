---
title: Scoring Data Model
tags:
  - architecture
  - data-model
  - scoring
  - team-mode
created: 2025-10-08
source: docs/SCORING_DATA_MODEL.md
last-updated: 2025-09-12
status: implemented
---

# Scoring Data Model

## Overview

This document defines the scoring data model for Archery Apprentice, covering current individual-only behavior, data integrity systems, and planned team mode functionality.

**Last Updated:** September 12, 2025 (Phase 5 implementations)

## Core Concepts

### ScoreSubject

A `ScoreSubject` represents the entity for which scores are calculated and displayed:

- `ScoreSubject.Participant(participantId)` - Individual participant scoring
- `ScoreSubject.Team(teamId)` - Team-based scoring (future implementation)

### Current Behavior (Individual Mode)

**MU Subject Resolution**: The MU (Main User) subject is always resolved as `ScoreSubject.Participant(localUserId)` where `localUserId` is the ID of the `SessionParticipant.LocalUser` found in the round's participant list.

**Score Storage**:
- `round.totalScore` stores **MU-only** score in multi-participant rounds
- `round.maxPossibleScore` represents the maximum possible score for the round format
- This design separates MU scores from aggregate scores to avoid data corruption

**UI Data Flow**:
- Historical and Details screens pull score data exclusively through ViewModel helper methods
- No direct UI math calculations on raw database fields
- All score resolution goes through `resolveMuSubject()` → `getSubjectScore()` → `getSubjectMaxScore()` pipeline

## Data Integrity & Repair Systems ✅ IMPLEMENTED

### Automated Upgrade Hook

**UpgradeRepairManager** (`domain/repository/UpgradeRepairManager.kt`):
- **Purpose**: Ensures data repairs run exactly once after each app upgrade
- **Mechanism**: Uses SharedPreferences key `"aa.repair.v1.done"` to track completion
- **Integration**: Wired into `RoundViewModel` startup; runs automatically if needed
- **Manual Override**: `runRepairsManually()` bypasses completion flag for Settings action
- **Error Handling**: Failed repairs don't mark as complete; allow retry on next startup

### Backfill Operations

**Legacy Totals Backfill** (`RoundRepository.backfillLegacyTotals()`):
- **Purpose**: Repairs historical rounds where `round.totalScore` stored aggregate instead of MU-only scores
- **Detection**: Identifies completed multi-participant rounds with inflated totals via heuristics
- **Process**: Recalculates correct MU-only totals from arrow-level data; updates `round.totalScore`
- **Execution**: `@Transaction`-wrapped; DEBUG-gated logging; idempotent operation
- **Return Value**: List of round IDs that were actually repaired

**Participant Types Backfill** (`RoundRepository.backfillParticipantTypes()`):
- **Purpose**: Ensures participant JSON includes proper type discriminator fields for reliable queries
- **Detection**: Processes all completed rounds with non-empty participant lists
- **Process**: Re-serializes participant data via TypeConverter to include type information
- **Execution**: `@Transaction`-wrapped; throttled processing; idempotent re-serialization
- **Return Value**: List of round IDs that had participant data updated

### Manual Repair Action

**Settings Integration** (`ui/settings/SettingsPage.kt` + `SettingsViewModel.kt`):
- **UI**: "Repair data now" button with confirmation dialog in Settings screen
- **UX**: Progress indicator during operation + snackbar results
- **Backend**: Calls `UpgradeRepairManager.runRepairsManually()` on IO dispatcher
- **State Management**: `repairInProgress` StateFlow prevents concurrent operations
- **Error Handling**: Try/catch with fallback counts; always clears progress state

### Data Validation & Constraints

**Current Model Enforces**:
- **MU-Only Totals**: `round.totalScore` contains **only** Main User scores (never aggregate)
- **Participant Integrity**: All participant data includes proper type discriminators for queries
- **Historical Consistency**: Automated repairs ensure legacy data matches current expectations
- **Idempotent Operations**: All repair methods safe to run multiple times without corruption
- **Defensive UI**: Historical/Details screens use VM subject resolution, never direct field math

## Team Mode Scaffolding ✅ IMPLEMENTED

### Feature Flag Infrastructure

**FeatureFlags.TEAM_MODE** (`data/models/FeatureFlags.kt`):
```kotlin
object FeatureFlags {
    const val TEAM_MODE: Boolean = false // TODO: Flip to true when shipping
}
```

**RoundScoringMode Enum** (`data/models/RoundScoringMode.kt`):
```kotlin
enum class RoundScoringMode {
    INDIVIDUAL,  // Current and default behavior
    TEAM         // Future implementation with team assignments
}
```

### Current Implementation (Feature-Gated)

**Scoring Mode Inference**:
```kotlin
private fun inferScoringMode(round: Round): RoundScoringMode =
    if (FeatureFlags.TEAM_MODE /* && team assignments exist */) 
        RoundScoringMode.TEAM 
    else 
        RoundScoringMode.INDIVIDUAL
```

**Enhanced Subject Resolution**:
```kotlin
fun resolveMuSubject(round: Round, settings: Settings?): ScoreSubject {
    if (inferScoringMode(round) == RoundScoringMode.TEAM && FeatureFlags.TEAM_MODE) {
        // TODO(team-mode): resolve MU's team when team assignments exist
        return ScoreSubject.Participant(resolveLocalParticipantId(round))
    } else {
        return ScoreSubject.Participant(resolveLocalParticipantId(round))
    }
}
```

**Subject-Aware Score Methods** (with team stubs):
- `getSubjectScore()`: Team branch falls back to participant calculation
- `getSubjectMaxScore()`: Team branch falls back to participant calculation
- All team branches preserve current behavior until schema implementation

### UI Label Preparation

```kotlin
// TODO(team-mode): switch to real team score when assignments wired
val isTeam = FeatureFlags.TEAM_MODE && /* future: has team assignments */ false
val scoreLabel = if (isTeam) "Team Score" else "Your Score"
```

**Current Behavior**: Labels use "Your Score" while feature is gated off; ready to flip when assignments are implemented.

## Team Mode Implementation Plan — FUTURE SCHEMA WORK

### Schema Extensions (Not Yet Implemented)

**Planned additions** (when team mode ships):
```kotlin
// Add to Round model:
val scoringMode: RoundScoringMode  // INDIVIDUAL or TEAM
val teamAssignments: Map<ParticipantId, TeamId>?  // null for individual rounds

// New team-specific data structures:
data class TeamScore(val teamId: TeamId, val totalScore: Int, val maxScore: Int)
data class TeamRanking(val teamId: TeamId, val rank: Int, val members: List<ParticipantId>)
```

### Future Subject Resolution Logic

**Enhanced `resolveMuSubject()`** (when schema ready):
```kotlin
fun resolveMuSubject(round: Round, settings: Settings?): ScoreSubject {
    if (round.scoringMode == RoundScoringMode.TEAM && FeatureFlags.TEAM_MODE) {
        val muParticipantId = resolveLocalParticipantId(round)
        val teamId = round.teamAssignments[muParticipantId]
        return if (teamId != null) 
            ScoreSubject.Team(teamId) 
        else 
            ScoreSubject.Participant(muParticipantId)
    } else {
        return ScoreSubject.Participant(resolveLocalParticipantId(round))
    }
}
```

### Score Computation

**Team Score Calculation**:
- Sum individual member scores: `teamScore = members.sumOf { getParticipantScore(it) }`
- Sum individual member max scores: `teamMaxScore = members.sumOf { getParticipantMaxScore(it) }`
- Team accuracy: `teamAccuracy = (teamScore / teamMaxScore) * 100`

**Team Ranking**:
- Rank teams by total team score (descending)
- Handle ties using standard competition ranking rules
- Compute per-team statistics similar to current per-participant stats

### UI Changes

**Label Updates**:
- "Your Score" becomes "Team Score" when `FeatureFlags.TEAM_MODE && hasTeamAssignments`
- Ranking displays show team names instead of individual names
- Team member lists shown in expanded views

**Toggles & Configuration**:
- Team vs Individual view toggle in completed round displays
- Team assignment UI in round setup (future)
- Settings for team mode preferences

## Implementation Status

### Phase 5: Completed ✅ (September 5-12, 2025)

- [x] **Data Integrity Systems**: Backfill infrastructure + UpgradeRepairManager + Settings repair action
- [x] **Historical Screen Fixes**: MU vs aggregate confusion solved; subject-aware display pipeline
- [x] **Team Mode Scaffolding**: `FeatureFlags.TEAM_MODE = false` (feature gated)
- [x] **RoundScoringMode Enum**: Presentation-tier scoring mode abstraction
- [x] **VM Method Stubs**: Subject resolution + score calculation stubs with feature flag guards
- [x] **UI Label Preparation**: "Your Score" vs "Team Score" variables
- [x] **TODO Anchors**: Comprehensive `TODO(team-mode)` markers for future implementation
- [x] **Documentation**: KDoc coverage for all affected methods
- [x] **Test Scaffolding**: `RoundViewModelTeamScaffoldingTest` with team mode test structure

### Next Phase: Schema Implementation (🔄 When Ready)

- [ ] **Round Model Extensions**: Add `scoringMode` and `teamAssignments` fields
- [ ] **Database Migration**: Schema update + migration logic
- [ ] **Team Score Calculation**: Implement real team totals/max/accuracy computation
- [ ] **Team Assignment UI**: Round creation flow with team assignment interface
- [ ] **Team Ranking System**: Enable team-based leaderboards
- [ ] **Team Display Components**: Team member lists, expanded views, toggle interfaces
- [ ] **Comprehensive Testing**: Team mode unit tests, integration tests, UI tests
- [ ] **Feature Flag Flip**: Enable `FeatureFlags.TEAM_MODE = true` for release

## TODO Search Tags

Use these tags to find all team-mode related code:
- `TODO(team-mode)` - General team mode implementation tasks
- `TODO(team-mode): introduce teamAssignments` - Schema-related changes
- `TODO(team-mode): compute teamRank` - Ranking calculation updates
- `TODO(team-mode): expose "Team Score" label` - UI label updates
- `TODO(team-mode): switch to real team score` - Score calculation updates

## Testing Strategy

### Current Tests ✅ IMPLEMENTED

- **Individual Mode Preservation**: All behavior unchanged under `FeatureFlags.TEAM_MODE = false`
- **Subject Resolution**: `resolveMuSubject()` returns participant for MU in all cases
- **Score Calculations**: VM score methods produce identical results to previous implementation
- **Backfill Operations**: `RoundRepository` repair methods are idempotent and safe to re-run
- **Settings Integration**: Manual repair action UI and backend integration tested
- **Test Scaffolding**: `RoundViewModelTeamScaffoldingTest.kt` provides structure for team mode tests

### Future Team Tests (When Schema Ready)

- **Team Score Computation**: Accuracy of team total/max/accuracy calculations
- **Team Ranking**: Leaderboard ordering with ties and complex scenarios
- **Team Assignment Validation**: Proper participant-to-team mapping and edge cases
- **Mixed Round Handling**: Individual and team rounds coexisting
- **Migration Testing**: Conversion from individual to team mode for existing rounds
- **UI Integration**: Team vs individual label switching and display toggling
- **Performance**: Team calculations with large participant counts

## Architecture Integration Notes

### Relationship to Phase 4 (Multi-Participant Foundation)

- **Builds On**: Per-participant scoring isolation and DB schema from Phase 4
- **Extends**: Subject abstraction layer enables both individual participants and teams
- **Preserves**: All Phase 4 functionality (Previous Ends, per-participant stats) unchanged

### Integration with Existing Systems

- **Equipment Models**: Team mode compatible with existing guest bow setup system
- **Network Participants**: Team assignments work with arbitrary `participantId` values
- **Statistics Pipeline**: Team stats can reuse existing per-participant calculation methods
- **Historical Data**: Repair systems ensure clean foundation for team mode implementation

### Performance Considerations

- **Display Data Caching**: `createRoundDisplayData()` caching works for both individual and team modes
- **Repair Throttling**: Backfill operations use in-process throttling to prevent UI blocking
- **Feature Flag Isolation**: Zero performance impact when `TEAM_MODE = false`
- **Future Optimization**: Team score calculations designed for efficient member aggregation

## Related Documentation

- [[System-Architecture]] - Overall system architecture
- [[MVVM-Patterns]] - ViewModel implementation patterns
- [[Technical-Debt]] - Technical debt tracking

---

*Phase 5 Implemented: September 2025*
*Source: `docs/SCORING_DATA_MODEL.md`*