# Debugging Principles

## Purpose

This document outlines systematic approaches to investigating and fixing bugs in LifeExperiment, drawing from past issues and their resolutions.

---

## General Debugging Workflow

### Step 1: Reproduce the Bug

**Goal**: Consistently trigger the bug with minimal steps.

**Actions**:
- [ ] Identify exact steps to reproduce
- [ ] Note any state dependencies (e.g., must have completed experiments)
- [ ] Check if bug occurs in fresh app state vs. existing data
- [ ] Document any timing or interaction dependencies

**Red Flags**:
- "It sometimes happens" → Investigate state changes or race conditions
- "Only on certain data" → Check edge cases or data validation

---

### Step 2: Isolate the Component

**Goal**: Narrow down where the bug occurs.

**Questions**:
1. Which view/component exhibits the issue?
2. Is it a visual bug (layout) or logic bug (calculation)?
3. Does it involve state changes or user interaction?
4. Is it consistent or intermittent?

**Actions**:
- [ ] Check recent changes to affected component
- [ ] Review related computed properties
- [ ] Inspect state management (who owns this state?)
- [ ] Look for dependencies between components

---

### Step 3: Form a Hypothesis

**Goal**: Develop a theory about root cause.

**Common Patterns**:
- **Unstable sorting** → Missing tie-breaker
- **Layout overlap** → Wrong layout strategy (overlay vs inline)
- **State inconsistency** → Wrong state owner or missing binding
- **Calculation error** → Off-by-one, missing filter, wrong formula
- **Visual jank** → Wrong opacity, shadow stacking, animation timing

**Document**:
- What you think is broken
- Why you think it's broken
- What evidence supports this theory

---

### Step 4: Test the Hypothesis

**Goal**: Verify or disprove your theory.

**Actions**:
- [ ] Add debug logging for suspected values
- [ ] Check intermediate calculation results
- [ ] Inspect SwiftUI view hierarchy (if layout issue)
- [ ] Test with minimal/edge case data

**Tools**:
- `print()` statements for logic debugging
- SwiftUI inspector for layout debugging
- Breakpoints for state changes

---

### Step 5: Implement the Fix

**Goal**: Apply minimal change to resolve issue.

**Principles**:
- Fix root cause, not symptoms
- Keep changes localized if possible
- Maintain existing patterns and conventions
- Add comments explaining non-obvious fixes

**After Fix**:
- [ ] Verify original bug is resolved
- [ ] Check for regressions (did fix break something else?)
- [ ] Test edge cases
- [ ] Update documentation if new rule emerges

---

## Common Bug Patterns & Solutions

### Pattern 1: Unstable List Ordering

**Symptom**: List reorders unexpectedly when unrelated state changes (e.g., tapping button in radar chart reorders Growth list).

**Root Cause**: Sorting has no tie-breaker for equal values.

**Incorrect Code**:
```swift
.sorted { $0.value > $1.value }  // ❌ Unstable for ties
```

**Fix**:
```swift
.sorted { lhs, rhs in
    if lhs.value != rhs.value {
        return lhs.value > rhs.value
    }
    return lhs.key.title < rhs.key.title  // Tie-breaker
}
```

**Prevention**: Always add deterministic tie-breaker when primary key can have duplicates.

---

### Pattern 2: Overlay/Label Overlap

**Symptom**: Interactive icon overlaps with text, especially when text wraps.

**Root Cause**: Using `.overlay()` for interactive elements adjacent to dynamic text.

**Incorrect Code**:
```swift
Text(dynamicText)
    .overlay(alignment: .topTrailing) {
        Button { } label: { Image(systemName: "info.circle") }
    }
```

**Fix**:
```swift
HStack(spacing: 4) {
    Text(dynamicText)
        .lineLimit(2)
    Button { } label: { Image(systemName: "info.circle") }
}
.frame(maxWidth: 140, alignment: .leading)
```

**Prevention**: Use inline layout (HStack/VStack) for interactive elements near dynamic text.

---

### Pattern 3: Heavy/Weird Modal Overlay

**Symptom**: Modal background looks too dark or has strange shadow effects.

**Root Cause**: Opacity too high or shadow applied to entire overlay.

**Incorrect Code**:
```swift
ZStack {
    Color.black.opacity(0.5)  // ❌ Too heavy
}
.shadow(radius: 20)  // ❌ Shadow on entire overlay
```

**Fix**:
```swift
ZStack {
    Color.black.opacity(0.2)  // ✅ Subtle (0.15-0.25)
    
    ContentCard()
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)  // ✅ Shadow on card only
}
```

**Prevention**: Use opacity 0.15-0.25 for dim layers, apply shadows only to content cards.

---

### Pattern 4: Experiments with 0 Logs Affecting Metrics

**Symptom**: Completed experiments without logs contribute to Strength/Growth.

**Root Cause**: Missing valid log filter in eligibility check.

**Incorrect Code**:
```swift
experiments.filter { exp in
    exp.status == .completed && exp.impact != nil
    // ❌ Missing valid log check
}
```

**Fix**:
```swift
experiments.filter { exp in
    exp.status == .completed &&
    exp.impact != nil &&
    !validLogDays(for: exp).isEmpty  // ✅ Check for valid logs
}
```

**Prevention**: Always check for valid logs when filtering eligible experiments.

---

### Pattern 5: Weighting Error in Strength Calculation

**Symptom**: Dimension percentages don't reflect expected weighting (primary vs secondary).

**Root Cause**: Denominator incorrectly weighted.

**Incorrect Code**:
```swift
scores[dim].totalWeighted += score * weight
scores[dim].totalPossible += 2.0 * weight  // ❌ Wrong
```

**Fix**:
```swift
scores[dim].totalWeighted += score * weight
scores[dim].totalPossible += 2.0  // ✅ Not weighted
```

**Prevention**: Weights affect contribution (numerator) only, not ceiling (denominator).

---

### Pattern 6: Button Hit Area Too Small

**Symptom**: Small icon buttons difficult to tap.

**Root Cause**: Button size equals icon size (no padding for hit area).

**Incorrect Code**:
```swift
Button {
    // action
} label: {
    Image(systemName: "info.circle")
        .font(.caption2)  // Visual size only ~12pt
}
// ❌ Hit area = visual size
```

**Fix**:
```swift
Button {
    // action
} label: {
    Image(systemName: "info.circle")
        .font(.caption2)  // Visual size: small
        .padding(8)       // Hit area: 44x44
}
.contentShape(Rectangle())  // Ensure full area tappable
```

**Prevention**: Add `.padding()` to reach 44pt minimum, use `.contentShape(Rectangle())`.

---

### Pattern 7: State Update Doesn't Trigger UI Refresh

**Symptom**: UI doesn't update after state change.

**Root Cause**: State not marked with `@State`, `@Binding`, or `@Published`.

**Incorrect Code**:
```swift
struct MyView: View {
    var selectedItem: Item? = nil  // ❌ Not observable
    
    var body: some View {
        Button("Select") {
            selectedItem = Item()  // UI won't refresh
        }
    }
}
```

**Fix**:
```swift
struct MyView: View {
    @State private var selectedItem: Item? = nil  // ✅ Observable
    
    var body: some View {
        Button("Select") {
            selectedItem = Item()  // UI refreshes
        }
    }
}
```

**Prevention**: Use `@State` for local state, `@Binding` for shared state.

---

## Debugging Checklist

### Before Debugging

- [ ] Can you consistently reproduce the bug?
- [ ] Do you have a hypothesis about the cause?
- [ ] Have you checked recent changes to affected code?
- [ ] Have you reviewed relevant documentation (these docs)?

### During Debugging

- [ ] Are you testing with realistic data?
- [ ] Have you checked edge cases (empty, zero, max values)?
- [ ] Are you looking at the right component/file?
- [ ] Have you verified intermediate values (not just final result)?

### After Fix

- [ ] Does the fix resolve the original issue?
- [ ] Have you checked for regressions?
- [ ] Have you tested edge cases?
- [ ] Should a new rule be added to prevent recurrence?

---

## Investigation Strategies

### Strategy 1: Binary Search

**Use when**: Bug is in large codebase or complex function.

**Approach**:
1. Comment out half the code
2. Check if bug still occurs
3. Narrow down to problematic half
4. Repeat until isolated

---

### Strategy 2: Minimal Reproduction

**Use when**: Bug involves complex state or interactions.

**Approach**:
1. Create simplest possible test case
2. Remove unrelated features one by one
3. Identify minimal conditions for bug
4. Fix isolated issue

---

### Strategy 3: State Inspection

**Use when**: Bug involves calculation or data transformation.

**Approach**:
1. Add logging at each transformation step
2. Print input values, intermediate results, output
3. Identify where values become incorrect
4. Fix transformation logic

**Example**:
```swift
func calculateStrength() -> [Dimension: Double] {
    let eligible = experiments.filter { /* ... */ }
    print("Eligible experiments: \(eligible.count)")  // Debug
    
    for exp in eligible {
        let score = calculateScore(exp)
        print("Experiment \(exp.title): score=\(score)")  // Debug
        // ... aggregation
    }
    
    print("Final scores: \(scores)")  // Debug
    return scores
}
```

---

### Strategy 4: Diff Comparison

**Use when**: Bug appeared after recent changes.

**Approach**:
1. Identify last working version
2. Compare current vs. working code (use git diff)
3. Review each change for potential issues
4. Revert suspicious changes to test

---

## Red Flags to Watch For

### Code Smells

- **Duplicate state**: Same data stored in multiple places
- **Manual synchronization**: Updating derived values manually
- **Complex conditionals**: Deeply nested if/else in view logic
- **Magic numbers**: Unexplained constants (use named values)
- **Side effects in computed properties**: Modifying state in getters

### Logic Smells

- **Off-by-one errors**: Especially in date calculations
- **Missing edge case handling**: Empty arrays, nil values, zero counts
- **Unstable operations**: Sorting without tie-breaker, set iteration order
- **Unvalidated assumptions**: "This will never be empty/nil/zero"

### UI Smells

- **Fixed frames without constraints**: Breaks on different text lengths
- **Overlays for dynamic content**: Can cause overlap when text wraps
- **Heavy visual effects**: Opacity > 0.3, double shadows
- **Missing accessibility**: Small hit targets, no labels

---

## Tools & Techniques

### SwiftUI Debugging

**View Hierarchy Inspector**: Xcode → Debug View Hierarchy (when running)
- Shows actual frame sizes, constraints, z-order
- Useful for layout issues

**Print Debugging**:
```swift
let _ = print("Current state: \(value)")  // Works in SwiftUI body
```

**Conditional Breakpoints**:
- Set breakpoint with condition (e.g., `experiments.count == 0`)
- Stops execution only when condition met

---

### Data Validation

**Check Invariants**:
```swift
#if DEBUG
func validateExperimentImpact(_ impact: ExperimentImpact) {
    assert(impact.primary != impact.secondary)
    assert(impact.primary != impact.tertiary)
    assert(impact.secondary != impact.tertiary || impact.secondary == nil)
}
#endif
```

**Log Unexpected Values**:
```swift
if validDays.isEmpty {
    print("⚠️ Experiment \(exp.title) has no valid logs but is marked completed")
}
```

---

## When to Refactor vs. Quick Fix

### Quick Fix Appropriate When:
- Bug is isolated to single line/function
- Fix doesn't introduce technical debt
- Pattern is already established in codebase
- Fix aligns with existing architecture

### Refactor Needed When:
- Bug reveals systemic issue (poor state management, wrong architecture)
- Same bug appears in multiple places
- Fix would create inconsistency with rest of codebase
- Code has accumulated too many quick fixes

**Rule of Thumb**: Three quick fixes in same area → time to refactor.

---

## Access Control: Don't private-initialize reusable View helpers

- If a helper `View` is instantiated outside its own type body (even within the same file), do NOT mark its `init` as `private`.
- Prefer no explicit `init` for simple helper views; rely on Swift's memberwise init.
- If you need a custom init, keep it `internal` (no modifier) unless you intentionally want to restrict construction.
- Symptom: `initializer is inaccessible due to 'private' protection level`.
- Fix: remove `private` from `init` or remove explicit init.

---

## Post-Fix Documentation

After fixing a bug, consider:

1. **Add to relevant doc**: Update edge cases, common pitfalls sections
2. **Add test case**: If bug was data-driven, add edge case data
3. **Add comment**: Explain non-obvious fix in code
4. **Update checklist**: Add verification step to prevent recurrence

**Example**:
```swift
// Sort with tie-breaker to prevent unstable ordering
// See: debugging_principles.md → Pattern 1
.sorted { lhs, rhs in
    if lhs.value != rhs.value {
        return lhs.value > rhs.value
    }
    return lhs.key.title < rhs.key.title
}
```

---

*Last updated: 2026-02-11*
