import SwiftUI

struct FullCalendarView: View {
    private struct DaySelection: Identifiable, Hashable {
        let date: Date
        var id: TimeInterval { date.timeIntervalSince1970 }
    }

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    let loggedDates: Set<Date>
    let experiments: [Experiment]
    var lowEnergyLogs: [LowEnergyLog] = []
    let onUpdate: (Experiment) -> Void

    @State private var selectedDay: DaySelection?
    @State private var hasAutoScrolledToToday: Bool = false
    private let calendar = Calendar.current

    private var normalizedLoggedDates: Set<Date> {
        Set(loggedDates.map { calendar.startOfDay(for: $0) })
    }

    private func startOfMonth(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        guard first > 0, first < symbols.count else { return symbols }
        return Array(symbols[first...] + symbols[..<first])
    }

    private func monthTitle(for date: Date) -> String {
        FullCalendarView.monthTitleFormatter.calendar = calendar
        return FullCalendarView.monthTitleFormatter.string(from: date)
    }

    private var todayMonthStart: Date {
        startOfMonth(Date())
    }

    private var minMonthStart: Date {
        if let earliest = normalizedLoggedDates.min() {
            let earliestMonthStart = startOfMonth(earliest)
            let shifted = calendar.date(byAdding: .month, value: -3, to: earliestMonthStart) ?? earliestMonthStart
            return startOfMonth(shifted)
        }
        let shifted = calendar.date(byAdding: .month, value: -12, to: todayMonthStart) ?? todayMonthStart
        return startOfMonth(shifted)
    }

    private var maxMonthStart: Date {
        let shifted = calendar.date(byAdding: .month, value: 6, to: todayMonthStart) ?? todayMonthStart
        return startOfMonth(shifted)
    }

    private var monthStarts: [Date] {
        var result: [Date] = []
        var cursor = startOfMonth(minMonthStart)
        while cursor <= maxMonthStart {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = startOfMonth(next)
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button("Today") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(todayMonthStart, anchor: .top)
                        }
                    }
                    .font(DSText.subheadline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(monthStarts, id: \.self) { monthStart in
                            MonthGrid(
                                monthTitle: monthTitle(for: monthStart),
                                monthStart: monthStart,
                                normalizedLoggedDates: normalizedLoggedDates,
                                lowEnergyLogs: lowEnergyLogs,
                                calendar: calendar,
                                weekdaySymbols: weekdaySymbols,
                                selectedDate: selectedDay?.date,
                                onSelectDay: { day in
                                    selectedDay = DaySelection(date: day)
                                }
                            )
                            .id(monthStart)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .onAppear {
                guard !hasAutoScrolledToToday else { return }
                hasAutoScrolledToToday = true
                DispatchQueue.main.async {
                    proxy.scrollTo(todayMonthStart, anchor: .top)
                }
            }
        }
        .navigationTitle("Full Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDay) { selection in
            DayDetailView(day: selection.date, experiments: experiments, lowEnergyLogs: lowEnergyLogs, onUpdate: onUpdate)
        }
    }
}

private struct MonthGrid: View {
    let monthTitle: String
    let monthStart: Date
    let normalizedLoggedDates: Set<Date>
    var lowEnergyLogs: [LowEnergyLog] = []
    let calendar: Calendar
    let weekdaySymbols: [String]
    let selectedDate: Date?
    let onSelectDay: (Date) -> Void

    private var monthGridDates: [Date] {
        let weekdayOfMonthStart = calendar.component(.weekday, from: monthStart)
        let leading = (weekdayOfMonthStart - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart) ?? monthStart
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let totalSpan = leading + daysInMonth
        let weeksNeeded = max(1, (totalSpan + 6) / 7)
        let cellCount = weeksNeeded * 7
        return (0..<cellCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthTitle)
                .font(DSText.subheadline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(DSText.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(monthGridDates, id: \.self) { date in
                    let day = calendar.component(.day, from: date)
                    let isInDisplayedMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
                    let isToday = calendar.isDateInToday(date)
                    let normalized = calendar.startOfDay(for: date)
                    let isLogged = normalizedLoggedDates.contains(normalized)
                    let hasLowEnergy = lowEnergyLogs.contains { calendar.isDate($0.date, inSameDayAs: normalized) }
                    let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: normalized) } ?? false

                    Button(action: {
                        onSelectDay(normalized)
                    }) {
                        VStack(spacing: 4) {
                            Text("\(day)")
                                .font(DSText.subheadline)
                                .fontWeight((isToday || isSelected) ? .semibold : .regular)
                                .foregroundColor(isInDisplayedMonth ? .primary : .secondary.opacity(0.5))

                            HStack(spacing: 2) {
                                Circle()
                                    .fill(isLogged ? Color.blue : Color.clear)
                                    .frame(width: 5, height: 5)
                                if hasLowEnergy {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(.green.opacity(0.7))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Color.blue.opacity(0.22) : (isToday ? Color.blue.opacity(0.15) : Color.clear))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

