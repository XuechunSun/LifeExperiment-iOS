# Summary Logic

## Purpose

This document defines the exact calculation logic for Strength and Growth metrics in the Summary tab. These formulas must be implemented consistently to ensure accurate and meaningful insights.

---

## Core Concepts

### Strength (Current Profile)
- **What it measures**: Current capability level across dimensions, based on completion + consistency
- **Can it change?**: ✅ Yes (can go up or down with new completed experiments)
- **Scope**: Completed experiments only
- **Weighting**: Yes (dimensions weighted by impact assignment)

### Growth (Accumulated Effort)
- **What it measures**: Total time invested (logged days) per dimension
- **Can it change?**: Only increases (monotonic)
- **Scope**: Active + Completed experiments
- **Weighting**: No (counts days, doesn't weight)

---

## Valid Log Day Definition

### Rule: What Counts as a Valid Log Day?

A log entry is **valid** if:
```
(note is non-empty after trim) OR (mood is set)
```

**Implementation**:
```swift
func validLogDays(for experiment: Experiment) -> Set<Date> {
    let calendar = Calendar.current
    return Set(experiment.logs.compactMap { log -> Date? in
        // Valid if note is non-empty (after trim) OR mood is set
        let trimmedNote = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty || log.mood != nil else { return nil }
        
        // Deduplicate by start of day
        return calendar.startOfDay(for: log.date)
    })
}
```

**Key Points**:
- Empty logs (no note, no mood) are **invalid** and don't count
- Multiple logs on same day count as **1 day** (deduplicated by `startOfDay`)
- Logs are always valid once they have content, regardless of completeness

---

## Strength Calculation

### Eligibility Filter

**Rule**: Only include experiments that meet ALL criteria:
1. `status == .completed`
2. `impact != nil` (has dimension assignment)
3. `validLogDays > 0` (has at least one valid log)

**Implementation**:
```swift
let eligibleExperiments = experiments.filter { exp in
    exp.status == .completed &&
    exp.impact != nil &&
    !validLogDays(for: exp).isEmpty
}
```

---

### Experiment Score (0-2 scale)

Each completed experiment contributes a score from 0 to 2:

**Formula**:
```
score = completion + consistency
```

Where:
- **Completion** = `1.0` (fixed for completed experiments)
- **Consistency** = `min(1.0, actualDays / plannedDays)` (clamped 0-1)

**Implementation**:
```swift
func calculateExperimentScore(_ experiment: Experiment) -> Double {
    let completion = 1.0
    
    // Calculate actualDays
    let actualDays = validLogDays(for: experiment).count
    
    // Calculate plannedDays
    let calendar = Calendar.current
    let plannedDays: Int
    
    if experiment.category == "challenge_30" {
        plannedDays = 30
    } else {
        let startDay = calendar.startOfDay(for: experiment.createdAt)
        let endDay: Date
        if let completedAt = experiment.completedAt {
            endDay = calendar.startOfDay(for: completedAt)
        } else {
            endDay = calendar.startOfDay(for: experiment.updatedAt)
        }
        
        let daysBetween = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        let computedDays = daysBetween + 1
        plannedDays = max(7, min(30, computedDays))  // Clamp to 7-30
    }
    
    // Calculate consistency (0-1)
    let consistency = plannedDays > 0 ? min(1.0, Double(actualDays) / Double(plannedDays)) : 0.0
    
    return completion + consistency
}
```

**Key Points**:
- **actualDays**: Count of unique valid log days
- **plannedDays**: Expected duration
  - `challenge_30` category: Always 30 days
  - Other categories: Days between `createdAt` and `completedAt`, clamped to [7, 30]
- **consistency**: Ratio of actual/planned, clamped to max 1.0
- **Total score range**: [0, 2]

---

### Dimension Aggregation

**Formula**:
```
strengthPercent[dim] = totalWeighted[dim] / totalPossible[dim]
```

**Aggregation Loop**:
```swift
var scores: [Dimension: DimensionScore] = [:]

for dimension in Dimension.allCases {
    scores[dimension] = DimensionScore()  // totalWeighted: 0, totalPossible: 0
}

for experiment in eligibleExperiments {
    guard let impact = experiment.impact else { continue }
    
    let experimentScore = calculateExperimentScore(experiment)
    
    // Primary dimension (weight 1.0)
    let primary = impact.primary
    scores[primary]!.totalWeighted += experimentScore * 1.0
    scores[primary]!.totalPossible += 2.0  // NOT weighted
    
    // Secondary dimension (weight 0.5)
    if let secondary = impact.secondary {
        scores[secondary]!.totalWeighted += experimentScore * 0.5
        scores[secondary]!.totalPossible += 2.0  // NOT weighted
    }
    
    // Tertiary dimension (weight 0.2)
    if let tertiary = impact.tertiary {
        scores[tertiary]!.totalWeighted += experimentScore * 0.2
        scores[tertiary]!.totalPossible += 2.0  // NOT weighted
    }
}

// Calculate percentages
for (dim, score) in scores {
    let percentage = score.totalPossible > 0 ? score.totalWeighted / score.totalPossible : 0.0
    // Display as 0-100%
    let displayPercent = Int(percentage * 100)
}
```

**Critical Implementation Detail**:
- **Numerator** (`totalWeighted`): Multiply score by weight
- **Denominator** (`totalPossible`): Always add `2.0` (NOT weighted)

This ensures weights affect the **contribution** but not the **ceiling**.

**Example**:
```
Experiment A (score: 1.8)
- Primary: Execution (weight 1.0)
- Secondary: Focus & Flow (weight 0.5)

Execution:
  totalWeighted += 1.8 * 1.0 = 1.8
  totalPossible += 2.0

Focus & Flow:
  totalWeighted += 1.8 * 0.5 = 0.9
  totalPossible += 2.0
```

---

### Display

**Radar Chart**:
- 7 dimensions (all Dimension.allCases)
- Values normalized to 0-1 for chart drawing
- Percentages shown inline with labels (e.g., "Execution 72%")

**Empty State**:
- Show if no eligible experiments exist
- Message: "Complete an experiment to see insights here."

---

## Growth Calculation

### Eligibility Filter

**Rule**: Include experiments that meet ALL criteria:
1. `status == .active` OR `status == .completed`
2. `impact != nil` (has dimension assignment)
3. `validLogDays > 0` (has at least one valid log)

**Implementation**:
```swift
let eligibleExperiments = experiments.filter { exp in
    (exp.status == .active || exp.status == .completed) &&
    exp.impact != nil &&
    !validLogDays(for: exp).isEmpty
}
```

---

### Day Aggregation

**Formula**: Count unique valid log days per dimension (across all eligible experiments).

**Implementation**:
```swift
func calculateGrowth() -> [Dimension: Int] {
    var dayCounts: [Dimension: Set<Date>] = [:]
    
    // Initialize all dimensions
    for dimension in Dimension.allCases {
        dayCounts[dimension] = Set<Date>()
    }
    
    // Aggregate days per dimension
    for experiment in eligibleExperiments {
        guard let impact = experiment.impact else { continue }
        
        let validDays = validLogDays(for: experiment)
        
        // Primary dimension
        dayCounts[impact.primary]?.formUnion(validDays)
        
        // Secondary dimension
        if let secondary = impact.secondary {
            dayCounts[secondary]?.formUnion(validDays)
        }
        
        // Tertiary dimension
        if let tertiary = impact.tertiary {
            dayCounts[tertiary]?.formUnion(validDays)
        }
    }
    
    // Convert to counts
    return dayCounts.mapValues { $0.count }
}
```

**Key Points**:
- Use `Set<Date>` to deduplicate days across experiments
- If an experiment has multiple dimensions, same day counts toward ALL those dimensions
- No weighting applied (simple count)

---

### Sorting & Display

**Sort Order**:
```swift
// Primary: days descending
// Tie-breaker: title ascending (stable)
let sorted = dimensionDays
    .filter { $0.value > 0 }  // Hide 0-day dimensions
    .sorted { lhs, rhs in
        if lhs.value != rhs.value {
            return lhs.value > rhs.value
        }
        return lhs.key.title < rhs.key.title
    }
```

**Display**:
- Bar chart (horizontal bars)
- Dimensions with 0 days: Hidden
- Show total logged days sum
- Footnote: "* Dimensions with 0 days are hidden for now."

---

## Important Implementation Invariants

### Invariant 1: Strength Denominator is NOT Weighted

**Correct**:
```swift
scores[dim].totalWeighted += score * weight
scores[dim].totalPossible += 2.0  // Always 2.0
```

**Incorrect**:
```swift
scores[dim].totalPossible += 2.0 * weight  // ❌ WRONG
```

**Rationale**: Weights affect contribution, not ceiling. This ensures primary dimensions have higher percentages than secondary.

---

### Invariant 2: Valid Log Days Must Be Deduplicated

**Correct**:
```swift
return Set(experiment.logs.compactMap { log -> Date? in
    // ... validation ...
    return calendar.startOfDay(for: log.date)
})
```

**Incorrect**:
```swift
return experiment.logs.filter { /* valid */ }.map { $0.date }  // ❌ Can have duplicates
```

**Rationale**: Multiple logs on same day should count as 1 day.

---

### Invariant 3: Growth Includes Active + Completed

**Correct**:
```swift
exp.status == .active || exp.status == .completed
```

**Incorrect**:
```swift
exp.status == .completed  // ❌ Missing active experiments
```

**Rationale**: Growth counts accumulated effort, including ongoing experiments.

---

### Invariant 4: Experiments with 0 Valid Logs Must Be Excluded

**Correct**:
```swift
!validLogDays(for: exp).isEmpty
```

**Incorrect**:
```swift
// ❌ Forgetting to check valid logs
exp.status == .completed && exp.impact != nil
```

**Rationale**: Experiments without engagement shouldn't affect metrics.

---

## Edge Cases

### Edge Case 1: Completed Experiment with No Logs

**Scenario**: User completes experiment without logging  
**Expected Behavior**:
- `validLogDays(for: exp).isEmpty` returns `true`
- Experiment filtered out from both Strength and Growth
- Does NOT appear in radar chart or bar chart

---

### Edge Case 2: Challenge_30 Completed in 10 Days

**Scenario**: User completes 30-day challenge in 10 days with 8 logged days  
**Expected Calculation**:
```
plannedDays = 30 (fixed for challenge_30)
actualDays = 8
consistency = 8 / 30 = 0.267
score = 1.0 + 0.267 = 1.267
```

---

### Edge Case 3: Experiment with Same Dimension in Multiple Slots

**Scenario**: User somehow assigns same dimension as primary and secondary  
**Expected Behavior**: Prevented in UI (should never happen)  
**Fallback**: If data exists, each assignment counts separately (not ideal, fix in UI)

---

### Edge Case 4: Experiment Spanning 60 Days

**Scenario**: Long-term experiment runs for 60 days  
**Expected Calculation**:
```
daysBetween = 60
computedDays = 61 (inclusive)
plannedDays = min(30, 61) = 30 (clamped)
```

**Rationale**: Cap at 30 days to avoid penalizing long experiments for consistency.

---

### Edge Case 5: Tied Days in Growth (Same Count)

**Scenario**: Execution and Focus both have 5 days  
**Expected Behavior**: Sort alphabetically as tie-breaker  
**Result**: "Execution" appears before "Focus & Flow"

---

## QA Checklist: Summary Logic

Before releasing changes to Summary calculations:

### Valid Logs
- [ ] Empty logs (no note, no mood) are excluded
- [ ] Multiple logs on same day count as 1 day
- [ ] `validLogDays()` returns `Set<Date>` with deduplicated days

### Strength
- [ ] Only completed experiments with valid logs included
- [ ] Experiment score formula: `completion + consistency`
- [ ] plannedDays clamped to [7, 30] for non-challenge experiments
- [ ] challenge_30 always uses 30 days
- [ ] Denominator `totalPossible` is NOT weighted (always += 2.0)
- [ ] Numerator `totalWeighted` uses weights (1.0, 0.5, 0.2)
- [ ] Displays as percentage (0-100%)

### Growth
- [ ] Includes both active and completed experiments
- [ ] Counts unique days per dimension (using Set)
- [ ] Same day can count toward multiple dimensions
- [ ] No weighting applied (simple count)
- [ ] Sorted by days desc, then title asc (stable)
- [ ] Dimensions with 0 days are hidden

### Edge Cases
- [ ] Experiments with 0 valid logs excluded from both metrics
- [ ] challenge_30 uses fixed 30 days
- [ ] Long experiments (>30 days) clamped to 30
- [ ] Tie-breaker prevents unstable sorting

### Display
- [ ] Strength: radar chart with 7 dimensions
- [ ] Growth: bar chart with non-zero dimensions only
- [ ] Total logged days displayed
- [ ] Footnotes shown for both sections

---

*Last updated: 2026-02-11*
