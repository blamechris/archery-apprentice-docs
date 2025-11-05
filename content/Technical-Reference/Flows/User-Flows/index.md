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

**Status:** ✅ Fully Documented
**Documentation:** Comprehensive multi-user tournament workflow from discovery to completion

**Overview:**

Complete workflow for discovering, joining, scoring in, and viewing results of multi-user tournaments with offline-first architecture, real-time Firebase synchronization, and intelligent conflict resolution.

**Flow Steps:**

#### 6.1 Tournament Discovery

1. **Navigate to Tournaments Tab**
   - Bottom navigation → Tournaments
   - Or: Dashboard → "Browse Tournaments" card

2. **Browse Available Tournaments**
   - View list of public tournaments
   - Filter by status (OPEN, IN_PROGRESS, COMPLETED)
   - Filter by format (WA_720, INDOOR_18M, FITA_OUTDOOR, etc.)
   - Search by location or date range

3. **View Tournament Details**
   - Tap tournament card to view details
   - View format, distance, target size, dates
   - See participant count and capacity
   - Check registration deadline
   - View tournament creator and description

**UI Screens:**
- TournamentDiscoveryScreen.kt - Browse and search
- TournamentDetailsScreen.kt - Full tournament information

**Data Sources:**
- Local cache: Immediate display from Room database
- Background sync: Firebase updates flow in real-time
- Network indicator: Shows sync status

#### 6.2 Joining a Tournament

**Authentication Flow:**

User identity resolved in priority order:
1. Firebase authenticated user → `firebaseUser.id`
2. Settings username → `settings.userName` (mapped to "local_user")
3. Anonymous user → Generated anonymous ID (if allowed by tournament)

**Join Process:**

1. **Pre-Join Validation**
   ```
   Check: User not already participant
   Check: Tournament has available space
   Check: Tournament status is OPEN
   Check: Registration deadline not passed
   ```

2. **Tap "Join Tournament" Button**
   - Button disabled if validation fails
   - Shows "View Details" if already joined
   - Shows capacity message if full

3. **Local Join (Immediate)**
   - Creates TournamentParticipant record in Room database
   - Updates local participant count
   - UI updates immediately (offline-first)

4. **Firebase Sync (Synchronous)**
   - Writes participant to Firestore `tournaments/{id}/participants/{participantId}`
   - Uses ID mapping table to translate local UUID → Firebase document ID
   - Synchronous execution ensures reliable cross-device sync
   - Failure shows error, allows retry

**Join Status States:**

```kotlin
LocalOnly → Joining → Synced
                 ↓
              Error (retryable)
```

**Error Handling:**
- Already joined: Show "View Details" instead
- Tournament full: Disable join, show capacity
- Not authenticated: Allow if `allowAnonymousParticipants == true`
- Firebase sync failure: Retry option, score saved locally

**Key Components:**
- TournamentDetailsViewModel.kt - Join orchestration
- HybridTournamentRepository.kt - Offline-first data layer
- UserIdentityResolver.kt - Authentication resolution

#### 6.3 Creating Tournament Round

1. **Navigate to "Start Scoring"**
   - From tournament details screen
   - Or: Create Round → Select tournament from dropdown

2. **Participant Conversion**
   - Tournament participants → Session participants
   - Local user → `SessionParticipant.LocalUser`
   - Other participants → `SessionParticipant.GuestArcher` (for multi-participant)
   - Auto-creates equipment for guests (duplicates with naming)

3. **Round Creation with Tournament Linkage**
   ```kotlin
   Round(
     roundName = "${tournament.name} - Round ${nextRoundNumber}",
     numEnds = tournament.roundFormat.numEnds,
     numArrows = tournament.roundFormat.numArrows,
     tournamentId = tournament.id, // Links to tournament
     tournamentRoundNumber = nextRoundNumber,
     syncStatus = SyncStatus.SYNCING,
     participants = sessionParticipants,
     bowSetupId = validBowSetupId // Required
   )
   ```

4. **Parameter Validation**
   - Distance must match tournament format
   - Target size must match tournament format
   - Scoring system must match tournament format
   - All participants must have equipment

**Key Components:**
- TournamentDetailsViewModel.kt - Round creation trigger
- TournamentManagementService.kt - Tournament-specific round setup
- RoundViewModel.kt - Standard round creation flow

#### 6.4 Scoring in Tournament

**Scoring Process:**

1. **Standard Scoring Flow**
   - User enters arrows normally (see Round Creation and Scoring Flow)
   - Local database updated immediately
   - UI continues without blocking

2. **End Completion Triggers Sync**
   ```
   User completes end →
   EndCompletionService validates →
   Save to local Round table (immediate) →
   Background: Submit to Firebase (async with retry)
   ```

3. **Background Firebase Sync**
   ```kotlin
   TournamentSyncService.submitTournamentScoreWithRetry(
     tournamentId,
     participantId,
     roundNumber,
     endNumber,
     arrowScores,
     maxRetries = 3
   )
   ```

**Retry Logic (Exponential Backoff):**
```
Attempt 1: Immediate
Attempt 2: Wait 100ms → retry
Attempt 3: Wait 200ms → retry
Attempt 4: Wait 400ms → final attempt
Failure: Mark for background sync, show error
```

**Sync Status Indicators:**

```kotlin
Idle → Syncing → Success (shows participant count)
           ↓
        Error (retryable, shows retry count)
```

**Offline Behavior:**
- All scores save locally immediately (offline-first)
- Queued for sync when network available
- Sync queue persists across app restarts
- Network monitoring triggers automatic sync on reconnection

**Key Components:**
- ActiveScoringScreen.kt - Arrow entry UI
- LiveScoringViewModel.kt - Scoring state management
- EndCompletionService.kt - Tournament score submission trigger
- TournamentSyncService.kt - Firebase sync with retry logic

#### 6.5 Viewing Tournament Leaderboard

**Setup Process:**

Navigate to tournament details → Leaderboard tab

**Real-Time Listeners:**

Three concurrent Firebase listeners provide live updates:

1. **Leaderboard Listener** - Overall standings
2. **Participants Listener** - Participant list updates
3. **Detailed Scores Listener** - End-by-end score updates

**Leaderboard Features:**

- **Real-Time Updates**: Firebase listeners push updates as participants score
- **Ranking Calculation**:
  - Primary: Total score (descending)
  - Tie-breaker #1: X-count (descending)
  - Tie-breaker #2: Timestamp (earliest)
- **Division Filtering**: View standings by division/category
- **Round-by-Round**: Track score progression across tournament
- **Participant Highlighting**: Current user highlighted in standings

**Conflict Detection & Resolution:**

**Trigger:** Incoming Firebase score differs from local score

**Detection:**
```
Compare remote total vs local total →
Check version numbers →
Check timestamp recency →
Determine resolution strategy
```

**Resolution Strategies:**

- `LOCAL_WINS`: Local has authority (default for offline-first)
- `REMOTE_WINS`: Remote version is newer
- `HIGHEST_WINS`: Use highest score
- `LATEST_WINS`: Use most recent timestamp
- `MANUAL`: Show conflict UI for user decision (if recent update <5min)

**Conflict UI:**
- Notification for affected end
- Shows both local and remote scores
- Displays recommended resolution
- Allows user override
- Option to dismiss (keep local)

**Key Components:**
- TournamentLeaderboardScreen.kt - Real-time standings UI
- TournamentLeaderboardViewModel.kt - Leaderboard state management
- TournamentSyncService.kt - Firebase listeners setup
- ScoreConflictResolutionService.kt - Conflict detection and resolution

#### 6.6 Tournament Completion

**Completion Process:**

*Permission: Tournament creator only*

1. **Navigate to Tournament Management**
   - Tournament details → "Manage Tournament" (creator only)
   - Or: Settings menu → "Complete Tournament"

2. **Complete Tournament**
   ```kotlin
   tournamentService.completeTournament(tournamentId)
   ```
   - Sets status to `COMPLETED`
   - Freezes leaderboard rankings
   - Disables further scoring
   - Triggers final results calculation

3. **Final Rankings Calculation**
   - Aggregate all participant scores across all rounds
   - Apply tie-breaking rules (X-count, timestamp)
   - Generate final standings by division
   - Store immutable results

4. **Participant Notifications** (if implemented)
   - Top 3 finishers notified
   - Achievement badges awarded
   - Results available for viewing

5. **Historical Viewing**
   - Tournament marked as completed
   - Results viewable by all participants
   - Leaderboard frozen in final state
   - Export options available

**Tournament Status State Machine:**

```
OPEN → IN_PROGRESS → COMPLETED
  ↓
CANCELLED (from any state)
```

**Key Components:**
- TournamentManagementViewModel.kt - Management controls
- TournamentManagementService.kt - Lifecycle orchestration
- FirebaseTournamentRepository.kt - Firebase state updates

---

**Tournament Participation Summary:**

| Phase | User Action | System Response | Offline Behavior |
|-------|-------------|-----------------|------------------|
| Discovery | Browse tournaments | Load from cache + Firebase sync | Show cached, sync when online |
| Join | Tap "Join Tournament" | Local DB update + Firebase sync | Queued for sync |
| Create Round | Start scoring | Validate format, create round | Local only until sync |
| Scoring | Enter arrows | Save local + async Firebase sync | Queue for sync |
| Leaderboard | View standings | Real-time Firebase listeners | Show local, sync when online |
| Completion | Creator completes | Freeze rankings, notify participants | N/A (creator action) |

**Key Features:**

- **Offline-First**: All operations complete locally immediately
- **Real-Time Sync**: Firebase listeners provide live leaderboard updates
- **Conflict Resolution**: Automatic detection and resolution with user override
- **Exponential Backoff**: Intelligent retry for transient network failures
- **Multi-Device Sync**: Consistent state across all devices
- **Anonymous Participation**: Optional anonymous user support

**Performance Optimizations:**

- Smart caching with TTL (5min for IN_PROGRESS, indefinite for COMPLETED)
- Batch operations for participant scores (1-2 queries vs 10+)
- Debounced sync triggers (avoid rapid-fire syncs)
- Network monitoring (single callback, automatic sync on reconnect)

**Key Components Reference:**

**ViewModels:**
- TournamentDiscoveryViewModel.kt - Browse tournaments
- TournamentDetailsViewModel.kt - View/manage tournament
- TournamentLeaderboardViewModel.kt - View standings
- TournamentManagementViewModel.kt - Host controls

**UI Screens:**
- TournamentDiscoveryScreen.kt - Browse/search
- TournamentDetailsScreen.kt - Tournament info, join/leave
- TournamentLeaderboardScreen.kt - Real-time standings
- ActiveScoringScreen.kt - Score arrows in tournament round

**Data Layer:**
- HybridTournamentRepository.kt (1,506 lines) - Offline-first with Firebase sync
- FirebaseTournamentRepository.kt (1,707 lines) - Firebase Firestore operations
- OfflineTournamentRepository.kt (908 lines) - Local Room database
- TournamentDao.kt - Tournament metadata queries
- TournamentScoreDao.kt - Score and leaderboard queries

**Services:**
- TournamentManagementService.kt (~850 lines) - Complete lifecycle management
- TournamentSyncService.kt - Real-time Firebase listeners and sync
- ScoreConflictResolutionService.kt - Conflict detection/resolution
- EndCompletionService.kt - Score submission trigger

**Models:**
- Tournament - Main entity (name, dates, format, status, capacity)
- TournamentParticipant - Participant registration
- TournamentScore - Score data (end scores, total, X-count)
- TournamentStatus - Enum: OPEN, IN_PROGRESS, COMPLETED, CANCELLED

**Firebase Collections:**
```
tournaments/{tournamentId}
├── participants/{participantId} → TournamentParticipant
├── scores/{scoreId} → TournamentScore (end-level detail)
└── settings → TournamentSettings (rules, format, privacy)
```

**See Also:**
- [Data Sync Flow](../../../../developer-guide/technical-reference/flows/data-sync-flow/) - Complete sync architecture
- [Integration Flows](../Integration-Flows/) - Firebase integration patterns
- [Tournament System Documentation](../../../../developer-guide/technical-reference/tournament/tournament-system-documentation/) - Complete technical documentation (1,165 lines)

---

### 7. Analytics Viewing Flow

**Status:** ✅ Fully Documented
**Documentation:** Comprehensive performance analysis workflow from basic statistics to advanced grouping metrics

**Overview:**

Complete workflow for viewing and analyzing performance data through round analytics, equipment comparisons, distance-specific statistics, fatigue detection, and advanced shot grouping analysis. The analytics system provides actionable insights to improve archery performance.

**Flow Steps:**

#### 7.1 Accessing Analytics

**Entry Points:**

1. **Bottom Navigation → Analytics Tab**
   - Main analytics dashboard
   - Overview of all analytics types

2. **Round Detail → "View Analytics" Button**
   - Round-specific analytics
   - Immediate access to performance data

3. **Equipment Page → "Analytics Hub" Button**
   - Equipment performance comparison
   - Cross-equipment analysis

#### 7.2 Round Analytics Dashboard

**Navigation:**
- From Analytics tab → Select round → View round analytics
- Or: Round detail screen → "View Analytics" button

**Performance Summary Display:**

```
Total Score: 580/600
Average per End: 48.3
Average per Arrow: 8.1
X-Count: 24 (13.3%)
10-Count: 58 (32.2%)
Accuracy: 96.7%
```

**End-by-End Performance Chart:**

- **Visual:** Line chart with connected points for each end score
- **Features:**
  - Average reference line (horizontal)
  - Best/worst end highlighting
  - Hover tooltips showing end details
  - Trend line overlay (linear regression)
  - Performance trend indicator: IMPROVING, DECLINING, STABLE

**Shot Distribution Visualization:**

- **Bar Chart:** Arrow value frequency (M, 1, 2, ..., 9, 10, X)
- **Ring Distribution:** Percentage in each ring zone
- **X-Ring %:** Highlighted metric for precision

**Score Trends Across Ends:**

```
Early Ends (1-4):   Average: 50.2
Middle Ends (5-8):  Average: 48.1
Late Ends (9-12):   Average: 46.5
Trend: DECLINING (-7.4%)
```

**Comparison with Other Rounds:**

- **Personal Best:** 590 (2025-10-15)
- **Average Comparison:** +5.3% above user average
- **Equipment Performance:** +2.1% above equipment average

**Key Components:**
- RoundAnalyticsViewModel.kt (605 lines) - Analytics state management
- RoundAnalyticsScreen.kt - Dashboard UI
- StatisticsCalculationService.kt - Statistical algorithms

#### 7.3 Equipment Performance Comparison

**Navigation:**
- Equipment page → "Analytics Hub" button
- Analytics tab → "Equipment Comparison"

**Equipment Analytics Hub UI:**

Analysis type selection:
1. **Performance by Setup** - Individual bow setup analytics
2. **Performance by Distance** - Distance-specific comparisons
3. **Equipment Comparison** - Side-by-side analysis (up to 4 setups)
4. **Usage Statistics** - Frequency and recency

**Side-by-Side Bow Setup Comparison:**

**Setup Process:**
1. Multi-select up to 4 bow setups
2. Apply filters:
   - Distance: 70m, 50m, 18m, or custom
   - Date range: Last 7/30/90 days, or custom
   - Scoring system: 10-zone, 5-zone, etc.
3. Tap "Compare" button
4. View parallel column display

**Comparison Metrics:**

| Metric | Competition Bow | Practice Bow | Backup Bow |
|--------|----------------|--------------|------------|
| Average Score | 580 (Best) | 565 | 545 |
| Accuracy % | 96.7% | 94.2% | 90.8% |
| X-Count Avg | 24 | 19 | 14 |
| Rounds Shot | 45 | 78 | 12 |
| Best Score | 598 | 582 | 568 |
| Consistency | 0.92 | 0.85 | 0.78 |
| Last Used | Yesterday | 2 days ago | 2 weeks ago |

**Visual Indicators:**
- Green highlight for best performer
- Performance trend arrows (↑↓→)
- Warning icons for equipment needing attention

**Equipment Ranking/Leaderboard:**
- Setups ranked by average score
- Sorting options: score, usage, consistency
- Equipment usage frequency

**Key Components:**
- EquipmentAnalyticsHubScreen.kt - Analytics hub UI
- EquipmentComparisonScreen.kt - Side-by-side comparison
- EquipmentPerformanceService.kt - Performance calculation

#### 7.4 Distance-Specific Statistics

**Filter Analytics by Distance:**

1. **Select Specific Distance**
   - Dropdown: 70m, 50m, 30m, 18m, custom
   - View all rounds shot at selected distance
   - Auto-updates charts and statistics

2. **Performance Trends at Specific Distance**
   - Chronological line chart
   - Score progression over time
   - Improvement tracking with trend line

3. **Equipment Comparison at Same Distance**
   - Filter multiple setups by distance
   - Side-by-side comparison for apples-to-apples analysis
   - Identify best-performing setup for specific range

4. **Distance-Specific Personal Bests**

```
70m: 598 (2025-10-15) with Competition Bow
50m: 612 (2025-09-20) with Competition Bow
30m: 658 (2025-08-10) with Practice Bow
18m: 682 (2025-07-05) with Practice Bow
```

**Key Features:**
- Distance-based filtering throughout analytics
- Historical trends at specific distances
- Equipment effectiveness by distance
- Personal best tracking

#### 7.5 Fatigue Detection Analysis

**Algorithm:**

```
Shot Segmentation:
- Recent shots: Last 20% of arrows (minimum 5)
- Earlier shots: First 80% of arrows

Performance Drop:
- avgRecent = mean(recent shot scores)
- avgEarlier = mean(earlier shot scores)
- performanceDrop = avgEarlier - avgRecent

Fatigue Score (0.0-1.0):
- scoreFactor = (performanceDrop / 2.0).clamp(0.0, 1.0)
- groupingFactor = (groupingDeterioration / 0.2).clamp(0.0, 1.0)
- fatigueScore = (scoreFactor + groupingFactor) / 2.0
```

**Score Trends Visualization:**

```
End-by-End Comparison:
┌────────────────────────────────────┐
│ Early Ends (1-4):  ████████ 50.2   │
│ Middle Ends (5-8): ███████  48.1   │
│ Late Ends (9-12):  ██████   46.5   │
└────────────────────────────────────┘
Performance Drop: -7.4% (Moderate Fatigue)
```

**Fatigue Score Interpretation:**

- **0.0-0.2:** No fatigue detected - Consistent performance
- **0.2-0.4:** Mild fatigue - Minor performance drop
- **0.4-0.6:** Moderate fatigue - Consider rest or technique check
- **0.6-0.8:** Significant fatigue - Rest recommended
- **0.8-1.0:** High fatigue - End session, avoid injury risk

**End-by-End Consistency Metrics:**

```
Standard Deviation: 2.3 points
Range (Best - Worst): 12 points (56 - 44)
Coefficient of Variation: 4.8%
```

**Recommendations Based on Patterns:**
- Fatigue > 0.6: "Consider shorter sessions or more breaks"
- Consistency < 0.7: "Focus on form consistency"
- Performance drop > 10%: "Check equipment or fatigue"

**Key Components:**
- FatigueAnalysisService.kt - Fatigue calculation
- Equipment Statistics data model - Fatigue metrics
- Chart components - Visual trend display

#### 7.6 Shot Grouping Analysis

**Requirements:**
- Target Face Scoring method (with coordinates)
- ArrowScore.targetX and targetY populated
- Minimum 5+ arrows with coordinates

**Grouping Metrics:**

**1. Eccentricity (Covariance Matrix Method)**

```
Algorithm:
1. Calculate covariance matrix (varX, varY, covXY)
2. Compute eigenvalues
3. eccentricity = eigenvalue1 / eigenvalue2 (capped at 10.0)

Interpretation:
- 1.0-1.2: Circular grouping (ideal form)
- 1.2-2.0: Slightly elliptical (good)
- 2.0-3.0: Moderately elliptical (needs work)
- 3.0+:    Highly directional (systematic issue)
```

**2. Radial Standard Deviation**

```
Algorithm:
distances = sqrt((x - centerX)² + (y - centerY)²) for each shot
groupTightness = sqrt(variance of distances)

Purpose: Measures shot group tightness
Lower = Better (tighter group)
```

**3. Aiming Bias Calculation**

```
horizontalBias = centerX (positive = right, negative = left)
verticalBias = centerY (positive = up, negative = down)
biasDirection = atan2(verticalBias, horizontalBias) * 180/π

Display: Clock position (e.g., "2 o'clock", "9 o'clock")
```

**4. Radial Consistency Index**

```
radialDistances = sqrt(x² + y²) from target center
radialConsistency = 1 / (stdDev / mean) (capped at 10.0)

Higher = Better (more consistent)
```

**Shot Distribution on Target Diagram:**

```
Visual Components:
- Concentric ring overlay (10, 9, 8, ..., M)
- Arrow coordinates plotted as dots
- Group center marker (crosshair)
- Dispersion ellipse overlay
- Bias direction indicator (arrow)
```

**Grouping Tightness Display:**

```
Group Statistics:
Center: (X: +0.8cm, Y: -1.2cm)
Radial SD: 3.2cm
Eccentricity: 1.4 (Slightly elliptical)
Radial Consistency: 7.8 (Good)
```

**Aiming Bias Detection:**

```
Bias Analysis:
Direction: 4 o'clock (Right-Low)
Magnitude: 1.5cm
Recommendation: Adjust sight 2 clicks left, 1 click up
```

**Comparison with Ideal Grouping:**

- Overlay of ideal circular pattern (same radius)
- Deviation percentage from ideal
- Equipment tuning indicators
- Form analysis insights

**Key Components:**
- ShotGroupingAnalysisService.kt - Grouping calculations
- TargetDiagramComponent.kt - Visual plot
- BiasCalculationService.kt - Aiming bias detection

#### 7.7 Export Analytics Data

**Export Process:**

1. **Navigate to Export**
   - Analytics screen → Menu → "Export Data"
   - Or: Round detail → "Export Analytics"

2. **Select Export Format**
   - CSV (Comma-Separated Values) - For spreadsheets
   - JSON (JavaScript Object Notation) - For programmatic access

3. **Choose Data Type**
   - Rounds export (all rounds data)
   - Equipment performance (aggregated stats)
   - Analytics data (calculated metrics: fatigue, grouping, trends)
   - Full backup (complete data model)

4. **Apply Filters**
   - Equipment: Select specific bow setups
   - Distance: Filter by distance (70m, 50yd, etc.)
   - Date range: Last 7/30/90 days, custom range
   - Scoring system: 10-zone, 5-zone, etc.

5. **Generate and Share**
   - Tap "Generate Export"
   - Choose sharing method:
     - Email attachment
     - Cloud storage (Google Drive, Dropbox)
     - Download to device
     - Share with external apps

**CSV Export Schema:**

```csv
Date,Round Name,Distance,Target Size,Total Score,Avg per End,Avg per Arrow,Num Ends,Equipment,X-Count,10-Count,Accuracy %,Consistency,Fatigue Score
2025-11-04,Indoor 18m,18m,40cm,680,56.7,9.4,12,Competition Bow,48,112,94.4%,0.91,0.15
2025-11-03,Outdoor 70m,70m,122cm,598,49.8,8.3,12,Competition Bow,32,87,83.1%,0.88,0.32
```

**JSON Export Structure:**

```json
{
  "export_metadata": {
    "exported_at": "2025-11-04T14:30:00Z",
    "version": "2.0",
    "filters": {
      "equipment": ["Competition Bow"],
      "distance": "70m",
      "date_range": "2025-10-01 to 2025-11-04"
    }
  },
  "rounds": [{...}],
  "equipment_stats": {
    "average_score": 580,
    "consistency": 0.92,
    "rounds_count": 45
  },
  "analytics": {
    "fatigue_analysis": {
      "avg_fatigue_score": 0.28,
      "rounds_with_fatigue": 12
    },
    "grouping_metrics": {
      "avg_eccentricity": 1.6,
      "avg_radial_sd": 3.8
    }
  }
}
```

**Key Components:**
- ExportService.kt - Export generation
- CSVFormatter.kt - CSV schema formatting
- ShareHelper.kt - Android intent sharing

---

**Analytics Viewing Summary:**

| Analytics Type | Entry Point | Key Metrics | Visualization |
|----------------|-------------|-------------|---------------|
| Round Analytics | Round detail | Score, avg, X-count, trend | Line chart, bar chart |
| Equipment Comparison | Analytics hub | Avg score, consistency, usage | Side-by-side columns |
| Distance Statistics | Filter by distance | PBs, trends, improvement | Line chart, history |
| Fatigue Detection | Round analytics | Score drop, fatigue score | Split chart, trend |
| Shot Grouping | Round analytics (with coords) | Eccentricity, bias, radial SD | Target diagram, plot |
| Export | Any analytics screen | All calculated metrics | CSV/JSON files |

**Key Features:**

- **Comprehensive Statistics**: Total score, averages, consistency, trends
- **Advanced Metrics**: Fatigue detection, shot grouping, aiming bias
- **Visual Analytics**: Charts, target diagrams, trend lines
- **Equipment Insights**: Performance comparison, effectiveness by distance
- **Data Export**: CSV/JSON with filtering and sharing

**Performance Optimizations:**

- Cached statistics (5 minutes TTL for frequently changing data)
- Pre-calculated metrics stored in database
- Lazy loading for historical data
- Efficient aggregation queries with database indexes

**Key Components Reference:**

**ViewModels:**
- RoundAnalyticsViewModel.kt (605 lines) - Analytics state management
- EquipmentAnalyticsViewModel.kt - Equipment analytics orchestration
- EquipmentComparisonViewModel.kt - Side-by-side comparison state

**UI Screens:**
- RoundAnalyticsScreen.kt - Complete analytics dashboard
- EquipmentAnalyticsHubScreen.kt - Equipment analytics central hub
- EquipmentComparisonScreen.kt - Side-by-side comparison UI
- Target diagram components - Shot grouping visualization

**Services:**
- StatisticsCalculationService.kt - Statistical algorithms and calculations
- EquipmentPerformanceService.kt - Equipment effectiveness analysis
- FatigueAnalysisService.kt - Fatigue detection algorithms
- ShotGroupingAnalysisService.kt - Grouping metrics calculations
- ExportService.kt - CSV/JSON export generation

**Data Models:**
- EquipmentPerformanceStats - Equipment analytics metrics
- RoundStatistics - Round analytics data
- ShotGroupingMetrics - Grouping and bias metrics
- FatigueAnalysisData - Fatigue detection results

**See Also:**
- [Data Models - Analytics](../../Data-Models/Analytics/) - Complete analytics entity documentation
- [Performance Guidelines](../../Performance/) - Caching and optimization strategies
- [Code Examples](../../Code-Examples/) - Statistics calculation examples

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
**Documentation Coverage:** 5 flows fully documented (4,045 total lines), 2 flows planned
