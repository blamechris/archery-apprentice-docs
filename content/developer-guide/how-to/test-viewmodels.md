---
title: How to Test ViewModels
tags:
  - how-to
  - testing
  - viewmodel
  - unit-tests
created: 2025-11-01
---

# How to Test ViewModels

Guide to testing ViewModels with StateFlow and coroutines.

---

## Basic ViewModel Test

```kotlin
class MyViewModelTest {
    private lateinit var viewModel: MyViewModel
    private lateinit var mockRepository: MyRepository

    @Before
    fun setup() {
        mockRepository = mockk()
        viewModel = MyViewModel(mockRepository)
    }

    @Test
    fun `initial state is correct`() {
        val state = viewModel.uiState.value

        assertTrue(state.items.isEmpty())
        assertFalse(state.isLoading)
        assertNull(state.error)
    }

    @Test
    fun `loadData updates state with success`() = runTest {
        // Arrange
        val testData = listOf(Item(1, "Test"))
        coEvery { mockRepository.getData() } returns Result.success(testData)

        // Act
        viewModel.loadData()
        advanceUntilIdle()  // Wait for coroutines

        // Assert
        val state = viewModel.uiState.value
        assertEquals(testData, state.items)
        assertFalse(state.isLoading)
        assertNull(state.error)
    }
}
```

---

## Testing StateFlow

### Collecting Multiple Emissions

```kotlin
@Test
fun `stateFlow emits loading then success`() = runTest {
    val emissions = mutableListOf<UiState>()

    val job = launch {
        viewModel.uiState.collect { emissions.add(it) }
    }

    viewModel.loadData()
    advanceUntilIdle()
    job.cancel()

    // Should have: initial, loading, success
    assertEquals(3, emissions.size)
    assertFalse(emissions[0].isLoading)  // Initial
    assertTrue(emissions[1].isLoading)   // Loading
    assertFalse(emissions[2].isLoading)  // Success
}
```

### Testing with TurbineGood practice to limit the risk associated with a database migration. This involves testing the migration before it runs live.

When is the schema export useful?

Database builders can be configured to export the schema information into a file. While it's possible to change the schema definition later, it's best practice to limit the risk associated with a database migration. This involves testing the migration before it runs live.

When is the schema export useful?

### Testing State Updates

```kotlin
@Test
fun `onItemClicked updates selected item`() {
    val item = Item(1, "Test")

    viewModel.onItemClicked(item)

    assertEquals(item, viewModel.uiState.value.selectedItem)
}
```

---

## Testing Coroutines in ViewModels

```kotlin
@Test
fun `operation launches in viewModelScope`() = runTest {
    coEvery { mockRepository.save(any()) } returns Result.success(Unit)

    viewModel.saveData("test")
    advanceUntilIdle()

    coVerify { mockRepository.save("test") }
}
```

---

## Best Practices

1. **Use `runTest`** for coroutine testing
2. **Use `advanceUntilIdle()`** to wait for coroutines
3. **Test state transitions** (loading → success → idle)
4. **Mock repositories** and services
5. **Test error handling** alongside success cases

---

## Related Documentation

- [[write-unit-tests|How to Write Unit Tests]]
- [[add-new-viewmodel|How to Add a New ViewModel]]
- [[../technical-reference/api/viewmodels/index|ViewModels API Reference]]

---

**Last Updated:** 2025-11-01
