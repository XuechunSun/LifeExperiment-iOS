# AI Development Framework — MiniLab

Welcome to the MiniLab (formerly LifeExperiment) development documentation. This framework helps maintain product consistency, prevent bugs, and guide AI-assisted development.

**App**: MiniLab · `com.xuechunsun.minilab` · iOS 17.0+ · iPhone only  
**Status**: v1.1 live on App Store (build 3). Local: build 4 in progress.

## Purpose

These docs serve as:
- **Product truth**: Canonical source for product decisions and logic
- **Bug prevention**: Rules and invariants to avoid past mistakes
- **AI context**: Reference material for AI-assisted development
- **Onboarding**: Quick ramp-up for new contributors

## Documentation Structure

### Core Product & Logic
- **[Product Rules](./product_rules.md)** - High-level product decisions, feature specs, and user experience patterns
- **[Summary Logic](./summary_logic.md)** - Strength vs Growth calculations, valid log definitions, scoring formulas
- **[Dimension Weighting Rules](./dimension_weighting_rules.md)** - How experiment impacts are calculated and displayed

### Implementation Guidelines
- **[UI Guidelines](./ui_guidelines.md)** - Layout patterns, accessibility, overlays, and visual consistency
- **[State Management](./state_management.md)** - SwiftUI state patterns and data flow
- **[Debugging Principles](./debugging_principles.md)** - Systematic approach to investigating and fixing issues

## How to Use This Framework

### During Development
1. **Before implementing a feature**: Review relevant docs to understand constraints and patterns
2. **When making product decisions**: Document in appropriate file with rationale
3. **When fixing bugs**: Check if a new rule should be added to prevent recurrence

### For AI-Assisted Development
Include relevant doc sections in context when:
- Implementing new features related to Summary, dimensions, or core calculations
- Fixing UI layout issues or state management bugs
- Making changes to experiment lifecycle or log validation

### Maintenance
- **Update docs** when product decisions change
- **Add edge cases** when new bugs are discovered
- **Refine rules** as patterns emerge

## Quick Reference

| I need to... | Check this doc |
|--------------|----------------|
| Understand Strength vs Growth | [Summary Logic](./summary_logic.md) |
| Know which experiments count toward metrics | [Summary Logic](./summary_logic.md) → Valid Log Rules |
| Implement dimension selection UI | [Dimension Weighting Rules](./dimension_weighting_rules.md) |
| Fix overlay positioning issues | [UI Guidelines](./ui_guidelines.md) → Overlays & Modals |
| Understand tab navigation | [Product Rules](./product_rules.md) → Navigation |
| Debug unstable sorting | [Debugging Principles](./debugging_principles.md) + [UI Guidelines](./ui_guidelines.md) → Stable Sorting |
| Manage experiment list actions | [Product Rules](./product_rules.md) → Experiment Actions |
| Check what's shipped vs pending | [Shipping Plan](./shipping_plan.md) |

## Contributing

When you encounter a bug or make a product decision:
1. Fix/implement the change
2. Document the decision or add a rule to prevent recurrence
3. Update relevant checklist or edge case section
4. Keep docs concise and actionable

---

*Framework established: 2026-02-11 · Last updated: 2026-08-09*
