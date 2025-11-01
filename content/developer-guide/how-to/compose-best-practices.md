---
title: Compose Best Practices
tags:
  - how-to
  - compose
  - ui
  - best-practices
created: 2025-11-01
---

# Compose Best Practices

Best practices for writing Jetpack Compose UI in Archery Apprentice.

---

## State Hoisting

```kotlin
// GOOD: State hoisted to ViewModel
@Composable
fun MyScreen(viewModel: MyViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsState()

    MyContent(
        items = state.items,
        onItemClick = { viewModel.onItemClicked(it) }
    )
}

@Composable
private fun MyContent(
    items: List<Item>,
    onItemClick: (Item) -> Unit
) {
    // Stateless component
}
```

---

## Remember and rememberSaveable

```kotlin
// Remember across recompositions
val scrollState = rememberScrollState()

// Survive configuration changes
var text by rememberSaveable { mutableStateOf("") }
```

---

## Derived State

```kotlin
@Composable
fun MyScreen() {
    val items by viewModel.items.collectAsState()

    // Derive state - only recomputes when items change
    val sortedItems = remember(items) {
        items.sortedBy { it.name }
    }
}
```

---

## LaunchedEffect

```kotlin
@Composable
fun MyScreen(itemId: Long) {
    LaunchedEffect(itemId) {
        viewModel.loadItem(itemId)
    }
}
```

---

## Performance Tips

1. **Use `key()` in lists** for stable identity
2. **Avoid creating lambdas in loops**
3. **Use `Modifier` efficiently**
4. **Hoist state when possible**
5. **Use `remember` for expensive calculations**

---

## Related Documentation

- [[state-management-compose|State Management in Compose]]
- [[add-new-screen|How to Add a New Screen]]

---

**Last Updated:** 2025-11-01
