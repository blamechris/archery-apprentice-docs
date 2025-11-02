---
title: How to Write Unit Tests
tags:
  - how-to
  - testing
  - unit-tests
  - junit
created: 2025-11-01
---

# How to Write Unit Tests

Comprehensive guide to writing effective unit tests in Archery Apprentice.

---

## Overview

Unit tests verify individual components in isolation using mocks for dependencies.

**Time:** ~20-30 minutes per class
**Difficulty:** Beginner to Intermediate

---

## Test Structure: AAA Pattern

```kotlin
@Test
fun `descriptive test name in backticks`() = runTest {
    // Arrange: Set up test data and mocks
    val testData = createTestData()
    coEvery { mockRepo.getData() } returns Result.success(testData)

    // Act: Execute the code under test
    val result = service.performOperation()

    // Assert: Verify the results
    assertTrue(result.isSuccess)
    assertEquals(expected, result.getOrNull())
}
```

---

## Dependencies

```kotlin
// File: app/build.gradle.kts
dependencies {
    // JUnit 4
    testImplementation("junit:junit:4.13.2")

    // Kotlin Coroutines Test
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")

    // MockK for mocking
    testImplementation("io.mockk:mockk:1.13.8")

    // Truth for assertions (optional)
    testImplementation("com.google.truth:truth:1.1.5")
}
```

---

## Basic Test Example

```kotlin
// File: test/domain/services/ScoreCalculationServiceTest.kt
class ScoreCalculationServiceTest {

    private lateinit var service: ScoreCalculationService

    @Before
    fun setup() {
        service = ScoreCalculationService()
    }

    @After
    fun teardown() {
        // Clean up if needed
    }

    @Test
    fun `calculateTotal returns sum of arrow scores`() {
        // Arrange
        val arrows = listOf(10, 9, 8, 10, 9, 8)

        // Act
        val total = service.calculateTotal(arrows)

        // Assert
        assertEquals(54, total)
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

## Testing with Mocks (MockK)

### Basic Mocking

```kotlin
class MyServiceTest {
    private lateinit var service: MyService
    private lateinit var mockRepository: MyRepository

    @Before
    fun setup() {
        mockRepository = mockk()  // Create mock
        service = MyService(mockRepository)
    }

    @Test
    fun `getData returns success from repository`() = runTest {
        // Arrange: Define mock behavior
        val testData = listOf(Item(1, "Test"))
        coEvery { mockRepository.getData() } returns Result.success(testData)

        // Act
        val result = service.getData()

        // Assert
        assertTrue(result.isSuccess)
        assertEquals(testData, result.getOrNull())

        // Verify mock was called
        coVerify { mockRepository.getData() }
    }
}
```

### Advanced Mocking

```kotlin
@Test
fun `service calls repository with correct parameters`() = runTest {
    // Mock returns value based on parameter
    coEvery { mockRepository.getById(any()) } answers {
        val id = firstArg<Long>()
        Result.success(Item(id, "Item $id"))
    }

    val result = service.getById(5L)

    assertEquals(5L, result.getOrNull()?.id)
    coVerify { mockRepository.getById(5L) }  // Verify exact parameter
}

@Test
fun `service handles repository failure`() = runTest {
    val error = Exception("Database error")
    coEvery { mockRepository.getData() } returns Result.failure(error)

    val result = service.getData()

    assertTrue(result.isFailure)
    assertEquals(error, result.exceptionOrNull())
}
```

### Verify Interactions

```kotlin
@Test
fun `service calls multiple repositories`() = runTest {
    coEvery { mockRepo1.getData() } returns Result.success(data1)
    coEvery { mockRepo2.getData() } returns Result.success(data2)

    service.complexOperation()

    // Verify both were called
    coVerify { mockRepo1.getData() }
    coVerify { mockRepo2.getData() }
}

@Test
fun `service does not call repository when validation fails`() = runTest {
    service.invalidOperation()

    // Verify repository was NOT called
    coVerify(exactly = 0) { mockRepository.save(any()) }
}
```

---

## Testing Coroutines

### Using runTest

```kotlin
@Test
fun `async operation completes successfully`() = runTest {
    // runTest provides a test dispatcher
    coEvery { mockRepo.getData() } returns Result.success(testData)

    val result = service.asyncOperation()

    assertTrue(result.isSuccess)
}
```

### Testing Delays

```kotlin
@Test
fun `operation waits for delay`() = runTest {
    service.operationWithDelay()  // Has delay(1000)

    // Time is virtually advanced
    advanceUntilIdle()

    assertTrue(service.isComplete)
}
```

---

## Testing Result<T>

```kotlin
@Test
fun `operation returns success result`() = runTest {
    val result = service.successfulOperation()

    // Check success
    assertTrue(result.isSuccess)
    assertFalse(result.isFailure)

    // Get value
    val value = result.getOrNull()
    assertNotNull(value)
    assertEquals(expected, value)
}

@Test
fun `operation returns failure result`() = runTest {
    val result = service.failingOperation()

    // Check failure
    assertTrue(result.isFailure)
    assertFalse(result.isSuccess)

    // Get exception
    val exception = result.exceptionOrNull()
    assertNotNull(exception)
    assertTrue(exception is CustomException)
}

@Test
fun `operation handles result with fold`() = runTest {
    val result = service.operation()

    var successCalled = false
    var failureCalled = false

    result.fold(
        onSuccess = { successCalled = true },
        onFailure = { failureCalled = true }
    )

    assertTrue(successCalled)
    assertFalse(failureCalled)
}
```

---

## Testing Edge Cases

```kotlin
class ValidationServiceTest {

    @Test
    fun `validate accepts valid input`() {
        val valid = service.validate("Valid Input")
        assertTrue(valid)
    }

    @Test
    fun `validate rejects empty string`() {
        val invalid = service.validate("")
        assertFalse(invalid)
    }

    @Test
    fun `validate rejects whitespace`() {
        val invalid = service.validate("   ")
        assertFalse(invalid)
    }

    @Test
    fun `validate rejects null`() {
        val invalid = service.validate(null)
        assertFalse(invalid)
    }

    @Test
    fun `validate handles maximum length`() {
        val maxLength = "a".repeat(255)
        assertTrue(service.validate(maxLength))

        val tooLong = "a".repeat(256)
        assertFalse(service.validate(tooLong))
    }

    @Test
    fun `calculate handles division by zero`() {
        val result = service.divide(10, 0)

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is ArithmeticException)
    }

    @Test
    fun `list operations handle empty list`() {
        assertEquals(0, service.sumList(emptyList()))
        assertEquals(0.0, service.averageList(emptyList()), 0.01)
        assertNull(service.maxOf(emptyList()))
    }
}
```

---

## Parameterized Tests

```kotlin
class ScoreValidationTest {

    @Test
    fun `validateScore accepts valid scores`() {
        val validScores = listOf(0, 1, 5, 8, 9, 10)

        validScores.forEach { score ->
            assertTrue(
                "Score $score should be valid",
                service.validateScore(score)
            )
        }
    }

    @Test
    fun `validateScore rejects invalid scores`() {
        val invalidScores = listOf(-1, 11, 100, -10)

        invalidScores.forEach { score ->
            assertFalse(
                "Score $score should be invalid",
                service.validateScore(score)
            )
        }
    }
}
```

---

## Test Data Builders

```kotlin
// File: test/utils/TestDataBuilders.kt
object TestData {
    fun round(
        id: Long = 1L,
        name: String = "Test Round",
        distance: Int = 18,
        endsCount: Int = 10
    ) = Round(
        id = id,
        name = name,
        distance = distance,
        endsCount = endsCount
    )

    fun endScore(
        id: Long = 1L,
        roundId: Long = 1L,
        endNumber: Int = 1,
        totalScore: Int = 54,
        xCount: Int = 2
    ) = EndScore(
        id = id,
        roundId = roundId,
        endNumber = endNumber,
        totalScore = totalScore,
        xCount = xCount
    )
}

// Usage
@Test
fun `test with builder`() {
    val round = TestData.round(name = "Custom Name", distance = 70)
    assertEquals("Custom Name", round.name)
}
```

---

## Best Practices

### 1. Test One Thing Per Test

```kotlin
// GOOD: Focused test
@Test
fun `calculateTotal returns sum`() {
    assertEquals(30, service.calculateTotal(listOf(10, 10, 10)))
}

@Test
fun `calculateAverage returns average`() {
    assertEquals(10.0, service.calculateAverage(listOf(10, 10, 10)), 0.01)
}

// BAD: Testing multiple things
@Test
fun `calculations work`() {
    assertEquals(30, service.calculateTotal(listOf(10, 10, 10)))
    assertEquals(10.0, service.calculateAverage(listOf(10, 10, 10)), 0.01)
    // Too much in one test!
}
```

### 2. Use Descriptive Test Names

```kotlin
// GOOD: Clear what's being tested
@Test
fun `calculateScore returns zero when arrows list is empty`()

@Test
fun `validateEmail returns false for invalid format`()

// BAD: Unclear
@Test
fun testCalculate()

@Test
fun test1()
```

### 3. Arrange-Act-Assert Pattern

```kotlin
@Test
fun `test with clear AAA structure`() {
    // Arrange: Setup
    val input = createInput()
    coEvery { mock.getData() } returns testData

    // Act: Execute
    val result = service.process(input)

    // Assert: Verify
    assertTrue(result.isSuccess)
    assertEquals(expected, result.getOrNull())
}
```

### 4. Test Public API Only

```kotlin
// GOOD: Test public methods
@Test
fun `publicMethod returns correct result`() {
    val result = service.publicMethod()
    assertEquals(expected, result)
}

// BAD: Testing private methods
@Test
fun `privateHelperMethod returns correct result`() {
    // Can't access private methods!
}
```

### 5. Mock External Dependencies Only

```kotlin
// GOOD: Mock repository (external)
val mockRepo = mockk<Repository>()

// BAD: Mock everything
val mockString = mockk<String>()  // Don't mock data classes
val mockList = mockk<List<Int>>()  // Don't mock collections
```

---

## Common Assertions

```kotlin
// Equality
assertEquals(expected, actual)
assertEquals(42.0, result, 0.01)  // Doubles with delta

// Boolean
assertTrue(condition)
assertFalse(condition)

// Null
assertNull(value)
assertNotNull(value)

// Collections
assertEquals(3, list.size)
assertTrue(list.contains(item))
assertTrue(list.isEmpty())

// Exceptions
assertThrows<CustomException> {
    service.methodThatThrows()
}
```

---

## Common Issues

### Issue: Test flakiness
**Solution:** Avoid real timers, use `runTest` and `advanceUntilIdle()`

### Issue: "lateinit property has not been initialized"
**Solution:** Initialize in `@Before` method

### Issue: Mocks not working
**Solution:** Check you're using `coEvery` for suspend functions

### Issue: Tests slow
**Solution:** Use unit tests (not instrumented tests) when possible

---

## Related Documentation

- [[test-viewmodels|How to Test ViewModels]]
- [[test-daos|How to Test DAOs]]
- [[write-integration-tests|How to Write Integration Tests]]
- [[../../../../testing/test-quality-standards|Testing Standards]]

---

**Last Updated:** 2025-11-01
