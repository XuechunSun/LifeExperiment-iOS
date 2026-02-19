# Dimension Weighting Rules

## Purpose

This document defines how experiment impacts are assigned, weighted, and calculated in LifeExperiment. These rules ensure consistent dimension scoring across the app.

---

## Core Concepts

### What are Dimensions?

Dimensions represent fundamental capability areas that experiments can develop:

1. **Emotional Awareness** - Noticing and understanding emotional patterns
2. **Body & Energy** - Building body awareness and stable energy
3. **Execution** - Starting and completing meaningful actions
4. **Focus & Flow** - Deep focus and flow states
5. **Expression & Creativity** - Creating and expressing authentically
6. **Connection** - Meaningful relationships and genuine connection
7. **Self-Understanding** - Understanding what works for you

---

## Impact Assignment

### Structure: ExperimentImpact

Each experiment can have up to **3 dimensions** assigned:

```swift
struct ExperimentImpact {
    var primary: Dimension        // Required
    var secondary: Dimension?     // Optional
    var tertiary: Dimension?      // Optional
}
```

**Constraints**:
- Primary: **Required** (exactly 1)
- Secondary: Optional (0 or 1)
- Tertiary: Optional (0 or 1)
- **No duplicates**: All three must be different dimensions

---

### Weight Values

| Position | Weight | Meaning |
|----------|--------|---------|
| Primary | `1.0` | Main focus of experiment |
| Secondary | `0.5` | Secondary benefit (50% contribution) |
| Tertiary | `0.2` | Tertiary benefit (20% contribution) |

**Intent**: Weights reflect relative importance within the same experiment. Primary dimension should contribute **most** to the experiment's impact on that dimension.

---

## Assignment Flows

### Seed-Based Experiments (Pre-defined Categories)

**Source**: `experiment_seed.json` → `subcategory.default_dimensions`

**Process**:
1. User selects category + subcategory
2. Dimensions auto-populate from JSON:
   ```json
   "default_dimensions": ["execution", "focus_flow", "self_understanding"]
   ```
3. Maps to:
   - `primary` = first item (`execution`)
   - `secondary` = second item (`focus_flow`)
   - `tertiary` = third item (`self_understanding`)
4. User can edit via `DimensionPickerSheet` (optional)

**Example JSON**:
```json
{
  "id": "daily_discipline",
  "title": "Daily Discipline",
  "default_dimensions": ["execution", "focus_flow", "self_understanding"],
  "prompts": ["..."]
}
```

**Mapping Function**:
```swift
func impactFromDefaultDimensions(_ arr: [Dimension]?) -> ExperimentImpact? {
    guard let arr = arr, !arr.isEmpty else { return nil }
    
    let primary = arr[0]
    let secondary: Dimension? = arr.count > 1 ? arr[1] : nil
    let tertiary: Dimension? = arr.count > 2 ? arr[2] : nil
    
    return ExperimentImpact(primary: primary, secondary: secondary, tertiary: tertiary)
}
```

---

### Custom Category Experiments

**Source**: User selection (no pre-defined defaults)

**Requirements**:
- Primary: **Required** (must be selected before creation)
- Secondary/Tertiary: Optional (user can select 0-2 additional)

**Validation**:
- Create button **disabled** if primary not selected
- Show inline message: "What does this experiment help with most? (required)"
- Max 2 additional dimensions (UI enforces limit)

**UI Flow**:
1. User taps "Choose dimensions" button
2. Opens `DimensionPickerSheet`:
   - Primary: Radio select (single choice)
   - Additional: Multi-select with numbered badges (1, 2)
3. User selects primary (required)
4. User optionally selects up to 2 additional
5. Save:
   - `selectedAdditional[0]` → `secondary`
   - `selectedAdditional[1]` → `tertiary`

---

## Dimension Picker UI

### DimensionPickerSheet Behavior

**Primary Selection**:
- Display: All 7 dimensions
- Selection: Radio (single choice)
- Constraint: Required (cannot save without)

**Additional Selection**:
- Display: All dimensions **except** currently selected primary
- Selection: Multi-select with checkboxes
- Constraint: Max 2 selections
- Visual: Numbered badges (1, 2) show selection order

**Order Matters**:
- First additional selection → secondary (weight 0.5)
- Second additional selection → tertiary (weight 0.2)
- User sees numbered badges (1, 2) to clarify order

**Implementation**:
```swift
struct DimensionPickerSheet: View {
    @State private var selectedPrimary: Dimension
    @State private var selectedAdditional: [Dimension] = []  // Ordered array
    
    let onSave: (ExperimentImpact) -> Void
    
    var body: some View {
        // Primary: Radio select
        Section("Primary (Required)") {
            ForEach(Dimension.allCases) { dim in
                Button {
                    selectedPrimary = dim
                    // Remove from additional if previously selected
                    selectedAdditional.removeAll { $0 == dim }
                } label: {
                    HStack {
                        Text(dim.title)
                        if selectedPrimary == dim {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
            }
        }
        
        // Additional: Multi-select (max 2)
        Section("Additional (Optional, max 2)") {
            ForEach(Dimension.allCases.filter { $0 != selectedPrimary }) { dim in
                Button {
                    if let index = selectedAdditional.firstIndex(of: dim) {
                        selectedAdditional.remove(at: index)
                    } else if selectedAdditional.count < 2 {
                        selectedAdditional.append(dim)
                    }
                } label: {
                    HStack {
                        Text(dim.title)
                        Spacer()
                        if let index = selectedAdditional.firstIndex(of: dim) {
                            Text("\(index + 1)")  // Badge: 1 or 2
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.blue))
                        }
                    }
                }
            }
        }
        
        // Save button
        Button("Save") {
            let impact = ExperimentImpact(
                primary: selectedPrimary,
                secondary: selectedAdditional.count > 0 ? selectedAdditional[0] : nil,
                tertiary: selectedAdditional.count > 1 ? selectedAdditional[1] : nil
            )
            onSave(impact)
        }
    }
}
```

---

## Usage in Calculations

### Strength (Weighted)

**Formula**: Weights apply to numerator only.

```swift
// For each experiment with impact
let score = calculateExperimentScore(experiment)  // 0-2

// Primary (weight 1.0)
scores[impact.primary].totalWeighted += score * 1.0
scores[impact.primary].totalPossible += 2.0  // NOT weighted

// Secondary (weight 0.5)
if let secondary = impact.secondary {
    scores[secondary].totalWeighted += score * 0.5
    scores[secondary].totalPossible += 2.0  // NOT weighted
}

// Tertiary (weight 0.2)
if let tertiary = impact.tertiary {
    scores[tertiary].totalWeighted += score * 0.2
    scores[tertiary].totalPossible += 2.0  // NOT weighted
}
```

**Critical**: Denominator (`totalPossible`) is always `+= 2.0`, **not** `2.0 * weight`.

**Why**: Weights affect contribution, not ceiling. This ensures:
- Primary dimensions have higher percentages than secondary
- Percentages represent actual capability level, not arbitrary scaling

---

### Growth (Not Weighted)

**Formula**: Simple day count, no weighting.

```swift
// For each experiment with impact
let validDays = validLogDays(for: experiment)

// All dimensions count equally
dayCounts[impact.primary].formUnion(validDays)

if let secondary = impact.secondary {
    dayCounts[secondary].formUnion(validDays)
}

if let tertiary = impact.tertiary {
    dayCounts[tertiary].formUnion(validDays)
}
```

**Result**: Each dimension shows total logged days across all experiments that assigned it (primary, secondary, or tertiary).

---

## Validation Rules

### Rule 1: Primary Required for Custom

**Check**: Before saving custom experiment  
**Condition**: `impact?.primary != nil`  
**Message**: "What does this experiment help with most? (required)"  
**Action**: Disable Create button until selected

---

### Rule 2: No Duplicate Dimensions

**Check**: When user selects dimensions  
**Condition**: `primary != secondary && primary != tertiary && secondary != tertiary`  
**Implementation**: UI excludes primary from additional selection list  
**Fallback**: If data exists with duplicates, each counts separately (not ideal, prevent in UI)

---

### Rule 3: Max 2 Additional Dimensions

**Check**: When user selects additional dimensions  
**Condition**: `selectedAdditional.count <= 2`  
**Implementation**: Disable additional checkboxes when count reaches 2

---

### Rule 4: Seed Defaults Must Exist

**Check**: During seed loading  
**Condition**: `subcategory.default_dimensions` is valid array  
**Fallback**: If missing or invalid, allow user to select manually

---

## Edge Cases

### Edge Case 1: Seed with Only 1 Dimension

**Scenario**: JSON has `"default_dimensions": ["execution"]`  
**Result**: `primary = execution`, `secondary = nil`, `tertiary = nil`  
**Valid**: Yes (secondary/tertiary are optional)

---

### Edge Case 2: User Selects Primary but No Additional

**Scenario**: Custom experiment with only primary  
**Result**: `ExperimentImpact(primary: .execution, secondary: nil, tertiary: nil)`  
**Valid**: Yes

---

### Edge Case 3: User Deselects Secondary

**Scenario**: User had 2 additional, removes the first one  
**Result**: Array shifts, second becomes first → `selectedAdditional = [original_tertiary]`  
**Implementation**: Use array operations (maintain order)

---

### Edge Case 4: Same Dimension in Multiple Experiments

**Scenario**: Experiment A has Execution as primary, Experiment B has Execution as secondary  
**Strength**: Execution receives contributions from both (weighted appropriately)  
**Growth**: Execution counts days from both experiments (deduplicated)  
**Valid**: Yes (common scenario)

---

## Common Pitfalls

### Pitfall 1: Weighting Denominator

**Problem**: Adding weight to `totalPossible`  
**Incorrect**:
```swift
scores[dim].totalPossible += 2.0 * weight  // ❌ WRONG
```

**Correct**:
```swift
scores[dim].totalPossible += 2.0  // ✅ RIGHT
```

---

### Pitfall 2: Using Set for Additional Dimensions

**Problem**: Set loses order, can't distinguish secondary from tertiary  
**Incorrect**:
```swift
@State private var selectedAdditional: Set<Dimension>  // ❌ No order
```

**Correct**:
```swift
@State private var selectedAdditional: [Dimension]  // ✅ Preserves order
```

---

### Pitfall 3: Forgetting to Update Additional on Primary Change

**Problem**: User changes primary, but additional still contains old primary  
**Fix**: When primary changes, remove from additional:
```swift
selectedPrimary = newDim
selectedAdditional.removeAll { $0 == newDim }
```

---

### Pitfall 4: Allowing Duplicate Dimensions

**Problem**: User can select same dimension for multiple slots  
**Fix**: Exclude primary from additional selection list:
```swift
ForEach(Dimension.allCases.filter { $0 != selectedPrimary }) { dim in
    // Additional selection UI
}
```

---

## QA Checklist: Dimension Weighting

Before releasing dimension-related features:

### Assignment
- [ ] Seed-based: dimensions auto-populate from JSON
- [ ] Custom: primary required, secondary/tertiary optional
- [ ] Create button disabled if custom experiment missing primary
- [ ] User can edit seed defaults via picker sheet

### Picker UI
- [ ] Primary: radio select, all 7 dimensions shown
- [ ] Additional: multi-select, excludes primary
- [ ] Max 2 additional selections enforced
- [ ] Numbered badges (1, 2) show selection order
- [ ] Changing primary removes it from additional

### Validation
- [ ] No duplicate dimensions (primary ≠ secondary ≠ tertiary)
- [ ] Primary required for custom experiments
- [ ] Max 3 total dimensions per experiment

### Calculations
- [ ] Strength: weights applied to numerator only
- [ ] Strength: denominator always += 2.0 (not weighted)
- [ ] Growth: no weighting, simple day count
- [ ] Same dimension in multiple experiments aggregates correctly

### Edge Cases
- [ ] Seed with only 1 dimension works
- [ ] User can select only primary (no additional)
- [ ] Removing secondary shifts tertiary to secondary slot
- [ ] Multiple experiments with same dimension aggregate correctly

---

*Last updated: 2026-02-11*
