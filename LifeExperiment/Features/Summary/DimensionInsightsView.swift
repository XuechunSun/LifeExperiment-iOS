import SwiftUI

// MARK: - Radar Axis Label View

//struct RadarAxisLabelView: View {
//    let shortTitle: String
//    let percentText: String
//    let onInfo: () -> Void
//
//    var body: some View {
//        VStack(spacing: 2) {
//            HStack(spacing: 4) {
//                Text(shortTitle)
//                    .font(.caption)
//                    .foregroundColor(.primary)
//                    .lineLimit(1)
//                    .multilineTextAlignment(.center)
//                    .fixedSize(horizontal: false, vertical: true)
//
//                Button(action: onInfo) {
//                    Image(systemName: "info.circle")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .frame(width: 18, height: 18)
//                }
//                .buttonStyle(.plain)
//                .contentShape(Rectangle())
//            }
//            .frame(maxWidth: .infinity, alignment: .center)
//
//            Text(percentText)
//                .font(.caption2)
//                .foregroundColor(.secondary)
//                .monospacedDigit()
//        }
//        .frame(maxWidth: 110)
//    }
//}

// MARK: - Radar Chart View

struct RadarChartView: View {
    let axes: [Dimension]      // Fixed order = Dimension.allCases
    let values: [Double]       // Normalized 0...1, same count as axes
    let percentages: [Int]     // Percentage values (0-100) for display
    let lang: AppLanguage
    let onInfoTap: (Dimension) -> Void

    @State private var animateProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum LabelAnchorPosition {
        case top
        case topLeading
        case topTrailing
        case leading
        case trailing
        case bottomLeading
        case bottomTrailing
    }

    var body: some View {
        GeometryReader { geometry in
            let labelWidth: CGFloat = 92
            let sideReserve: CGFloat = 44
            let topReserve: CGFloat = 44
            let bottomReserve: CGFloat = 44

            let chartAreaWidth = max(120, geometry.size.width - (sideReserve * 2))
            let chartAreaHeight = max(120, geometry.size.height - topReserve - bottomReserve)

            let center = CGPoint(
                x: geometry.size.width / 2,
                y: topReserve + (chartAreaHeight / 2)
            )

            let gridRadius = max(80, min(chartAreaWidth, chartAreaHeight) / 2 * 1.08)
            let animatedValues = values.map { $0 * animateProgress }

            ZStack {
                // Grid rings
                ForEach([0.33, 0.66, 1.0], id: \.self) { scale in
                    Path { path in
                        drawPolygon(
                            path: &path,
                            center: center,
                            radius: gridRadius * scale,
                            sides: axes.count
                        )
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }

                // Axis lines
                ForEach(Array(axes.indices), id: \.self) { index in
                    Path { path in
                        let angle = angleForIndex(index, totalCount: axes.count)
                        let point = pointOnCircle(center: center, radius: gridRadius, angle: angle)
                        path.move(to: center)
                        path.addLine(to: point)
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }

                // Filled polygon
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
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Stroke polygon
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
                .stroke(Color.blue, lineWidth: 2.5)

                // Compact labels around chart
                ForEach(Array(axes.indices), id: \.self) { index in
                    let dimension = axes[index]
                    let percentage = percentages[index]
                    let anchor = anchorPosition(for: index, totalCount: axes.count)
                    let point = labelPosition(
                        in: geometry.size,
                        center: center,
                        gridRadius: gridRadius,
                        anchor: anchor,
                        labelWidth: labelWidth
                    )

                    RadarAxisLabelView(
                        shortTitle: L.dimensionShortLabel(lang, dimension: dimension),
                        percentText: "\(percentage)%",
                        onInfo: { onInfoTap(dimension) }
                    )
                    .frame(width: labelWidth)
                    .position(point)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if reduceMotion {
                    animateProgress = 1.0
                } else {
                    withAnimation(.easeOut(duration: 0.7)) {
                        animateProgress = 1.0
                    }
                }
            }
            .onChange(of: values) { oldValue, newValue in
                if !reduceMotion && animateProgress >= 1.0 {
                    animateProgress = 0
                    withAnimation(.easeOut(duration: 0.7)) {
                        animateProgress = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Anchor Layout

    private func anchorPosition(for index: Int, totalCount: Int) -> LabelAnchorPosition {
        // Assumes 7 axes starting from top, then clockwise.
        if totalCount == 7 {
            switch index {
            case 0: return .top
            case 1: return .topTrailing
            case 2: return .trailing
            case 3: return .bottomTrailing
            case 4: return .bottomLeading
            case 5: return .leading
            case 6: return .topLeading
            default: return .top
            }
        }

        // Safe fallback
        let angle = angleForIndex(index, totalCount: totalCount)
        if angle > -.pi / 6 && angle < .pi / 6 { return .trailing }
        if angle >= .pi / 6 && angle < 5 * .pi / 6 { return .bottomTrailing }
        if angle <= -5 * .pi / 6 || angle >= 5 * .pi / 6 { return .leading }
        if angle < -.pi / 6 && angle > -5 * .pi / 6 { return .topTrailing }
        return .top
    }

    private func labelPosition(
        in size: CGSize,
        center: CGPoint,
        gridRadius: CGFloat,
        anchor: LabelAnchorPosition,
        labelWidth: CGFloat
    ) -> CGPoint {
        let dx = gridRadius + 26
        let dy = gridRadius + 18

        let rawPoint: CGPoint
        switch anchor {
        case .top:
            rawPoint = CGPoint(x: center.x, y: center.y - dy)
        case .topLeading:
            rawPoint = CGPoint(x: center.x - dx, y: center.y - dy * 0.65)
        case .topTrailing:
            rawPoint = CGPoint(x: center.x + dx, y: center.y - dy * 0.65)
        case .leading:
            rawPoint = CGPoint(x: center.x - dx - 24, y: center.y)
        case .trailing:
            rawPoint = CGPoint(x: center.x + dx + 28, y: center.y)
        case .bottomLeading:
            rawPoint = CGPoint(x: center.x - dx * 0.82, y: center.y + dy * 0.84)
        case .bottomTrailing:
            rawPoint = CGPoint(x: center.x + dx * 0.82, y: center.y + dy * 0.84)
        }

        let halfWidth = labelWidth / 2
        let clampedX = min(max(rawPoint.x, halfWidth + 0.1), size.width - halfWidth - 0.1)
        let clampedY = min(max(rawPoint.y, 22), size.height - 24)

        return CGPoint(x: clampedX, y: clampedY)
    }

    // MARK: - Geometry Helpers

    private func angleForIndex(_ index: Int, totalCount: Int) -> Double {
        let angleStep = 2.0 * .pi / Double(totalCount)
        return -.pi / 2.0 + Double(index) * angleStep
    }

    private func pointOnCircle(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle)),
            y: center.y + radius * CGFloat(sin(angle))
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
}

struct RadarAxisLabelView: View {
    let shortTitle: String
    let percentText: String
    let onInfo: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Text(shortTitle)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .allowsTightening(true)

                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Text(percentText)
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Growth Bar Row

struct GrowthBarRow: View {
    let title: String
    let days: Int
    let maxDays: Int
    let lang: AppLanguage

    @State private var animatedFraction: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetFraction: Double {
        maxDays > 0 ? Double(days) / Double(maxDays) : 0
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(DSText.subheadline)
                .foregroundColor(.primary)
                .frame(width: 112, alignment: .leading)

            // Bar track with fill (responsive to available width, animated)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5).opacity(0.7))
                    .frame(height: 8)

                GeometryReader { geometry in
                    let fillWidth = geometry.size.width * min(1.0, max(0.0, animatedFraction))

                    Capsule()
                        //.fill(Color.blue)
                        // .fill(
                        //     LinearGradient(
                        //         colors: [
                        //             Color.blue.opacity(0.7),
                        //             Color.purple.opacity(0.5)
                        //         ],
                        //         startPoint: .leading,
                        //         endPoint: .trailing
                        //     )
                        // )
                        //.fill(Color(red: 0.35, green: 0.55, blue: 0.85))
                        .fill(Color.accentColor.opacity(0.6))
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

            Text(L.summaryGrowthBarDays(lang, count: days))
                .font(DSText.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(minWidth: 64, alignment: .trailing)
        }
    }
}

// MARK: - Dimension Insights (v1)

struct DimensionInsightsView: View {
    let experiments: [Experiment]
    @State private var selectedDimensionForInfo: Dimension? = nil
    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

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

    private var hasGrowthEligibleExperiments: Bool {
        experiments.contains { exp in
            (exp.status == .active || exp.status == .completed) &&
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
        uniqueGrowthLoggedDays.count
    }

    private var uniqueGrowthLoggedDays: Set<Date> {
        experiments.reduce(into: Set<Date>()) { result, experiment in
            guard (experiment.status == .active || experiment.status == .completed),
                  experiment.impact != nil,
                  !validLogDays(for: experiment).isEmpty else {
                return
            }
            result.formUnion(validLogDays(for: experiment))
        }
    }

    private var maxDaysInGrowth: Int {
        sortedDimensionsByDays.map { $0.1 }.max() ?? 1
    }

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            SectionBlock(
                title: L.summaryYourStrength(lang),
                subtitle: L.summaryYourStrengthSubtitle(lang),
                style: .strength
            ) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    if hasEligibleExperiments {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text(L.summaryPatternsSoFar(lang))
                                .font(DSText.caption)
                                .foregroundColor(.secondary.opacity(0.85))
                                .padding(.leading, 22)
                        }

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
                            lang: lang,
                            onInfoTap: { dimension in
                                selectedDimensionForInfo = dimension
                            }
                        )
                        .frame(height: 278)
                        .padding(.top, DSSpacing.sm)

                        Text(L.summaryStrengthFooter(lang))
                            .lifeCaption()
                            .padding(.top, DSSpacing.xxs)
                    } else {
                        Text(L.summaryStrengthEmpty(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, DSSpacing.md)
                    }
                }
            }
            .alert(
                selectedDimensionForInfo.map { L.dimensionDisplayTitle(lang, dimension: $0) } ?? "",
                isPresented: Binding(
                    get: { selectedDimensionForInfo != nil },
                    set: { if !$0 { selectedDimensionForInfo = nil } }
                )
            ) {
                Button(L.actionOK(lang), role: .cancel) {
                    selectedDimensionForInfo = nil
                }
            } message: {
                Text(L.summaryDimensionInfoMessage(lang))
            }

            if hasGrowthEligibleExperiments && !sortedDimensionsByDays.isEmpty {
                SectionBlock(
                    title: L.summaryYourGrowth(lang),
                    subtitle: L.summaryYourGrowthSubtitle(lang),
                    style: .growth
                ) {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        // Bar list (sorted by count, descending)
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            ForEach(sortedDimensionsByDays, id: \.0) { dimension, days in
                                GrowthBarRow(
                                    title: L.dimensionShortLabel(lang, dimension: dimension),
                                    days: days,
                                    maxDays: maxDaysInGrowth,
                                    lang: lang
                                )
                            }
                        }

                        // Bottom info (total days + footnote)
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text(L.profileShownUp(lang, count: totalLoggedDays))
                                .font(DSText.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()

                            Text(L.summaryHiddenDimensionsNote(lang))
                                .font(DSText.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(.top, DSSpacing.md)
                    }
                }
            }
        }
    }
}

