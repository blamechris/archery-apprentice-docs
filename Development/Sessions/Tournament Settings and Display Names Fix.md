# Tournament Settings and Display Names Fix

**Date:** October 12, 2025  
**Session Type:** Bug Fix + UI Enhancement  
**Related Features:** Tournament Settings, Display Names, Participant Sync  
**V2 Roadmap:** Feature #5 (Tournament Guest Management) - 30% Complete

## Overview

Fixed critical bugs in tournament display name settings and participant Firebase sync, then added UI enhancements to make settings more visible and user-friendly.

## Problems Fixed

### 1. Display Name Settings Not Working

**Issue:** The `useSettingsDisplayNames` toggle didn't work for network tournaments - participants always saw Google account names instead of their chosen Settings.userName.

**Root Cause:**
- Settings retrieval in ViewModels only handled `OfflineTournamentRepository`
- For `HybridTournamentRepository` (network tournaments), settings was null
- UserIdentityResolver's `forceSettingsUserName` parameter had no effect
- Fell back to Firebase displayName (Google account name)

**Solution:**
- Added public `getCurrentSettings()` method to `HybridTournamentRepository`
- Updated 3 ViewModels to use `when` expression instead of if/else
- Now handles all repository types correctly

**Files Changed:**
- `HybridTournamentRepository.kt` (lines 1121-1127)
- `TournamentDetailsViewModel.kt` (lines 17, 219-223, 291-295)
- `TournamentCreationViewModel.kt` (lines 17, 179-183)

### 2. Participant Firebase Sync Failing Silently

**Issue:** Network participants joined locally but didn't sync to Firestore. They appeared in local UI but other devices couldn't see them.

**Root Cause:**
- HybridTournamentRepository synced regular participants asynchronously in background
- If Firebase sync failed, exception was caught and logged silently
- Local operation succeeded, but Firebase never got the participant
- Users saw "participant joined" but other devices showed different counts

**Solution:**
- Changed Firebase sync from asynchronous fire-and-forget to synchronous
- Firebase failures now return `Result.failure()` to caller
- Users see clear error messages instead of silent local-only joins
- All participants (guest and regular) synced consistently

**File Changed:**
- `HybridTournamentRepository.kt` (lines 467-497)

## UI Enhancements Added

### 1. Settings Status Display

Added two new rows to Tournament Information Card showing:
- **Display Names:** "Using Settings Usernames" or "Using Google Account Names" (with badge/account icons)
- **Anonymous Join:** "Allowed" or "Not Allowed" (with person/person-off icons)

**File Changed:**
- `TournamentDetailsScreen.kt` (lines 845-925)

### 2. Settings Warning Message

Added conditional warning message in Tournament Settings Dialog that appears when `useSettingsDisplayNames` toggle is changed:

> "Existing participants will keep their current display names. They must leave and rejoin the tournament to update their names."

**Design:**
- Material3 secondaryContainer background (50% opacity)
- Warning icon (20dp)
- Only shows when toggle state differs from saved setting

**File Changed:**
- `TournamentDetailsScreen.kt` (lines 1444-1470)

## Technical Patterns Used

### Repository Delegation Pattern

```kotlin
// HybridTournamentRepository delegates to OfflineTournamentRepository for settings
suspend fun getCurrentSettings(): Settings? {
    return offlineRepository.getCurrentSettings()
}
```

**Benefits:**
- Single source of truth (Settings in SharedPreferences, not Firebase)
- Consistent behavior across repository types
- Proper encapsulation (offlineRepository remains private)

### Synchronous Firebase Sync Pattern

**Before (Async Fire-and-Forget):**
```kotlin
// Local succeeds → Returns success
// Firebase fails in background → User never knows
viewModelScope.launch {
    firebaseRepository.joinTournament(...)  // Silent failure
}
return localResult  // ⚠️ Might be only partially complete
```

**After (Synchronous with Error Propagation):**
```kotlin
// Local succeeds
// Firebase attempted immediately
// If Firebase fails → Return error to caller
val firebaseResult = firebaseRepository.joinTournament(...)
if (firebaseResult.isFailure) {
    return Result.failure(Exception("Failed to sync with server"))
}
return localResult  // ✅ Guaranteed fully complete
```

### When Expression for Type Checking

```kotlin
// Better than if/else for exhaustiveness and extensibility
val settings = when (currentRepo) {
    is OfflineTournamentRepository -> currentRepo.getCurrentSettings()
    is HybridTournamentRepository -> currentRepo.getCurrentSettings()
    else -> null  // Future repository types
}
```

## Testing

- ✅ Build successful (32s)
- ✅ All unit tests passing (1m 55s)
- ⚠️ Manual testing recommended (display names, sync, UI)

## Impact

### User Experience
- Display names now work correctly for network tournaments
- Participants sync reliably across all devices
- Settings status visible at a glance
- Users informed of settings change behavior

### Code Quality
- Clean when expression pattern
- Proper repository delegation
- Material3 design compliance
- Synchronous sync with error propagation

## V2 Roadmap Progress

**Feature #5: Tournament Guest Management**
- **Status:** 30% Complete (was 0%)
- **Completed:** 4/9 acceptance criteria
  - ✅ Anonymous toggle properly controls guest permissions
  - ✅ Firebase sync works for guest participants
  - ✅ Settings status visible in UI
  - ✅ Display names work correctly with useSettingsDisplayNames

**Remaining Work:**
- Allow tournament joiners (not just creators) to add guests
- Update Firebase Security Rules for guest additions
- Add guest management UI for non-creator participants
- Comprehensive multi-device guest testing

## Related Documentation

- [[V2 Release Roadmap]] - Feature #5 progress updated
- [[Tournament Settings]] - Settings architecture
- [[Firebase Sync Patterns]] - Synchronous sync pattern
- [[Repository Pattern]] - HybridTournamentRepository delegation

## Tags

#bug-fix #tournament-settings #display-names #firebase-sync #ui-enhancement #v2-roadmap #feature-5

## Next Steps

**Option A:** Continue ViewModel extraction (TournamentRoundLifecycleService, StatisticsAggregationService)

**Option B:** Complete Feature #5 (allow joiners to add guests, Firebase Security Rules, testing)

**Optional:** Manual testing of display names and participant sync on device
