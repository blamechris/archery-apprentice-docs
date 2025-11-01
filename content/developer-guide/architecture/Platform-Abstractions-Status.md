# Platform Abstractions Status

## Overview

Platform abstractions enable KMP migration by replacing Android-specific dependencies with cross-platform interfaces.

## Implemented Abstractions

### Pattern 1: Data Type Abstraction
**Status:** ✅ COMPLETE (Week 4)

**DomainCoordinate:**
- Replaces `androidx.compose.ui.geometry.LatLng` (Android-only)
- Uses `Double` (lat/lng) - platform-agnostic
- PR #142 (MERGED)

---

### Pattern 3: Context Abstraction
**Status:** ✅ COMPLETE (Week 7)

**PreferenceStorage:**
- **Android:** `SharedPreferences`
- **iOS:** `NSUserDefaults` (future)
- **API:** get/put for String, Int, Long, Boolean, Float
- **Tests:** 21 test cases
- PR #152 (MERGED)

**ResourceProvider:**
- **Android:** `context.getString(R.string.*)`
- **iOS:** `NSBundle.localizedStringForKey()` (future)
- **API:** getString(), getStringArray(), format args
- **Tests:** 11 test cases
- PR #152 (MERGED)

**FileSystemProvider:**
- **Android:** `context.filesDir`, `context.cacheDir`
- **iOS:** `NSDocumentDirectory`, `NSCachesDirectory` (future)
- **API:** read/write text/binary, directory management
- **Tests:** 21 test cases
- PR #152 (MERGED)

---

### Pattern 2: FirebaseDataSource Abstraction
**Status:** 🟡 DESIGNED (Week 4), Implementation Week 9

**FirebaseDataSource:**
- **Android:** Firebase SDK
- **iOS:** GitLive firebase-kotlin-sdk
- **Design:** FIREBASE_DEPENDENCY_AUDIT.md (998 lines)
- **Implementation:** Week 9 Days 4-5

---

## Planned Abstractions

### Pattern 4: Additional Platform Abstractions (TBD)

**Candidates:**
- NetworkMonitor (already exists - Week 2)
- Logger abstraction
- Analytics abstraction
- Biometric auth abstraction

---

## Service Migration Status

### Migrated to shared:domain (8 services)

**Week 3-5:**
1. ArrowScoringDomainService
2. ParticipantStateService
3. ProgressTrackingService
4. SessionStateBuilderService
5. ParticipantStateQueryService
6. EndStateTransitionService
7. ProgressTrackingService enhancements

**Week 7:**
8. ExportUtils (Pattern 3 - FileSystemProvider)

---

### Ready to Migrate (Week 8 Candidates)

**Using Pattern 3 Abstractions:**
1. OfflineScoreQueueManager - FileSystemProvider
2. PlatformProvider extensions - PreferenceStorage
3. Settings utilities - PreferenceStorage

**Estimated Effort:** 5-7 hours (3-5 services)

---

### Blocked Until Week 9

**Firebase-Dependent (Pattern 2 needed):**
- TournamentSyncService
- ScoreConflictResolutionService
- FirebaseTournamentRepository methods

**Database-Dependent (Room KMP needed):**
- Repository implementations
- DAO wrappers

---

## Migration Impact

**Current KMP Migration Progress:**
- **shared:domain:** 8 services (Week 3-7)
- **shared:data:** 768 lines (Week 3)
- **Abstractions:** Pattern 1 + Pattern 3 complete

**Blocked Services:**
- ~40% blocked by Firebase (Pattern 2 implementation Week 9)
- ~30% blocked by Database (Room KMP Week 9-12)
- ~15% now unblocked by Pattern 3 ✅

**Week 8 Goal:** Migrate 3-5 more services using Pattern 3

---

**Last Updated:** 2025-10-26
**Next:** Week 8 service migration sprint
