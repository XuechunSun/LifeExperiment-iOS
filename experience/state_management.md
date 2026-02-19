# State Management

## Purpose

This document defines SwiftUI state management patterns used in LifeExperiment, including when to use `@State`, `@Binding`, `@Environment`, and how to structure data flow.

---

## Core Principles

1. **Single Source of Truth**: Each piece of state has one canonical owner
2. **Explicit Data Flow**: State flows down, events flow up
3. **Minimal State**: Only store what can't be computed
4. **Appropriate Scope**: Place state at the right hierarchy level

---

## State Ownership Patterns

### @State (Private, Local State)

**Use when**: State is owned and managed entirely within a single view.

**Examples**:
- UI toggles (sheet presentation, picker selection)
- Temporary form input
- Animation states
- Overlay visibility

**Pattern**:
```swift
struct MyView: View {
    @State private var showSheet = false
    @State private var selectedItem: Item? = nil
    
    var body: some View {
        Button("Show") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            DetailView()
        }
    }
}
```

**Rules**:
- Always mark as `private`
- Initialize with default value
- Don't pass to sibling views (use `@Binding` instead)

---

### @Binding (Shared Reference)

**Use when**: Child view needs to read and modify parent's state.

**Examples**:
- Form fields that update parent
- Toggle switches controlling parent state
- Picker selections
- Shared overlay state

**Pattern**:
```swift
// Parent (owner)
struct ParentView: View {
    @State private var selectedDimension: Dimension? = nil
    
    var body: some View {
        ChildView(selectedDimension: $selectedDimension)
    }
}

// Child (consumer)
struct ChildView: View {
    @Binding var selectedDimension: Dimension?
    
    var body: some View {
        Button("Select") {
            selectedDimension = .execution
        }
    }
}
```

**Rules**:
- Use `$` prefix when passing `@State` to `@Binding`
- Child can read and write
- Parent remains source of truth

---

### @Environment (Shared Global State)

**Use when**: State is truly global or provided by system.

**Examples**:
- Color scheme (light/dark mode)
- Presentation mode (dismiss)
- Managed object context (Core Data)

**Pattern**:
```swift
struct MyView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button("Dismiss") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
```

**Note**: Not used for app-specific state in LifeExperiment (we use explicit passing).

---

## Navigation State Patterns

### Tab Selection

**Owner**: Root `ContentView`  
**Type**: `@State private var selectedTab: Tab = .home`  
**Scope**: Global (affects entire tab bar)

**Pattern**:
```swift
struct ContentView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)
            // ... other tabs
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == .create {
                showCreateSheet = true
            }
        }
    }
}
```

---

### Navigation Path (Per Tab)

**Owner**: Each tab's root view  
**Type**: `@State private var path: [Route] = []`  
**Scope**: Per-tab (isolated)

**Pattern**:
```swift
struct HomeView: View {
    @State private var path: [Route] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            // Root content
            List { /* ... */ }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .experimentDetail(let experiment):
                        ExperimentDetailView(experiment: experiment)
                    // ... other routes
                    }
                }
        }
    }
}
```

**Rules**:
- Each tab has independent `NavigationStack`
- `path` is private to that tab
- Don't share `path` across tabs

---

### Sheet Presentation

**Owner**: View that presents the sheet  
**Type**: `@State private var showSheet = false`  
**Scope**: Local to presenter

**Pattern**:
```swift
struct ListView: View {
    @State private var showCreateSheet = false
    
    var body: some View {
        List { /* ... */ }
            .sheet(isPresented: $showCreateSheet) {
                CreateView()
            }
    }
}
```

---

## Overlay State Patterns

### Simple Overlay (Owned by Parent)

**Use when**: Overlay is tightly coupled to parent view.

**Pattern**:
```swift
struct CardView: View {
    @State private var showInfo: Bool = false
    
    var body: some View {
        VStack { /* content */ }
            .overlay {
                if showInfo {
                    InfoOverlay(onDismiss: { showInfo = false })
                }
            }
    }
}
```

**Rules**:
- Parent owns `showInfo` state
- Child receives dismiss callback
- Overlay doesn't own its own visibility

---

### Complex Overlay (Shared State)

**Use when**: Overlay is triggered from multiple child components.

**Pattern**:
```swift
struct ParentView: View {
    @State private var selectedDimension: Dimension? = nil
    
    var body: some View {
        VStack {
            RadarChart(selectedDimension: $selectedDimension)
            DimensionList(selectedDimension: $selectedDimension)
        }
        .overlay {
            if let dim = selectedDimension {
                DimensionInfoOverlay(
                    dimension: dim,
                    onDismiss: { selectedDimension = nil }
                )
            }
        }
    }
}
```

**Rules**:
- Parent owns `selectedDimension`
- Multiple children can trigger via `@Binding`
- Overlay is at parent level (common ancestor)

---

## Data Flow Patterns

### Pattern 1: Computed Properties

**Use when**: Value can be derived from other state.

**Example**:
```swift
struct SummaryView: View {
    let experiments: [Experiment]
    
    // ✅ GOOD: Computed from experiments
    private var eligibleExperiments: [Experiment] {
        experiments.filter { 
            $0.status == .completed && 
            !validLogDays(for: $0).isEmpty 
        }
    }
    
    // ❌ BAD: Don't store as @State
    // @State private var eligibleExperiments: [Experiment] = []
}
```

**Rules**:
- Use computed `var` for derived state
- Recomputes on each access (SwiftUI caches efficiently)
- No manual synchronization needed

---

### Pattern 2: Callbacks for Events

**Use when**: Child needs to notify parent of action.

**Pattern**:
```swift
// Parent
struct ListView: View {
    let experiments: [Experiment]
    
    var body: some View {
        ForEach(experiments) { exp in
            ExperimentRow(
                experiment: exp,
                onDelete: { deleteExperiment(exp) }
            )
        }
    }
    
    func deleteExperiment(_ exp: Experiment) {
        // Handle deletion
    }
}

// Child
struct ExperimentRow: View {
    let experiment: Experiment
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(experiment.title)
            Button("Delete") { onDelete() }
        }
    }
}
```

**Rules**:
- Child doesn't modify parent state directly
- Parent provides closure for events
- Keeps responsibilities clear

---

## Common State Management Pitfalls

### Pitfall 1: Duplicating State

**Problem**: Storing derived state separately from source.

**Example**:
```swift
// ❌ BAD
struct MyView: View {
    @State private var experiments: [Experiment]
    @State private var completedCount: Int  // Duplicate!
    
    func updateExperiments() {
        experiments = fetchExperiments()
        completedCount = experiments.filter { $0.status == .completed }.count
    }
}

// ✅ GOOD
struct MyView: View {
    @State private var experiments: [Experiment]
    
    private var completedCount: Int {
        experiments.filter { $0.status == .completed }.count
    }
}
```

---

### Pitfall 2: Wrong State Owner

**Problem**: State owned by view that doesn't control it.

**Example**:
```swift
// ❌ BAD: Overlay owns its own visibility
struct InfoOverlay: View {
    @State private var isVisible = true  // Who sets this?
    
    var body: some View {
        if isVisible { /* ... */ }
    }
}

// ✅ GOOD: Parent owns visibility
struct ParentView: View {
    @State private var showOverlay = false
    
    var body: some View {
        Button("Show") { showOverlay = true }
            .overlay {
                if showOverlay {
                    InfoOverlay(onDismiss: { showOverlay = false })
                }
            }
    }
}
```

---

### Pitfall 3: Passing State Sideways

**Problem**: Trying to share state between sibling views.

**Example**:
```swift
// ❌ BAD: Can't pass @State between siblings
struct ParentView: View {
    var body: some View {
        HStack {
            SiblingA()
            SiblingB()  // How does this access SiblingA's state?
        }
    }
}

// ✅ GOOD: Lift state to parent
struct ParentView: View {
    @State private var sharedValue = 0
    
    var body: some View {
        HStack {
            SiblingA(value: $sharedValue)
            SiblingB(value: $sharedValue)
        }
    }
}
```

**Rule**: If siblings need to share state, lift it to their common parent.

---

### Pitfall 4: Forgetting to Invalidate Derived State

**Problem**: Not using computed properties for derived values.

**Example**:
```swift
// ❌ BAD: Manual update required
struct SummaryView: View {
    @State private var experiments: [Experiment]
    @State private var sortedExperiments: [Experiment] = []
    
    func updateExperiments() {
        experiments = fetchExperiments()
        sortedExperiments = experiments.sorted { $0.createdAt > $1.createdAt }  // Easy to forget!
    }
}

// ✅ GOOD: Automatic update
struct SummaryView: View {
    @State private var experiments: [Experiment]
    
    private var sortedExperiments: [Experiment] {
        experiments.sorted { $0.createdAt > $1.createdAt }
    }
}
```

---

## State Management Checklist

Before implementing new features, verify:

### State Ownership
- [ ] Each piece of state has clear owner (one source of truth)
- [ ] `@State` is `private` and owned by the view
- [ ] `@Binding` is used for child views that need to modify parent state
- [ ] Shared state is lifted to common ancestor

### Data Flow
- [ ] State flows down (parent → child via props/bindings)
- [ ] Events flow up (child → parent via callbacks)
- [ ] No sideways state passing between siblings

### Computed State
- [ ] Derived values use computed `var` (not @State)
- [ ] No duplicate state (storing both source and derived)
- [ ] Computed properties are pure (no side effects)

### Overlay State
- [ ] Overlay visibility owned by parent (not by overlay itself)
- [ ] Overlay placed at common ancestor level
- [ ] Multiple children can trigger via `@Binding`

### Navigation State
- [ ] Each tab has independent `NavigationStack`
- [ ] Navigation paths are private to tab
- [ ] Sheet presentation state is local to presenter

---

## Pattern Reference

### Pattern: Simple Toggle

```swift
@State private var isEnabled = false

Toggle("Enable", isOn: $isEnabled)
```

---

### Pattern: Optional Selection

```swift
@State private var selectedItem: Item? = nil

Button("Select") {
    selectedItem = someItem
}
.sheet(item: $selectedItem) { item in
    DetailView(item: item)
}
```

---

### Pattern: List with Selection

```swift
@State private var selectedID: UUID? = nil

List(items, selection: $selectedID) { item in
    Text(item.name)
}
```

---

### Pattern: Multi-Component Shared State

```swift
// Parent
@State private var filterText = ""

VStack {
    SearchBar(text: $filterText)
    FilteredList(filterText: filterText)
}
```

---

*Last updated: 2026-02-11*
