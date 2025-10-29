---
title: "expect/actual Pattern - KMP Platform Abstraction"
date: 2025-10-28
tags:
  - kmp
  - architecture
  - patterns
  - multiplatform
---

# expect/actual Pattern - KMP Platform Abstraction

**Kotlin Multiplatform's solution for platform-specific code**

## Overview

The `expect`/`actual` pattern is Kotlin Multiplatform's mechanism for declaring platform-specific APIs in common code while providing platform-specific implementations.

**Think of it as**: An interface + implementation pattern, but enforced at compile-time across platforms.

### When to Use

✅ **Use expect/actual when:**
- Platform-specific APIs needed (Context, File I/O, Logging)
- Same interface across all platforms
- Type-safe compile-time verification required
- Platform capabilities differ (Android vs iOS)

❌ **Don't use expect/actual when:**
- Pure business logic (use shared code instead)
- Simple differences (use `if` platform checks)
- Only one platform planned (no need for abstraction)

---

## Basic Syntax

### Common Code (expect declaration)

```kotlin
// shared/src/commonMain/kotlin/Platform.kt
expect object Platform {
    fun name(): String
    fun version(): Int
}
```

**Key points:**
- `expect` keyword declares the API
- No implementation in common code
- All platforms MUST implement this

---

### Platform-Specific Code (actual implementation)

**Android:**
```kotlin
// shared/src/androidMain/kotlin/Platform.android.kt
actual object Platform {
    actual fun name(): String = "Android"
    actual fun version(): Int = android.os.Build.VERSION.SDK_INT
}
```

**iOS:**
```kotlin
// shared/src/iosMain/kotlin/Platform.ios.kt
import platform.UIKit.UIDevice

actual object Platform {
    actual fun name(): String = UIDevice.currentDevice.systemName()
    actual fun version(): Int =
        UIDevice.currentDevice.systemVersion.toIntOrNull() ?: 0
}
```

**Key points:**
- `actual` keyword provides the implementation
- Signatures MUST match `expect` declaration
- Each platform must provide an implementation (or compile error!)

---

## Week 11 Case Study: DatabaseBuilder

### The Problem

Room database instantiation is platform-specific:
- **Android**: Requires `Context` to access app storage
- **iOS**: Requires file path for database location

Room KMP doesn't provide a cross-platform builder - you must use expect/actual.

---

### The Solution

**Step 1: Common expect declaration**

```kotlin
// shared/database/src/commonMain/kotlin/DatabaseBuilder.kt
expect object DatabaseBuilder {
    fun buildDatabase(): ArcheryKmpDatabase
}
```

This declares: "All platforms will provide a `buildDatabase()` function that returns `ArcheryKmpDatabase`"

---

**Step 2: Android actual implementation**

```kotlin
// shared/database/src/androidMain/kotlin/DatabaseBuilder.android.kt
actual object DatabaseBuilder {
    @Volatile
    private var INSTANCE: ArcheryKmpDatabase? = null

    @Volatile
    private var applicationContext: Context? = null

    /**
     * Initialize with Application context.
     * Call this in Application.onCreate() before using the database.
     */
    fun initialize(context: Context) {
        applicationContext = context.applicationContext
    }

    actual fun buildDatabase(): ArcheryKmpDatabase {
        // Return test instance if set
        ArcheryKmpDatabase.TEST_INSTANCE?.let { return it }

        // Return cached instance
        INSTANCE?.let { return it }

        // Check context initialized
        val context = applicationContext
            ?: throw IllegalStateException(
                "DatabaseBuilder.initialize(context) must be called first"
            )

        // Create new instance with double-checked locking
        return synchronized(this) {
            INSTANCE ?: Room.databaseBuilder(
                context,
                ArcheryKmpDatabase::class.java,
                "archery_database"
            ).build().also { INSTANCE = it }
        }
    }
}
```

**Android-specific features:**
- Uses Android's `Context` for database location
- Thread-safe singleton with `@Volatile` and `synchronized`
- Initialization step (`initialize()`) for dependency injection

---

**Step 3: iOS actual implementation**

```kotlin
// shared/database/src/iosMain/kotlin/DatabaseBuilder.ios.kt
actual object DatabaseBuilder {
    actual fun buildDatabase(): ArcheryKmpDatabase {
        throw NotImplementedError(
            "iOS database support not yet implemented. " +
            "Will be added when iOS development begins (Week 15+)."
        )
    }
}
```

**iOS stub features:**
- Satisfies compiler (actual implementation exists)
- Throws clear error if used before iOS work begins
- Documents future implementation plan in comments

**Future iOS implementation:**
```kotlin
// When iOS work begins:
actual object DatabaseBuilder {
    actual fun buildDatabase(): ArcheryKmpDatabase {
        val dbPath = NSHomeDirectory() + "/archery_database.db"
        return Room.databaseBuilder<ArcheryKmpDatabase>(name = dbPath)
            .setDriver(BundledSQLiteDriver())
            .build()
    }
}
```

---

### Usage in App

**Initialize in Application.onCreate():**
```kotlin
// app/src/main/kotlin/ArcheryApplication.kt
class ArcheryApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize KMP database builder
        DatabaseBuilder.initialize(this)
    }
}
```

**Use in repositories:**
```kotlin
// shared/data/src/commonMain/kotlin/Repository.kt
class TournamentRepository {
    private val database = DatabaseBuilder.buildDatabase()
    private val dao = database.tournamentDao()

    suspend fun getTournament(id: String) = dao.getTournamentById(id)
}
```

**Key benefits:**
- Repository code is 100% platform-agnostic
- No `#if Android` or platform checks needed
- Type-safe at compile time
- Easy to add iOS support later (just implement iOS actual)

---

## Advanced Patterns

### Pattern 1: expect class with constructor

**When to use:** Need platform-specific state or dependencies

```kotlin
// commonMain
expect class Logger(tag: String) {
    fun log(message: String)
}

// androidMain
import android.util.Log

actual class Logger actual constructor(private val tag: String) {
    actual fun log(message: String) {
        Log.d(tag, message)
    }
}

// iosMain
import platform.Foundation.NSLog

actual class Logger actual constructor(private val tag: String) {
    actual fun log(message: String) {
        NSLog("[$tag] $message")
    }
}
```

**Usage:**
```kotlin
val logger = Logger("MyClass")
logger.log("Hello from KMP!")
```

---

### Pattern 2: expect function (top-level)

**When to use:** Simple utilities, no state needed

```kotlin
// commonMain
expect fun currentTimeMillis(): Long

// androidMain
import java.lang.System

actual fun currentTimeMillis(): Long = System.currentTimeMillis()

// iosMain
import platform.Foundation.NSDate

actual fun currentTimeMillis(): Long =
    (NSDate().timeIntervalSince1970 * 1000).toLong()
```

---

### Pattern 3: expect interface (less common)

**When to use:** Multiple implementations per platform

```kotlin
// commonMain
expect interface FileSystem {
    fun readFile(path: String): ByteArray
    fun writeFile(path: String, data: ByteArray)
}

// androidMain
actual interface FileSystem {
    actual fun readFile(path: String): ByteArray
    actual fun writeFile(path: String, data: ByteArray)
}

class AndroidFileSystem(private val context: Context) : FileSystem {
    override fun readFile(path: String): ByteArray =
        context.openFileInput(path).readBytes()

    override fun writeFile(path: String, data: ByteArray) =
        context.openFileOutput(path, Context.MODE_PRIVATE).write(data)
}
```

---

## Common Gotchas

### Gotcha 1: expect members must have actual implementations

**Error:**
```
Expect declaration 'buildDatabase' does not have corresponding actual declaration
```

**Fix:** Ensure every `expect` has a matching `actual` on ALL platforms

---

### Gotcha 2: Signatures must match exactly

**Error:**
```kotlin
// commonMain
expect fun getName(): String

// androidMain
actual fun getName(): String? = ... // ❌ Return type doesn't match!
```

**Fix:** Signatures must be identical (parameters, return type, nullability)

---

### Gotcha 3: Can't use platform-specific types in expect

**Error:**
```kotlin
// commonMain
expect fun getContext(): Context // ❌ Context is Android-only!
```

**Fix:** Use platform-agnostic types in expect, platform-specific in actual

**Correct approach:**
```kotlin
// commonMain
expect class PlatformContext

expect fun getPlatformContext(): PlatformContext

// androidMain
import android.content.Context

actual typealias PlatformContext = Context

actual fun getPlatformContext(): PlatformContext =
    // ... get Android Context
```

---

### Gotcha 4: expect/actual in same module only

**Error:**
```kotlin
// Module A: expect declaration
// Module B: actual implementation // ❌ Won't compile!
```

**Fix:** expect and actual must be in the same multiplatform module

---

### Gotcha 5: @Volatile not available in commonMain

**Problem:**
```kotlin
// commonMain
@Volatile // ❌ Unresolved reference!
var instance: MyClass? = null
```

**Fix:** Use @Volatile in platform-specific code only
```kotlin
// androidMain
@Volatile
actual var instance: MyClass? = null
```

**Week 11 solution:** Remove @Volatile from commonMain, add in androidMain

---

## Best Practices

### 1. Keep expect declarations minimal

✅ **Good:**
```kotlin
expect object Platform {
    fun name(): String
}
```

❌ **Bad:**
```kotlin
expect object Platform {
    fun name(): String
    fun version(): Int
    fun deviceModel(): String
    fun osVersion(): String
    fun architecture(): String
    // ... 20 more functions
}
```

**Why?** More functions = more platform-specific code to maintain

---

### 2. Use expect for capabilities, not implementations

✅ **Good:**
```kotlin
expect fun log(message: String) // Capability: logging
```

❌ **Bad:**
```kotlin
expect fun logWithAndroidLogcat(message: String) // Android-specific!
```

---

### 3. Provide clear error messages for unimplemented platforms

✅ **Good:**
```kotlin
actual fun buildDatabase(): ArcheryKmpDatabase {
    throw NotImplementedError(
        "iOS database support not yet implemented. " +
        "Will be added in Week 15. " +
        "Current focus: Android KMP migration."
    )
}
```

❌ **Bad:**
```kotlin
actual fun buildDatabase(): ArcheryKmpDatabase {
    TODO() // Unhelpful!
}
```

---

### 4. Document platform-specific requirements

```kotlin
/**
 * Android-specific database builder.
 *
 * IMPORTANT: Must call initialize(context) before buildDatabase()
 *
 * Usage:
 * ```
 * // Application.onCreate()
 * DatabaseBuilder.initialize(applicationContext)
 *
 * // Later in code
 * val db = DatabaseBuilder.buildDatabase()
 * ```
 */
actual object DatabaseBuilder { ... }
```

---

### 5. Test both platforms

- ✅ Write tests for common code
- ✅ Write platform-specific tests for actual implementations
- ✅ Verify error messages for unimplemented platforms

---

## Comparison to Alternatives

### expect/actual vs Interface/Implementation

| Aspect | expect/actual | Interface |
|---|---|---|
| **Compile-time verification** | ✅ Enforced | ❌ Runtime |
| **Platform detection** | ✅ Automatic | ❌ Manual |
| **Boilerplate** | Low | High |
| **Flexibility** | Medium | High |

**Use expect/actual when:** Platform abstraction is the primary goal

**Use Interface when:** Multiple implementations needed per platform

---

### expect/actual vs Conditional Compilation

| Aspect | expect/actual | #if / #ifdef |
|---|---|---|
| **Type safety** | ✅ Yes | ❌ No |
| **Refactoring** | ✅ Safe | ❌ Brittle |
| **IDE support** | ✅ Full | ⚠️ Limited |
| **Kotlin-native** | ✅ Yes | ❌ Not standard |

**Use expect/actual:** It's the Kotlin Multiplatform way

---

## Real-World Examples in Archery Apprentice

### 1. DatabaseBuilder (Week 11)

**What it abstracts:** Room database instantiation
**Platforms:** Android (implemented), iOS (stub)
**Key feature:** Context dependency injection on Android

---

### 2. LoggingProvider (Week 9)

**What it abstracts:** Platform logging (android.util.Log vs console)
**Platforms:** Android (android.util.Log), iOS (future: NSLog)
**Key feature:** Tag-based logging with platform-specific formatting

---

### 3. Future: FileManager (Week 14+)

**What it will abstract:** File system access
**Platforms:** Android (Context.filesDir), iOS (NSHomeDirectory)
**Key feature:** Cross-platform file read/write

---

## Migration Path

### From Android-only to KMP with expect/actual

**Step 1: Identify platform-specific code**
```kotlin
// Android-only
class FileManager(private val context: Context) {
    fun readFile(name: String) = context.openFileInput(name).readBytes()
}
```

**Step 2: Extract interface**
```kotlin
interface FileManager {
    fun readFile(name: String): ByteArray
}
```

**Step 3: Create expect declaration in commonMain**
```kotlin
// shared/src/commonMain/kotlin/FileManager.kt
expect class FileManager() {
    fun readFile(name: String): ByteArray
}
```

**Step 4: Move Android implementation to androidMain**
```kotlin
// shared/src/androidMain/kotlin/FileManager.android.kt
import android.content.Context

actual class FileManager {
    private val context: Context = ... // Injected somehow

    actual fun readFile(name: String): ByteArray =
        context.openFileInput(name).readBytes()
}
```

**Step 5: Add iOS stub**
```kotlin
// shared/src/iosMain/kotlin/FileManager.ios.kt
actual class FileManager {
    actual fun readFile(name: String): ByteArray {
        TODO("iOS file system not yet implemented")
    }
}
```

**Step 6: Update call sites**
```kotlin
// Now works in shared code!
val fileManager = FileManager()
val data = fileManager.readFile("settings.json")
```

---

## Troubleshooting

### Problem: "Expect declaration has no actual"

**Symptoms:** Compilation fails with "Expect declaration 'X' does not have corresponding actual declaration"

**Solution:**
1. Check file is in correct sourceSet (androidMain, iosMain)
2. Verify `actual` keyword is present
3. Ensure signature matches exactly
4. Clean and rebuild: `./gradlew clean build`

---

### Problem: "Actual must have the same members"

**Symptoms:** Compilation fails with signature mismatch

**Solution:**
```kotlin
// commonMain
expect fun getName(): String? // Nullable

// androidMain
actual fun getName(): String? = ... // Must be nullable too!
```

---

### Problem: Can't use platform types in expect

**Symptoms:** "Unresolved reference: Context" in commonMain

**Solution:** Use typealias pattern:
```kotlin
// commonMain
expect class PlatformContext

// androidMain
actual typealias PlatformContext = Context
```

---

## Further Reading

**Official Kotlin docs:**
- [Kotlin Multiplatform expect/actual](https://kotlinlang.org/docs/multiplatform-connect-to-apis.html)

**Archery Apprentice examples:**
- [[Agent-1-AAP-Week-11-Infrastructure]] - DatabaseBuilder implementation
- Code repo: `shared/database/src/androidMain/kotlin/DatabaseBuilder.android.kt`
- Code repo: `shared/database/src/iosMain/kotlin/DatabaseBuilder.ios.kt`

**Related patterns:**
- [[Pattern 3 Context-Dependent Services]] - When NOT to use expect/actual
- [[Room KMP Architecture]] - DatabaseBuilder case study

---

## Summary

**expect/actual pattern provides:**
- ✅ Compile-time verification of platform implementations
- ✅ Type-safe platform abstraction
- ✅ Clear separation of common and platform code
- ✅ Incremental iOS support (stubs are valid implementations)

**Use it for:**
- Platform APIs (Context, File I/O, Logging, Networking)
- Different capabilities per platform
- Clear abstraction boundaries

**Avoid for:**
- Simple platform checks (`if (Android) ... else ...`)
- Pure business logic (use shared code)
- Complex DI needs (consider interface + factory)

---

**Created by Agent 1 (AAP) - Week 11**
**Last Updated: 2025-10-28**
**Status: Complete ✅**
