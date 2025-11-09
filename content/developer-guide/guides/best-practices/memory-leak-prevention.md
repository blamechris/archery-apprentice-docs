# Memory Leak Prevention: stateIn vs collectLatest

**Category**: Best Practices
**Area**: KMP Presenters, StateFlow, Coroutines
**Importance**: 🔴 CRITICAL - Prevents production memory leaks
**Discovered**: Week 18 (November 2025)

## Overview

When creating KMP Presenters that expose StateFlows from repository data, **ALWAYS use `stateIn()` instead of manual `collectLatest` collectors**. Manual collectors create memory leaks because they are not automatically cancelled when the Presenter is cleared.

**Critical Rule**: Use `stateIn(scope, SharingStarted.Eagerly, initialValue)` for exposing repository Flows as StateFlows.

## The Problem: Memory Leak Pattern

### ❌ WRONG: Manual collectLatest (Memory Leak)

```kotlin
class EquipmentPresenter(
    private val repository: EquipmentRepository,
    private val coroutineScope: CoroutineScope
) {
    private val _items = MutableStateFlow<List<Equipment>>(emptyList())
    val items: StateFlow<List<Equipment>> = _items.asStateFlow()

    init {
        loadItems()
    }

    private fun loadItems() {
        coroutineScope.launch {
            repository.getAll().collectLatest { items ->
                _items.value = items
            }
        }
    }

    fun onCleared() {
        // ❌ Problem: collectLatest collector NOT cancelled here
        // The collector continues running even after Presenter is cleared
        // This causes a memory leak!
    }
}
```

**Why This Leaks**:
1. `collectLatest` starts a coroutine collector
2. Collector runs indefinitely (or until Flow completes)
3. When `onCleared()` is called, the collector is NOT automatically cancelled
4. Presenter is cleared but collector keeps running
5. Presenter remains in memory (garbage collector cannot free it)
6. **Result**: Memory leak

**Impact**:
- Presenter cannot be garbage collected
- ViewModel holding Presenter cannot be garbage collected
- Repository references remain active
- Memory usage grows with each Presenter instance created

### Discovery Story

This pattern was discovered in Week 18 during ViewModel → Presenter migrations:

**Timeline**:
1. Week 17: 6 Presenters created with manual `collectLatest` pattern
2. Week 18: 3 more Presenters created with same pattern
3. Week 18: Copilot flagged memory leak during Agent 3 validation
4. Week 18: Agent 2 fixed all 9 Presenters immediately
5. Week 19: New Presenters used correct `stateIn` pattern from start

**Result**: 9 memory leaks prevented before production deployment

## The Solution: stateIn Pattern

### ✅ CORRECT: stateIn (No Memory Leak)

```kotlin
class EquipmentPresenter(
    private val repository: EquipmentRepository,
    private val coroutineScope: CoroutineScope
) {
    val items: StateFlow<List<Equipment>> = repository.getAll()
        .stateIn(
            scope = coroutineScope,
            started = SharingStarted.Eagerly,
            initialValue = emptyList()
        )

    fun onCleared() {
        // ✅ Automatic cleanup: stateIn collector cancelled when coroutineScope is cancelled
        // No manual cleanup needed!
    }
}
```

**Why This Works**:
1. `stateIn` creates a StateFlow that automatically manages the collector
2. Collector is tied to the provided `coroutineScope`
3. When `coroutineScope` is cancelled, `stateIn` collector is automatically cancelled
4. Presenter can be garbage collected normally
5. **Result**: No memory leak

**Benefits**:
- Automatic lifecycle management
- Cleaner code (no manual collector logic)
- No manual cleanup required
- KMP-compatible (works on Android, iOS, etc.)

## Pattern Comparison

### Manual collectLatest vs stateIn

| Aspect | Manual collectLatest | stateIn |
|--------|---------------------|---------|
| **Code complexity** | Higher (init, loadX(), manual state) | Lower (single expression) |
| **Memory safety** | ❌ Leaks if not cancelled | ✅ Automatic cleanup |
| **Lifecycle management** | ❌ Manual cancellation required | ✅ Tied to coroutineScope |
| **Initialization** | ❌ Requires init/loadX() call | ✅ Automatic (SharingStarted) |
| **State exposure** | Requires MutableStateFlow + asStateFlow() | Direct StateFlow |
| **Lines of code** | ~10 lines | ~4 lines |
| **Recommended** | ❌ NO | ✅ YES |

### Code Reduction Example

**Before (Manual collectLatest)**: 10 lines
```kotlin
private val _items = MutableStateFlow<List<Equipment>>(emptyList())
val items: StateFlow<List<Equipment>> = _items.asStateFlow()

init {
    loadItems()
}

private fun loadItems() {
    coroutineScope.launch {
        repository.getAll().collectLatest { items ->
            _items.value = items
        }
    }
}
```

**After (stateIn)**: 4 lines
```kotlin
val items = repository.getAll()
    .stateIn(
        scope = coroutineScope,
        started = SharingStarted.Eagerly,
        initialValue = emptyList()
    )
```

**Result**: 60% code reduction + memory safety

## stateIn Parameters Explained

### scope: CoroutineScope

**Purpose**: The coroutine scope that owns the StateFlow collector

**Lifecycle**:
- When scope is cancelled, `stateIn` collector is automatically cancelled
- Use the Presenter's `coroutineScope` parameter

**Example**:
```kotlin
class EquipmentPresenter(
    private val repository: EquipmentRepository,
    private val coroutineScope: CoroutineScope  // ← Pass this to stateIn
) {
    val items = repository.getAll()
        .stateIn(coroutineScope, ..., ...)  // ← Use coroutineScope here
}
```

**ViewModel Integration**:
```kotlin
class EquipmentViewModel(
    private val presenter: EquipmentPresenter
) : ViewModel() {
    // Pass viewModelScope to Presenter
    init {
        // Presenter created with viewModelScope
    }

    override fun onCleared() {
        super.onCleared()
        // viewModelScope is cancelled automatically by Android ViewModel
        // This cancels the stateIn collector in Presenter
    }
}
```

### started: SharingStarted

**Purpose**: Determines when the StateFlow collector starts and stops

**Options**:

1. **SharingStarted.Eagerly** (RECOMMENDED for Presenters)
   - Starts collector immediately
   - Collector runs until scope is cancelled
   - Use when: Data should load immediately on Presenter creation

2. **SharingStarted.Lazily**
   - Starts collector on first subscriber
   - Collector runs until scope is cancelled
   - Use when: Data should load only when observed

3. **SharingStarted.WhileSubscribed()**
   - Starts when first subscriber appears
   - Stops when last subscriber disappears (with optional timeout)
   - Use when: Want to stop collecting when no subscribers (rare for Presenters)

**Recommendation**: Use `SharingStarted.Eagerly` for Presenters
- Presenters typically load data immediately
- Simplifies lifecycle (no delayed start logic)
- Consistent pattern across all Presenters

**Example**:
```kotlin
val items = repository.getAll()
    .stateIn(
        scope = coroutineScope,
        started = SharingStarted.Eagerly,  // ← Start immediately
        initialValue = emptyList()
    )
```

### initialValue: T

**Purpose**: Initial value emitted before first repository value arrives

**Use Cases**:
- Empty list: `initialValue = emptyList()`
- Null: `initialValue = null`
- Loading state: `initialValue = LoadingState.Loading`
- Default value: `initialValue = DefaultConfig`

**Example**:
```kotlin
// List of items (empty initially)
val items = repository.getAll()
    .stateIn(coroutineScope, SharingStarted.Eagerly, emptyList())

// Nullable single item (null initially)
val selectedItem = repository.getById(id)
    .stateIn(coroutineScope, SharingStarted.Eagerly, null)

// Loading state (loading initially)
val loadingState = repository.getStatus()
    .stateIn(coroutineScope, SharingStarted.Eagerly, LoadingState.Loading)
```

## Real-World Examples

### Example 1: Simple List (Equipment)

```kotlin
class EquipmentPresenter(
    private val repository: EquipmentRepository,
    private val coroutineScope: CoroutineScope
) {
    // ✅ Expose all equipment items
    val items = repository.getAll()
        .stateIn(coroutineScope, SharingStarted.Eagerly, emptyList())

    // Methods that modify data
    fun deleteItem(id: Long) = coroutineScope.launch {
        repository.delete(id)
    }

    fun insertItem(item: Equipment) = coroutineScope.launch {
        repository.insert(item)
    }
}
```

### Example 2: Dual-Entity Management (Sight + SightMark)

```kotlin
class SightPresenter(
    private val repository: SightRepository,
    private val coroutineScope: CoroutineScope
) {
    // ✅ Multiple StateFlows (all using stateIn)
    val sights = repository.getAllSights()
        .stateIn(coroutineScope, SharingStarted.Eagerly, emptyList())

    val sightMarks = repository.getAllSightMarks()
        .stateIn(coroutineScope, SharingStarted.Eagerly, emptyList())

    val selectedSight = repository.getSelectedSight()
        .stateIn(coroutineScope, SharingStarted.Eagerly, null)

    val measurementSystem = repository.getMeasurementSystem()
        .stateIn(coroutineScope, SharingStarted.Eagerly, MeasurementSystem.METRIC)
}
```

### Example 3: Complex State (Multiple Flows)

```kotlin
class RoundScoringPresenter(
    private val roundRepo: RoundRepository,
    private val scoreRepo: ScoreRepository,
    private val coroutineScope: CoroutineScope
) {
    // ✅ All Flows use stateIn
    val currentRound = roundRepo.getCurrentRound()
        .stateIn(coroutineScope, SharingStarted.Eagerly, null)

    val scores = scoreRepo.getScoresForRound()
        .stateIn(coroutineScope, SharingStarted.Eagerly, emptyList())

    val statistics = scoreRepo.getStatistics()
        .stateIn(coroutineScope, SharingStarted.Eagerly, null)

    val isLoading = combine(
        currentRound,
        scores,
        statistics
    ) { round, scores, stats ->
        round == null && scores.isEmpty() && stats == null
    }.stateIn(coroutineScope, SharingStarted.Eagerly, true)
}
```

## Testing Presenters with stateIn

### Unit Test Pattern

```kotlin
class EquipmentPresenterTest {
    private lateinit var mockRepository: EquipmentRepository
    private lateinit var testScope: TestCoroutineScope
    private lateinit var presenter: EquipmentPresenter

    @Before
    fun setup() {
        mockRepository = mockk()
        testScope = TestCoroutineScope()

        // Mock repository returns Flow
        every { mockRepository.getAll() } returns flowOf(
            listOf(equipment1, equipment2)
        )

        // Create presenter with test scope
        presenter = EquipmentPresenter(mockRepository, testScope)
    }

    @Test
    fun `items emits repository data`() = testScope.runBlockingTest {
        // Advance coroutines (stateIn collector starts)
        advanceUntilIdle()

        // Verify StateFlow has expected value
        assertEquals(listOf(equipment1, equipment2), presenter.items.value)
    }

    @After
    fun tearDown() {
        // Cancel test scope (cleans up stateIn collector)
        testScope.cleanupTestCoroutines()
    }
}
```

**Key Points**:
- Use `TestCoroutineScope` for testing
- Call `advanceUntilIdle()` to process stateIn initialization
- Verify `StateFlow.value` directly
- Call `cleanupTestCoroutines()` in tearDown

## Migration Guide: collectLatest → stateIn

If you have existing Presenters using the wrong pattern, migrate them:

### Step 1: Identify Manual Collectors

Look for this pattern:
```kotlin
private val _items = MutableStateFlow<T>(initialValue)
val items: StateFlow<T> = _items.asStateFlow()

private fun loadItems() {
    scope.launch {
        repository.getX().collectLatest { data ->
            _items.value = data
        }
    }
}
```

### Step 2: Replace with stateIn

```kotlin
val items = repository.getX()
    .stateIn(scope, SharingStarted.Eagerly, initialValue)
```

### Step 3: Remove Manual Load Methods

Delete:
- `init { loadItems() }` blocks
- `loadItems()` methods
- `_items` private MutableStateFlow
- `.asStateFlow()` calls

### Step 4: Update Tests

Update tests to use `advanceUntilIdle()` if using `TestCoroutineScope`:
```kotlin
@Test
fun `test items`() = testScope.runBlockingTest {
    advanceUntilIdle()  // ← Add this to process stateIn initialization
    assertEquals(expected, presenter.items.value)
}
```

### Example Migration

**Before**:
```kotlin
class EquipmentPresenter(
    private val repository: EquipmentRepository,
    private val coroutineScope: CoroutineScope
) {
    private val _items = MutableStateFlow<List<Equipment>>(emptyList())
    val items: StateFlow<List<Equipment>> = _items.asStateFlow()

    init {
        loadItems()
    }

    private fun loadItems() {
        coroutineScope.launch {
            repository.getAll().collectLatest { items ->
                _items.value = items
            }
        }
    }
}
```

**After**:
```kotlin
class EquipmentPresenter(
    private val repository: EquipmentRepository,
    private val coroutineScope: CoroutineScope
) {
    val items = repository.getAll()
        .stateIn(coroutineScope, SharingStarted.Eagerly, emptyList())
}
```

**Lines of code**: 16 → 5 (69% reduction)

## Enforcement

### Code Review Checklist

When reviewing Presenter code:
- [ ] ✅ All repository Flows use `stateIn`
- [ ] ❌ No manual `collectLatest` collectors
- [ ] ❌ No `MutableStateFlow` with manual updates from repository Flows
- [ ] ❌ No `loadX()` methods that call `collectLatest`
- [ ] ✅ `coroutineScope` passed to `stateIn`
- [ ] ✅ `SharingStarted.Eagerly` used
- [ ] ✅ Appropriate `initialValue` provided

### Automated Detection

Consider adding a lint rule or static analysis check:
```kotlin
// Detectable pattern (REJECT in code review):
repository.getX().collectLatest { _stateFlow.value = it }

// Required pattern (APPROVE in code review):
repository.getX().stateIn(scope, SharingStarted.Eagerly, initialValue)
```

## Performance Considerations

### Memory Impact

**Manual collectLatest (Memory Leak)**:
- Memory usage grows linearly with Presenter instances
- Example: 100 screens visited = 100 leaked Presenters in memory
- Impact: App slowdown, potential OOM crashes

**stateIn (No Leak)**:
- Memory usage stays constant (only active Presenters in memory)
- Garbage collector can free cleared Presenters
- Impact: No performance degradation over time

### CPU Impact

**Both patterns have similar CPU usage**:
- `collectLatest` and `stateIn` both collect from repository Flow
- `stateIn` has negligible overhead for automatic cancellation
- Performance difference is not measurable in practice

**Recommendation**: Always use `stateIn` (memory safety > negligible CPU difference)

## History

**Week 17 (November 2025)**:
- 6 Presenters created with manual `collectLatest` pattern
- No memory leak detected initially

**Week 18 (November 2025)**:
- 3 more Presenters created with same pattern
- Copilot flagged memory leak during Agent 3 validation
- Agent 2 fixed all 9 Presenters (Week 17 + Week 18) immediately
- Pattern documented in CLAUDE.md

**Week 19 (November 2025)**:
- PlungerPresenter created with CORRECT `stateIn` pattern from start
- Evidence: Pattern learning successful (Agent 2 internalized fix)

**Result**: 9 memory leaks prevented, pattern established for all future work

## Related Documentation

- [[week-17-19-summary|Weeks 17-19 Overview]]
- [[agent-2-week-17-19|Agent 2 Week 17-19 Summary]]
- [[agent-3-week-17-19|Agent 3 Week 17-19 Summary]]
- [[add-new-viewmodel|How to Add a New ViewModel]]

## Tags

#best-practice #memory-leak #statein #collectlatest #kmp #presenter-pattern #coroutines #stateflow #critical

## Summary

**Rule**: Always use `stateIn(scope, SharingStarted.Eagerly, initialValue)` for exposing repository Flows in Presenters.

**Why**: Prevents memory leaks, cleaner code, automatic lifecycle management.

**When**: Every time you create a Presenter that exposes repository data as StateFlow.

**Enforcement**: Code review checklist, pattern documented in CLAUDE.md, validated by Agent 3.
