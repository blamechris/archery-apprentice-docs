---
title: RoundDisplayService API Reference
tags:
  - api
  - service
  - display
  - ranking
  - multi-participant
created: 2025-11-01
---

# RoundDisplayService API Reference

Service for round data formatting and multi-participant ranking.

---

## Overview

**File:** `domain/services/RoundDisplayService.kt`
**Status:** ✅ Production

### Purpose

Handles round display logic:
- Round total calculation
- Per-participant totals
- **Multi-participant ranking**
- X-count tie-breaking
- Display formatting

---

## Ranking Algorithm

**Primary:** Score (descending)
**Secondary:** X-count (descending)

```kotlin
fun rankParticipants(
    participants: List<ParticipantScore>
): List<ParticipantRanking> {
    return participants
        .sortedWith(
            compareByDescending<ParticipantScore> { it.score }
                .thenByDescending { it.xCount }
        )
        .mapIndexed { index, participant ->
            ParticipantRanking(
                rank = index + 1,
                participant = participant,
                isTied = checkIfTied(participant, participants)
            )
        }
}
```

**See:** [[../../../../internal/technical-notes/multi-participant-ranking-and-tie-breaking|Ranking Algorithm Details]]

---

## Key Methods

```kotlin
// Calculate participant totals
fun calculateParticipantTotals(
    roundId: Long,
    participantId: Long
): ParticipantTotal

// Rank all participants
fun rankParticipants(
    roundId: Long
): List<ParticipantRanking>

// Format score display
fun formatScore(
    score: Int,
    maxScore: Int
): String  // e.g., "540/600"
```

---

## Usage Example

```kotlin
val rankings = service.rankParticipants(roundId)

rankings.forEach { ranking ->
    val medal = when (ranking.rank) {
        1 -> "\ud83e\udd47"
        2 -> "\ud83e\udd48"
        3 -> "\ud83e\udd49"
        else -> ""
    }

    println("${ranking.rank}. $medal ${ranking.participant.name}")
    println("   Score: ${ranking.participant.score}")
    println("   X-count: ${ranking.participant.xCount}")

    if (ranking.isTied) {
        println("   (tied)")
    }
}
```

---

**Status:** ✅ Production
**Last Updated:** 2025-11-01
