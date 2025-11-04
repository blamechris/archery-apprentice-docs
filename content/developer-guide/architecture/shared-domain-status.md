# shared:domain Module Status

## Overview

The `shared:domain` module contains platform-agnostic business logic interfaces, domain models, and pure services.

## Current Status (Week 5)

### Migrated Components

#### Week 4
- ✅ DomainCoordinate (data type abstraction)
  - Removes Compose UI dependency from domain models
  - Uses Float (x/y) for coordinates

#### Week 5
- ✅ ParticipantProgress (data model)
  - Sync metadata (version, updatedAt, isDirty)
  - kotlinx.datetime.Instant
- ✅ ProgressTrackingService (service)
  - 11 pure functions
  - Manual DI pattern
  - Zero Android dependencies

### Pattern: Manual DI (No Hilt)

All shared:domain services use manual dependency injection:

```kotlin
class ProgressTrackingService(
    // Explicit constructor parameters
    // No @Inject annotation
) {
    // Pure functions
}
```

**Rationale:**
- Hilt is Android-specific (not KMP-compatible)
- Manual DI is simpler for pure services
- Matches existing RepositoryFactory pattern

### Pattern: kotlinx.datetime (No java.time)

All time/date handling uses kotlinx.datetime:

```kotlin
// ✅ KMP-compatible
import kotlinx.datetime.Instant
import kotlinx.datetime.Clock

val timestamp = Clock.System.now()

// ❌ Android-only
import java.time.Instant
```

## Module Structure

```
shared/domain/
├── src/
│   ├── commonMain/kotlin/
│   │   ├── models/        # Data models
│   │   │   └── ParticipantProgress.kt
│   │   └── services/      # Business logic services
│   │       └── ProgressTrackingService.kt
│   └── commonTest/kotlin/ # Platform-agnostic tests
│       └── services/
│           └── ProgressTrackingServiceTest.kt
```

## Dependencies

```kotlin
dependencies {
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.datetime)
    // NO Android dependencies
}
```

## Testing Strategy

- **Platform:** commonTest (platform-agnostic)
- **Framework:** Kotlin Test
- **Coverage goal:** >80% for all shared:domain code
- **Current coverage:** 83% (Week 5)

## Next Steps (Week 6+)

1. Continue migrating pure services
2. Apply DomainCoordinate pattern to more models
3. Prepare for Week 9 Firebase abstraction

## Blockers

- Firebase-dependent services require Week 9 abstraction layer
- DomainCoordinate pattern needs broader application

---

**Last Updated:** 2025-10-25
**Status:** Week 5 complete - First service migrated successfully
