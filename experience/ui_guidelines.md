# Personal UI Design Philosophy

## Purpose

This framework defines a comprehensive approach to UI design and implementation, distilled from building LifeExperiment. It serves as both a design system and a prevention framework against common layout, interaction, and visual issues.

---

## Philosophy

### Core Beliefs

**UI should never surprise the user.**
- Layouts remain stable across state changes
- Actions produce predictable outcomes
- Visual feedback confirms user intent

**Space is information.**
- Whitespace creates hierarchy and clarity
- Consistent spacing builds rhythm
- Overcrowding reduces comprehension

**Accessibility is non-negotiable.**
- Every interactive element must be reachable
- Motion can be disabled
- Contrast and sizing must meet standards

**Visual hierarchy should be subtle.**
- Restrained use of color and emphasis
- Typography creates natural flow
- Shadows and opacity used sparingly

**Interactions must feel intentional.**
- No accidental taps or gestures
- Clear visual states (default, pressed, disabled)
- Feedback confirms every action

**Stability over novelty.**
- Proven patterns over experimental layouts
- Performance over visual complexity
- Maintenance over cleverness

---

# Layout Invariants (Guardrails)

These are non-negotiable rules that MUST be followed to prevent layout failures.

## MUST Rules

**L-MUST-1**: Labels MUST NOT intersect grid boundaries in radial layouts  
→ Use separate `gridRadius` and `labelRadius` with minimum 50pt margin

**L-MUST-2**: Interactive elements MUST have minimum 32x32pt tap targets (44x44pt preferred)  
→ Use `.padding()` + `.contentShape(Rectangle())`

**L-MUST-3**: Lists MUST have deterministic sorting with tie-breakers  
→ Always add secondary sort criteria when primary key can have duplicates

**L-MUST-4**: Text in constrained layouts MUST have `.lineLimit()`  
→ Prevents infinite expansion and layout breaks

**L-MUST-5**: Multi-line text MUST match text alignment with frame alignment  
→ `.multilineTextAlignment()` should equal `.frame(alignment:)`

**L-MUST-6**: Bottom elements in radial layouts MUST have extra vertical margin  
→ Minimum 30pt additional margin to prevent overlap with content below

**L-MUST-7**: Progress bars MUST scale to available width  
→ Use `GeometryReader` for responsive fills, not fixed pixel values

**L-MUST-8**: Overlays MUST NOT cause layout recalculation  
→ Use `.overlay { }` and keep state isolated from content layout

## NEVER Rules

**L-NEVER-1**: NEVER use `.overlay()` to position interactive elements next to dynamic text  
→ Use inline `HStack`/`VStack` instead

**L-NEVER-2**: NEVER sort lists without tie-breakers  
→ Causes unstable UI reordering on state changes

**L-NEVER-3**: NEVER apply shadows to background overlay layers  
→ Apply shadows only to content cards

**L-NEVER-4**: NEVER use fixed pixel scaling for responsive elements  
→ Breaks on different screen sizes

**L-NEVER-5**: NEVER position radial labels using same radius as grid  
→ Causes immediate overlap

**L-NEVER-6**: NEVER forget `.contentShape()` on padded buttons  
→ Tap area won't match visual appearance

**L-NEVER-7**: NEVER hardcode layout values without named constants  
→ Makes future adjustments difficult and error-prone

**L-NEVER-8**: NEVER let showing overlays cause content to reorder or shift  
→ State management must be isolated

---

# Design Tokens

## Layout Spacing Tokens

```swift
enum LayoutTokens {
    // MARK: - Radial Layouts
    
    /// Base margin between grid boundary and labels (all sides)
    static let radarBaseMargin: CGFloat = 55
    
    /// Extra margin for bottom labels (prevents overlap with content below)
    static let radarBottomExtraMargin: CGFloat = 35
    
    /// Directional nudge to reduce adjacent label collisions
    static let radarNudge: CGFloat = 10
    
    /// Chart height for 7-axis radar with 2-line labels
    static let radarChartHeight: CGFloat = 300
    
    /// Vertical padding around radar chart
    static let radarChartPadding: CGFloat = 16
    
    /// Spacing between chart and footnote/content below
    static let radarFootnoteSpacing: CGFloat = 12
    
    // MARK: - Card Styling
    
    /// Standard card padding
    static let cardPadding: CGFloat = 16
    
    /// Standard card corner radius
    static let cardCornerRadius: CGFloat = 14
    
    /// Spacing between card elements
    static let cardElementSpacing: CGFloat = 12
    
    // MARK: - Interactive Elements
    
    /// Minimum tap target size (accessibility)
    static let minTapTarget: CGFloat = 44
    
    /// Comfortable tap target for dense layouts
    static let comfortableTapTarget: CGFloat = 32
    
    // MARK: - Progress Bars
    
    /// Standard progress bar height
    static let progressBarHeight: CGFloat = 8
    
    // MARK: - Label Constraints
    
    /// Max width for radar side labels
    static let radarSideLabelMaxWidth: CGFloat = 160
    
    /// Max width for radar bottom labels (tighter to prevent horizontal collision)
    static let radarBottomLabelMaxWidth: CGFloat = 140
}
```

## Visual Tokens

```swift
enum VisualTokens {
    // MARK: - Overlays
    
    /// Subtle dim opacity for modal backgrounds
    static let overlayDimOpacity: Double = 0.2
    
    /// Shadow for elevated cards
    static let cardShadow = (
        color: Color.black.opacity(0.12),
        radius: CGFloat(18),
        x: CGFloat(0),
        y: CGFloat(8)
    )
    
    // MARK: - Colors
    
    /// Standard card background
    static let cardBackground = Color(.systemGray6)
    
    /// Grid line opacity
    static let gridLineOpacity: Double = 0.2
    
    /// Axis line opacity
    static let axisLineOpacity: Double = 0.3
    
    /// Chart fill opacity
    static let chartFillOpacity: Double = 0.18
}
```

## Motion Tokens

```swift
enum MotionTokens {
    // MARK: - Animation Durations
    
    /// Quick interactions (buttons, toggles)
    static let quickDuration: Double = 0.2
    
    /// Standard transitions (sheets, navigation)
    static let standardDuration: Double = 0.3
    
    /// Chart reveals (radar, graphs)
    static let chartRevealDuration: Double = 0.7
    
    /// Progress bar fills
    static let progressFillDuration: Double = 0.5
    
    // MARK: - Animation Curves
    
    static let standardCurve = Animation.easeOut
    static let springyCurve = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
```

---

# Layout Rules

## L1: Inline Layout Over Overlay for Interactive Elements

**Principle**: Interactive elements adjacent to dynamic text must use inline layout containers, not overlays.

**Rationale**: Overlays calculate position before text wrapping, causing icons to overlap text when it wraps to multiple lines.

**Implementation**:
```swift
// ❌ Avoid: Overlay with dynamic text
VStack {
    Text(dynamicText)
        .overlay(alignment: .topTrailing) {
            Button("Info") { }
        }
}

// ✅ Correct: Inline layout
HStack(spacing: LayoutTokens.iconSpacing) {
    Text(dynamicText)
        .lineLimit(2)
        .layoutPriority(1)
    Button("Info") { }
        .fixedSize()
}
.frame(maxWidth: LayoutTokens.labelMaxWidth, alignment: .leading)
```

**When overlay is acceptable**: Non-interactive decorations or guaranteed single-line text.

---

## L2: Position-Aware Layout Constraints

**Principle**: Elements in radial or asymmetric layouts must use position-aware alignment to prevent overflow and collision.

**Rationale**: Different positions require different alignment strategies. Left-side elements should align trailing, right-side leading, center elements centered.

**Implementation**:
```swift
private var frameAlignment: Alignment {
    let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
    
    // Right side (0° ± 45°)
    if normalized > -.pi / 4 && normalized < .pi / 4 {
        return .leading
    }
    // Left side (180° ± 45°)
    else if normalized > 3 * .pi / 4 || normalized < -3 * .pi / 4 {
        return .trailing
    }
    // Top/bottom
    else {
        return .center
    }
}

// Apply
.frame(maxWidth: LayoutTokens.radarSideLabelMaxWidth, alignment: frameAlignment)
```

**Checklist**:
- [ ] Labels have explicit `maxWidth` constraint
- [ ] Alignment varies based on position
- [ ] Sufficient spacing from boundaries

---

## L3: Radial Layout Three-Layer Positioning

**Principle**: Radial layouts (radar charts, circular menus) require three layers of collision prevention: margin separation, directional nudging, and quadrant-specific handling.

**Layer 1: Separate Radii with Named Constants**

```swift
struct RadarChartView: View {
    private let labelMargin: CGFloat = LayoutTokens.radarBaseMargin
    private let bottomLabelExtraMargin: CGFloat = LayoutTokens.radarBottomExtraMargin
    private let nudgeAmount: CGFloat = LayoutTokens.radarNudge
    
    var body: some View {
        let gridRadius = size * 0.35           // Chart content
        let baseLabelRadius = gridRadius + labelMargin  // Label ring
    }
}
```

**Invariant**: `labelRadius > gridRadius` by minimum 50pt

---

**Layer 2: Directional Nudge Helper**

```swift
/// Pushes labels outward along axis to reduce adjacent collisions
private func nudgeOffset(for angle: Double) -> CGSize {
    CGSize(
        width: cos(angle) * nudgeAmount,
        height: sin(angle) * nudgeAmount
    )
}

// Apply
let baseLabelPoint = pointOnCircle(center: center, radius: labelRadius, angle: angle)
let nudge = nudgeOffset(for: angle)
let finalPoint = CGPoint(
    x: baseLabelPoint.x + nudge.width,
    y: baseLabelPoint.y + nudge.height
)
```

**Typical nudge**: 8-12pt

---

**Layer 3: Quadrant-Specific Margins**

Bottom labels need extra spacing to avoid overlapping content below:

```swift
private func isBottomLabel(angle: Double) -> Bool {
    let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
    return normalized > .pi / 4 && normalized < 3 * .pi / 4
}

// Apply extra margin to bottom quadrant
let effectiveRadius = isBottomLabel(angle: angle)
    ? baseLabelRadius + bottomLabelExtraMargin
    : baseLabelRadius
```

**Bottom extra margin**: 30-40pt

**Result**:
- Top/side labels: ~65pt from grid
- Bottom labels: ~100pt from grid
- Prevents overlap with footnotes/content below

---

## L4: Responsive Progress Bars

**Principle**: Progress indicators must scale proportionally to available width, not use fixed pixel dimensions.

**Implementation**:
```swift
// ❌ Avoid: Fixed scaling
.frame(width: CGFloat(value) / CGFloat(maxValue) * 100, height: 8)

// ✅ Correct: Responsive scaling
ZStack(alignment: .leading) {
    Capsule()
        .fill(Color(.systemGray5))
        .frame(height: LayoutTokens.progressBarHeight)
    
    GeometryReader { geometry in
        let ratio = Double(value) / Double(maxValue)
        let fillWidth = geometry.size.width * min(1.0, max(0.0, ratio))
        
        Capsule()
            .fill(Color.blue)
            .frame(width: fillWidth, height: LayoutTokens.progressBarHeight)
    }
}
.frame(maxWidth: .infinity)
.frame(height: LayoutTokens.progressBarHeight)
```

**Critical**: Always constrain GeometryReader height to prevent unexpected vertical expansion.

---

## L5: Layout Priority for Combined Elements

**Principle**: When combining text with interactive elements in constrained spaces, text must have explicit layout priority.

**Implementation**:
```swift
HStack(alignment: .firstTextBaseline, spacing: 6) {
    Text(title)
        .lineLimit(2)
        .layoutPriority(1)  // Text gets space first
        .fixedSize(horizontal: false, vertical: true)
    
    Button(action: onInfo) {
        Image(systemName: "info.circle")
            .frame(width: LayoutTokens.comfortableTapTarget,
                   height: LayoutTokens.comfortableTapTarget)
    }
    .fixedSize()  // Icon maintains size
    .contentShape(Rectangle())
}
```

**Key modifiers**:
- `.layoutPriority(1)` on text: Allocates space to text first
- `.fixedSize()` on icon: Prevents compression
- `.firstTextBaseline` alignment: Keeps icon aligned with first line
- `.contentShape()`: Ensures full tap area is responsive

---

# Interaction Rules

## I1: Accessible Hit Targets

**Principle**: All interactive elements must provide comfortable tap targets.

**Standards**:
- **Minimum**: 32x32pt (dense layouts only)
- **Preferred**: 44x44pt (iOS HIG standard)
- **Comfortable**: 48-56pt (generous spacing)

**Implementation**:
```swift
Button(action: { }) {
    Image(systemName: "info.circle")
        .font(.caption2)  // Visual size: small (~12pt)
        .frame(width: LayoutTokens.minTapTarget,
               height: LayoutTokens.minTapTarget)  // Tap area: 44pt
}
.contentShape(Rectangle())  // Make entire frame tappable
```

**Pattern**: Small visual size, large tap target.

---

## I2: Content Shape for Non-Standard Tap Areas

**Principle**: When padding or custom frames create tap areas, explicitly define the tappable region.

**Implementation**:
```swift
Button(action: { }) {
    Icon()
        .padding(12)  // Increases tap area
}
.contentShape(Rectangle())  // Without this, only icon is tappable
```

**Rule**: Always add `.contentShape()` after `.padding()` on buttons.

---

# Visual Rules

## V1: Subtle Overlay Opacity

**Principle**: Modal and popup backgrounds must be barely noticeable, not oppressive.

**Values**:
- **Light**: 0.15 opacity (very subtle)
- **Standard**: 0.20 opacity (preferred)
- **Maximum**: 0.25 opacity (heavy but acceptable)
- **Never**: 0.30+ opacity (too dark)

**Alternative**: Use `.ultraThinMaterial` for iOS-native blur effect.

**Implementation**:
```swift
ZStack {
    Color.black.opacity(VisualTokens.overlayDimOpacity)
        .ignoresSafeArea()
        .onTapGesture { dismissOverlay() }
    
    ContentCard()
}
```

---

## V2: Shadow Hierarchy

**Principle**: Shadows indicate elevation. Apply shadows only to elevated content, never to background layers.

**Shadow Specification**:
```swift
.shadow(
    color: VisualTokens.cardShadow.color,    // .black.opacity(0.12)
    radius: VisualTokens.cardShadow.radius,  // 18
    x: VisualTokens.cardShadow.x,            // 0
    y: VisualTokens.cardShadow.y             // 8
)
```

**Application**:
- ✅ Content cards
- ✅ Floating panels
- ✅ Elevated buttons
- ❌ Background dim layers
- ❌ Full-screen overlays

**Implementation**:
```swift
// ✅ Correct: Shadow on card only
ZStack {
    Color.black.opacity(0.2)  // No shadow
        .ignoresSafeArea()
    
    VStack { /* content */ }
        .background(Color(.systemBackground))
        .cornerRadius(LayoutTokens.cardCornerRadius)
        .shadow(color: VisualTokens.cardShadow.color,
                radius: VisualTokens.cardShadow.radius,
                x: VisualTokens.cardShadow.x,
                y: VisualTokens.cardShadow.y)
}
```

**Never**: Apply shadow to entire `ZStack` containing background overlay.

---

## V3: Standard Card Styling

**Principle**: Cards provide visual grouping and elevation. Use consistent styling across the app.

**Specification**:
```swift
VStack(alignment: .leading, spacing: LayoutTokens.cardElementSpacing) {
    // Content
}
.padding(LayoutTokens.cardPadding)
.background(VisualTokens.cardBackground)
.cornerRadius(LayoutTokens.cardCornerRadius)
```

**Token Values**:
- Padding: `16pt`
- Corner radius: `14pt`
- Internal spacing: `12pt`
- Background: `Color(.systemGray6)` (system-adaptive)

---

# Data Rules

## D1: Stable Sorting with Tie-Breakers

**Principle**: All sorted collections must have deterministic ordering to prevent UI instability.

**Pattern**:
```swift
.sorted { lhs, rhs in
    // Primary sort
    if lhs.primaryValue != rhs.primaryValue {
        return lhs.primaryValue > rhs.primaryValue
    }
    
    // Tie-breaker (REQUIRED)
    return lhs.stableKey < rhs.stableKey
}
```

**Stable Keys** (preference order):
1. Enum case order: `Dimension.allCases.firstIndex(of:)`
2. Fixed property: `.title`, `.id`, `.rawValue`
3. Timestamp: `.createdAt` (last resort)

**Never use**: Random values, computed hashes, memory addresses

**Applied Example**:
```swift
// Growth list: sort by days desc, then Dimension.allCases order
private var sortedDimensionsByDays: [(Dimension, Int)] {
    dimensionDays
        .filter { $0.value > 0 }
        .sorted { lhs, rhs in
            if lhs.value != rhs.value {
                return lhs.value > rhs.value
            }
            // Tie-breaker: enum declaration order
            let lhsIndex = Dimension.allCases.firstIndex(of: lhs.key) ?? 0
            let rhsIndex = Dimension.allCases.firstIndex(of: rhs.key) ?? 0
            return lhsIndex < rhsIndex
        }
}
```

**Verification**: Open/close unrelated UI elements (modals, sheets) → list order must not change.

---

## D2: ForEach Stable Identifiers

**Principle**: ForEach must use stable, unique identifiers to prevent unnecessary view recreation.

**Pattern**:
```swift
// ✅ Correct: Stable ID
ForEach(sortedItems, id: \.dimension) { item in
    ItemRow(item)
}

// Or for tuples
ForEach(sortedDimensionsByDays, id: \.0) { dimension, count in
    // dimension is enum (stable)
}
```

**Never**: Use index-based IDs for dynamic content that can reorder.

---

# Motion & State Guidelines

## Motion Design Principles

**When to Animate**:
- State transitions that affect user understanding
- Content reveals (charts, data loading)
- Confirmatory feedback (success, completion)

**When NOT to Animate**:
- During typing or text input
- Frequently-changing values (counters)
- Accessibility Reduce Motion is enabled

**Duration Guidelines**:

| Interaction Type | Duration | Curve | Example |
|------------------|----------|-------|---------|
| Quick feedback | 0.15-0.2s | `.easeOut` | Button press |
| Standard transition | 0.3-0.4s | `.easeOut` | Sheet present/dismiss |
| Progress fills | 0.4-0.6s | `.easeOut` | Bar chart fills |
| Chart reveals | 0.6-0.8s | `.easeOut` | Radar polygon animation |

**Implementation Pattern**:
```swift
struct AnimatedView: View {
    @State private var animationProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ContentView(progress: animationProgress)
            .onAppear {
                if reduceMotion {
                    animationProgress = 1.0  // Immediate
                } else {
                    withAnimation(.easeOut(duration: MotionTokens.chartRevealDuration)) {
                        animationProgress = 1.0
                    }
                }
            }
    }
}
```

---

## M1: Reduce Motion Compliance

**Principle**: All animations must respect `accessibilityReduceMotion` environment value.

**MUST comply**: Every `withAnimation` block

**Implementation**:
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// Before animating
if reduceMotion {
    // Set final state immediately
    animatedValue = finalValue
} else {
    // Animate
    withAnimation(.easeOut(duration: duration)) {
        animatedValue = finalValue
    }
}
```

**Never**: Animate when `reduceMotion == true`

---

## M2: Layout-Stable Animations

**Principle**: Animations must not cause layout recalculation or content reordering.

**Rules**:
- Animate visual properties only: opacity, scale, offset, colors
- Never animate frame sizes that affect surrounding content
- Never trigger animations that mutate sorted arrays

**Safe to animate**:
- `.opacity()`
- `.scaleEffect()`
- `.offset()`
- `.rotationEffect()`
- Fill widths within fixed containers

**Unsafe** (causes layout):
- `.frame(width:)` on elements with siblings
- `.padding()` changes
- Inserting/removing views during animation

---

## M3: Loading State Layout Consistency

**Principle**: Loading states must occupy the same space as loaded content to prevent layout shifts.

**Implementation**:
```swift
// ✅ Correct: Same height for loading and content
if isLoading {
    ProgressView()
        .frame(height: LayoutTokens.contentHeight)  // Match content height
} else {
    ContentView()
        .frame(height: LayoutTokens.contentHeight)
}
```

**Never**: Let loading states collapse or expand layout.

---

# Applied Examples

## Example 1: Radar Chart Label Overlap Resolution

**Context**: 7-dimension radar chart with multi-line labels and info icons.

**Symptoms Observed**:
1. Bottom labels ("Expression & Creativity", "Focus & Flow") overlapping footnote
2. Labels too close to grid boundary
3. Info icons misaligned with wrapped text
4. Inconsistent spacing between adjacent labels

**Measurements (from screenshot)**:
- Chart height: 260pt (insufficient)
- Bottom label margin: 70pt (inadequate for 2-line + percentage)
- Footnote spacing: 4pt (too tight)

**Root Causes**:
1. Insufficient bottom margin (20pt extra, needed 35pt)
2. Inadequate chart height (needed 40pt more)
3. Minimal footnote spacing (needed 8pt more)
4. Small directional nudge (8pt, needed 10pt)

---

**Complete Solution**:

```swift
// Layout Constants
private let labelMargin: CGFloat = 55              // +5pt
private let bottomLabelExtraMargin: CGFloat = 35   // +15pt
private let nudgeAmount: CGFloat = 10              // +2pt

// Chart sizing
.frame(height: 300)        // +40pt
.padding(.vertical, 16)     // +4pt

// Footnote spacing
Text("* Based on...").padding(.top, 12)  // +8pt
```

**Changes Table**:

| Parameter | Before | After | Delta | Purpose |
|-----------|--------|-------|-------|---------|
| Base margin | 50pt | 55pt | +5pt | General clearance |
| Bottom extra margin | 20pt | 35pt | +15pt | Footnote separation |
| Directional nudge | 8pt | 10pt | +2pt | Label-to-label spacing |
| Chart height | 260pt | 300pt | +40pt | Vertical room |
| Chart padding | 12pt | 16pt | +4pt | Breathing room |
| Footnote spacing | 4pt | 12pt | +8pt | Clear separation |

**Result Spacing**:
- Top/side labels: 65pt from grid (55 + 10 nudge)
- Bottom labels: 100pt from grid (55 + 35 + 10 nudge)
- Chart-to-footnote: 28pt minimum (16 + 12)

**Verification**:
- ✅ iPhone SE: Tight but no overlaps
- ✅ iPhone 15 Pro: Perfect spacing
- ✅ iPhone 15 Pro Max: Generous spacing
- ✅ Default + Large Dynamic Type: Works correctly

**Lessons**:
1. Bottom quadrant requires 30-40pt extra margin
2. 2-line labels + percentage need 90-100pt total clearance
3. Minimum 12pt spacing between chart and content below
4. 300pt minimum height for 7-axis radar with 2-line labels
5. Always test on actual device/simulator with screenshots

---

## Example 2: Progress Bar Fixed-Width Issue

**Context**: Growth section bar charts using fixed 100pt scaling.

**Symptom**: Bars looked too short on larger screens, not proportional.

**Root Cause**: Fixed pixel calculation `* 100` instead of responsive width.

**Solution**: Use GeometryReader for proportional scaling.

**Before**:
```swift
Capsule()
    .fill(Color.blue)
    .frame(width: CGFloat(days) / CGFloat(maxDays) * 100, height: 8)
```

**After**:
```swift
GeometryReader { geometry in
    let ratio = Double(days) / Double(maxDays)
    let fillWidth = geometry.size.width * min(1.0, max(0.0, ratio))
    
    Capsule()
        .fill(Color.blue)
        .frame(width: fillWidth, height: LayoutTokens.progressBarHeight)
}
```

**Result**: Bars scale beautifully on all screen sizes.

---

# QA Validation Rules

## Q1: Pre-Submission Checklist

Before committing UI changes:

### Layout Validation
- [ ] All interactive elements have ≥32pt tap targets (44pt preferred)
- [ ] Text in constrained layouts has `.lineLimit()`
- [ ] Frame alignment matches text alignment
- [ ] No overlaps: labels, icons, content
- [ ] Layout stable across state changes

### Visual Validation
- [ ] Overlays use subtle opacity (0.15-0.25)
- [ ] Shadows only on content cards
- [ ] Consistent spacing (use Design Tokens)
- [ ] Works in light and dark mode

### Data Validation
- [ ] Sorted lists have deterministic tie-breakers
- [ ] ForEach uses stable IDs
- [ ] Computed properties don't mutate state

### Motion Validation
- [ ] All animations respect Reduce Motion
- [ ] Animation durations within guidelines (0.15-0.8s)
- [ ] No layout-affecting animations

### Device Validation
- [ ] Tested on small device (iPhone SE)
- [ ] Tested on standard device (iPhone 15 Pro)
- [ ] Tested with Default and Large Dynamic Type

---

## Q2: Radial Layout Specific Checklist

Additional checks for radar charts, pie charts, circular menus:

- [ ] Grid and label radii are separate named constants
- [ ] Label margin ≥ 50pt
- [ ] Bottom labels have extra margin (30-40pt)
- [ ] Directional nudge helper implemented (8-12pt)
- [ ] Labels use `.fixedSize(horizontal: true, vertical: true)`
- [ ] Text has `.layoutPriority(1)` when combined with icons
- [ ] Icons use `.fixedSize()` to prevent compression
- [ ] Max width set based on position (140-160pt)
- [ ] Sufficient spacing below chart (≥12pt)
- [ ] Verified no overlaps: label-grid, label-label, label-icon, label-content-below

---

## Q3: Animation Checklist

Before shipping animated transitions:

- [ ] Reduce Motion checked via `@Environment`
- [ ] Immediate fallback when Reduce Motion enabled
- [ ] Duration within guidelines (0.15-0.8s)
- [ ] Curve appropriate for action type (`.easeOut` preferred)
- [ ] Animation doesn't cause layout shifts
- [ ] No animation on frequently-updating values
- [ ] Smooth on 60Hz displays

---

# Common Pitfalls & Solutions

## Pitfall 1: Forgetting `.contentShape()` on Padded Buttons

**Symptom**: Button with padding doesn't respond to taps in padded area

**Cause**: SwiftUI tap area defaults to content, not frame

**Fix**:
```swift
Button { } label: { Icon() }
    .padding(12)
    .contentShape(Rectangle())  // Required
```

---

## Pitfall 2: Using Overlay for Dynamic Text + Interactive Icon

**Symptom**: Icon overlaps text when text wraps to 2 lines

**Cause**: Overlay positions before text layout

**Fix**: Use `HStack` instead:
```swift
// ❌ Breaks with wrapping
Text(dynamic).overlay { Icon() }

// ✅ Stable
HStack {
    Text(dynamic).lineLimit(2)
    Icon()
}
```

---

## Pitfall 3: Heavy Modal Overlays

**Symptom**: Modal background looks oppressive (too dark)

**Cause**: Opacity too high (0.3-0.5)

**Fix**: Reduce to 0.15-0.25:
```swift
Color.black.opacity(VisualTokens.overlayDimOpacity)  // 0.2
```

---

## Pitfall 4: Unstable List Ordering

**Symptom**: List reorders when tapping unrelated UI elements

**Cause**: Sorting without tie-breaker

**Fix**: Add deterministic secondary sort:
```swift
.sorted { lhs, rhs in
    if lhs.value != rhs.value { return lhs.value > rhs.value }
    return lhs.id < rhs.id  // Tie-breaker
}
```

---

## Pitfall 5: Text Without Line Limit

**Symptom**: Layout breaks with very long text

**Cause**: Text expands infinitely

**Fix**:
```swift
Text(content)
    .lineLimit(2)
    .fixedSize(horizontal: false, vertical: true)
```

---

## Pitfall 6: Single Radius for Grid and Labels (Radial Layouts)

**Symptom**: Labels overlap grid boundary

**Cause**: Using same radius for both grid drawing and label positioning

**Fix**:
```swift
// ❌ Wrong
let radius = size * 0.35
// Use for both grid and labels → overlap

// ✅ Correct
let gridRadius = size * 0.35
let labelRadius = gridRadius + LayoutTokens.radarBaseMargin
```

---

## Pitfall 7: No Special Handling for Bottom Quadrant

**Symptom**: Bottom labels overlap footnote or content below

**Cause**: Uniform margin for all labels

**Fix**: Add extra margin for bottom labels:
```swift
let effectiveRadius = isBottomLabel(angle)
    ? baseRadius + extraBottomMargin
    : baseRadius
```

---

## Pitfall 8: Magic Number Offsets

**Symptom**: Difficult to tune layout, unclear why numbers chosen

**Cause**: Hardcoded values scattered through code

**Fix**: Use named constants:
```swift
// ❌ What is 48?
let labelRadius = radius + 48

// ✅ Clear purpose
let labelRadius = gridRadius + LayoutTokens.radarBaseMargin
```

---

## Pitfall 9: No Layout Priority with Text + Icon

**Symptom**: Icon compresses text in tight spaces

**Cause**: SwiftUI splits space evenly by default

**Fix**:
```swift
HStack {
    Text(title)
        .layoutPriority(1)  // Gets space first
    Icon()
        .fixedSize()  // Maintains size
}
```

---

## Pitfall 10: GeometryReader Without Height Constraint

**Symptom**: Progress bar container expands vertically unexpectedly

**Cause**: GeometryReader takes all available space

**Fix**:
```swift
GeometryReader { geometry in
    // Content
}
.frame(height: LayoutTokens.progressBarHeight)  // Required
```

---

# Typography & Text

## T1: Multiline Text Constraints

**Principle**: Text in constrained layouts must have explicit line limits and alignment.

**Pattern**:
```swift
Text(dynamicContent)
    .lineLimit(2)  // Prevent infinite expansion
    .multilineTextAlignment(.leading)  // Match frame alignment
    .fixedSize(horizontal: false, vertical: true)  // Allow vertical wrapping
```

**Alignment Mapping**:

| Layout Position | Text Alignment | Frame Alignment |
|----------------|----------------|-----------------|
| Left side | `.leading` | `.leading` |
| Right side | `.trailing` | `.trailing` |
| Center | `.center` | `.center` |

**Rules**:
1. Always set `.lineLimit()` for constrained layouts
2. Text alignment MUST match frame alignment
3. Use `.fixedSize(horizontal: false, vertical: true)` for proper wrapping

---

# Prevention Patterns

## Pattern 1: Radial Layout Implementation

When implementing radar charts, circular menus, or radial layouts:

```swift
struct RadarView: View {
    // 1. Define layout tokens
    private let labelMargin: CGFloat = LayoutTokens.radarBaseMargin
    private let bottomExtraMargin: CGFloat = LayoutTokens.radarBottomExtraMargin
    private let nudge: CGFloat = LayoutTokens.radarNudge
    
    var body: some View {
        GeometryReader { geometry in
            let gridRadius = size * 0.35
            let baseLabelRadius = gridRadius + labelMargin
            
            ZStack {
                // 2. Draw grid/content using gridRadius
                drawGrid(radius: gridRadius)
                
                // 3. Position labels with quadrant awareness
                ForEach(Dimension.allCases.indices, id: \.self) { index in
                    let angle = angleForIndex(index)
                    
                    // Bottom labels get extra margin
                    let effectiveRadius = isBottomLabel(angle)
                        ? baseLabelRadius + bottomExtraMargin
                        : baseLabelRadius
                    
                    // 4. Apply directional nudge
                    let basePoint = pointOnCircle(center, radius: effectiveRadius, angle)
                    let nudgeOffset = CGSize(
                        width: cos(angle) * nudge,
                        height: sin(angle) * nudge
                    )
                    let finalPoint = CGPoint(
                        x: basePoint.x + nudgeOffset.width,
                        y: basePoint.y + nudgeOffset.height
                    )
                    
                    // 5. Use stable-ordered data
                    LabelView(
                        title: Dimension.allCases[index].title,
                        angle: angle
                    )
                    .position(finalPoint)
                }
            }
        }
        .frame(height: LayoutTokens.radarChartHeight)
        .padding(.vertical, LayoutTokens.radarChartPadding)
    }
    
    // 6. Bottom quadrant detection
    private func isBottomLabel(angle: Double) -> Bool {
        let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        return normalized > .pi / 4 && normalized < 3 * .pi / 4
    }
}

// 7. Add spacing for content below
Text("Footnote").padding(.top, LayoutTokens.radarFootnoteSpacing)
```

**Critical Steps**:
1. Define named constants (no magic numbers)
2. Separate grid and label radii
3. Implement bottom quadrant detection
4. Apply extra margin to bottom labels
5. Add directional nudge helper
6. Use stable-ordered data sources
7. Provide sufficient spacing to content below

---

## Pattern 2: Stable Sorted List

When displaying sorted lists that should maintain order:

```swift
struct ListView: View {
    let items: [Item]
    
    // 1. Compute sorted array in stable property
    private var sortedItems: [Item] {
        items.sorted { lhs, rhs in
            // Primary sort
            if lhs.priority != rhs.priority {
                return lhs.priority > rhs.priority
            }
            // Tie-breaker (required)
            return lhs.title < rhs.title
        }
    }
    
    var body: some View {
        // 2. Use stable ID
        ForEach(sortedItems, id: \.id) { item in
            ItemRow(item)
        }
    }
}
```

**Verification**: Opening/closing sheets or modals must not reorder list.

---

## Pattern 3: Animated Progress Bar

When implementing animated progress indicators:

```swift
struct ProgressBar: View {
    let value: Double
    let maxValue: Double
    
    @State private var animatedFraction: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var targetFraction: Double {
        maxValue > 0 ? value / maxValue : 0
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color(.systemGray5))
                .frame(height: LayoutTokens.progressBarHeight)
            
            GeometryReader { geometry in
                let fillWidth = geometry.size.width * min(1.0, animatedFraction)
                
                Capsule()
                    .fill(Color.blue)
                    .frame(width: fillWidth, height: LayoutTokens.progressBarHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: LayoutTokens.progressBarHeight)
        .onAppear {
            if reduceMotion {
                animatedFraction = targetFraction
            } else {
                withAnimation(.easeOut(duration: MotionTokens.progressFillDuration)) {
                    animatedFraction = targetFraction
                }
            }
        }
        .onChange(of: targetFraction) { newValue in
            if reduceMotion {
                animatedFraction = newValue
            } else {
                withAnimation(.easeOut(duration: MotionTokens.progressFillDuration)) {
                    animatedFraction = newValue
                }
            }
        }
    }
}
```

**Key elements**:
- Responsive width via GeometryReader
- Reduce Motion compliance
- Smooth easing curve
- Proper state management

---

# Implementation Checklist

## For New Features

Before implementing new UI components:

1. **Review Philosophy** - Understand core principles
2. **Check Invariants** - Ensure no MUST rules violated
3. **Use Design Tokens** - Reference named constants
4. **Follow Patterns** - Use established patterns when applicable
5. **Plan for Motion** - Consider animation early if needed
6. **Verify Accessibility** - Check hit targets and Reduce Motion

## During Implementation

1. **Use Named Constants** - No magic numbers
2. **Add Layout Priority** - Explicitly set when combining elements
3. **Constrain GeometryReader** - Always set height/width
4. **Add Tie-Breakers** - Every sort needs secondary criteria
5. **Test Wrapping** - Verify 2-line text handling
6. **Check State Isolation** - Overlays shouldn't affect content

## After Implementation

1. **Run QA Checklist** - Verify all applicable rules
2. **Test Device Sizes** - iPhone SE, standard, Pro Max, iPad
3. **Test Dynamic Type** - Default and Large
4. **Screenshot Test** - Visual inspection reveals issues code review misses
5. **Document Edge Cases** - Add to this document if new pattern discovered

---

# Reference: Design Token Values

## Layout Tokens

```swift
enum LayoutTokens {
    // Radial Layouts
    static let radarBaseMargin: CGFloat = 55
    static let radarBottomExtraMargin: CGFloat = 35
    static let radarNudge: CGFloat = 10
    static let radarChartHeight: CGFloat = 300
    static let radarChartPadding: CGFloat = 16
    static let radarFootnoteSpacing: CGFloat = 12
    static let radarSideLabelMaxWidth: CGFloat = 160
    static let radarBottomLabelMaxWidth: CGFloat = 140
    
    // Cards
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 14
    static let cardElementSpacing: CGFloat = 12
    
    // Interactive Elements
    static let minTapTarget: CGFloat = 44
    static let comfortableTapTarget: CGFloat = 32
    
    // Progress Bars
    static let progressBarHeight: CGFloat = 8
}
```

## Visual Tokens

```swift
enum VisualTokens {
    // Overlays
    static let overlayDimOpacity: Double = 0.2
    
    // Shadows
    static let cardShadowColor = Color.black.opacity(0.12)
    static let cardShadowRadius: CGFloat = 18
    static let cardShadowX: CGFloat = 0
    static let cardShadowY: CGFloat = 8
    
    // Colors
    static let cardBackground = Color(.systemGray6)
    static let gridLineOpacity: Double = 0.2
    static let axisLineOpacity: Double = 0.3
    static let chartFillOpacity: Double = 0.18
}
```

## Motion Tokens

```swift
enum MotionTokens {
    // Durations
    static let quickFeedback: Double = 0.2
    static let standardTransition: Double = 0.3
    static let progressFill: Double = 0.5
    static let chartReveal: Double = 0.7
    
    // Curves
    static let defaultCurve = Animation.easeOut
    static let springCurve = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
```

---

# Create/Subcategory Hardening Notes

## Recent Issues

- List row buttons can fail due to row hit-testing; destructive actions become unclickable.
- Popover/swipe delete patterns are unstable on phone and can cause accidental deletion.
- Other-category subcategory menu can disappear from conflicting visibility conditions.
- Custom mode can appear broken if state reset is incomplete (text not cleared, focus not moved).
- AppStorage self-writes can trigger onChange decode loops and UI churn.
- Persistence keys based on display titles are unstable across rename/localization.
- Hint text can conflict with state (saved selection vs new custom entry).
- Max-cap replacement behavior can surprise users when not pre-announced.

## Rules

- Use reliable row actions in `List` (`.buttonStyle(.borderless)` for inline buttons); avoid overlapping delete mechanisms.
- Require confirmation for destructive deletes in management flows.
- Make mode switches atomic: set mode flags, clear conflicting state, and set focus in one action.
- Use stable persistence keys (`seed:<id>`, `__other__`), never display titles.
- Decode persisted JSON only on initial load or true external changes; guard internal writes.
- Keep copy state-aware (enter vs edit, saved vs custom); avoid generic hints.
- If max-cap policy drops oldest items, show warning before save when replacement will occur.

---

# Framework Maintenance

## When to Update This Document

**Add new rules** when:
- A new bug pattern is discovered
- A new layout pattern is established
- A design decision is made that should be consistent

**Update existing rules** when:
- Token values change based on testing
- Better implementation pattern is discovered
- Edge case reveals need for clarification

**Add case studies** when:
- Screenshot reveals overlap issue
- User feedback identifies confusing interaction
- Performance issue is traced to layout pattern

## How to Use This Framework

**During Planning**:
- Review Philosophy section for principles
- Check Invariants for constraints
- Reference Design Tokens for values

**During Implementation**:
- Follow numbered rules (L1, L2, I1, V1, etc.)
- Use provided code patterns
- Reference token values instead of magic numbers

**During QA**:
- Run through applicable checklists
- Verify no NEVER rules violated
- Test on multiple device sizes

**For AI-Assisted Development**:
- Include relevant sections in AI context
- Reference specific rule numbers in prompts
- Use this as source of truth for product decisions

---

*Framework established: 2026-02-11*  
*Last updated: 2026-02-11*
