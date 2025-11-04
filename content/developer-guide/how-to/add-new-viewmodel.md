---
title: How to Add a New ViewModel
tags:
  - how-to
  - viewmodel
  - mvvm
  - state-management
created: 2025-11-01
---

# How to Add a New ViewModel

Step-by-step guide to creating a new ViewModel following MVVM best practices.

---

## Overview

**Time:** ~20-30 minutes
**Difficulty:** Beginner to Intermediate

---

## Step 1: Define UI State

```kotlin
// File: ui/viewmodels/MyFeatureUiState.kt
data class MyFeatureUiState(
    // Data
    val items: List<Item> = emptyList(),
    val selectedItem: Item? = null,

    // UI flags
    val isLoading: Boolean = false,
    val error: String? = null,
    val showDialog: Boolean = false,

    // Form state (if applicable)
    val inputText: String = "",
    val isValid: Boolean = false
) {
    companion object {
        fun initial() = MyFeatureUiState()
    }
}
```

**Best Practices:**
- Keep state immutable (use `val`, not `var`)
- Group related properties
- Provide `initial()` factory method
- Use descriptive names

---

## Step 2: Create ViewModel

```kotlin
// File: ui/viewmodels/MyFeatureViewModel.kt
class MyFeatureViewModel(
    private val repository: MyRepository,
    private val service: MyService? = null
) : ViewModel() {

    // State
    private val _uiState = MutableStateFlow(MyFeatureUiState.initial())
    val uiState: StateFlow<MyFeatureUiState> = _uiState.asStateFlow()

    // Initialize
    init {
        loadData()
    }

    // Public API - User Actions
    fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            repository.getData()
                .onSuccess { data ->
                    _uiState.update {
                        it.copy(
                            items = data,
                            isLoading = false
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            error = error.message,
                            isLoading = false
                        )
                    }
                }
        }
    }

    fun onItemClicked(item: Item) {
        _uiState.update { it.copy(selectedItem = item) }
    }

    fun onInputChanged(text: String) {
        _uiState.update {
            it.copy(
                inputText = text,
                isValid = validateInput(text)
            )
        }
    }

    fun onSaveClicked() {
        if (!uiState.value.isValid) return

        viewModelScope.launch {
            service?.saveData(uiState.value.inputText)
                ?.onSuccess {
                    // Clear form, show success
                    _uiState.update {
                        MyFeatureUiState.initial()
                    }
                }
        }
    }

    fun onDismissDialog() {
        _uiState.update { it.copy(showDialog = false) }
    }

    // Private helpers
    private fun validateInput(text: String): Boolean {
        return text.isNotBlank() && text.length >= 3
    }
}
```

---

## Step 3: Create ViewModel Factory (if needed)

```kotlin
// File: ui/viewmodels/MyFeatureViewModelFactory.kt
class MyFeatureViewModelFactory(
    private val repository: MyRepository,
    private val service: MyService? = null
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(MyFeatureViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return MyFeatureViewModel(repository, service) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
```

---

## Step 4: Use in Composable

```kotlin
@Composable
fun MyFeatureScreen(
    viewModel: MyFeatureViewModel = viewModel(
        factory = MyFeatureViewModelFactory(
            repository = LocalRepository.current
        )
    )
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("My Feature") })
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when {
                state.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                state.error != null -> {
                    ErrorView(
                        error = state.error!!,
                        onRetry = { viewModel.loadData() }
                    )
                }
                else -> {
                    ContentView(
                        items = state.items,
                        selectedItem = state.selectedItem,
                        onItemClick = { viewModel.onItemClicked(it) }
                    )
                }
            }
        }
    }

    // Dialog
    if (state.showDialog) {
        AlertDialog(
            onDismissRequest = { viewModel.onDismissDialog() },
            title = { Text("Dialog") },
            text = { Text("Content") },
            confirmButton = {
                Button(onClick = { viewModel.onDismissDialog() }) {
                    Text("OK")
                }
            }
        )
    }
}
```

---

## Step 5: Add Tests

```kotlin
// File: test/ui/viewmodels/MyFeatureViewModelTest.kt
class MyFeatureViewModelTest {
    private lateinit var viewModel: MyFeatureViewModel
    private lateinit var mockRepository: MyRepository
    private lateinit var mockService: MyService

    @Before
    fun setup() {
        mockRepository = mockk()
        mockService = mockk()
        viewModel = MyFeatureViewModel(mockRepository, mockService)
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
        advanceUntilIdle()

        // Assert
        val state = viewModel.uiState.value
        assertEquals(testData, state.items)
        assertFalse(state.isLoading)
        assertNull(state.error)
    }

    @Test
    fun `loadData updates state with error`() = runTest {
        // Arrange
        val error = Exception("Test error")
        coEvery { mockRepository.getData() } returns Result.failure(error)

        // Act
        viewModel.loadData()
        advanceUntilIdle()

        // Assert
        val state = viewModel.uiState.value
        assertEquals("Test error", state.error)
        assertFalse(state.isLoading)
        assertTrue(state.items.isEmpty())
    }

    @Test
    fun `onItemClicked updates selected item`() {
        val item = Item(1, "Test")

        viewModel.onItemClicked(item)

        assertEquals(item, viewModel.uiState.value.selectedItem)
    }

    @Test
    fun `onInputChanged validates input`() {
        // Valid input
        viewModel.onInputChanged("Valid")
        assertTrue(viewModel.uiState.value.isValid)

        // Invalid input (too short)
        viewModel.onInputChanged("ab")
        assertFalse(viewModel.uiState.value.isValid)

        // Invalid input (blank)
        viewModel.onInputChanged("")
        assertFalse(viewModel.uiState.value.isValid)
    }

    @Test
    fun `onSaveClicked calls service when valid`() = runTest {
        // Arrange
        coEvery { mockService.saveData(any()) } returns Result.success(Unit)
        viewModel.onInputChanged("Valid input")

        // Act
        viewModel.onSaveClicked()
        advanceUntilIdle()

        // Assert
        coVerify { mockService.saveData("Valid input") }
    }

    @Test
    fun `onSaveClicked does nothing when invalid`() = runTest {
        // Arrange
        viewModel.onInputChanged("")  // Invalid

        // Act
        viewModel.onSaveClicked()
        advanceUntilIdle()

        // Assert
        coVerify(exactly = 0) { mockService.saveData(any()) }
    }
}
```

---

## Best Practices

### 1. Single Responsibility

Each ViewModel should handle ONE screen or feature:

```kotlin
// GOOD: Focused ViewModel
class RoundListViewModel  // Handles round list only

// BAD: God ViewModel
class RoundViewModel  // Handles list, creation, editing, scoring, etc.
```

### 2. Immutable State

Always use `copy()` to update state:

```kotlin
// GOOD
_uiState.update { it.copy(isLoading = true) }

// BAD: Direct mutation
_uiState.value.isLoading = true  // Won't compile with val
```

### 3. Use viewModelScope

Launch coroutines in `viewModelScope` for automatic cancellation:

```kotlin
// GOOD
fun loadData() {
    viewModelScope.launch {  // Cancelled when ViewModel cleared
        repository.getData()
    }
}

// BAD: GlobalScope
fun loadData() {
    GlobalScope.launch {  // Never cancelled!
        repository.getData()
    }
}
```

### 4. Handle All States

Always handle loading, success, and error states:

```kotlin
data class UiState(
    val data: List<T> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)
```

### 5. Expose StateFlow, Not MutableStateFlow

```kotlin
// GOOD
private val _uiState = MutableStateFlow(UiState())
val uiState: StateFlow<UiState> = _uiState.asStateFlow()

// BAD: Exposes mutable state
val uiState = MutableStateFlow(UiState())
```

### 6. Keep ViewModels Thin

Delegate business logic to services:

```kotlin
// GOOD
class MyViewModel(
    private val service: MyService  // Business logic in service
) {
    fun performAction() {
        viewModelScope.launch {
            service.doComplexOperation()  // Delegate
        }
    }
}

// BAD: Business logic in ViewModel
class MyViewModel {
    fun performAction() {
        // 100 lines of complex business logic...
    }
}
```

---

## Common Patterns

### Form Validation

```kotlin
data class FormUiState(
    val name: String = "",
    val email: String = "",
    val nameError: String? = null,
    val emailError: String? = null,
    val isValid: Boolean = false
)

fun onNameChanged(name: String) {
    val error = if (name.isBlank()) "Name required" else null
    _uiState.update {
        it.copy(
            name = name,
            nameError = error,
            isValid = error == null && it.emailError == null
        )
    }
}
```

### Pagination

```kotlin
data class ListUiState(
    val items: List<Item> = emptyList(),
    val page: Int = 0,
    val hasMore: Boolean = true,
    val isLoadingMore: Boolean = false
)

fun loadMore() {
    if (!uiState.value.hasMore || uiState.value.isLoadingMore) return

    viewModelScope.launch {
        _uiState.update { it.copy(isLoadingMore = true) }

        repository.getPage(uiState.value.page + 1)
            .onSuccess { newItems ->
                _uiState.update {
                    it.copy(
                        items = it.items + newItems,
                        page = it.page + 1,
                        hasMore = newItems.isNotEmpty(),
                        isLoadingMore = false
                    )
                }
            }
    }
}
```

### Search/Filter

```kotlin
data class SearchUiState(
    val allItems: List<Item> = emptyList(),
    val filteredItems: List<Item> = emptyList(),
    val searchQuery: String = ""
)

fun onSearchQueryChanged(query: String) {
    _uiState.update {
        val filtered = if (query.isBlank()) {
            it.allItems
        } else {
            it.allItems.filter { item ->
                item.name.contains(query, ignoreCase = true)
            }
        }

        it.copy(
            searchQuery = query,
            filteredItems = filtered
        )
    }
}
```

---

## Common Issues

### Issue: State not updating in UI
**Solution:** Ensure you're using `collectAsState()`:
```kotlin
val state by viewModel.uiState.collectAsState()  // ✓
val state = viewModel.uiState.value  // ✗ Won't update
```

### Issue: ViewModel recreated on rotation
**Solution:** Use `viewModel()` function, not constructor:
```kotlin
@Composable
fun MyScreen(
    viewModel: MyViewModel = viewModel()  // ✓ Survives rotation
) {
    // ...
}
```

### Issue: Coroutine leaks
**Solution:** Use `viewModelScope`:
```kotlin
viewModelScope.launch {  // ✓ Auto-cancelled
    // ...
}
```

---

## Related Documentation

- [[../technical-reference/api/viewmodels/index|ViewModels API Reference]]
- [[add-new-screen|How to Add a New Screen]]
- [[test-viewmodels|How to Test ViewModels]]
- [[../getting-started|Getting Started Guide]]

---

**Last Updated:** 2025-11-01
