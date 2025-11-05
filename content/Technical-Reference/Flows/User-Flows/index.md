---
title: "User Flows"
description: "User interaction flows and workflows"
category: "technical-reference"
audience: "developers, designers"
status: "active"
tags:
  - flows
  - user-experience
  - user-journey
  - workflows
---

[Home](/) > [Technical Reference](../../) > [Flows](../) > User Flows

---

# User Flows

Complete reference for user-facing workflows and interaction patterns in Archery Apprentice.

## Overview

User flows describe the complete journey users take through the application, from initial setup to advanced features like tournament participation and performance analytics. This guide documents all major user-facing workflows.

**Flow Organization:**

Flows are organized by user journey stage, from initial setup through advanced features:

1. **Setup & Configuration** - Onboarding, equipment setup, preferences
2. **Core Activities** - Scoring rounds, viewing history
3. **Advanced Features** - Tournaments, analytics, exports

**Related Documentation:**

- [System Flows](../System-Flows/) - Internal system processes
- [Integration Flows](../Integration-Flows/) - External service integrations
- [User Guide](../../../user-guide/) - User-facing documentation

---

## User Journey Map

```
First Launch → Onboarding → Equipment Setup → Settings Configuration
     ↓
Create Round → Select Equipment → Start Scoring → Complete Round
     ↓
View History → View Analytics → Compare Equipment → Export Data
     ↓
(Optional) Join Tournament → Score in Tournament → View Leaderboard
```

---

## Setup & Configuration Flows

Flows related to initial setup and configuration of the application.

### 1. Onboarding Flow

**Status:** ⚠️ Not Fully Documented
**Documentation:** See [User Guide - Getting Started](../../../user-guide/getting-started/)

**Overview:**

First-time user experience introducing core features and guiding initial setup.

**Flow Steps:**

1. **First Launch Detection**
   - Settings entity checked for `isFirstLaunch` flag
   - If true, show onboarding screens
   - Skip if user has already completed onboarding

2. **Feature Introduction**
   - Welcome screen
   - Core feature highlights (scoring, equipment, analytics)
   - Permission requests (if any)

3. **Optional Setup**
   - Create first bow setup (optional, can skip)
   - Set default preferences (measurement system)
   - Set user display name

4. **Onboarding Completion**
   - Update Settings entity: `isFirstLaunch = false`
   - Persist onboarding completion
   - Navigate to main screen (Dashboard or Rounds list)

**Key Components:**

- OnboardingScreen.kt (Compose UI screens)
- SettingsRepository.kt (persist onboarding completion)
- Settings entity (first launch flag)

**User Can:**

- Skip onboarding (return to onboarding from Settings)
- Complete minimal setup and configure later
- Return to feature introductions via Settings > Help

**Exit Points:**

- Main Dashboard screen
- Rounds list screen
- Equipment setup screen (if user chooses to set up equipment first)

---

### 2. Equipment Setup Flow

**Status:** ✅ Fully Documented (1,949 lines)
**Documentation:** [Equipment Management End-to-End Flow](../../../../developer-guide/technical-reference/flows/equipment-management-end-to-end-flow/)

**Overview:**

Complete workflow for creating, managing, and versioning bow setups with 10+ component types.

**Flow Steps:**

1. **Navigate to Equipment**
   - Bottom navigation → Equipment tab
   - Or: Create Round → "Create new setup" link

2. **Create Bow Setup**
   - Enter bow setup name (e.g., "Competition Recurve")
   - Optionally add description
   - Select bow type (Recurve, Compound, Longbow, Barebow)

3. **Add Equipment Components**
   - Add Arrows (shaft type, length, weight, fletching)
   - Add Sight (type, model, manufacturer)
   - Add Rest (type, model)
   - Add Stabilizer (length, weight, configuration)
   - Add Plunger, Clicker, Tab, String, Nocking Point, Kisser Button (all optional)

4. **Save Bow Setup**
   - Validation (bow setup name required)
   - Initial version created (v1)
   - Snapshot saved to database

5. **Select for Round**
   - During round creation, select this bow setup
   - Bow setup snapshot embedded in round
   - Historical accuracy preserved even if equipment changes later

**Key Components:**

- BowSetupViewModel.kt - Orchestration
- BowSetupRepository.kt - CRUD and versioning
- Equipment component ViewModels (10+ specialized)
- BowSetupDetailScreen.kt - Configuration UI

**User Can:**

- Create multiple bow setups
- Edit equipment (creates new version)
- View equipment performance statistics
- Export equipment data to CSV
- Delete unused equipment
- Duplicate equipment for guests (multi-participant)

**Equipment Versioning:**

Every equipment modification creates a new version. Historical rounds reference specific versions via snapshots, ensuring accuracy even after equipment changes.

```
Bow Setup v1 (Original) → Add Sight → Bow Setup v2 → Change Arrows → Bow Setup v3
         ↓                              ↓                              ↓
   Round 1 (uses v1)            Round 2 (uses v2)            Round 3 (uses v3)
```

**See Full Documentation:** [Equipment Management End-to-End Flow](../../../../developer-guide/technical-reference/flows/equipment-management-end-to-end-flow/)

---

### 3. Settings Configuration Flow

**Status:** ✅ Fully Documented (493 lines)
**Documentation:** [Settings Architecture](../../../../developer-guide/technical-reference/flows/settings-architecture/)

**Overview:**

Device settings management with reactive StateFlow propagation for user preferences.

**Flow Steps:**

1. **Navigate to Settings**
   - Bottom navigation → Settings tab
   - Or: Hamburger menu → Settings

2. **Configure Display Preferences**
   - Measurement system (Metric vs Imperial)
   - Target zoom behavior (Auto-zoom vs Manual)
   - Theme preferences (Light/Dark/System) - if implemented

3. **Configure User Identity**
   - Set display name (used for local rounds)
   - View Firebase user ID (if authenticated)
   - Manage account settings

4. **Configure Equipment Defaults**
   - View last used bow setup
   - Set default bow setup (if desired)

5. **Save Settings**
   - Settings saved immediately on change (reactive)
   - StateFlow propagates changes to all consumers
   - UI recomposition triggered across app

**Key Components:**

- SettingsViewModel.kt - State management
- SettingsRepository.kt - Persistence
- Settings entity (single-row singleton)
- SettingsPage.kt - Compose UI

**Settings Propagation:**

```
User Input → ViewModel Update → Repository Save → StateFlow Emission →
UI Recomposition → All Consumers Updated (Live)
```

**User Can:**

- Change measurement system (affects distance, target size display)
- Set default user name
- Reset onboarding (return to first-time experience)
- Manage account (if authenticated)

**See Full Documentation:** [Settings Architecture](../../../../developer-guide/technical-reference/flows/settings-architecture/)

---

## Core Activity Flows

Primary user activities for archery practice and record-keeping.

### 4. Round Creation and Scoring Flow

**Status:** ✅ Fully Documented (1,733 lines combined)
**Documentation:**
- [Round Lifecycle Flow](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/) (1,168 lines)
- [Scoring Flow](../../../../developer-guide/technical-reference/flows/scoring-flow/) (565 lines)

**Overview:**

Complete workflow from round creation through active scoring to completion and historical viewing.

**Flow Steps:**

#### Round Creation

1. **Navigate to Rounds**
   - Bottom navigation → Rounds tab
   - Or: Dashboard → "Create Round" button

2. **Configure Round Parameters**
   - Select round name (York, Portsmouth, or Custom)
   - Set distance (e.g., 70m, 50yd)
   - Set target size (e.g., 122cm, 40cm)
   - Set number of ends (e.g., 12 ends)
   - Set number of arrows per end (e.g., 6 arrows)
   - Select scoring system (10-zone, 5-zone, etc.)

3. **Select Equipment**
   - Choose from existing bow setups
   - Or: Create new bow setup inline
   - Equipment snapshot embedded in round

4. **Add Participants (Optional)**
   - Default: Single participant (self)
   - Or: Add guest participants (names only)
   - Guest equipment auto-created (duplicates with naming)

5. **Create Round**
   - Validation (all required fields present)
   - Round saved with status: PLANNED
   - Navigate to round detail screen

6. **Start Round**
   - User clicks "Start Scoring"
   - Round status: PLANNED → IN_PROGRESS
   - Navigate to ActiveScoringScreen

#### Active Scoring

1. **Score Arrows**
   - Select arrow score (X, 10, 9, 8, ..., M for miss)
   - StateFlow updates UI reactively
   - Multi-participant: Rotate between participants

2. **Complete End**
   - After all arrows scored (e.g., 6/6 arrows)
   - Validation (all arrows entered)
   - Calculate end statistics (total, average)
   - Save end to database

3. **Continue Scoring**
   - Navigate to next end automatically
   - Progress tracker updates (e.g., "End 2/12")
   - Running total displayed

4. **Pause Round (Optional)**
   - User can pause mid-round
   - Round status: IN_PROGRESS → PAUSED
   - Resume later from same position

5. **Complete Round**
   - After all ends completed
   - Final statistics calculated (total score, average, highs/lows)
   - Round status: IN_PROGRESS → COMPLETED
   - Navigate to round summary screen

#### Tournament Sync (If Applicable)

If round is associated with a tournament:

1. **Async Score Submission**
   - Score submitted to Firebase after each end
   - Exponential backoff retry (up to 5 attempts)
   - Background sync with TournamentSyncService

2. **Conflict Detection**
   - Timestamp-based conflict detection
   - Last-write-wins resolution strategy
   - User notification on conflict

3. **Real-Time Updates**
   - Firebase listener for leaderboard changes
   - Other participants' scores updated live
   - Ranking recalculated dynamically

**Key Components:**

- RoundViewModel.kt (2,177 lines) - Round lifecycle orchestration
- LiveScoringViewModel.kt (2,808 lines) - Active scoring state management
- EndCompletionService.kt - End finalization logic
- TournamentSyncService.kt - Firebase sync with retry
- RoundRepository.kt - Persistence layer
- ActiveScoringScreen.kt - Live scoring UI

**Round Status State Machine:**

```
PLANNED → IN_PROGRESS ⇄ PAUSED → COMPLETED/CANCELLED
```

**User Can:**

- Pause and resume rounds
- Edit round parameters before starting
- View real-time statistics during scoring
- Complete partial rounds (mark as CANCELLED)
- Delete draft rounds (PLANNED status)
- View completed rounds in history

**Performance Considerations:**

- StateFlow for reactive UI updates (minimal recomposition)
- End completion validation prevents invalid data
- Tournament sync is async (doesn't block UI)
- Retry mechanism handles network failures gracefully

**See Full Documentation:**
- [Round Lifecycle Flow](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/) - Round creation → completion
- [Scoring Flow](../../../../developer-guide/technical-reference/flows/scoring-flow/) - Arrow input → end completion

---

### 5. Historical Rounds Viewing Flow

**Status:** ✅ Documented (part of Round Lifecycle Flow)
**Documentation:** [Round Lifecycle Flow - Historical Viewing](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/#historical-viewing)

**Overview:**

View and analyze past rounds with smart caching and filtering.

**Flow Steps:**

1. **Navigate to Historical Rounds**
   - Bottom navigation → Rounds tab
   - Default view: "Active Rounds" (IN_PROGRESS, PAUSED)
   - Toggle to "Historical Rounds" (COMPLETED, CANCELLED)

2. **Filter Rounds**
   - By status (COMPLETED, CANCELLED, ALL)
   - By date range (Last 7 days, Last 30 days, All time)
   - By equipment (filter by bow setup)
   - By scoring system (10-zone, 5-zone, etc.)

3. **View Round Details**
   - Select round from list
   - View round summary (total score, average, date, equipment)
   - View end-by-end breakdown
   - View participant statistics (if multi-participant)

4. **View Round Analytics**
   - Navigate to Analytics tab from round detail
   - See performance trends, shot grouping, fatigue detection
   - Compare with other rounds (same distance/equipment)

5. **Export Round Data**
   - Export to CSV (round details, end scores, arrow scores)
   - Share via Android intents (email, cloud storage)

**Key Components:**

- HistoricalRoundsScreen.kt - Historical viewing UI
- RoundViewModel.kt - Round data loading
- RoundRepository.kt - Filtering and querying
- RoundDao.kt - Database queries with indexes

**Caching Strategy:**

- Historical rounds cached for 1 week (TTL)
- Lazy loading with pagination (50 rounds per page)
- Indexed queries on `status`, `createdAt` columns for performance

**User Can:**

- View all completed rounds
- Filter by various criteria (date, equipment, status)
- View detailed statistics for any round
- Compare multiple rounds side-by-side
- Export round data for external analysis
- Delete old rounds (confirmation required)

**See Full Documentation:** [Round Lifecycle Flow - Historical Viewing](../../../../developer-guide/technical-reference/flows/round-lifecycle-flow/#historical-viewing)

---

## Advanced Feature Flows

Advanced user features for tournaments, analytics, and data management.

### 6. Tournament Participation Flow

**Status:** ⚠️ Not Documented (High Priority)
**Planned Documentation:** To be created

**Overview:**

Discover, join, and participate in multi-user tournaments with real-time leaderboards.

**Flow Steps (High-Level):**

1. **Tournament Discovery**
   - Navigate to Tournaments tab
   - Browse available tournaments (public, invite-only)
   - View tournament details (format, distance, dates, participants)

2. **Join Tournament**
   - Firebase authentication required (anonymous or account-based)
   - Request to join tournament
   - Wait for tournament owner approval (if required)

3. **Create Tournament Round**
   - Create round associated with tournament
   - Select tournament from dropdown during round creation
   - Equipment and round parameters must match tournament requirements

4. **Score in Tournament**
   - Follow normal scoring flow (see Round Creation and Scoring Flow)
   - Scores automatically synced to Firebase after each end
   - Real-time sync with exponential backoff retry

5. **View Tournament Leaderboard**
   - Navigate to tournament detail screen
   - View real-time leaderboard with all participants
   - Ranking recalculated dynamically as scores updated
   - Tie-breaking rules applied (highest score, most Xs, etc.)

6. **Tournament Completion**
   - Tournament owner marks tournament as COMPLETED
   - Final rankings calculated and frozen
   - Participants notified of final results

**Key Components (Identified but Not Documented):**

- TournamentViewModel.kt - Tournament orchestration
- TournamentDiscoveryScreen.kt - Browse and join UI
- TournamentLeaderboardScreen.kt - Real-time leaderboard
- FirebaseTournamentRepository.kt - Firebase data layer
- TournamentParticipant.kt - Participant model

**User Can:**

- Browse public tournaments
- Join tournaments (with owner approval if required)
- Create tournament-associated rounds
- View real-time leaderboards
- Compete with other archers
- View final rankings

**Why Not Documented:**

This flow requires comprehensive Firebase integration documentation, real-time sync patterns, and multi-user permission logic. It is identified as **High Priority** for future documentation.

**See:** [System Flows - Integration Flows](../Integration-Flows/) for related Firebase sync documentation.

---

### 7. Analytics Viewing Flow

**Status:** ⚠️ Not Documented (High Priority)
**Planned Documentation:** To be created

**Overview:**

View and analyze performance trends, equipment comparisons, and shot grouping patterns.

**Flow Steps (High-Level):**

1. **Navigate to Analytics**
   - Bottom navigation → Analytics tab
   - Or: Round detail → "View Analytics" button

2. **Round Analytics Dashboard**
   - View performance summary for selected round
   - End-by-end performance chart
   - Shot distribution visualization (target diagram)
   - Score trends across ends (fatigue detection)

3. **Equipment Performance Comparison**
   - Navigate to Equipment Analytics Hub
   - Compare multiple bow setups side-by-side
   - Filter by distance, date range, scoring system
   - View aggregated statistics (average score, consistency)

4. **Distance-Specific Statistics**
   - Filter analytics by distance (e.g., 70m, 50yd)
   - View performance trends over time for specific distance
   - Compare different equipment at same distance

5. **Fatigue Detection**
   - View score trends across ends within a round
   - Identify performance degradation patterns
   - Visualize fatigue impact on accuracy

6. **Shot Grouping Analysis**
   - View shot distribution on target diagram
   - Analyze grouping tightness (dispersion metrics)
   - Identify aiming biases (left/right, high/low)

7. **Export Analytics Data**
   - Export to CSV (aggregated statistics)
   - Include equipment, distance, date range filters
   - Share via Android intents

**Key Components (Identified but Not Documented):**

- RoundAnalyticsViewModel.kt - Analytics orchestration
- EquipmentAnalyticsHubScreen.kt - Equipment comparison UI
- EquipmentComparisonScreen.kt - Side-by-side comparison
- StatisticsCalculationService.kt - Aggregation logic
- EquipmentPerformanceStats.kt - Analytics models

**User Can:**

- View detailed round analytics
- Compare equipment performance
- Identify performance trends over time
- Detect fatigue patterns
- Analyze shot grouping and aiming biases
- Export analytics data for external analysis

**Why Not Documented:**

This flow requires comprehensive statistics calculation documentation, visualization patterns, and data aggregation logic. It is identified as **High Priority** for future documentation as it represents a key value proposition for users.

**See:** [Data Models - Analytics](../../Data-Models/Analytics/) for related analytics entity documentation.

---

## User Flow Patterns

Common patterns across user flows:

### Navigation Patterns

- **Bottom Navigation** - Primary navigation for main sections (Rounds, Equipment, Analytics, Tournaments, Settings)
- **Back Stack** - Standard Android back button behavior, state preserved
- **Deep Linking** - Support for direct navigation to specific rounds, equipment, or tournaments
- **Cross-Feature Navigation** - Equipment → Rounds, Rounds → Analytics, etc.

**See:** [System Flows - Navigation Patterns](../System-Flows/) (planned) for detailed navigation documentation.

---

### State Management Patterns

- **StateFlow** - Reactive state management for UI updates
- **State Persistence** - ViewModel state survives configuration changes
- **Shared State** - Multi-participant scoring shares state across participants
- **State Validation** - Input validation before state changes (e.g., end completion)

**See:** [System Flows - State Management](../System-Flows/) (planned) for detailed state management documentation.

---

### Error Handling Patterns

- **Input Validation** - UI-level validation with user-friendly error messages
- **Network Errors** - Graceful degradation for Firebase sync failures (offline-first)
- **Conflict Resolution** - Automatic conflict resolution for tournament scores
- **Retry Logic** - Exponential backoff for transient failures

**See:** [System Flows - Error Handling](../System-Flows/) (planned) for detailed error handling documentation.

---

## Related Documentation

- **[System Flows](../System-Flows/)** - Internal system processes and state machines
- **[Integration Flows](../Integration-Flows/)** - External service integrations (Firebase, exports)
- **[User Guide](../../../user-guide/)** - User-facing documentation and tutorials
- **[Features Documentation](../../../user-guide/features/)** - Detailed feature guides
- **[Database Overview](../../Database/)** - Data persistence and schemas
- **[Data Models](../../Data-Models/)** - Entity models and relationships

---

## Contributing User Flow Documentation

To add or improve user flow documentation:

1. **Map the User Journey** - Trace user interactions from entry to exit
2. **Document Each Step** - Include screenshots, UI states, and decision points
3. **Identify Exit Points** - Where can users leave this flow?
4. **Document Alternatives** - What if user skips a step or takes a different path?
5. **Add Error Scenarios** - What happens when things go wrong?
6. **Cross-Reference** - Link to related flows, features, and technical docs
7. **Include User Goals** - Why is the user performing this flow?

**User Flow Checklist:**

- [ ] User journey map (entry → exit)
- [ ] Step-by-step walkthrough with screenshots
- [ ] Decision points and branching paths
- [ ] Error scenarios and recovery strategies
- [ ] Exit points and alternative paths
- [ ] Related flows and features
- [ ] User goals and motivations
- [ ] Success criteria (how do we know user completed flow?)

---

**Last Updated:** 2025-11-04
**Documentation Coverage:** 4 flows fully documented (3,675 total lines), 3 flows planned
