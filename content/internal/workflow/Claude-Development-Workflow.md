---
title: Claude Development Workflow
tags:
  - workflow
  - development
  - claude
  - testing
created: 2025-10-08
source: CLAUDE.md
---

# Claude Development Notes

Essential development notes and configurations for working with Claude on this archery scoring app.

## Testing Strategy

### Instrumented Test Protocol
**Policy:** Default to user-executed instrumented tests to prevent emulator instability.
**Claude CAN run instrumented tests** when Android emulator is available
- **Limitations:** Still limit to 1 test file or single test method at a time to prevent emulator overload

**Commands for single test execution:**
```bash
# Claude execution (when emulator available)
./gradlew :app:connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=TestClass#method --no-daemon

# User execution (fallback)
./gradlew :app:connectedAndroidTest --tests="TestClass.method"
```

### Testing Philosophy: 3-Layer Architecture
**Problem:** Android scroll reliability causes `assertIsDisplayed()` failures for off-screen items.

**Solution:**
- **Layer 1 (80%):** `assertExists()` for data verification - fast, scroll-safe
- **Layer 2 (5%):** Master scroll tests validate infrastructure works
- **Layer 3 (15%):** `assertIsDisplayed()` only for user interaction workflows

**Decision Tree:**
```
Navigation/Layout/System UI → assertIsDisplayed() ✅
User interaction → verifyEquipmentVisible() + assertIsDisplayed() ⚠️
Data verification → verifyEquipmentCreated() + assertExists() ✅
```

### Emulator Management
**Essential cleanup commands:**
```bash
# Clear app state between test runs
adb shell pm clear com.archeryapprentice.debug

# Emergency recovery (frozen emulator)
adb kill-server && adb start-server
```

## Build Configuration

### Unit Test Setup
```kotlin
// app/build.gradle.kts
testOptions {
    unitTests {
        isIncludeAndroidResources = true
        isReturnDefaultValues = true
    }

    unitTests.all { test ->
        test.systemProperty("robolectric.sdk", "35")

        // Exclude Compose UI tests from release builds (Robolectric incompatibility)
        if (test.name.contains("release", ignoreCase = true)) {
            test.exclude("**/ActiveScoringScreenExtendedTest.class")
            test.exclude("**/components/ParticipantTabsTest.class")
            test.exclude("**/components/RoundProgressHeaderTest.class")
        }
    }
}
```

### Essential Test Commands
```bash
# Core testing
./gradlew testDebugUnitTest              # All tests including Compose UI
./gradlew testReleaseUnitTest            # Excludes problematic Compose tests

# Layer-specific testing
./gradlew :app:testDebugUnitTest --tests="*ViewModel*"    # ViewModels
./gradlew :app:testDebugUnitTest --tests="*Repository*"   # Data layer
./gradlew :app:testDebugUnitTest --tests="*Dao*"         # Database

# Quality checks
./gradlew ktlintCheck detekt testDebugUnitTest
```

## Architecture Issues

### Critical God Classes
1. **RoundViewModel.kt** - 2,058 lines, 55 methods 🚨
2. **ActiveScoringScreen.kt** - 1,896 lines, 22 methods
3. **LiveScoringViewModel.kt** - 1,753 lines, 34 methods

### Performance Priorities
1. **Database Indexes** 🚨 - Tournament queries: 500ms → <200ms
2. **N+1 Query Fix** 🚨 - 30-end round: 31+ queries → 1 query
3. **LRU Caching** 🚨 - Memory: 100MB+ → <50MB

### Quick Wins
- Extract statistics service from RoundViewModel (safe, incremental)
- Add database performance tests
- Fix Compose recomposition issues

## Common Patterns

### Enum Evolution
Adding enum values → Find all `when` expressions → Add new branches → Consider sealed classes

### Repository Test Mocks
Test failures after repo changes → Mock ALL dependencies implementation calls → Use flexible assertions

### Data Model Migration
Field migrations break tests → Review commit history → Update test expectations → Use IDE refactoring

## Claude Collaboration

### Development Workflow
1. **TDD Approach:** Write failing test → Implement → Verify
2. **Layer Progression:** ViewModel → Repository → Database → UI
3. **Performance Validation:** Run `DatabasePerformanceTest.kt` for data changes
4. **God Class Monitoring:** Check line counts when editing RoundViewModel.kt

### Agent Usage Strategy
- **Multi-file searches** → Use `general-purpose` agent
- **Single file fixes** → Use direct tools (Read, Edit, Grep)

### Code Generation Preferences
- **StateFlow over LiveData** - Consistent with existing patterns
- **Repository pattern** - All data access through repositories
- **Given-When-Then** test structure
- **MockK** for mocking in tests

### Emergency Commands
```bash
# Clean rebuild (gradle cache issues)
./gradlew clean build

# Test failure investigation
./gradlew :app:testDebugUnitTest --tests="FailingTest" --info --stacktrace

# Performance debugging
./gradlew build --profile --scan
```

---

*Last Updated: 2025-09-28*
*Streamlined for essential development guidance*

## Related Documentation
- [[Architecture/MVVM-Patterns|MVVM Architecture]]
- [[Testing/Test-Coverage-Guide|Test Coverage]]
- [[Architecture/Technical-Debt|Technical Debt]]
- [[Development/Contributing-Guide|Contributing Guide]]
