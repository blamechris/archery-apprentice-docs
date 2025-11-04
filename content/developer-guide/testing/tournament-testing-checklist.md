---
tags: [testing, tournament, multi-device, checklist, qa, manual-testing]
created: 2025-10-08
test-count: 10
estimated-time: 20-30 minutes
requirements:
  - 2 Android devices/emulators
  - Firebase connection
related:
  - "[[Tournament-Test-Guide]]"
  - "[[Tournament-Flow]]"
  - "[[Data-Sync-Flow]]"
---

[Home](/) > [Development](/Development/) > [Testing](/Development/Testing/) > ---

---


# Tournament Multi-Device Testing Checklist

## Overview
Manual testing checklist for tournament features with real-time sync across multiple devices. Test all scenarios before merging tournament-related PRs.

**Requirements:**
- 2 Android devices/emulators running the app
- Firebase connection
- ~20-30 minutes for full test suite

---

## 🎯 Test Setup

### Device Setup
- [ ] **Device A**: Emulator or physical device (will be tournament creator)
- [ ] **Device B**: Second emulator or physical device (will be participant)
- [ ] Both devices have app installed and can connect to Firebase
- [ ] Clear app data on both devices before testing: `adb shell pm clear com.archeryapprentice.debug`

---

## 📋 Test Cases

### 1. Tournament Creation and Discovery
**Goal:** Verify tournament creation and cross-device discovery

#### Device A (Creator):
- [ ] Open app and navigate to Tournaments
- [ ] Create new tournament:
  - Name: "Multi-Device Test Tournament"
  - Public tournament (toggle ON)
  - Max participants: 10
  - Allow anonymous participants: YES
- [ ] Verify tournament appears in "My Tournaments"
- [ ] Note the tournament ID/name for Device B

#### Device B (Participant):
- [ ] Open app and navigate to Tournaments
- [ ] Browse "Public Tournaments"
- [ ] **VERIFY:** Find "Multi-Device Test Tournament" in the list
- [ ] **VERIFY:** Tournament shows correct status (OPEN)
- [ ] **VERIFY:** Shows available spots (0/8)

**Expected Result:** ✅ Tournament created by Device A is discoverable by Device B

---

### 2. Multi-Participant Joining
**Goal:** Verify multiple participants can join the same tournament

#### Device A:
- [ ] Join your own tournament "Multi-Device Test Tournament"
- [ ] Add a guest participant:
  - Name: "Guest Player A"
- [ ] Verify you see 2 participants (yourself + guest)

#### Device B:
- [ ] Join "Multi-Device Test Tournament"
- [ ] **VERIFY:** See 3 total participants:
  - Device A user
  - Guest Player A (added by Device A)
  - Device B user

#### Device A (verification):
- [ ] **VERIFY:** See all 3 participants updated in real-time
- [ ] **VERIFY:** Participant indicators show:
  - ★ for your own participant
  - ★ for your guest
  - 👁 for Device B user (view-only)

**Expected Result:** ✅ All devices see all participants with correct controllability indicators

---

### 3. Concurrent Scoring Synchronization
**Goal:** Verify scores sync in real-time across devices

#### Device A:
- [ ] Start scoring for your participant
- [ ] Score End 1: 10, 9, 8 (Total: 27)
- [ ] Submit end

#### Device B (immediately after):
- [ ] Start scoring for your participant
- [ ] Score End 1: 9, 9, 9 (Total: 27)
- [ ] Submit end
- [ ] Wait 5 seconds for sync

#### Both Devices (verification):
- [ ] **VERIFY:** Leaderboard shows both participants with 27 points
- [ ] **VERIFY:** Both devices show the same leaderboard data
- [ ] **VERIFY:** Scores updated within 5 seconds

**Expected Result:** ✅ Concurrent scoring synchronizes across all devices

---

### 4. Leaderboard Ranking with Ties
**Goal:** Verify standard competition ranking (tied participants share rank)

#### Using results from Test 3:
- [ ] **VERIFY Device A:** Both participants show Rank 1 (tied for first)
- [ ] **VERIFY Device B:** Both participants show Rank 1 (tied for first)

#### Add a third score:
- [ ] Device A scores End 2: 7, 7, 7 (Total: 21, Running Total: 48)
- [ ] Wait for sync

#### Both Devices:
- [ ] **VERIFY:** Leaderboard shows:
  - Rank 1: Device B (27 points)
  - Rank 2: Device A (48 points) ← Note: Lower rank because higher score
- [ ] **VERIFY:** Ranking updates on both devices

**Expected Result:** ✅ Tie handling works correctly with standard competition ranking

---

### 5. Average Score Calculation
**Goal:** Verify average is calculated per-end (not per-arrow)

#### Device A:
- [ ] Check your participant's stats:
  - Total Score: 48 (from 27 + 21)
  - Ends Completed: 2
  - **VERIFY:** Average Score: 24.0 (48 ÷ 2 ends)

#### Device B:
- [ ] Check Device A's participant stats from your device
- [ ] **VERIFY:** Shows same average score: 24.0

**Expected Result:** ✅ Average score = Total ÷ Ends (not Total ÷ Arrows)

---

### 6. Sync Status Indicators
**Goal:** Verify sync status badges appear correctly

#### Device A:
- [ ] View participant roster
- [ ] **VERIFY:** Your participant shows ★ (controllable)
- [ ] **VERIFY:** Your guest shows ★ Guest (Yours)
- [ ] **VERIFY:** Device B user shows 👁 Network Player (view-only)

#### Device B:
- [ ] View participant roster
- [ ] **VERIFY:** Your participant shows ★ (controllable)
- [ ] **VERIFY:** Device A user shows 👁 Network Player (view-only)
- [ ] **VERIFY:** Guest Player A shows 👁 Guest (Other's) (view-only)

**Expected Result:** ✅ Controllability indicators correctly show who can modify which participants

---

### 7. Name Truncation and Chip Display
**Goal:** Verify participant names display correctly in chips and full views

#### Device A:
- [ ] Add another guest with long name: "Christopher Alexander"
- [ ] **VERIFY:** Chip shows "CHR" (3 letters)
- [ ] **VERIFY:** Full name visible in participant roster
- [ ] **VERIFY:** Name truncates with ellipsis if too long in tabs

#### Add collision scenario:
- [ ] Add two more guests:
  - "Guest 1"
  - "Guest 2"
- [ ] **VERIFY:** Chips show "GU1", "GU2" (collision detection working)

**Expected Result:** ✅ Names truncate correctly, collision detection works

---

### 8. Tournament Round Progress Header
**Goal:** Verify progress header shows correct information

#### Device A:
- [ ] Open scoring screen
- [ ] **VERIFY:** Header shows:
  - Tournament name
  - Current end (e.g., "End 2 of 10")
  - Participant count
  - Online tournament indicator (cloud icon)

#### Device B:
- [ ] Open scoring screen
- [ ] **VERIFY:** Same header information
- [ ] **VERIFY:** Real-time sync indicator shows "Connected"

**Expected Result:** ✅ Progress header displays accurate real-time tournament info

---

### 9. Tournament Deletion and Cleanup
**Goal:** Verify tournament deletion removes data for all participants

#### Device A (Creator only):
- [ ] Navigate to tournament details
- [ ] Delete tournament
- [ ] Confirm deletion

#### Device B (within 10 seconds):
- [ ] **VERIFY:** Tournament disappears from "My Tournaments"
- [ ] **VERIFY:** Tournament no longer appears in "Public Tournaments"
- [ ] **VERIFY:** Attempting to view tournament shows "Tournament not found"

**Expected Result:** ✅ Deletion propagates to all devices, tournament completely removed

---

### 10. Orphaned Tournament Filtering
**Goal:** Verify tournaments deleted remotely don't appear in local lists

#### Setup:
- [ ] Device A creates "Test Orphan Tournament"
- [ ] Device B joins the tournament
- [ ] Device A deletes tournament from Firebase Console (or via Device A app)

#### Device B:
- [ ] Pull to refresh tournament list
- [ ] **VERIFY:** "Test Orphan Tournament" removed from "My Tournaments"
- [ ] **VERIFY:** Trying to access tournament shows error/removed state

**Expected Result:** ✅ Orphaned tournaments filtered from all device lists

---

## 🔍 Edge Cases and Error Handling

### Connection Loss Scenarios
- [ ] **Test:** Score an end on Device A, turn off WiFi, score another end
- [ ] **Verify:** Pending sync indicator shows
- [ ] **Test:** Reconnect WiFi
- [ ] **Verify:** Scores sync automatically within 10 seconds

### Full Tournament
- [ ] Create tournament with maxParticipants: 2
- [ ] Device A and Device B join
- [ ] Try joining from Device C
- [ ] **VERIFY:** Shows "Tournament is full" error

### Concurrent End Submission
- [ ] Both devices score same end number at exact same time
- [ ] **VERIFY:** Both submissions succeed
- [ ] **VERIFY:** Both ends appear in leaderboard
- [ ] **VERIFY:** No data loss or corruption

---

## 📊 Performance Checks

### Sync Speed
- [ ] Score an end on Device A
- [ ] Time how long until visible on Device B
- [ ] **VERIFY:** < 5 seconds for typical sync
- [ ] **VERIFY:** < 10 seconds for poor connections

### UI Responsiveness
- [ ] **VERIFY:** Scoring input remains responsive during sync
- [ ] **VERIFY:** No UI freezing when receiving updates
- [ ] **VERIFY:** Leaderboard updates smoothly (no jank)

---

## ✅ Sign-Off

### All Tests Passing
- [ ] All 10 test cases completed successfully
- [ ] All edge cases handled correctly
- [ ] Performance meets expectations
- [ ] No crashes or data loss observed

### Notes
_Add any issues, observations, or additional testing notes here:_

```
[Your notes here]
```

### Tester Information
- **Tester Name:** _________________
- **Test Date:** _________________
- **App Version:** _________________
- **Devices Used:**
  - Device A: _________________
  - Device B: _________________

---

## 🐛 Known Issues
_Document any issues discovered during testing:_

- [ ] Issue 1: [Description]
  - Severity: [Critical/High/Medium/Low]
  - Repro steps: [Steps]
- [ ] Issue 2: [Description]
  - Severity: [Critical/High/Medium/Low]
  - Repro steps: [Steps]

---

## 📚 Reference

### Key Features Tested
1. ✅ Tournament creation and discovery
2. ✅ Multi-participant joining
3. ✅ Real-time score synchronization
4. ✅ Leaderboard ranking with ties
5. ✅ Per-end average calculation
6. ✅ Sync status indicators
7. ✅ Name truncation and display
8. ✅ Progress header
9. ✅ Tournament deletion
10. ✅ Orphaned tournament filtering

### Quick Reference Commands
```bash
# Clear app data
adb shell pm clear com.archeryapprentice.debug

# Check Firebase connection
adb logcat | grep "Firebase"

# View sync logs
adb logcat | grep "TournamentSync"
```

---

**Related Documentation:**
- See [[Tournament-Test-Guide]] for automated test suite
- See [[Tournament-Flow]] for tournament architecture
- See [[Data-Sync-Flow]] for real-time sync details
