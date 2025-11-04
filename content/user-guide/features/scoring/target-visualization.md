---
title: Target Face Visualization
tags:
  - visualization
  - statistics
  - grouping
  - ui-component
  - arrows
  - analysis
aliases:
  - shot-pattern-visualization
  - target-visualization
source: docs/target-face-visualization.md
created: 2025-10-11
---

# Target Face Visualization

## Overview

The **Target Face Visualization** component provides real-time visual analysis of arrow distribution patterns. It renders arrows on a target face canvas with statistical overlays to help archers understand their shooting patterns.

**Component:** `RoundTargetFaceVisualization.kt`  
**Location:** `app/src/main/java/com/archeryapprentice/ui/roundScoring/components/`

## Key Features

### 🎯 Arrow Rendering
- Color-coded scoring values
- Multiple scoring systems (10-ring, 5-ring)
- Multiple target sizes (40cm, 80cm, 122cm)
- Normalized coordinate system (-1 to 1)

### 📊 Statistical Overlays

Requires **3+ arrows with coordinates** to display:

1. **Group Center Crosshair**
   - Shows calculated arrow group center
   - May differ from target center

2. **Spread Oval (Ellipse)**
   - Visualizes directional arrow distribution
   - Black outline + green inner ring
   - Shape adapts to horizontal vs vertical spread

3. **Bias Lines**
   - **Red line**: Horizontal bias (left/right)
   - **Blue line**: Vertical bias (high/low)
   - Shows systematic offset from target center

### ⚠️ Coverage Warnings

- **< 50%**: Hides visualization (insufficient data)
- **50-89%**: Shows with warning banner
- **≥ 90%**: Shows without warnings

## Why Ellipse? (Not Circle)

Traditional metrics use a single radius → always produces a **circle**.

Real arrow distributions show **directional patterns**:

- **Vertical spread**: Arrows at 12 & 6 o'clock → tall oval
- **Horizontal spread**: Arrows at 3 & 9 o'clock → wide oval
- **Mixed spread**: Different amounts in each direction

**Ellipse accurately represents non-circular distributions.**

## Calculation Method

### Directional Spreads

```
1. Group Center = average(x, y coordinates)

2. Horizontal Spread = max(|arrow.x - groupCenter.x|)
   
3. Vertical Spread = max(|arrow.y - groupCenter.y|)

4. Bias = groupCenter offset from target center (0,0)
```

### Oval Dimensions

```
ovalWidth = horizontalSpread × targetRadius × 2
ovalHeight = verticalSpread × targetRadius × 2
```

## Interpretation Guide

### Spread Patterns

#### 🔵 Circular (horizontal ≈ vertical)
- **Means**: Balanced form, no directional issues
- **Action**: Focus on reducing overall group size

#### ⬆️ Tall Oval (vertical >> horizontal)
- **Means**: Vertical inconsistency
- **Causes**: Anchor height, release timing, bow cant
- **Action**: Vertical consistency drills

#### ↔️ Wide Oval (horizontal >> vertical)
- **Means**: Horizontal inconsistency  
- **Causes**: Bow arm alignment, release direction, grip torque
- **Action**: Horizontal alignment training

### Bias Patterns

#### No Bias (minimal/no lines)
- Sight properly adjusted ✅
- Good centering ✅

#### Horizontal Bias (Red Line)
- **Right**: Group right of center → adjust windage
- **Left**: Group left of center → adjust windage

#### Vertical Bias (Blue Line)
- **High**: Group above center → adjust elevation
- **Low**: Group below center → adjust elevation

#### Combined Bias (Both Lines)
- Major sight adjustment needed
- Or form correction required

## Data Requirements

### Minimums
- **Display arrows**: 1+ with coordinates
- **Show overlays**: 3+ with coordinates  
- **Coverage**: 50%+ must have coordinates

### Coordinate System
- **Range**: -1.0 (edge) to 1.0 (edge)
- **Center**: (0, 0)
- **Storage**: `ArrowScore` model fields

## Grouping Quality

Based on spread radius:

- **Excellent**: < 10% of target radius
- **Tight**: 10-20%
- **Moderate**: 20-30%
- **Wide**: > 30%

Measurements scaled to real dimensions:
- 40cm target: spread × 20cm
- 80cm target: spread × 40cm
- 122cm target: spread × 61cm

Example: *"Tight grouping: 3.5cm spread, slight right bias"*

## Test Coverage

**42 unit tests** covering:
- Coordinate coverage (6 tests)
- Statistical calculations (8 tests)
- Directional spreads (6 tests)
- Component rendering (10 tests)
- Statistical descriptions (12 tests)

Key scenarios:
- ✅ Vertical spread (tall oval)
- ✅ Horizontal spread (wide oval)
- ✅ Mixed spreads
- ✅ Circular patterns
- ✅ Bias detection
- ✅ Coverage thresholds

## Performance

- **Calculations**: O(n), very fast
- **Rendering**: Optimized for real-time
- **Tested with**: 100+ arrows (< 1 second)
- **Large datasets**: 200+ arrows maintain performance

## Related

- [[Equipment-Statistics|Equipment Statistics]] - Advanced calculations
- [[Scoring-Data-Model|Scoring Data Model]] - Arrow coordinate storage
- See: `docs/target-face-visualization.md` (full documentation)

## Future Ideas

- 🎯 Outlier detection (highlight errors)
- 📊 Historical comparison overlays
- 📈 Confidence interval bands
- 🌬️ Wind direction indicators
- 💾 Export as images

---

*Created: 2025-10-11*  
*Test Coverage: 42/42 passing*  
*Status: ✅ Stable*
