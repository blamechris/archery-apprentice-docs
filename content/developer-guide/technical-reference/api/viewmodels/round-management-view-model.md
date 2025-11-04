---
title: RoundManagementViewModel API Reference
tags:
  - api
  - viewmodel
  - round
  - list
  - filtering
created: 2025-11-01
---

# RoundManagementViewModel API Reference

ViewModel for round list management, search, and filtering.

---

## Overview

**File:** `ui/viewmodels/RoundManagementViewModel.kt`
**Lines:** 495 lines
**Status:** ✅ Production

### Purpose

Manages round list display, search, filtering, and bulk operations:
- Round list with pagination
- Search and filtering
- Sorting options
- Bulk deletion
- Status filtering

---

## UI State

```kotlin
data class RoundManagementUiState(
    val rounds: List<Round> = emptyList(),
    val filteredRounds: List<Round> = emptyList(),
    val searchQuery: String = "",
    val statusFilter: RoundStatus? = null,
    val sortOrder: SortOrder = SortOrder.DATE_DESC,
    val selectedRounds: Set<Long> = emptySet(),
    val isLoading: Boolean = false
)
```

---

## Key Methods

```kotlin
// Search and filter
fun searchRounds(query: String)
fun filterByStatus(status: RoundStatus?)
fun setSortOrder(order: SortOrder)

// Selection
fun toggleRoundSelection(roundId: Long)
fun selectAll()
fun clearSelection()

// Bulk operations
fun deleteSelectedRounds()
fun archiveSelectedRounds()
```

---

## Usage Example

```kotlin
@Composable
fun RoundListScreen(viewModel: RoundManagementViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsState()

    Column {
        SearchBar(
            query = state.searchQuery,
            onQueryChange = { viewModel.searchRounds(it) }
        )

        FilterChips(
            selected = state.statusFilter,
            onFilterChange = { viewModel.filterByStatus(it) }
        )

        LazyColumn {
            items(state.filteredRounds) { round ->
                RoundListItem(
                    round = round,
                    selected = round.id in state.selectedRounds,
                    onToggleSelection = { viewModel.toggleRoundSelection(round.id) }
                )
            }
        }
    }
}
```

---

**Status:** ✅ Production
**Last Updated:** 2025-11-01
