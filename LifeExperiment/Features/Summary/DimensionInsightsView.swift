import SwiftUI

// MARK: - Radar Axis Label View

struct RadarAxisLabelView: View {
    let title: String
    let percentText: String
    let angle: Double
    let onInfo: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            // Title with info icon (baseline-aligned)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(textAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32) // Tap target
                }
                .contentShape(Rectangle())
                .fixedSize()
            }

            // Percentage
            Text(percentText)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: labelMaxWidth, alignment: frameAlignment)
    }

    // MARK: - Quadrant-based alignment

    private var labelMaxWidth: CGFloat {
        // Tighter width for bottom labels to prevent horizontal collision
        if isBottomLabel {
            return 140
        }
        return 160
    }

    private var textAlignment: TextAlignment {
        let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        // Right side (0 ± 45°)
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

    private var frameAlignment: Alignment {
        let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        if normalized > -.pi / 4 && normalized < .pi / 4 {
            return .leading
        }
        else if normalized > 3 * .pi / 4 || normalized < -3 * .pi / 4 {
            return .trailing
        }
        else {
            return .center
        }
    }

    private var isBottomLabel: Bool {
        let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        // Bottom quadrant (roughly 45° to 135° in normalized space)
        return normalized > .pi / 4 && normalized < 3 * .pi / 4
    }
}

// MARK: - Radar Chart View

struct RadarChartView: View {
    let axes: [Dimension]      // Fixed order = Dimension.allCases
    let values: [Double]       // Normalized 0...1, same count as axes
    let percentages: [Int]     // Percentage values (0-100) for display
    @Binding var selectedDimension: Dimension?

    @State private var animateProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Layout Constants

    /// Base margin between grid boundary and label placement
    private let labelMargin: CGFloat = 55

    /// Extra spacing for bottom labels (prevents vertical collision with footnote)
    private let bottomLabelExtraMargin: CGFloat = 35

    /// Additional directional nudge to reduce collisions
    private let nudgeAmount: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let gridRadius = size * 0.35
            let baseLabelRadius = gridRadius + labelMargin
            let animatedValues = values.map { $0 * animateProgress }

            ZStack {
                // Grid rings at 0.33, 0.66, 1.0
                ForEach([0.33, 0.66, 1.0], id: \.self) { scale in
                    Path { path in
                        drawPolygon(path: &path, center: center, radius: gridRadius * scale, sides: axes.count)
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }

                // Axis lines from center to vertices
                ForEach(0..<axes.count, id: \.self) { index in
                    Path { path in
                        let angle = angleForIndex(index, totalCount: axes.count)
                        let point = pointOnCircle(center: center, radius: gridRadius, angle: angle)
                        path.move(to: center)
                        path.addLine(to: point)
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }

                // Value polygon (filled) - animated
                Path { path in
                    for (index, value) in animatedValues.enumerated() {
                        let angle = angleForIndex(index, totalCount: axes.count)
                        let point = pointOnCircle(center: center, radius: gridRadius * value, angle: angle)
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.18))

                // Value polygon (stroke) - animated
                Path { path in
                    for (index, value) in animatedValues.enumerated() {
                        let angle = angleForIndex(index, totalCount: axes.count)
                        let point = pointOnCircle(center: center, radius: gridRadius * value, angle: angle)
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color.blue, lineWidth: 2)

                // Dimension labels with percentages and info icons
                ForEach(0..<axes.count, id: \.self) { index in
                    let dimension = axes[index]
                    let percentage = percentages[index]
                    let angle = angleForIndex(index, totalCount: axes.count)

                    // Use extra margin for bottom labels to prevent vertical collision
                    let effectiveLabelRadius = isBottomLabel(angle: angle)
                        ? baseLabelRadius + bottomLabelExtraMargin
                        : baseLabelRadius

                    let baseLabelPoint = pointOnCircle(center: center, radius: effectiveLabelRadius, angle: angle)

                    // Apply directional nudge to reduce collisions
                    let nudge = nudgeOffset(for: angle)
                    let labelPoint = CGPoint(
                        x: baseLabelPoint.x + nudge.width,
                        y: baseLabelPoint.y + nudge.height
                    )

                    RadarAxisLabelView(
                        title: dimension.title,
                        percentText: "\(percentage)%",
                        angle: angle,
                        onInfo: { selectedDimension = dimension }
                    )
                    .position(labelPoint)
                }
            }
            .onAppear {
                if reduceMotion {
                    animateProgress = 1.0
                } else {
                    withAnimation(.easeOut(duration: 0.7)) {
                        animateProgress = 1.0
                    }
                }
            }
            .onChange(of: values) {
                // Re-animate if values change meaningfully
                if !reduceMotion && animateProgress >= 1.0 {
                    animateProgress = 0
                    withAnimation(.easeOut(duration: 0.7)) {
                        animateProgress = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    /// Calculates directional nudge to push labels further from grid based on angle
    /// This prevents label-to-grid and label-to-label collisions
    private func nudgeOffset(for angle: Double) -> CGSize {
        let dx = cos(angle) * nudgeAmount
        let dy = sin(angle) * nudgeAmount
        return CGSize(width: dx, height: dy)
    }

    /// Determines if a label is in the bottom quadrant (needs extra spacing)
    private func isBottomLabel(angle: Double) -> Bool {
        let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        // Bottom half (roughly 45° to 135° in unit circle space)
        return normalized > .pi / 4 && normalized < 3 * .pi / 4
    }

    private func angleForIndex(_ index: Int, totalCount: Int) -> Double {
        // Start from top (90 degrees = -π/2) and go clockwise
        let angleStep = 2.0 * .pi / Double(totalCount)
        return -.pi / 2.0 + Double(index) * angleStep
    }

    private func pointOnCircle(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    private func drawPolygon(path: inout Path, center: CGPoint, radius: Double, sides: Int) {
        for i in 0..<sides {
            let angle = angleForIndex(i, totalCount: sides)
            let point = pointOnCircle(center: center, radius: radius, angle: angle)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
    }

    private func textAlignmentForAngle(_ angle: Double) -> TextAlignment {
        let normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        if normalized > -.pi / 4 && normalized < .pi / 4 {
            return .leading
        } else if normalized > 3 * .pi / 4 || normalized < -3 * .pi / 4 {
            return .trailing
        } else {
            return .center
        }
    }
}

// MARK: - Growth Bar Row

struct GrowthBarRow: View {
    let title: String
    let days: Int
    let maxDays: Int

    @State private var animatedFraction: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetFraction: Double {
        maxDays > 0 ? Double(days) / Double(maxDays) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.primary)
                .frame(width: 140, alignment: .leading)

            // Bar track with fill (responsive to available width, animated)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 8)

                GeometryReader { geometry in
                    let fillWidth = geometry.size.width * min(1.0, max(0.0, animatedFraction))

                    Capsule()
                        .fill(Color.blue)
                        .frame(width: fillWidth, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 8)
            .onAppear {
                if reduceMotion {
                    animatedFraction = targetFraction
                } else {
                    withAnimation(.easeOut(duration: 0.5)) {
                        animatedFraction = targetFraction
                    }
                }
            }
            .onChange(of: targetFraction) { _, newValue in
                if reduceMotion {
                    animatedFraction = newValue
                } else {
                    withAnimation(.easeOut(duration: 0.5)) {
                        animatedFraction = newValue
                    }
                }
            }

            Text("\(days) \(days == 1 ? "day" : "days")")
                .font(.footnote)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)
        }
    }
}

// MARK: - Dimension Insights (v1)

struct DimensionInsightsView: View {
    let experiments: [Experiment]

    @State private var selectedDimension: Dimension? = nil

    // MARK: - Calculation Logic

    // MARK: - Helper: Valid Log Days

    private func validLogDays(for experiment: Experiment) -> Set<Date> {
        let calendar = Calendar.current
        return Set(experiment.logs.compactMap { log -> Date? in
            // Valid if note is non-empty (after trim) OR mood is set
            let trimmedNote = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedNote.isEmpty || log.mood != nil else { return nil }
            return calendar.startOfDay(for: log.date)
        })
    }

    private struct DimensionScore {
        var totalWeighted: Double = 0.0
        var totalPossible: Double = 0.0

        var percentage: Double {
            guard totalPossible > 0 else { return 0 }
            return totalWeighted / totalPossible
        }
    }

    // MARK: - Strength Calculation

    private var dimensionScores: [Dimension: DimensionScore] {
        var scores: [Dimension: DimensionScore] = [:]

        // Initialize all dimensions
        for dimension in Dimension.allCases {
            scores[dimension] = DimensionScore()
        }

        // RULE 2: Strength uses only completed experiments with at least 1 valid log day
        let eligibleExperiments = experiments.filter { exp in
            exp.status == .completed &&
            exp.impact != nil &&
            !validLogDays(for: exp).isEmpty
        }

        // Aggregate scores
        for experiment in eligibleExperiments {
            guard let impact = experiment.impact else { continue }

            // Calculate experiment score (0-2)
            let experimentScore = calculateExperimentScore(experiment)

            // Distribute score to dimensions with weights
            var dimensionWeights: [(Dimension, Double)] = [(impact.primary, 1.0)]

            if let secondary = impact.secondary {
                dimensionWeights.append((secondary, 0.5))
            }

            if let tertiary = impact.tertiary {
                dimensionWeights.append((tertiary, 0.2))
            }

            for (dimension, weight) in dimensionWeights {
                scores[dimension]?.totalWeighted += experimentScore * weight
                scores[dimension]?.totalPossible += 2.0
            }
        }

        return scores
    }

    private func calculateExperimentScore(_ experiment: Experiment) -> Double {
        let completion = 1.0

        // Calculate actualDays using helper
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
            plannedDays = max(7, min(30, computedDays))
        }

        // Calculate consistency (0-1)
        let consistency = plannedDays > 0 ? min(1.0, Double(actualDays) / Double(plannedDays)) : 0.0

        return completion + consistency
    }

    private var hasEligibleExperiments: Bool {
        experiments.contains { exp in
            exp.status == .completed &&
            exp.impact != nil &&
            !validLogDays(for: exp).isEmpty
        }
    }

    // MARK: - Growth Calculation (Accumulated Days)

    private var dimensionDays: [Dimension: Int] {
        var dayCounts: [Dimension: Set<Date>] = [:]

        // Initialize all dimensions
        for dimension in Dimension.allCases {
            dayCounts[dimension] = Set<Date>()
        }

        // RULE 3: Growth includes active + completed experiments with at least 1 valid log day
        let eligibleExperiments = experiments.filter { exp in
            (exp.status == .active || exp.status == .completed) &&
            exp.impact != nil &&
            !validLogDays(for: exp).isEmpty
        }

        // Count unique days per dimension
        for experiment in eligibleExperiments {
            guard let impact = experiment.impact else { continue }

            // Get all valid log days using helper (consistent definition)
            let validDays = validLogDays(for: experiment)

            // Add days to primary dimension
            dayCounts[impact.primary]?.formUnion(validDays)

            // Add days to secondary dimension if present
            if let secondary = impact.secondary {
                dayCounts[secondary]?.formUnion(validDays)
            }

            // Add days to tertiary dimension if present
            if let tertiary = impact.tertiary {
                dayCounts[tertiary]?.formUnion(validDays)
            }
        }

        // Convert to counts
        return dayCounts.mapValues { $0.count }
    }

    private var sortedDimensionsByDays: [(Dimension, Int)] {
        dimensionDays
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in
                // Primary sort: days descending
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                // Tie-breaker: Dimension.allCases order (stable, deterministic)
                let lhsIndex = Dimension.allCases.firstIndex(of: lhs.key) ?? 0
                let rhsIndex = Dimension.allCases.firstIndex(of: rhs.key) ?? 0
                return lhsIndex < rhsIndex
            }
    }

    private var totalLoggedDays: Int {
        sortedDimensionsByDays.reduce(0) { $0 + $1.1 }
    }

    private var maxDaysInGrowth: Int {
        sortedDimensionsByDays.map { $0.1 }.max() ?? 1
    }

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // PART 1: Strength (Current Profile) - Radar Chart
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Text("Your Strength (Current Profile)")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Explanation text (single paragraph, 2 lines max)
                Text("This reflects your current strengths based on completed experiments and consistency. It may change over time — and that's normal.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)

                if hasEligibleExperiments {
                    // Radar chart with inline percentages on labels
                    let axes = Dimension.allCases
                    let values = axes.map { dimension in
                        dimensionScores[dimension]?.percentage ?? 0.0
                    }
                    let percentages = axes.map { dimension in
                        Int((dimensionScores[dimension]?.percentage ?? 0.0) * 100)
                    }

                    RadarChartView(
                        axes: axes,
                        values: values,
                        percentages: percentages,
                        selectedDimension: $selectedDimension
                    )
                    .frame(height: 300)
                    .padding(.vertical, 16)

                    // Footnote at bottom (with sufficient spacing to avoid label overlap)
                    Text("* Based on completed experiments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 12)
                } else {
                    // Empty state
                    Text("Complete an experiment to see insights here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 16)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(14)
            .overlay {
                // Info overlay with subtle dim background
                if let dimension = selectedDimension {
                    ZStack {
                        // Subtle dimmed background
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                            .onTapGesture {
                                selectedDimension = nil
                            }

                        // Info card with proper shadow
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(dimension.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                Button(action: {
                                    selectedDimension = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text(dimension.blurb)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
                        .padding(.horizontal, 40)
                    }
                }
            }

            // PART 2: Growth (Accumulated Effort) - Bar Chart
            if hasEligibleExperiments && !sortedDimensionsByDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    Text("Your Growth")
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Explanation text (single paragraph, 2 lines max)
                    Text("Every day you tried counts. This reflects the time you've invested — nothing more, nothing less.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)

                    // Bar list (sorted by count, descending)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(sortedDimensionsByDays, id: \.0) { dimension, days in
                            GrowthBarRow(
                                title: dimension.title,
                                days: days,
                                maxDays: maxDaysInGrowth
                            )
                        }
                    }
                    .padding(.top, 12)

                    // Bottom info (total days + footnote)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total logged days: \(totalLoggedDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()

                        Text("* Dimensions with 0 days are hidden for now.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.top, 12)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
            }
        }
    }
}

