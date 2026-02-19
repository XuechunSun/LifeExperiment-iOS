# Development Rules & Best Practices

## UI Layout & Positioning

**Rule 1: Inline Layout Over Overlay for Interactive Elements**
- Use `HStack`/`VStack` instead of `.overlay()` when adding interactive elements (buttons, icons) next to dynamic text
- Reason: Overlays can cause overlap when text wraps to multiple lines
- Set explicit `maxWidth` constraints and position-aware alignment to prevent content overflow

**Rule 2: Position-Aware Layout Constraints**
- For radial/circular layouts (e.g., radar chart labels), define explicit frame constraints based on element position
- Use alignment that matches position: `.leading` for left-side, `.trailing` for right-side, `.center` for top/bottom
- Push elements outward sufficiently to avoid overlap with core content

**Rule 3: Accessible Hit Targets**
- Interactive elements must have minimum 44x44pt hit area (use `.padding()` + `.contentShape(Rectangle())`)
- Keep visual size appropriate while ensuring accessibility
- Example: Small icon with `.padding(8)` for larger tap area

## Overlays & Modals

**Rule 4: Subtle Overlay Opacity**
- Use opacity 0.15-0.25 for modal/popup backgrounds (NOT 0.3+)
- Alternative: Use `.ultraThinMaterial` for iOS-native blur effect
- Apply shadows only to content cards, not entire overlay layer

**Rule 5: Shadow Hierarchy**
- Shadow format: `.shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)`
- Only apply to foreground cards, not background overlays
- Avoid double-stacking shadows (overlay + card)

## Data & Sorting

**Rule 6: Stable Sorting with Tie-Breakers**
- Always add secondary sort criteria when primary key can have duplicates
- Pattern:
  ```swift
  .sorted { lhs, rhs in
      if lhs.primaryValue != rhs.primaryValue {
          return lhs.primaryValue > rhs.primaryValue
      }
      return lhs.stableKey < rhs.stableKey  // tie-breaker
  }
  ```
- Use stable keys: `.title`, `.id`, `.rawValue` (alphabetical/deterministic)
- Reason: Prevents UI reordering when unrelated state changes

## SwiftUI State Management

**Rule 7: State Ownership**
- Place `@State` at the appropriate hierarchy level
- Pass `@Binding` down for shared state across components
- Keep overlay state in parent view that owns the overlay, not in child components

## Text & Typography

**Rule 8: Multiline Text Constraints**
- Always set `.lineLimit()` for text in constrained layouts
- Use `.fixedSize(horizontal: false, vertical: true)` to allow vertical expansion
- Match `.multilineTextAlignment()` with frame alignment

---

*Last updated: 2026-02-11*
