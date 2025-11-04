---
title: ProgressCalculationService API Reference
tags:
  - api
  - service
  - progress
  - calculation
created: 2025-11-01
---

# ProgressCalculationService API Reference

Service for calculating round and end progress tracking.

---

## Overview

**File:** `domain/services/ProgressCalculationService.kt`
**Status:** ✅ Production

### Purpose

Calculates progress metrics for rounds:
- Ends completed tracking
- Arrows shot counting
- Completion percentage
- Remaining ends calculation
- Time estimates

---

## API Methods

```kotlin
// Calculate round progress
fun calculateRoundProgress(
    endsCompleted: Int,
    endsTotal: Int,
    arrowsPerEnd: Int
): RoundProgress

// Estimate time remaining
fun estimateTimeRemaining(
    endsRemaining: Int,
    averageEndTime: Duration
): Duration?

// Check if round is complete
fun isRoundComplete(
    endsCompleted: Int,
    endsTotal: Int
): Boolean
```

---

## Data Models

```kotlin
data class RoundProgress(
    val endsCompleted: Int,
    val endsTotal: Int,
    val arrowsCompleted: Int,
    val arrowsTotal: Int,
    val percentageComplete: Double,
    val endsRemaining: Int,
    val arrowsRemaining: Int
)
```

---

## Usage Example

```kotlin
val progress = service.calculateRoundProgress(
    endsCompleted = 7,
    endsTotal = 10,
    arrowsPerEnd = 6
)

println("Progress: ${progress.percentageComplete}%")
println("Remaining: ${progress.endsRemaining} ends")
println("Arrows shot: ${progress.arrowsCompleted}/${progress.arrowsTotal}")

// Output:
// Progress: 70.0%
// Remaining: 3 ends
// Arrows shot: 42/60
```

---

**Status:** ✅ Production
**Last Updated:** 2025-11-01
