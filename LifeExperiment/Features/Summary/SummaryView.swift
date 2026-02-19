import SwiftUI

// MARK: - Summary View (Week 4 Structure)

struct SummaryView: View {
    let loadExperiments: () -> [Experiment]
    let onUpdate: (Experiment) -> Void
    let seedCatalog: SeedCatalog?

    @State private var showFullCalendar: Bool = false
    @State private var selectedDay: Date?
    @State private var showCreateStorageBox: Bool = false

    // Toggle to show/hide Calendar Footprint (currently hidden for v1)
    private let showCalendarFootprint: Bool = false

    var experiments: [Experiment] {
        loadExperiments()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Module 1: Dimension Insights (v1) - Now at top
                DimensionInsightsView(experiments: experiments)

                Divider()

                // Module 2: Storage Boxes by Category
                StorageBoxesView(experiments: experiments, seedCatalog: seedCatalog, onUpdate: onUpdate, showCreateStorageBox: $showCreateStorageBox)

                // Module 3: Calendar Footprint (hidden for v1, can be restored later)
                if showCalendarFootprint {
                    Divider()

                    CalendarFootprintView(experiments: experiments, onSelectDay: { day in
                        selectedDay = day
                    })
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showFullCalendar) {
            FullCalendarView()
        }
        .navigationDestination(item: $selectedDay) { day in
            DayDetailView(day: day, experiments: experiments, onUpdate: onUpdate)
        }
        .navigationDestination(isPresented: $showCreateStorageBox) {
            CreateStorageBoxView()
        }
    }
}

