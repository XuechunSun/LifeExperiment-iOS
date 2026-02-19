# Product Rules

## Purpose

This document defines high-level product decisions, feature specifications, and user experience patterns for LifeExperiment. These rules ensure consistency across the app and prevent conflicting implementations.

---

## Navigation Architecture

### Bottom Tab Bar (Primary Navigation)

**Tabs** (left to right):
1. **Home** - Dashboard with CTAs, active experiments, recent events
2. **Active Exp** - List of all active experiments
3. **Create** ⚡ - Action tab (opens experiment creation flow)
4. **Summary** - Insights: Strength radar + Growth metrics + Storage boxes
5. **Profile** - User settings and profile

**Rules**:
- Each tab has its own `NavigationStack` (isolated navigation state)
- Create tab is an **action tab**: tapping presents a sheet, doesn't land on content
- Switching to Create tab presents creation sheet → on dismiss, auto-switch back to Home
- Back navigation stays within tab context (doesn't cross tabs)

**Implementation Notes**:
- Use `.onChange(of: selectedTab)` to trigger Create sheet presentation
- After experiment creation, switch to Active tab (optional: push to detail)
- Home tab is default on launch

---

## Experiment Lifecycle & Status

### Status Values
- **Active**: Experiment is in progress, accepting new logs
- **Completed**: User marked as complete, no longer accepting logs
- **Paused**: (Future - not implemented yet)

### State Transitions
```
[Create] → Active
Active → Completed (user completes)
Active → Active (user logs)
Completed → [no further transitions]
```

**Rules**:
- Once completed, experiment stops accepting new logs
- Completion date (`completedAt`) is set when status changes to `.completed`
- Completed experiments remain in data (never auto-deleted)

---

## Experiment Actions & Permissions

### Active Experiments

**Available Actions**:
- ✏️ **Rename**: Edit experiment title
- 📋 **Duplicate**: Create copy (as new active experiment)
- 🗑️ **Delete**: Remove experiment (with confirmation)

**UI Presentation**:
- Swipe actions (left/right swipe on row)
- "..." trailing menu button (always visible)
- Both must provide same actions

**Implementation**:
```swift
// Active experiment row
ExperimentRowMenu(
    kind: .active,
    onRename: { /* show rename sheet */ },
    onDuplicate: { /* duplicate and create */ },
    onDelete: { /* confirm and delete */ }
)
```

---

### Completed Experiments

**Available Actions**:
- 📋 **Duplicate**: Create copy (as new active experiment)
- 🗑️ **Delete**: Remove experiment (with confirmation)

**Not Available**:
- ❌ **Rename**: Completed experiments cannot be renamed (data integrity)

**Rationale**: Completed experiments represent historical records. Allowing renames could cause confusion when reviewing past insights.

**Implementation**:
```swift
// Completed experiment row
ExperimentRowMenu(
    kind: .completed,
    onRename: nil,  // No rename for completed
    onDuplicate: { /* duplicate and create */ },
    onDelete: { /* confirm and delete */ }
)
```

---

## Home View States

Home adapts based on user's experiment status:

### State A: No Active Experiments
- Show CTA: encouragement to start first experiment
- Link to Create tab

### State B: Active Experiments, None Updated Today
- Show "Continue Recording" section with active experiments (max 2 preview)
- CTA: gentle reminder to log
- "More" button → Active Exp tab

### State C: Active Experiments, At Least One Updated Today
- Show "Continue Recording" section (visually lighter emphasis)
- Show "Recent Events" (positive acknowledgment)
- "More" button → Active Exp tab

**Additional Sections** (all states):
- **Completed Preview**: Max 2 completed experiments (most recent)
- "More" button → Completed list view
- **Calendar Footprint**: (Future - currently hidden)

---

## Summary Page Structure

The Summary tab presents three core insights modules:

### 1. Dimension Insights (Top)

Two subsections, vertically stacked:

#### A) Strength (Current Profile)
- **Visual**: Radar chart (7 dimensions)
- **Data**: Based on completed experiments + consistency
- **Nature**: Can go up or down over time
- **User message**: "This reflects your current strengths based on completed experiments and consistency. It may change over time — and that's normal."
- **Footnote**: "* Based on completed experiments"

**Purpose**: Help users understand their **current capability profile** across dimensions. Emphasize this is a snapshot, not a permanent score.

#### B) Growth
- **Visual**: Horizontal bar chart (ranked by days, descending)
- **Data**: Total logged days per dimension (across active + completed experiments)
- **Nature**: Monotonically increasing (accumulated effort)
- **User message**: "Every day you tried counts. This reflects the time you've invested — nothing more, nothing less."
- **Footnote**: "* Dimensions with 0 days are hidden for now."

**Purpose**: Show accumulated **time investment** per dimension. This never decreases, reducing anxiety.

---

### 2. Storage Boxes by Category

- Displays experiments grouped by category/subcategory
- Categories: Life Reset, Life List, 30-Day Challenge, Well-Being, Emotional Care, Custom
- Shows experiment count per category
- Tap category → sheet with filtered experiment list

---

### 3. Calendar Footprint (Future)

Currently hidden behind flag (`showCalendarFootprint = false`). Can be restored later.

---

## Strength vs Growth: Key Differences

| Aspect | Strength | Growth |
|--------|----------|--------|
| **Metric** | Percentage (0-100%) | Days count |
| **Scope** | Completed experiments only | Active + Completed |
| **Can Decrease?** | ✅ Yes (if new completions lower average) | ❌ No (monotonic) |
| **Formula** | Completion + Consistency | Sum of logged days |
| **Weighting** | Yes (primary 1.0, secondary 0.5, tertiary 0.2) | No (count days, not weighted) |
| **Purpose** | Show current capability profile | Show accumulated time investment |
| **Emotional Framing** | "It may change — that's normal" | "Every day you tried counts" |

**Rationale**: Strength shows **quality** (with weighting), Growth shows **quantity** (time invested). Separating these reduces anxiety from fluctuating metrics.

---

## Valid Log Rules

### Definition: Valid Log Day

A log entry is **valid** if:
- Note is non-empty (after trimming whitespace) **OR**
- Mood is set (non-nil)

Empty logs (no note, no mood) do NOT count.

**Implementation**:
```swift
func validLogDays(for experiment: Experiment) -> Set<Date> {
    let calendar = Calendar.current
    return Set(experiment.logs.compactMap { log -> Date? in
        let trimmedNote = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty || log.mood != nil else { return nil }
        return calendar.startOfDay(for: log.date)
    })
}
```

**Deduplication**: Use `startOfDay` to ensure multiple logs on same day count as 1 day.

---

### Eligibility for Metrics

**Rule**: Experiments with **0 valid log days** do NOT contribute to Strength or Growth.

**Rationale**: Experiments without engagement shouldn't affect user's profile or insights.

**Strength Eligibility**:
- Status: `.completed`
- Impact: `!= nil`
- Valid log days: `> 0`

**Growth Eligibility**:
- Status: `.active` OR `.completed`
- Impact: `!= nil`
- Valid log days: `> 0`

---

## Experiment Creation Flows

### Seed-Based Creation (Pre-defined Categories)

1. User selects category (e.g., "30-Day Challenge")
2. User selects subcategory (e.g., "Daily Discipline")
3. **Dimensions auto-populated** from `experiment_seed.json` → `default_dimensions`
4. User can edit dimensions (opens `DimensionPickerSheet`)
5. User enters title, description, etc.
6. **Validation**: Title required, subcategory required
7. Save → creates active experiment

---

### Custom Category Creation

1. User enters title
2. User enters custom category name
3. **Dimensions required**: User must select at least primary dimension
4. **Validation**:
   - Title required
   - Primary dimension required (show inline validation if missing)
   - Secondary/tertiary optional (max 2 additional)
5. Save → creates active experiment

**UI Note**: Show inline message "What does this experiment help with most? (required)" if no dimension selected.

---

## Dimension Selection Rules

### Requirements

| Experiment Type | Primary | Secondary | Tertiary |
|----------------|---------|-----------|----------|
| Seed-based | Auto-filled (editable) | Auto-filled (editable) | Auto-filled (editable) |
| Custom category | ✅ Required | Optional | Optional |

### Constraints
- Primary: Exactly 1 (required)
- Additional: Max 2 (secondary + tertiary)
- No duplicates: Primary, secondary, tertiary must all be different

### UI Pattern
- Use `DimensionPickerSheet` for selection
- Primary: Radio select (single choice)
- Additional: Multi-select with numbered badges (1, 2) showing order
- Save applies: `selectedAdditional[0]` → secondary, `selectedAdditional[1]` → tertiary

---

## Categories & Seed Data

### Seed Categories (from `experiment_seed.json`)

1. **Life Reset** (`life_reset`)
   - Self Reflection
   - Career Reorientation
   - Daily Structure

2. **Life List** (`life_list`)
   - New Experiences
   - Creative Expression
   - Personal Milestones

3. **30-Day Challenge** (`challenge_30`)
   - Daily Discipline
   - Skill Sprint
   - Habit Reset

4. **Well-Being** (`well_being`)
   - Movement
   - Sleep & Rest
   - Nutrition Awareness

5. **Emotional Care** (`emotional_care`)
   - Emotional Awareness
   - Self-Compassion
   - Mental Reset

### Custom Category

- User-defined category name
- Not pre-seeded, no default dimensions
- Shows as "Custom" in Storage Boxes (aggregated)

**Storage Box Subtitle**: Show up to 2 distinct custom category names as subtitle/tag line.

---

## Edge Cases & Validation

### Edge Case 1: Create Button Disabled
**Condition**: Title empty OR (seed category selected but no subcategory) OR (custom category but no primary dimension)  
**Behavior**: Show inline validation message, disable Create button

### Edge Case 2: Completed Experiment with 0 Logs
**Condition**: User completes experiment without logging  
**Behavior**: Experiment is completed, but contributes 0 to Strength and Growth (filtered out)

### Edge Case 3: Duplicate Dimension Selection
**Condition**: User tries to select same dimension as primary and secondary  
**Behavior**: Prevent in UI (exclude primary from additional selection list)

### Edge Case 4: Multiple Custom Categories
**Condition**: User creates many custom categories  
**Behavior**: Storage box shows "Custom" with subtitle showing 2 distinct names (e.g., "Cooking, Reading")

### Edge Case 5: Tied Days in Growth List
**Condition**: Multiple dimensions have same day count  
**Behavior**: Sort by title (alphabetical) as tie-breaker (stable sort)

---

## QA Checklist: Product Rules

Before releasing features, verify:

### Navigation
- [ ] Each tab has isolated NavigationStack
- [ ] Create tab presents sheet and returns to Home on dismiss
- [ ] Back button stays within tab (doesn't cross tabs)

### Experiment Actions
- [ ] Active experiments: Rename + Duplicate + Delete
- [ ] Completed experiments: Duplicate + Delete (no Rename)
- [ ] Both swipe actions and "..." menu work
- [ ] Delete shows confirmation

### Summary Page
- [ ] Strength shows radar chart for completed experiments only
- [ ] Growth shows bar chart for active + completed experiments
- [ ] Experiments with 0 valid logs don't contribute
- [ ] "Dimensions with 0 days are hidden" footnote appears

### Dimension Selection
- [ ] Seed-based: dimensions auto-populate
- [ ] Custom: primary dimension required
- [ ] No duplicate dimensions in same experiment
- [ ] Max 3 dimensions per experiment

### Valid Logs
- [ ] Empty logs (no note, no mood) don't count
- [ ] Days are deduplicated (multiple logs same day = 1 day)

### Edge Cases
- [ ] Create button validation works for all flows
- [ ] Completed experiments with 0 logs handled correctly
- [ ] Tie-breakers prevent unstable sorting

---

*Last updated: 2026-02-11*
