---
title: "Firebase Auth State Loss Across Coroutines"
description: "Firebase authentication state management in coroutines"
category: "development"
audience:
  - "developers"
difficulty: "advanced"
status: "active"
last_updated: "2025-10-29"
tags:
  - "best-practices"
  - "patterns"
  - "lessons-learned"
---

[Home](/) > [Development](/Development/) > [Guides](/Development/Guides/) > [Best Practices](/Development/Guides/Best-Practices/) > Firebase Auth State Loss Across Coroutines

---


# Firebase Auth State Loss Across Coroutines

**Date:** 2025-10-15  
**Status:** ✅ RESOLVED  
**Tags:** #firebase #authentication #coroutines #bug-fix #tournament-repository

## Problem Statement

Authenticated users (email/password) were being **downgraded to anonymous users** when joining tournaments through `HybridTournamentRepository`. This caused users to lose their authenticated status and be treated as anonymous participants.

### Symptoms
- User signs in with email/password successfully
- User attempts to join tournament
- Firebase creates a NEW anonymous user instead of using the authenticated user
- User appears in tournament with anonymous UID, not their authenticated UID

### Root Cause
`firebaseAuth.currentUser` returns **null** when accessed inside coroutine contexts (specifically `syncScope.launch {}`), even when the user is authenticated. Firebase Authentication state does not propagate across coroutine boundaries.

## Discovery Timeline

### 1. Initial Detection
**E2E Test Logs:**
```
User created: device1_1760508970607@test.com (UID: lbLKRWyFX4fpW2rIBASI2PHe0aFA)
Joined tournament as anonymous: (UID: SuShu4LX6orynruDMMlfT8Mr1nRt)
```

### 2. Investigation
Found in `HybridTournamentRepository.kt`:
```kotlin
// Local join succeeded - now sync to Firebase in background
syncScope.launch {
    // PROBLEM: firebaseAuth.currentUser returns null here!
    firebaseRepository.joinTournament(tournamentId, participant)
}
```

The background coroutine lost access to Firebase auth state, causing `FirebaseTournamentRepository` to create an anonymous user.

## Solution: Explicit State Passing Pattern

### Architecture
```
User Context (Auth Available)
    ↓
Capture Auth State
    ↓
Launch Coroutine (Auth Lost)
    ↓
Pass Captured State Explicitly
    ↓
Trust Explicit Parameter
```

### Implementation

#### 1. Interface Update (`TournamentRepository.kt`)
Added optional parameter to `joinTournament()`:
```kotlin
suspend fun joinTournament(
    tournamentId: TournamentId,
    participant: TournamentParticipant,
    authenticatedUserId: String? = null  // NEW: Explicit auth UID
): Result<Unit>
```

#### 2. Capture Before Coroutine (`HybridTournamentRepository.kt:534-559`)
```kotlin
override suspend fun joinTournament(
    tournamentId: TournamentId,
    participant: TournamentParticipant,
    authenticatedUserId: String?
): Result<Unit> {
    // Local join first (optimistic)
    val localResult = offlineRepository.joinTournament(tournamentId, participant)
    
    if (localResult.isFailure) return localResult
    
    // CRITICAL: Capture auth state BEFORE launching background sync
    val authenticatedUid = try {
        FirebaseAuth.getInstance().currentUser?.uid
    } catch (e: Exception) {
        LogConfig.e("HybridRepository", "Failed to get current user: ${e.message}")
        null
    }
    LogConfig.tournamentSync("HybridRepository", 
        "🔐 Captured authenticated UID before background sync: $authenticatedUid")
    
    // Background Firebase sync
    syncScope.launch {
        val firebaseId = getFirebaseIdOrLocal(tournamentId)
        
        // Pass captured UID explicitly
        val firebaseResult = firebaseRepository.joinTournament(
            firebaseId,
            participant,
            authenticatedUserId = authenticatedUid  // ✅ Explicit state
        )
        // ... handle result
    }
    
    return localResult
}
```

#### 3. Trust Explicit Parameter (`FirebaseTournamentRepository.kt:548-625`)
```kotlin
override suspend fun joinTournament(
    tournamentId: TournamentId,
    participant: TournamentParticipant,
    authenticatedUserId: String?  // Receive explicit UID
): Result<Unit> {
    return try {
        // Use "effective user ID" pattern
        val effectiveUserId: String
        val isAnonymousUser: Boolean
        
        if (authenticatedUserId != null) {
            // ✅ Trust the explicit UID (captured in reliable context)
            LogConfig.firebase("FirebaseTournamentRepo", 
                "🔐 Using explicit authenticated UID: $authenticatedUserId")
            effectiveUserId = authenticatedUserId
            isAnonymousUser = false
        } else {
            // Fallback: check Firebase auth state
            var currentUser = firebaseAuth.currentUser
            
            if (currentUser == null && tournament.allowAnonymousParticipants) {
                val result = firebaseAuth.signInAnonymously().await()
                currentUser = result.user
            }
            
            effectiveUserId = currentUser?.uid 
                ?: return Result.failure(Exception("Failed to authenticate"))
            isAnonymousUser = currentUser.isAnonymous
        }
        
        // Use effectiveUserId throughout the method
        val participantWithId = participant.copy(
            participantId = effectiveUserId,  // Not currentUser.uid!
            tournamentId = tournamentId,
            joinedAt = System.currentTimeMillis()
        )
        
        // ... rest of implementation
    }
}
```

## Verification Results

### Before Fix
```
10-14 23:56:22.552 D FirebaseTournamentRepo: 👤 Current Firebase user: null
10-14 23:56:22.552 E FirebaseTournamentRepo: ❌ Authentication lost: 
    expected UID TDNLDk08fbTRIHaMhQvT6WZRz6hf but currentUser is null
```

### After Fix ✅
```
10-15 00:06:24.019 D HybridTournamentRepository: 🔐 Captured authenticated UID: 
    AQgsAmP8OMoxnU9GD9HffkzHlD3b
10-15 00:06:24.108 D FirebaseTournamentRepo: 🔐 Using explicit authenticated UID: 
    AQgsAmP8OMoxnU9GD9HffkzHlD3b
10-15 00:06:24.234 D FirebaseTournamentRepo: ✅ Transaction completed - 
    user AQgsAmP8OMoxnU9GD9HffkzHlD3b joined tournament

10-15 00:06:24.188 D HybridTournamentRepository: 🔐 Captured authenticated UID: 
    q41Pn3brb07HjaP74Wwsnkdre1qK
10-15 00:06:24.223 D FirebaseTournamentRepo: 🔐 Using explicit authenticated UID: 
    q41Pn3brb07HjaP74Wwsnkdre1qK
10-15 00:06:24.299 D FirebaseTournamentRepo: ✅ Transaction completed - 
    user q41Pn3brb07HjaP74Wwsnkdre1qK joined tournament

🔄 Updating tournament: {currentParticipants=2, 
    participantIds=[AQgsAmP8OMoxnU9GD9HffkzHlD3b, q41Pn3brb07HjaP74Wwsnkdre1qK]}
```

**Result:** Both users joined with their authenticated UIDs. NO anonymous users created! 🎉

## Key Learnings

### Why This Pattern Works
1. **Caller Context Reliability**: `firebaseAuth.currentUser` is reliable in the calling context (before coroutine)
2. **Explicit > Implicit**: Passing state explicitly avoids implicit context dependencies
3. **Trust Captured State**: Don't re-validate auth state in async contexts where it's unreliable
4. **Backward Compatibility**: Optional parameter maintains existing behavior for callers who don't provide UID

### When to Use This Pattern
Apply this pattern whenever:
- ✅ Calling Firebase APIs from background coroutines
- ✅ Using `CoroutineScope.launch {}` with Firebase Auth
- ✅ Async operations that need user identity
- ✅ Multi-repository patterns with async sync

### Alternative Approaches Considered
1. ❌ **Using FirebaseAuth.getInstance() inside coroutine** - Still returns null
2. ❌ **Passing entire FirebaseUser object** - May contain stale data
3. ❌ **Using withContext(Dispatchers.Main)** - Breaks offline-first architecture
4. ✅ **Explicit UID parameter** - Simple, testable, reliable

## Related Issues

### E2E Test Fix Required
The E2E test also had a bug where `createTestUser()` leaves the last created user signed in. Fixed by adding explicit `signInAs(device1User)` calls before each participant joins.

**Files Modified:**
- `TournamentLifecycleE2ETest.kt:189` - Added signInAs before device1 joins
- `TournamentLifecycleE2ETest.kt:483` - Added signInAs in guest participant test

## Code References

### Files Modified
| File | Lines | Change Summary |
|------|-------|----------------|
| `TournamentRepository.kt` | 99-103 | Added optional `authenticatedUserId` parameter |
| `FirebaseTournamentRepository.kt` | 548-625 | Implemented "effective user ID" pattern |
| `HybridTournamentRepository.kt` | 534-559 | Capture auth UID before coroutine |
| `OfflineTournamentRepository.kt` | 200-204 | Added parameter (not used in offline mode) |
| `TournamentLifecycleE2ETest.kt` | 189, 483 | Fixed test authentication flow |

### Test Coverage
- ✅ E2E test validates authenticated users maintain their UIDs
- ✅ Both single-participant and multi-participant flows tested
- ✅ Guest participant flow unaffected (uses explicit guest IDs)

## Future Considerations

### Potential Improvements
1. **Wrapper Class**: Create `AuthenticatedContext` class to encapsulate captured state
2. **Extension Function**: `FirebaseAuth.captureForCoroutine()` helper
3. **Compile-Time Safety**: Use context receivers (Kotlin 1.6+) to enforce auth capture

### Other Coroutine-Sensitive Operations
Review these for similar issues:
- `createTournament()` - Already captures auth before sync ✅
- `submitScore()` - May need similar fix if used in background 🔍
- `updateTournamentStatus()` - Review for auth dependency 🔍

## References

- **CLAUDE.md**: Common Patterns → Firebase Authentication in Coroutines
- **Branch**: `p2-e2e-test-setup`
- **Discovery Date**: 2025-10-15
- **Resolution Date**: 2025-10-15

---

**Pattern Name**: Explicit State Passing for Firebase Auth in Coroutines  
**Applies To**: All Firebase operations requiring user identity in async contexts
