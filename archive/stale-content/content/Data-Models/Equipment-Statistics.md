---
tags:
  - data-model
  - equipment
  - statistics
  - mathematics
  - grouping
  - fatigue
  - consistency
  - analysis
created: 2025-10-08
related:
  - "[[Equipment-Management-Flow]]"
  - "[[Scoring-Data-Model]]"
---

# Advanced Equipment Statistics Documentation

## Overview

This document describes the mathematical calculations and interpretation logic behind the advanced equipment statistics system in the Archery Apprentice application. These statistics provide insights into shooting performance, equipment effectiveness, and form consistency through mathematical analysis of shot coordinate data.

## Data Requirements

### Minimum Data Thresholds
- **Basic Statistics**: 1+ arrows
- **Advanced Grouping Analysis**: 5+ arrows with coordinates
- **Fatigue Analysis**: 20+ arrows with recent shot data
- **Consistency Analysis**: 5+ completed ends

### Coordinate System
- Coordinates are normalized to target-face units (-1 to 1 range)
- Target center is always (0, 0)
- Distance measurements are in target radii (1.0 = full target radius)

## Statistical Calculations

### 1. Basic Shot Grouping

#### Group Center Calculation
```
centerX = average(all shot x-coordinates)
centerY = average(all shot y-coordinates)
```

#### Average Group Size
```
distances = sqrt((x - centerX)² + (y - centerY)²) for each shot
averageGroupSize = mean(distances)
```

#### Group Tightness (Standard Deviation)
```
variance = mean((distance - averageGroupSize)² for each distance)
groupTightness = sqrt(variance)
```

#### Bias Calculation
```
horizontalBias = centerX (positive = right bias, negative = left bias)
verticalBias = centerY (positive = up bias, negative = down bias)
```

### 2. Advanced Grouping Analysis

#### Eccentricity Analysis (Covariance Matrix Method)

**Covariance Matrix Components:**
```
deltaX = x-coordinates - centerX
deltaY = y-coordinates - centerY
varX = mean(deltaX²)
varY = mean(deltaY²) 
covXY = mean(deltaX * deltaY)
```

**Eigenvalue Calculation:**
```
trace = varX + varY
determinant = varX * varY - covXY²
discriminant = sqrt(trace² - 4 * determinant)
eigenvalue1 = (trace + discriminant) / 2
eigenvalue2 = (trace - discriminant) / 2
```

**Eccentricity:**
```
eccentricity = eigenvalue1 / eigenvalue2 (capped at 10.0)
```

**Interpretation:**
- 1.0 - 1.2: Circular grouping (ideal)
- 1.2 - 2.0: Slightly elliptical
- 2.0 - 3.0: Moderately elliptical
- 3.0+: Highly directional (systematic issue)

#### Primary Axis Calculation
```
primaryAxis = atan2(eigenvalue1 - varX, covXY) * 180/π
```
Angle of the major axis of the elliptical grouping pattern.

#### Radial Consistency
```
radialDistances = sqrt(x² + y²) for each shot from actual target center
mean = average(radialDistances)
stdDev = sqrt(mean((distance - mean)² for each distance))
radialConsistency = 1 / (stdDev / mean) (capped at 10.0)
```

**Purpose:** Measures how consistent the distance from target center is across shots, independent of grouping pattern.

### 3. Fatigue Analysis

#### Shot Segmentation
```
recentShotCount = shotCount * 0.2 (minimum 5)
recentShots = last 20% of shots in chronological order
earlierShots = remaining 80% of shots
```

#### Performance Drop Calculation
```
recentAverageScore = mean(recent shot scores)
earlierAverageScore = mean(earlier shot scores)
performanceDrop = earlierAverageScore - recentAverageScore
```

#### Grouping Deterioration
```
recentGroupTightness = stdDev(recent shot distances from center)
earlierGroupTightness = stdDev(earlier shot distances from center)
groupingDeterioration = recentGroupTightness - earlierGroupTightness
```

#### Fatigue Score Calculation
```
scoreFactor = (performanceDrop / 2.0).clamp(0.0, 1.0)
groupingFactor = (groupingDeterioration / 0.2).clamp(0.0, 1.0)
fatigueScore = (scoreFactor + groupingFactor) / 2.0
```

**Interpretation:**
- 0.0 - 0.2: No fatigue detected
- 0.2 - 0.4: Mild fatigue
- 0.4 - 0.6: Moderate fatigue
- 0.6 - 0.8: Significant fatigue
- 0.8 - 1.0: High fatigue

### 4. Consistency Analysis

#### Score Variation
```
endScores = total score for each completed end
mean = average(endScores)
variance = mean((score - mean)² for each end)
scoreVariation = sqrt(variance)
```

#### Consistency Percentage
```
consistencyPercentage = (1 - (scoreVariation / mean)) * 100
```
Clamped to 0-100% range.

#### Trend Analysis (Linear Regression)
```
x = [0, 1, 2, ..., n-1] (end sequence numbers)
y = end average scores
n = number of ends
sumX = sum(x)
sumY = sum(y) 
sumXY = sum(x[i] * y[i])
sumXX = sum(x[i]²)

slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX²)
```

**Trend Interpretation:**
- slope > 0.5: Improving significantly
- slope > 0.1: Slightly improving
- slope < -0.5: Declining significantly
- slope < -0.1: Slightly declining
- else: Stable

## Confidence Assessment

### Data Confidence Levels
```
confidence = switch(totalArrows) {
    0: NONE
    1-19: LOW
    20-49: MEDIUM
    50-99: HIGH
    100+: VERY_HIGH
}
```

### Statistical Reliability
- **Low Confidence**: Statistics may fluctuate significantly with new data
- **Medium Confidence**: Statistics becoming stable, trends emerging
- **High Confidence**: Reliable patterns, meaningful for equipment decisions
- **Very High Confidence**: Highly stable statistics, suitable for detailed analysis

## Practical Applications

### Equipment Tuning Indicators

**High Eccentricity (>2.5)**
- Check arrow spine compatibility
- Verify rest alignment and centershot
- Inspect sight mounting stability
- Review bow tuning parameters

**Consistent Bias Pattern**
- Horizontal bias: Windage adjustment needed
- Vertical bias: Elevation adjustment needed
- Combined bias: Anchor point consistency issue

**Poor Radial Consistency**
- Arrow spine mismatch
- Inconsistent release technique
- Bow balance issues
- Environmental factors (wind patterns)

### Form Analysis Insights

**Circular Grouping + Good Radial Consistency**
- Excellent shooting form
- Proper equipment setup
- Consistent execution

**Directional Grouping + Poor Radial Consistency**
- Form inconsistencies (anchor point, release)
- Equipment problems (rest, spine)
- Systematic shooting errors

**High Fatigue Detection**
- Reduce practice session length
- Focus on quality over quantity
- Consider physical conditioning

## Implementation Notes

### Error Handling
- All calculations include bounds checking and null safety
- Insufficient data returns null rather than invalid statistics
- Division by zero protection throughout
- Outlier detection could be added in future versions

### Performance Considerations
- Calculations are O(n) where n = number of shots
- Eigenvalue calculation is O(1) for 2x2 matrices
- Large datasets (>1000 shots) may need optimization
- Consider caching for frequently accessed statistics

### Future Enhancements
- Outlier detection and removal
- Moving window analysis for trend detection
- Environmental factor correlation
- Machine learning performance prediction
- Cross-equipment comparative analysis

## Mathematical References

- **Covariance Matrix Analysis**: Standard multivariate statistics
- **Eigenvalue Decomposition**: Linear algebra for pattern detection
- **Linear Regression**: Basic trend analysis
- **Statistical Moments**: Mean, variance, standard deviation calculations

## Testing and Validation

### Unit Test Cases
- Known circular patterns should yield eccentricity ≈ 1.0
- Known linear patterns should yield high eccentricity
- Performance decline patterns should trigger fatigue detection
- Consistent end scores should yield high consistency percentage

### Integration Testing
- Verify calculations with real shooting data
- Compare results with manual calculations
- Test edge cases (single shot, identical coordinates)
- Validate performance with large datasets

---

*This documentation covers Phase 2 implementation (August 2025). Future phases may expand these calculations with additional statistical methods and machine learning integration.*