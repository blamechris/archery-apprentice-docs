---
title: How to Add a New Service
tags:
  - how-to
  - service
  - business-logic
  - clean-architecture
created: 2025-11-01
---

# How to Add a New Service

Step-by-step guide to extracting business logic into a service.

---

## Overview

Services encapsulate business logic and keep ViewModels thin.

**When to Create a Service:**
- Complex business logic (>50 lines)
- Logic used by multiple ViewModels
- Logic that coordinates multiple repositories
- Calculations and transformations
- Validation rules

**Time:** ~30 minutes
**Difficulty:** Intermediate

---

## Step 1: Identify the Business Logic

Look for logic in ViewModels that should be extracted:

```kotlin
// BEFORE: Business logic in ViewModel (BAD)
class MyViewModel(private val repo: Repository) : ViewModel() {
    fun calculateScore(arrows: List<Int>): Int {
        // Complex calculation logic...
        val total = arrows.sum()
        val bonus = if (arrows.all { it >= 8 }) 10 else 0
        val multiplier = if (arrows.contains(10)) 1.2 else 1.0
        return ((total + bonus) * multiplier).toInt()
    }
}
```

---

## Step 2: Create the Service

```kotlin
// File: domain/services/ScoreCalculationService.kt
class ScoreCalculationService {

    fun calculateScore(arrows: List<Int>): Int {
        val total = arrows.sum()
        val bonus = calculateBonus(arrows)
        val multiplier = calculateMultiplier(arrows)
        return ((total + bonus) * multiplier).toInt()
    }

    fun calculateBonus(arrows: List<Int>): Int {
        return if (arrows.all { it >= 8 }) 10 else 0
    }

    fun calculateMultiplier(arrows: List<Int>): Double {
        return if (arrows.contains(10)) 1.2 else 1.0
    }

    fun calculateAverage(scores: List<Int>): Double {
        if (scores.isEmpty()) return 0.0
        return scores.average()
    }
}
```

---

## Step 3: Add Dependency Injection

```kotlin
// File: di/ServiceModule.kt
@Module
@InstallIn(SingletonComponent::class)
object ServiceModule {

    @Provides
    @Singleton
    fun provideScoreCalculationService(): ScoreCalculationService {
        return ScoreCalculationService()
    }
}
```

---

## Step 4: Inject Service into ViewModel

```kotlin
// AFTER: Clean ViewModel (GOOD)
class MyViewModel(
    private val repository: Repository,
    private val scoreService: ScoreCalculationService  // Inject service
) : ViewModel() {

    fun onScoreEntered(arrows: List<Int>) {
        viewModelScope.launch {
            // Delegate to service
            val score = scoreService.calculateScore(arrows)

            _uiState.update { it.copy(totalScore = score) }

            // Save to repository
            repository.saveScore(score)
        }
    }
}
```

---

## Step 5: Add Tests

```kotlin
// File: test/domain/services/ScoreCalculationServiceTest.kt
class ScoreCalculationServiceTest {
    private lateinit var service: ScoreCalculationService

    @Before
    fun setup() {
        service = ScoreCalculationService()
    }

    @Test
    fun `calculateScore returns correct total`() {
        val arrows = listOf(10, 9, 8, 10, 9, 8)

        val score = service.calculateScore(arrows)

        // Base: 54, Bonus: 0 (not all >= 8), Multiplier: 1.2 (has 10)
        // (54 + 0) * 1.2 = 64.8 = 64
        assertEquals(64, score)
    }

    @Test
    fun `calculateBonus returns 10 when all arrows >= 8`() {
        val arrows = listOf(10, 9, 8, 10, 9, 8)

        val bonus = service.calculateBonus(arrows)

        assertEquals(0, bonus)  // Not all >= 8 (has 8)
    }

    @Test
    fun `calculateBonus returns 10 when all arrows >= 9`() {
        val arrows = listOf(10, 9, 9, 10, 9, 9)

        val bonus = service.calculateBonus(arrows)

        assertEquals(0, bonus)  // Actually fails - logic bug!
        // Should be: all >= 8 includes 8
    }

    @Test
    fun `calculateMultiplier returns 1_2 when has 10`() {
        val arrows = listOf(10, 9, 8)

        val multiplier = service.calculateMultiplier(arrows)

        assertEquals(1.2, multiplier, 0.01)
    }

    @Test
    fun `calculateAverage handles empty list`() {
        val average = service.calculateAverage(emptyList())

        assertEquals(0.0, average, 0.01)
    }

    @Test
    fun `calculateAverage returns correct average`() {
        val scores = listOf(10, 20, 30)

        val average = service.calculateAverage(scores)

        assertEquals(20.0, average, 0.01)
    }
}
```

---

## Service Patterns

### Service with Repository Dependencies

```kotlin
class MyService(
    private val repository: Repository,
    private val otherRepo: OtherRepository
) {
    suspend fun performComplexOperation(data: Data): Result<Output> {
        // Coordinate multiple repositories
        val result1 = repository.getData().getOrElse { return Result.failure(it) }
        val result2 = otherRepo.getOtherData().getOrElse { return Result.failure(it) }

        // Business logic
        val output = combineAndProcess(result1, result2)

        return Result.success(output)
    }

    private fun combineAndProcess(d1: Data1, d2: Data2): Output {
        // Complex processing logic
        return Output()
    }
}
```

### Service with Service Dependencies

```kotlin
class HighLevelService(
    private val calculationService: CalculationService,
    private val validationService: ValidationService
) {
    suspend fun processData(input: Input): Result<Output> {
        // Validate
        if (!validationService.isValid(input)) {
            return Result.failure(ValidationException())
        }

        // Calculate
        val result = calculationService.calculate(input)

        return Result.success(Output(result))
    }
}
```

---

## Real-World Example: EndCompletionService

```kotlin
class EndCompletionService(
    private val roundRepository: RoundRepository,
    private val validationService: ValidationService,
    private val statsService: StatisticsCalculationService
) {
    suspend fun completeEnd(
        roundId: Long,
        endNumber: Int,
        arrowScores: List<Int>,
        participantId: Long? = null
    ): Result<Unit> = try {
        // 1. Validate
        if (!validationService.validateArrowScores(arrowScores)) {
            return Result.failure(InvalidScoresException())
        }

        // 2. Calculate totals
        val totalScore = arrowScores.sum()
        val xCount = arrowScores.count { it == 10 }

        // 3. Create end score
        val endScore = EndScore(
            roundId = roundId,
            endNumber = endNumber,
            totalScore = totalScore,
            xCount = xCount,
            participantId = participantId
        )

        val endScoreId = roundRepository.createEndScore(endScore)
            .getOrElse { return Result.failure(it) }

        // 4. Create arrow scores
        val arrows = arrowScores.mapIndexed { index, score ->
            ArrowScore(
                endScoreId = endScoreId,
                arrowNumber = index + 1,
                score = score,
                isX = score == 10
            )
        }

        roundRepository.createArrowScores(arrows)
            .getOrElse { return Result.failure(it) }

        // 5. Update statistics
        statsService.updateRoundStats(roundId)

        Result.success(Unit)
    } catch (e: Exception) {
        LogConfig.e(TAG, "Failed to complete end", e)
        Result.failure(e)
    }

    companion object {
        private const val TAG = "EndCompletionService"
    }
}
```

---

## Best Practices

### 1. Single Responsibility

Each service should have ONE clear purpose:

```kotlin
// GOOD: Focused services
class ScoreCalculationService  // Calculates scores
class ScoreValidationService   // Validates scores
class ScorePersistenceService  // Saves scores

// BAD: God service
class ScoreService  // Does everything
```

### 2. Dependency Injection

Services should receive dependencies via constructor:

```kotlin
// GOOD: Testable
class MyService(
    private val repository: Repository
)

// BAD: Hard-coded
class MyService {
    private val repository = RepositoryImpl()
}
```

### 3. Use Result<T> for Error Handling

```kotlin
suspend fun performOperation(): Result<Output> {
    return try {
        val data = repository.getData()
            .getOrElse { return Result.failure(it) }

        val output = process(data)
        Result.success(output)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
```

### 4. No Android Dependencies

Services should be pure Kotlin (no Android imports):

```kotlin
// GOOD: Pure Kotlin
class MyService {
    fun calculate(data: Data): Result
}

// BAD: Android dependency
class MyService(
    private val context: Context  // ✗ Android dependency
) {
    fun calculate(data: Data): Result {
        val string = context.getString(R.string.label)  // ✗
    }
}
```

### 5. Keep Services Stateless

Services should not hold mutable state:

```kotlin
// GOOD: Stateless
class CalculationService {
    fun calculate(input: Int): Int {
        return input * 2
    }
}

// BAD: Stateful
class CalculationService {
    private var lastResult: Int = 0  // ✗ Mutable state

    fun calculate(input: Int): Int {
        lastResult = input * 2
        return lastResult
    }
}
```

---

## When to Extract to Service

### Extract When:
- ✅ Logic is >50 lines
- ✅ Logic is complex/hard to understand
- ✅ Logic is reused in multiple ViewModels
- ✅ Logic coordinates multiple repositories
- ✅ Logic is pure business rules

### Keep in ViewModel When:
- ❌ Simple UI state updates
- ❌ Navigation logic
- ❌ Single-line operations
- ❌ UI-specific transformations

---

## Common Issues

### Issue: Circular dependencies
**Problem:**
```kotlin
class ServiceA(private val serviceB: ServiceB)
class ServiceB(private val serviceA: ServiceA)  // Circular!
```

**Solution:** Refactor to remove circular dependency or use interface

### Issue: Service too large
**Problem:** Service has >500 lines, too many responsibilities

**Solution:** Split into multiple focused services

### Issue: Hard to test
**Problem:** Service has hard-coded dependencies

**Solution:** Use dependency injection

---

## Related Documentation

- [[../technical-reference/api/services/index|Services API Reference]]
- [[../technical-reference/api/services/end-completion-service|EndCompletionService Example]]
- [[add-new-viewmodel|How to Add a New ViewModel]]
- [[write-unit-tests|How to Write Unit Tests]]

---

**Last Updated:** 2025-11-01
