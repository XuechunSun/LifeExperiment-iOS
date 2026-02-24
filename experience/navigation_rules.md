# Navigation Rules

## Identity & Navigation Engineering Rules

- Normalize `Date` to the intended granularity (`startOfDay` / `startOfMonth`) before using it as identity.
- Do not depend on raw `Date` equality for `scrollTo`, `.id`, or navigation state.
- For `navigationDestination(item:)`, wrap value types in explicit `Identifiable` structs.
- Navigation state ownership must match view ownership.
- Avoid mixing global path-based navigation and local item-based navigation without clear boundaries.
- Ensure `scrollTo` targets exactly match the corresponding `.id` source.
- Cache `DateFormatter` instances; never instantiate formatters during render.
- Prefer scroll-based layouts over paged controls for chronological data.

---

## State Stability Rules

- State ownership must be explicit and intentional.
- The view that creates state should own and manage it unless sharing is required.
- Avoid mutating parent navigation paths from child views unless explicitly designed.
- Prefer local `@State` for view-local transitions; use bindings only when state must propagate upward.
- Maintain a single source of truth for persistent data.
- Do not mix transient UI state with persistent model state.
- During refactor, preserve state ownership boundaries before modifying UI structure.
- Stabilize identity and navigation before adding new features or visual polish.