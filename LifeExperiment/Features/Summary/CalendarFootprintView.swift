import SwiftUI

// MARK: - Calendar Footprint Module

struct CalendarFootprintView: View {
    let experiments: [Experiment]
    let onSelectDay: (Date) -> Void
    @State private var weekOffset: Int = 0

    // Find the earliest and latest activity dates across all experiments
    private var activityDateRange: (earliest: Date, latest: Date) {
        var minDate: Date?
        var maxDate: Date?

        for experiment in experiments {
            // Check createdAt
            if minDate == nil || experiment.createdAt < minDate! {
                minDate = experiment.createdAt
            }
            if maxDate == nil || experiment.createdAt > maxDate! {
                maxDate = experiment.createdAt
            }

            // Check log dates
            for log in experiment.logs {
                if minDate == nil || log.date < minDate! {
                    minDate = log.date
                }
                if maxDate == nil || log.date > maxDate! {
                    maxDate = log.date
                }
            }

            // Check completedAt
            if let completedAt = experiment.completedAt {
                if minDate == nil || completedAt < minDate! {
                    minDate = completedAt
                }
                if maxDate == nil || completedAt > maxDate! {
                    maxDate = completedAt
                }
            }

            // Check updatedAt
            if minDate == nil || experiment.updatedAt < minDate! {
                minDate = experiment.updatedAt
            }
            if maxDate == nil || experiment.updatedAt > maxDate! {
                maxDate = experiment.updatedAt
            }
        }

        let today = Date()
        return (earliest: minDate ?? today, latest: maxDate ?? today)
    }

    // Find the most recent activity date across all experiments (for reference)
    private var referenceDate: Date {
        activityDateRange.latest
    }

    // Calculate the Monday of the week for a given date
    private func monday(for date: Date) -> Date {
        let calendar = Calendar.current
        let dateStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dateStart)  // 1=Sun, 2=Mon, ..., 7=Sat
        let offsetToMonday = (weekday + 5) % 7  // Mon->0, Tue->1, ..., Sun->6
        return calendar.date(byAdding: .day, value: -offsetToMonday, to: dateStart)!
    }

    // Calculate weeks between two Mondays
    private func weeksBetween(from: Date, to: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.weekOfYear], from: from, to: to).weekOfYear ?? 0
    }

    // Week bounds
    private var weekBounds: (min: Int, max: Int) {
        //let calendar = Calendar.current
        let referenceMonday = monday(for: referenceDate)
        let earliestMonday = monday(for: activityDateRange.earliest)
        let today = Date()
        let latestActivityMonday = monday(for: activityDateRange.latest)
        let todayMonday = monday(for: today)

        // Do not allow beyond today's week
        let latestMonday = latestActivityMonday < todayMonday ? latestActivityMonday : todayMonday

        let minWeekOffset = weeksBetween(from: referenceMonday, to: earliestMonday)
        let maxWeekOffset = weeksBetween(from: referenceMonday, to: latestMonday)

        return (min: minWeekOffset, max: maxWeekOffset)
    }

    // Get the displayed week based on reference date and offset
    private var displayedWeekStart: Date {
        let calendar = Calendar.current
        let baseMonday = monday(for: referenceDate)
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseMonday)!
    }

    private var currentWeekDays: [Date] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            calendar.date(byAdding: .day, value: offset, to: displayedWeekStart)!
        }
    }

    private var weekHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: displayedWeekStart))"
    }

    private func jumpToToday() {
        let calendar = Calendar.current
        let todayMonday = monday(for: Date())
        let referenceMonday = monday(for: referenceDate)

        // Calculate weeks difference
        if let weeks = calendar.dateComponents([.weekOfYear], from: referenceMonday, to: todayMonday).weekOfYear {
            let bounds = weekBounds
            weekOffset = min(max(weeks, bounds.min), bounds.max)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar Footprint")
                .font(.headline)

            // Week navigation header
            HStack {
                // Previous week button
                Button(action: {
                    let bounds = weekBounds
                    weekOffset = max(weekOffset - 1, bounds.min)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline)
                        .foregroundColor(weekOffset <= weekBounds.min ? .gray : .blue)
                        .frame(width: 30, height: 30)
                }
                .disabled(weekOffset <= weekBounds.min)

                Spacer()

                // Week label
                Text(weekHeaderText)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Today button
                Button("Today") {
                    jumpToToday()
                }
                .font(.caption)
                .foregroundColor(.blue)

                // Next week button
                Button(action: {
                    let bounds = weekBounds
                    weekOffset = min(weekOffset + 1, bounds.max)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(weekOffset >= weekBounds.max ? .gray : .blue)
                        .frame(width: 30, height: 30)
                }
                .disabled(weekOffset >= weekBounds.max)
            }

            // Weekly row (Mon-Sun)
            HStack(spacing: 4) {
                ForEach(currentWeekDays, id: \.self) { day in
                    CalendarDayCell(day: day, experiments: experiments)
                        .onTapGesture {
                            onSelectDay(day)
                        }
                }
            }

            // See full calendar link
            NavigationLink(destination: FullCalendarView()) {
                HStack {
                    Text("See full calendar")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
    }
}

struct CalendarDayCell: View {
    let day: Date
    let experiments: [Experiment]

    private var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day)
    }

    private var dateNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day)
    }

    private var activeUpdateExperiments: [Experiment] {
        let calendar = Calendar.current
        return experiments.filter { exp in
            guard exp.status == .active else { return false }

            // Check if has log on this day
            let hasLog = exp.logs.contains { log in
                calendar.isDate(log.date, inSameDayAs: day)
            }

            // Check if created on this day
            let createdOnDay = calendar.isDate(exp.createdAt, inSameDayAs: day)

            return hasLog || createdOnDay
        }
    }

    private var activeCount: Int {
        activeUpdateExperiments.count
    }

    private var completedExperiments: [Experiment] {
        let calendar = Calendar.current
        return experiments.filter { exp in
            if let completedAt = exp.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: day)
            }
            return false
        }
    }

    private var completedCount: Int {
        completedExperiments.count
    }

    private var totalIntensity: Int {
        // Count distinct experiments that are either active updates OR completed on this day
        let activeIDs = Set(activeUpdateExperiments.map(\.id))
        let completedIDs = Set(completedExperiments.map(\.id))
        return activeIDs.union(completedIDs).count
    }

    var body: some View {
        VStack(spacing: 4) {
            // Weekday
            Text(weekdayLabel)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Date number
            Text(dateNumber)
                .font(.caption)
                .fontWeight(.medium)

            // Status icons row
            HStack(spacing: 2) {
                if activeCount > 0 {
                    Image(systemName: "pencil.circle")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                if completedCount > 0 {
                    Image(systemName: "checkmark.seal")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .frame(height: 12)

            // Intensity dots row
            HStack(spacing: 1) {
                if totalIntensity > 0 {
                    let displayCount = min(totalIntensity, 5)
                    ForEach(0..<displayCount, id: \.self) { _ in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)
                    }
                    if totalIntensity > 5 {
                        Image(systemName: "plus")
                            .font(.system(size: 6))
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Stub Views

struct FullCalendarView: View {
    var body: some View {
        VStack {
            Text("Full Calendar View")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Full Calendar")
        .navigationBarTitleDisplayMode(.large)
    }
}

