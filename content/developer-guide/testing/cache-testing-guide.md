---
tags: [testing, caching, performance, phase-2, firebase]
created: 2025-10-08
last-updated: 2025-10-03
database-version: 31
related:
  - "[[Data-Sync-Flow]]"
  - "[[Tournament-Flow]]"
---

[Home](/) > [Development](/Development/) > [Testing](/Development/Testing/) > ---

---


# Phase 2 Cache Testing Guide

## Quick Start: Log Tags

**Copy-paste for logcat filtering:**
```
tag:CacheService tag:CacheMetrics tag:HybridTournamentRepo tag:FirebaseTournamentRepo tag:RoundDetailsScreen tag:ArcheryApp
```

**Verbose version (includes more detail):**
```
tag:CacheService tag:CacheMetrics tag:HybridTournamentRepo tag:FirebaseTournamentRepo tag:RoundDetailsScreen tag:ArcheryApp tag:TournamentSync tag:TournamentRoundState
```

## Feature Flag Activation (Gradual Rollout)

### Step 1: Basic Caching (Start Here)
```kotlin
// In CacheFeatureFlags.kt
var enableTournamentScoreCache = true
var enableSmartListeners = true
```

**What to test:**
- Open completed tournament round → Should cache data
- Reopen same round → Should use cache (faster load)

**Expected logs:**
- First load: `❌ Cache miss: Fetching from Firestore`
- Second load: `✅ Cache hit: Returning X cached ends`

---

### Step 2: Batch Fetching (After Step 1 works)
```kotlin
var enableBatchParticipantFetch = true
```

**What to test:**
- Open participant selector modal (roster button)
- Should load all participants faster

**Expected logs:**
- `🎯 Batch fetching tournament participant scores for modal`
- `✅ Batch cache hit: [participantId] = [score]` (for cached)
- `❌ Batch cache miss: X participants need Firestore fetch`

---

### Step 3: Indefinite Caching (After Step 2 works)
```kotlin
var cacheCompletedTournamentsIndefinitely = true
```

**What to test:**
- Completed tournaments should stay cached forever
- Cache should survive app restarts

**Expected logs:**
- `💾 Cached X ends for [participant] (status: COMPLETED)`

---

### Step 4: Automatic Cleanup (Last)
```kotlin
var enableAutomaticCacheCleanup = true
```

**What to test:**
- Wait 30 seconds after app startup
- Check for cleanup log

**Expected logs:**
- `🧹 Initial cache cleanup: X entries removed`
- After 24 hours: `🧹 Periodic cache cleanup: X entries removed`

---

## Manual Test Scenarios

### Test 1: Completed Tournament Cache Hit
**Steps:**
1. Complete a tournament round (or find an already completed round)
2. Open the round details from tournament screen
3. **Observe logs** - Should see cache miss + Firestore fetch
4. Close the round details
5. Reopen the same round
6. **Observe logs** - Should see cache hit, no Firestore

**Success Criteria:**
- ✅ Second load shows `✅ Cache hit`
- ✅ Second load is noticeably faster
- ✅ No Firestore logs on cache hit

---

### Test 2: Active Tournament TTL
**Steps:**
1. Start scoring a tournament round (IN_PROGRESS)
2. Score a few ends
3. Exit and reopen within 30 seconds
4. **Observe logs** - Should see cache hit
5. Wait 31+ seconds
6. Reopen round
7. **Observe logs** - Should see cache miss (TTL expired)

**Success Criteria:**
- ✅ Cache hit within 30 seconds
- ✅ Cache miss after 30 seconds
- ✅ Real-time updates still work

---

### Test 3: Modal Batch Fetch
**Steps:**
1. Open a round with 3+ participants
2. Click the roster/filter button (top-right list icon)
3. **Observe logs** - Check batch fetch behavior
4. Close and reopen modal
5. **Observe logs** - Should use cache

**Success Criteria:**
- ✅ First load: `📊 Modal: Batch fetched X participant scores`
- ✅ Second load: Cache hits for all participants
- ✅ Modal opens faster on second load

---

### Test 4: Cache Invalidation (Status Change)
**Steps:**
1. Have a cached active tournament
2. Complete the tournament
3. **Observe logs** - Should see invalidation
4. Reopen tournament
5. **Observe logs** - Should fetch fresh from Firestore

**Success Criteria:**
- ✅ `🔄 Invalidated cache for completed tournament: [id]`
- ✅ Fresh cache created with indefinite TTL

---

### Test 5: Multi-Participant Modal Performance
**Steps:**
1. Create tournament with 5+ participants
2. Each scores a few ends
3. Open round details
4. Click roster button to open modal
5. **Time the modal load**
6. Close and reopen modal
7. **Time again** - Should be 3-5x faster

**Success Criteria:**
- ✅ Cached load < 200ms
- ✅ All participant scores visible
- ✅ Logs show batch cache hits

---

## Performance Metrics to Report

### Cache Effectiveness
Run these after testing for a while:
```kotlin
// Add to any screen temporarily to see stats
CacheMetrics.logSummary()
CacheMetrics.logDetailedMetrics()
```

**Look for:**
- **Hit Rate**: Should be > 70% for completed tournaments
- **Firestore Reads Saved**: Should increase over time
- **Cache Efficiency**: Should be > 80%

### Load Time Comparison
**Measure these scenarios:**
1. **First load (cache miss)**: Typical = 1-2 seconds
2. **Cached load (hit)**: Target = < 500ms
3. **Modal with 5 participants**: Target < 300ms (cached)

---

## Bug Fix Verification

### COMPLETED Round Navigation
**Previously:** Clicking "View Results" on completed round showed error snackbar
**Now:** Should navigate smoothly to round details

**Test:**
1. Complete a tournament round
2. Return to tournament details screen
3. Click "View Results" button
4. **Expected:** Navigate directly to RoundDetailsScreen
5. **Not expected:** No error snackbar about "Cannot score a COMPLETED round"

---

## Troubleshooting

### Cache Not Working
**Check:**
1. Feature flags are `true` in CacheFeatureFlags.kt
2. Database migrated to version 31: Check in Android Studio Database Inspector
3. Logs show `enableTournamentScoreCache` is true

### Logs Not Showing
**Check:**
1. Using correct log tags (see top of document)
2. LogConfig.d() is not filtered in your build
3. `CacheFeatureFlags.logCacheMetrics = true`

### Cache Always Missing
**Check:**
1. TTL settings (30s for active, indefinite for completed)
2. Tournament status is correct
3. Participant ID matches exactly

---

## What to Report Back

For each test scenario, please share:

### 1. Log Output
```
# Use this logcat command:
adb logcat -s CacheService:D CacheMetrics:D HybridTournamentRepo:D
```

### 2. Observations
- Modal load time (before/after caching)
- Any errors or unexpected behavior
- Cache hit rates from `CacheMetrics.logSummary()`

### 3. Performance Notes
- Perceived speed improvement
- Any UI lag or freezing
- Memory usage (if noticeable)

---

## Expected Log Examples

### Cache Hit (Good)
```
D/HybridTournamentRepo: 🔍 Smart cache check: KYD3J4/1/participant123 (status: COMPLETED)
D/CacheService: 💾 Cache check: KYD3J4/1/participant123 = HIT (status: COMPLETED, ttl: 9223372036854775807s)
D/HybridTournamentRepo: ✅ Cache hit: Returning 10 cached ends for participant123
```

### Cache Miss (Expected on First Load)
```
D/HybridTournamentRepo: 🔍 Smart cache check: KYD3J4/1/participant123 (status: COMPLETED)
D/CacheService: 💾 Cache check: KYD3J4/1/participant123 = MISS (status: COMPLETED, ttl: 9223372036854775807s)
D/HybridTournamentRepo: ❌ Cache miss: Fetching from Firestore
D/FirebaseTournamentRepo: 📦 Fetching scores for participant123
D/CacheService: 💾 Cached 10 ends for participant123 (status: COMPLETED)
```

### Batch Fetch (Modal)
```
D/RoundDetailsScreen: 🎯 Batch fetching tournament participant scores for modal
D/HybridTournamentRepo: ✅ Batch cache hit: participant1 = 280
D/HybridTournamentRepo: ✅ Batch cache hit: participant2 = 295
D/HybridTournamentRepo: ❌ Batch cache miss: 1 participants need Firestore fetch
D/RoundDetailsScreen: 📊 Modal: Batch fetched 3 participant scores
```

---

## Success Criteria Summary

**Phase 2 is successful when:**

✅ **Performance:**
- Completed rounds load in < 500ms (cached)
- Modal loads 3-5x faster with cache
- Cache hit rate > 70%

✅ **Functionality:**
- No breaking changes
- Real-time updates work for active rounds
- All participant types work correctly

✅ **Reliability:**
- No crashes or errors
- Graceful degradation if cache fails
- Proper TTL expiration

---

**Related Documentation:**
- See [[Data-Sync-Flow]] for smart caching architecture details
- See [[Tournament-Flow]] for tournament lifecycle integration

*Last Updated: 2025-10-03*  
*Database Version: 31*  
*Feature Flags: Located in `CacheFeatureFlags.kt`*
