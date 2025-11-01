---
title: How to Add a New Screen
tags:
  - how-to
  - ui
  - compose
  - screen
created: 2025-11-01
---

# How to Add a New Screen

Step-by-step guide to creating a new UI screen in Archery Apprentice.

---

## Overview

This guide covers creating a complete new screen with:
- Jetpack Compose UI
- ViewModel for state management
- Navigation integration
- Repository/Service integration

**Time:** ~30-60 minutes
**Difficulty:** Intermediate

---

## Step 1: Create the ViewModel

```kotlin
// File: ui/viewmodels/MyFeatureViewModel.kt
package com.archeryapprentice.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class MyFeatureUiState(
    val data: List<Item> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

class MyFeatureViewModel(
    private val repository: MyRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MyFeatureUiState())
    val uiState: StateFlow<MyFeatureUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            repository.getData()
                .onSuccess { data ->
                    _uiState.update { it.copy(data = data, isLoading = false) }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(error = error.message, isLoading = false)
                    }
                }
        }
    }

    fun onAction(action: MyAction) {
        // Handle user actions
    }
}
```

---

## Step 2: Create the Composable Screen

```kotlin
// File: ui/screens/MyFeatureScreen.kt
package com.archeryapprentice.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun MyFeatureScreen(
    onNavigateBack: () -> Unit,
    viewModel: MyFeatureViewModel = viewModel()
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Feature") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Back")
                    }
                }
            )
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
                        data = state.data,
                        onAction = { viewModel.onAction(it) }
                    )
                }
            }
        }
    }
}

@Composable
private fun ContentView(
    data: List<Item>,
    onAction: (MyAction) -> Unit
) {
    LazyColumn {
        items(data) { item ->
            ItemCard(
                item = item,
                onClick = { onAction(MyAction.ItemClicked(item.id)) }
            )
        }
    }
}
```

---

## Step 3: Add Navigation Route

```kotlin
// File: navigation/NavGraph.kt

sealed class Screen(val route: String) {
    object Home : Screen("home")
    object MyFeature : Screen("my_feature")  // Add new route
}

@Composable
fun NavGraph(
    navController: NavHostController
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToMyFeature = {
                    navController.navigate(Screen.MyFeature.route)
                }
            )
        }

        // Add new screen
        composable(Screen.MyFeature.route) {
            MyFeatureScreen(
                onNavigateBack = {
                    navController.navigateUp()
                }
            )
        }
    }
}
```

---

## Step 4: Create ViewModel Factory (if needed)

```kotlin
// File: ui/viewmodels/MyFeatureViewModelFactory.kt

class MyFeatureViewModelFactory(
    private val repository: MyRepository
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(MyFeatureViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return MyFeatureViewModel(repository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

// Usage in Composable
@Composable
fun MyFeatureScreen(
    repository: MyRepository = LocalRepository.current,
    viewModel: MyFeatureViewModel = viewModel(
        factory = MyFeatureViewModelFactory(repository)
    )
) {
    // ...
}
```

---

## Step 5: Add Tests

### ViewModel Test

```kotlin
// File: test/ui/viewmodels/MyFeatureViewModelTest.kt

class MyFeatureViewModelTest {
    private lateinit var viewModel: MyFeatureViewModel
    private lateinit var mockRepository: MyRepository

    @Before
    fun setup() {
        mockRepository = mockk()
        viewModel = MyFeatureViewModel(mockRepository)
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
        assertEquals(testData, state.data)
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
    }
}
```

### UI Test

```kotlin
// File: androidTest/ui/screens/MyFeatureScreenTest.kt

@RunWith(AndroidJUnit4::class)
class MyFeatureScreenTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun displaysLoadingState() {
        val viewModel = MyFeatureViewModel(mockRepository)
        // Set loading state
        viewModel._uiState.value = MyFeatureUiState(isLoading = true)

        composeTestRule.setContent {
            MyFeatureScreen(
                onNavigateBack = {},
                viewModel = viewModel
            )
        }

        composeTestRule
            .onNodeWithContentDescription("Loading")
            .assertIsDisplayed()
    }
}
```

---

## Step 6: Update Navigation Links

Add navigation from existing screens:

```kotlin
// In HomeScreen.kt or wherever you want to navigate from
Button(
    onClick = {
        navController.navigate(Screen.MyFeature.route)
    }
) {
    Text("Go to My Feature")
}
```

---

## Complete Example

Here's a complete minimal example:

```kotlin
// MyFeatureScreen.kt
@Composable
fun MyFeatureScreen(
    onNavigateBack: () -> Unit,
    viewModel: MyFeatureViewModel = viewModel()
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Feature") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            if (state.isLoading) {
                CircularProgressIndicator()
            } else {
                LazyColumn {
                    items(state.data) { item ->
                        Text(item.name)
                    }
                }
            }
        }
    }
}
```

---

## Best Practices

1. **Separate Concerns**: Keep UI, ViewModel, and business logic separate
2. **State Management**: Use StateFlow for reactive UI updates
3. **Error Handling**: Always handle loading and error states
4. **Testing**: Write tests for ViewModel logic
5. **Navigation**: Use type-safe navigation arguments
6. **Accessibility**: Add content descriptions for screen readers

---

## Common Issues

### Issue: ViewModel survives configuration changes
**Solution:** ViewModels automatically survive rotations. Don't recreate them manually.

### Issue: State not updating in UI
**Solution:** Make sure you're collecting StateFlow with `collectAsState()`

### Issue: Memory leaks
**Solution:** Use `viewModelScope` for coroutines, they're automatically cancelled

---

## Related Documentation

- [[../technical-reference/api/viewmodels/index|ViewModels API Reference]]
- [[add-new-viewmodel|How to Add a New ViewModel]]
- [[../getting-started|Getting Started Guide]]

---

**Last Updated:** 2025-11-01
