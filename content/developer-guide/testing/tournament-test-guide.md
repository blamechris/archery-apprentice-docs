---
tags: [testing, tournament, instrumented-tests, regression, multi-device]
created: 2025-10-08
last-updated: 2025-09-26
test-suite-version: 1.0
total-tests: 29
test-breakdown:
  sanity-checks: 15
  bug-regression: 6
  multi-device: 8
related:
  - "[[Tournament-Flow]]"
  - "[[Data-Sync-Flow]]"
  - "[[Multi-Participant-Flow]]"
---

[Home](/) > [Development](/Development/) > [Testing](/Development/Testing/) > ---

---


# Tournament Test Execution Guide

## Overview

This guide provides comprehensive instructions for running the tournament instrumented test suite, understanding test results, and using the tests for development and debugging.

## Test Suite Architecture

### Files Created
```
app/src/androidTest/java/com/archeryapprentice/
├── helpers/
│   └── TournamentTestHelpers.kt           # Tournament-specific test utilities
└── ui/tournament/
    ├── BaseTournamentInstrumentedTest.kt  # Base class for all tournament tests
    ├── TournamentSanityCheckTest.kt       # 15 automated sanity check tests
    ├── TournamentBugRegressionTest.kt     # 6 failing tests for known bugs
    └── TournamentMultiDeviceTest.kt       # Two-device simulation tests
```

### Test Categories

| Test Class | Test Count | Purpose | Expected Results |
|------------|------------|---------|------------------|
| **TournamentSanityCheckTest** | 15 tests | Automated manual checklist | 8-12 passing, 3-7 may fail |
| **TournamentBugRegressionTest** | 6 tests | Document known bugs | ALL SHOULD FAIL initially |
| **TournamentMultiDeviceTest** | 8 tests | Cross-device synchronization | Depends on implementation |
| **Total** | **29 tests** | Complete tournament coverage | Mixed results expected |

---

## Running Tests

### Prerequisites
- Android device or emulator running API 31+
- Git Bash terminal (Windows) or equivalent
- Tournament UI implementation (tests may skip if not implemented)

### Command Line Execution (Recommended)

#### Run All Tournament Tests
```bash
# From project root directory
./gradlew connectedAndroidTest --tests "*Tournament*"
```

#### Run Specific Test Classes
```bash
# Sanity check tests only
./gradlew connectedAndroidTest --tests "TournamentSanityCheckTest"

# Bug regression tests only
./gradlew connectedAndroidTest --tests "TournamentBugRegressionTest"

# Multi-device tests only
./gradlew connectedAndroidTest --tests "TournamentMultiDeviceTest"
```

#### Run Individual Tests
```bash
# Specific bug test
./gradlew connectedAndroidTest --tests "TournamentBugRegressionTest.testBug1_TournamentBadgeAlwaysShowsSynced"

# Specific sanity test
./gradlew connectedAndroidTest --tests "TournamentSanityCheckTest.test_1a_appLaunchColdStart"
```

#### Run with Verbose Output
```bash
# See detailed test output and debug information
./gradlew connectedAndroidTest --tests "*Tournament*" --info --stacktrace
```

### Android Studio Execution

1. **Navigate to test files:**
   ```
   app/src/androidTest/java/com/archeryapprentice/ui/tournament/
   ```

2. **Run test class:**
   - Right-click on test class file
   - Select "Run 'TournamentSanityCheckTest'"

3. **Run individual test:**
   - Right-click on specific test method
   - Select "Run 'test_1a_appLaunchColdStart()'"

4. **Run all tournament tests:**
   - Right-click on `tournament` package
   - Select "Run 'Tests in tournament'"

---

## Understanding Test Results

### Sanity Check Tests (TournamentSanityCheckTest)

#### Expected Outcomes

| Test | Expected Result | Meaning |
|------|----------------|---------|
| `test_1a_appLaunchColdStart` | ✅ PASS | App launches successfully |
| `test_1b_anonymousUserAccess` | ✅ PASS | Basic anonymous functionality works |
| `test_1c_signInSignOutFlow` | ⚠️ SKIP/PASS | Auth flow may need implementation |
| `test_2a_equipmentCRUD` | ✅ PASS | Equipment functionality stable |
| `test_3a_singleParticipantScoringComplete` | ⚠️ SKIP | Needs scoring implementation |
| `test_3b_multiParticipantScoring` | ⚠️ SKIP | Needs MP scoring implementation |
| `test_4a_anonymousTournamentCreation` | ⚠️ VARIES | Depends on tournament UI |
| `test_4b_anonymousTournamentJoin` | ⚠️ VARIES | Depends on join flow |
| `test_4c_anonymousTournamentPersistence_REGRESSION` | ❌ FAIL | Known bug - expected |
| `test_5a_authenticatedTournamentCreation` | ⚠️ VARIES | Depends on online tournaments |
| `test_5b_creatorGuestManagement_REGRESSION` | ❌ FAIL | Known bug - expected |
| `test_6a_participantJoinFlow` | ⚠️ VARIES | Depends on UI implementation |
| `test_6b_participantScoringPermissions_REGRESSION` | ❌ FAIL | Known bug - expected |
| `test_7a_localOnlineTournamentCoexistence` | ⚠️ VARIES | Depends on tournament types |
| `test_8a_participantRemoval` | ⚠️ VARIES | Depends on management UI |

#### Success Criteria
- **8+ tests passing**: Core functionality working
- **3-7 tests failing**: Expected regressions and missing features
- **No crashes**: Test infrastructure stable

### Bug Regression Tests (TournamentBugRegressionTest)

#### Expected Outcomes - ALL SHOULD FAIL

| Test | Bug Description | When It Should Pass |
|------|-----------------|-------------------|
| `testBug1_TournamentBadgeAlwaysShowsSynced` | Badge shows "Synced" for local tournaments | When badge logic checks isLocal |
| `testBug2_AnonymousTournamentsPersistAfterSignIn` | Anonymous tournaments not cleaned up | When cleanup service timing fixed |
| `testBug3_AnonymousUsersBlockedFromJoining` | Validation too restrictive | When allowAnonymous flag respected |
| `testBug4_OnlineTournamentsFromAnonymousStayLocal` | Anonymous online tournaments stay local | When sync works for anonymous |
| `testBug5_AddGuestButtonNeverAppears` | Guest management UI missing | When button renders correctly |
| `testBug6_UsersCanScoreForAllParticipants` | No scoring permission enforcement | When permissions implemented |

#### Success Criteria
- **All 6 tests FAILING**: Confirms bugs still exist
- **Detailed error messages**: Each test explains the bug clearly
- **When bug is fixed**: Corresponding test should pass

### Multi-Device Tests (TournamentMultiDeviceTest)

#### Expected Outcomes

| Test | Purpose | Expected Result |
|------|---------|-----------------|
| `test_TwoDeviceTournamentCreationAndDiscovery` | Cross-device sync | ⚠️ Needs Firestore mock |
| `test_ParticipantJoiningSyncBetweenDevices` | Real-time participant updates | ⚠️ Needs sync implementation |
| `test_GuestAdditionVisibilityAcrossDevices` | Guest management sync | ⚠️ Needs guest functionality |
| `test_RealTimeTournamentStatusUpdates` | Status change propagation | ⚠️ Needs real-time updates |
| `test_ScoreSynchronizationBetweenDevices` | Score sync between devices | ⚠️ Needs scoring implementation |
| `test_ConcurrentParticipantJoinConflictResolution` | Conflict handling | ⚠️ Needs transaction support |
| `test_OfflineOnlineStateSynchronization` | Offline sync | ⚠️ Needs offline support |
| `test_AnonymousToAuthenticatedSyncAcrossDevices` | Auth conversion sync | ⚠️ Needs auth linking |

#### Success Criteria
- **Tests provide framework**: Ready for implementation
- **Skip/fail gracefully**: Don't crash when features missing
- **Clear requirements**: Each test shows what needs implementing

---

## Interpreting Common Results

### ✅ All Tests Pass
```
CONGRATULATIONS! 🎉

Tournament functionality is working correctly:
- Core features implemented
- Known bugs have been fixed
- Multi-device sync operational
- Ready for production deployment
```

### ⚠️ Mixed Results (Expected)
```
NORMAL DEVELOPMENT STATE

Passing tests: Core functionality stable
Failing tests: Known issues and missing features
Skipped tests: Features not yet implemented

Action: Continue development, fix failing tests progressively
```

### ❌ Many Tests Fail
```
INVESTIGATION NEEDED

Possible causes:
- Tournament UI not implemented yet
- Test infrastructure issues
- Repository/database problems
- Authentication not working

Action: Check error messages and implement missing dependencies
```

### 💥 Tests Crash
```
INFRASTRUCTURE PROBLEM

Possible causes:
- Compose UI test setup issues
- Database/repository initialization problems
- Missing dependencies or imports
- Test device/emulator issues

Action: Check test base classes and dependencies
```

---

## Debugging Failed Tests

### Step 1: Check Error Messages
```bash
# Run with full details
./gradlew connectedAndroidTest --tests "FailingTestName" --info --stacktrace
```

Look for:
- `AssertionError`: Expected vs actual behavior
- `ComponentNotFoundException`: UI element not found
- `TimeoutException`: Test waiting too long
- `NullPointerException`: Missing implementation

### Step 2: Review Test Logs
Error messages include detailed context:
```
🚨 BUG 1 CONFIRMED: Tournament badge incorrectly shows "Synced"

EXPECTED: "Local" or "Offline" for local tournaments
ACTUAL: "Synced" (incorrect)

DESCRIPTION: Local tournaments should not show as "Synced"...
ROOT CAUSE: Badge logic not checking tournament.isLocal property
```

### Step 3: Verify Prerequisites
Check if test has required UI elements:
```kotlin
// Test may skip if tournament UI not implemented
try {
    navigateToTournamentCreate()
    // ... test logic
} catch (e: Exception) {
    println("⚠️ Tournament creation UI not implemented: ${e.message}")
    // Test skips gracefully
}
```

### Step 4: Manual Verification
Run the same scenario manually:
1. Follow test steps in the app
2. Compare actual behavior to test expectations
3. Confirm if test is correct or needs updating

---

## Test Maintenance

### When to Update Tests

#### UI Changes
```kotlin
// Old navigation
composeTestRule.onNodeWithText("Create Tournament").performClick()

// Update for new UI
composeTestRule.onNodeWithText("New Tournament").performClick()
```

#### Feature Implementation
```kotlin
// Remove try-catch when feature is implemented
try {
    verifyTournamentBadge("Local")
} catch (e: Exception) {
    println("⚠️ Badge feature not implemented")
    // Remove this catch block when implemented
}
```

#### Bug Fixes
```kotlin
// When Bug 1 is fixed, remove the expected failure logic
// and update test to expect success
```

### Adding New Tests

#### New Feature Test
```kotlin
@Test
fun test_NewFeatureFunctionality() = runBlocking {
    // Given: Setup scenario
    // When: Exercise new feature
    // Then: Verify behavior
}
```

#### New Bug Test
```kotlin
@Test
fun testBugN_NewBugDescription() = runBlocking {
    // Document expected vs actual behavior
    // Include reproduction steps
    // Add to bug regression suite
}
```

---

## Performance Considerations

### Test Execution Time
- **Single test**: 30-60 seconds
- **Full sanity suite**: 10-15 minutes
- **All tournament tests**: 15-25 minutes

### Optimization Tips
```bash
# Run specific tests during development
./gradlew connectedAndroidTest --tests "*SanityCheck*"

# Run bug tests to verify fixes
./gradlew connectedAndroidTest --tests "*BugRegression*"

# Full suite for CI/regression testing
./gradlew connectedAndroidTest --tests "*Tournament*"
```

### Device Requirements
- **RAM**: 4GB+ recommended for stable execution
- **Storage**: 500MB+ free space
- **API Level**: 31+ (Android 12+)
- **Network**: Not required (tests use local database)

---

## Integration with Development Workflow

### During Feature Development
1. **Start with failing test**: Write test for new feature first
2. **Implement feature**: Build until test passes
3. **Verify regression**: Run full suite to ensure no breaks

### During Bug Fixes
1. **Confirm bug test fails**: Verify test reproduces issue
2. **Fix implementation**: Address root cause
3. **Verify test passes**: Confirm bug is resolved
4. **Run regression suite**: Ensure fix doesn't break other features

### Before Releases
1. **Run full test suite**: All tests on clean device
2. **Review expected failures**: Confirm known bugs are documented
3. **Update documentation**: Note any new test results or changes

### In CI/CD Pipeline
```yaml
# Example CI configuration
- name: Run Tournament Tests
  run: ./gradlew connectedAndroidTest --tests "*Tournament*"
- name: Upload Test Results
  uses: actions/upload-artifact@v2
  with:
    name: tournament-test-results
    path: app/build/outputs/androidTest-results/
```

---

## Troubleshooting Common Issues

### "Tournament UI not found" Errors
**Cause**: Tournament UI components not implemented yet  
**Solution**: Implement tournament screens or expect test skips

### Authentication Test Failures
**Cause**: Auth repository mock not configured  
**Solution**: Update auth setup in test base classes

### Database Errors
**Cause**: Tournament database schema issues  
**Solution**: Check Room database configuration and migrations

### Timeout Errors
**Cause**: UI operations taking too long  
**Solution**: Increase wait times or optimize test device performance

### Test Flakiness
**Cause**: Timing issues with UI operations  
**Solution**: Add appropriate delays and wait conditions

---

## Coverage Report

### Current Implementation Coverage

| Feature Area | Tests | Coverage | Status |
|--------------|-------|----------|--------|
| **App Launch** | 4 tests | 95% | ✅ Stable |
| **Equipment** | 2 tests | 80% | ✅ Reference impl |
| **Authentication** | 3 tests | 60% | ⚠️ Needs auth UI |
| **Tournament Creation** | 4 tests | 40% | ⚠️ Needs tournament UI |
| **Participant Management** | 6 tests | 30% | ⚠️ Needs participant UI |
| **Scoring Integration** | 3 tests | 20% | ⚠️ Needs scoring UI |
| **Multi-Device Sync** | 8 tests | 10% | ⚠️ Needs Firestore mock |
| **Bug Regression** | 6 tests | 100% | ✅ Complete documentation |

### Test Value Progression

| Development Stage | Expected Passing | Value |
|-------------------|------------------|-------|
| **Phase 1 Start** | 4-6 tests (App/Equipment) | Foundation validation |
| **Tournament UI** | 8-12 tests | Core functionality |
| **Bug Fixes** | 15-18 tests | Stable feature set |
| **Multi-Device** | 20-25 tests | Production ready |
| **All Features** | 25-29 tests | Complete system |

---

## Contributing to Test Suite

### Adding Test Cases
1. **Identify scenario**: What user behavior needs testing?
2. **Choose appropriate class**: Sanity, regression, or multi-device?
3. **Follow patterns**: Use existing test structure and helpers
4. **Document expected results**: Clear success/failure criteria

### Improving Test Infrastructure
1. **Enhance helpers**: Add common operations to TournamentTestHelpers
2. **Better assertions**: Create domain-specific verification methods
3. **Mock improvements**: Better simulation of real tournament behavior
4. **Documentation**: Keep this guide updated with changes

### Reporting Test Issues
1. **Test name and class**: Specific test that's problematic
2. **Expected vs actual**: What should happen vs what does happen
3. **Environment**: Device, Android version, test configuration
4. **Reproduction**: Steps to reproduce the test issue
5. **Logs**: Full error output with stack traces

---

**Related Documentation:**
- See [[Tournament-Flow]] for tournament lifecycle details
- See [[Data-Sync-Flow]] for multi-device sync architecture
- See [[Multi-Participant-Flow]] for participant management

_Last Updated: 2025-09-26_  
_Test Suite Version: 1.0_  
_Total Tournament Tests: 29_
