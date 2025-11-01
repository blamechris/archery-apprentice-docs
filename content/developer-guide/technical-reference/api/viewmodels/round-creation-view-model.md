---
title: RoundCreationViewModel API Reference
tags:
  - api
  - viewmodel
  - round
  - creation
created: 2025-11-01
---

# RoundCreationViewModel API Reference

ViewModel for creating and configuring new rounds.

---

## Overview

**File:** `ui/viewmodels/RoundCreationViewModel.kt`
**Lines:** 480 lines
**Status:** ✅ Production

### Purpose

Manages new round creation workflow:
- Round configuration
- Participant selection
- Equipment setup
- Validation
- Round creation

---

## UI State

```kotlin
data class RoundCreationUiState(
    val name: String = "",
    val distance: Int = 18,
    val targetFace: String = "122cm",
    val endsCount: Int = 10,
    val arrowsPerEnd: Int = 6,
    val selectedParticipants: List<Participant> = emptyList(),
    val selectedBowSetup: BowSetup? = null,
    val validationErrors: List<String> = emptyList(),
    val isCreating: Boolean = false
)
```

---

## Key Methods

```kotlin
// Configuration
fun setRoundName(name: String)
fun setDistance(distance: Int)
fun setEndsCount(count: Int)

// Participants
fun addParticipant(participant: Participant)
fun removeParticipant(participantId: Long)

// Equipment
fun selectBowSetup(setupId: Long)

// Validation and creation
fun validate(): Boolean
fun createRound()
```

---

## Usage Example

```kotlin
@Composable
fun CreateRoundScreen(viewModel: RoundCreationViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsState()

    Column {
        TextField(
            value = state.name,
            onValueChange = { viewModel.setRoundName(it) },
            label = { Text("Round Name") }
        )

        NumberPicker(
            value = state.endsCount,
            onValueChange = { viewModel.setEndsCount(it) },
            label = "Ends"
        )

        ParticipantSelector(
            selected = state.selectedParticipants,
            onAdd = { viewModel.addParticipant(it) }
        )

        Button(
            onClick = { viewModel.createRound() },
            enabled = state.validationErrors.isEmpty()
        ) {
            Text("Create Round")
        }
    }
}
```

---

**Status:** ✅ Production
**Last Updated:** 2025-11-01
