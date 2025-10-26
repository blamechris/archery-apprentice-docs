# Service Migration Flow (KMP)

## Overview

Step-by-step process for migrating Android services to shared:domain for Kotlin Multiplatform compatibility.

## When to Use This Flow

**Migrate to shared:domain when service meets ALL criteria:**
- ✅ Pure business logic (no side effects like DB writes, network calls)
- ✅ No Android dependencies (Context, Resources, etc.)
- ✅ No Firebase dependencies (or Firebase abstraction exists)
- ✅ No UI dependencies (Compose, View, etc.)

**DO NOT migrate yet if service:**
- ❌ Depends on Android Context
- ❌ Directly calls Firebase APIs (wait for Week 9 abstraction)
- ❌ Has database write operations (wait for Week 9-12 database migration)

## 5-Step Migration Process

### Step 1: Remove Hilt Annotations

**Before (Android-specific):**
```kotlin
@Singleton
class ProgressTrackingService @Inject constructor(
    // dependencies
) {
    // implementation
}
```

**After (KMP-compatible):**
```kotlin
class ProgressTrackingService(
    // dependencies (no @Inject)
) {
    // implementation
}
```

### Step 2: Convert to Constructor Injection

**Manual DI Pattern:**
```kotlin
// In Android app module
class AndroidSharedModuleFactory(context: Context) : SharedModuleFactory {
    override fun createProgressTrackingService(): ProgressTrackingService {
        return ProgressTrackingService(
            // Explicit dependency instantiation
        )
    }
}
```

### Step 3: Replace java.time with kotlinx.datetime

**Before (Android-only):**
```kotlin
import java.time.Instant
import java.time.ZonedDateTime

val timestamp = Instant.now()
```

**After (KMP-compatible):**
```kotlin
import kotlinx.datetime.Instant
import kotlinx.datetime.Clock

val timestamp = Clock.System.now()
```

### Step 4: Verify Zero Android Dependencies

**Run dependency analysis:**
```bash
./gradlew :shared:domain:dependencies
```

**Verify NO Android imports:**
```kotlin
// ❌ Forbidden in shared:domain
import android.content.Context
import android.util.Log
import androidx.compose.ui.geometry.Offset

// ✅ Allowed in shared:domain
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.Instant
```

### Step 5: Add Comprehensive Unit Tests

**Test location:** `shared/domain/src/commonTest/kotlin/`

**Coverage goal:** >80% patch coverage

**Test structure:**
```kotlin
class ProgressTrackingServiceTest {
    private lateinit var service: ProgressTrackingService

    @BeforeTest
    fun setup() {
        service = ProgressTrackingService()
    }

    @Test
    fun `calculateProgress - normal case`() {
        // Given-When-Then
    }

    @Test
    fun `calculateProgress - edge case (divide by zero)`() {
        // Given-When-Then
    }
}
```

## Example: ProgressTrackingService (Week 5)

### Migration Stats

- **Original location:** `app/src/main/java/.../services/`
- **New location:** `shared/domain/src/commonMain/kotlin/.../services/`
- **Lines migrated:** 250+
- **Tests added:** 30+ test cases
- **Coverage:** 83% patch coverage
- **Duration:** 8 hours

### Files Created

1. ParticipantProgress.kt (data model - 50 lines)
2. ProgressTrackingService.kt (service - 250+ lines)
3. ProgressTrackingServiceTest.kt (tests - 400+ lines)

### Validation

- ✅ All 2051 tests passing
- ✅ Zero regressions
- ✅ Zero Android dependencies
- ✅ Manual DI pattern works

## Common Pitfalls

### Pitfall 1: Forgetting to Update Imports

**Problem:** Android imports still present after migration
**Solution:** Use IDE "Optimize Imports" and verify with `grep -r "import android"`

### Pitfall 2: Hilt Annotations Remaining

**Problem:** @Inject or @Singleton still in shared:domain code
**Solution:** Convert to manual DI with explicit factory pattern

### Pitfall 3: java.time Usage

**Problem:** Instant.now() uses Android-only java.time
**Solution:** Replace with Clock.System.now() from kotlinx.datetime

### Pitfall 4: Insufficient Test Coverage

**Problem:** <80% coverage after migration
**Solution:** Add edge case tests (null handling, divide by zero, boundary conditions)

## Next Services to Migrate (Candidates)

**High Priority (Week 6-8):**
- Statistics calculation services (pure math)
- Validation services (pure logic)
- Progress tracking utilities (no side effects)

**Blocked Until Week 9:**
- Firebase-dependent services (need FirebaseDataSource abstraction)
- Database write services (need Room KMP migration)

## Success Metrics

| Metric         | Goal        | Week 5 Result |
|----------------|-------------|---------------|
| Patch coverage | >80%        | 83% ✅         |
| Regressions    | 0           | 0 ✅           |
| Android deps   | 0           | 0 ✅           |
| Build time     | No increase | No increase ✅ |

---

**Pattern Validated:** Week 5 (PR #144)
**Next Application:** Week 6+
