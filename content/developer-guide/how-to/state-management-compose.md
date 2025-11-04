---
title: State Management in Compose
tags:
  - how-to
  - compose
  - state
  - stateflow
created: 2025-11-01
---

# State Management in Compose

Guide to managing state in Jetpack Compose with StateFlow.

---

## ViewModel + StateFlow Pattern

```kotlin
// ViewModel
class MyViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    fun updateState() {
        _uiState.update { it.copy(isLoading = true) }
    }
}

// Composable
@Composable
fun MyScreen(viewModel: MyViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsState()

    if (state.isLoading) {
        LoadingIndicator()
    }
}
```

---

## Local UI State

```kotlin
@Composable
fun MyScreen() {
    // For simple UI-only state
    var selectedTab by remember { mutableStateOf(0) }

    TabRow(selectedTabIndex = selectedTab) {
        Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 })
        Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 })
    }
}
```

---

## State Hoisting

```kotlin
@Composable
fun ParentScreen() {
    var text by remember { mutableStateOf("") }

    ChildComponent(
        text = text,
        onTextChange = { text = it }
    )
}

@Composable
fun ChildComponent(
    text: String,
    onTextChange: (String) -> Unit
) {
    TextField(
        value = text,
        onValueChange = onTextChange
    )
}
```

---

## Side Effects

```kotlin
// LaunchedEffect: Run when key changes
LaunchedEffect(userId) {
    viewModel.loadUser(userId)
}

// DisposableEffect: Cleanup
DisposableEffect(Unit) {
    val listener = createListener()
    onDispose { listener.remove() }
}

// SideEffect: Run after every recomposition
SideEffect {
    analytics.trackScreenView()
}
```

---

## Related Documentation

- [[compose-best-practices|Compose Best Practices]]
- [[add-new-viewmodel|How to Add a New ViewModel]]

---

**Last Updated:** 2025-11-01
