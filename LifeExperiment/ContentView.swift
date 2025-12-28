//
//  ContentView.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 12/20/25.
//

import SwiftUI

struct ContentView: View {
    enum LoggingStatus: String {
        case idle
        case logging
        case logged
    }

    // Persistent storage
    @AppStorage("dayCount") private var dayCount: Int = 1
    @AppStorage("statusRaw") private var statusRaw: String = LoggingStatus.idle.rawValue
    @AppStorage("historyData") private var historyData: Data = .init()
    
    // Navigation state
    @State private var selectedDay: Int?

    // MARK: - Persistence helpers

    private func getStatus() -> LoggingStatus {
        LoggingStatus(rawValue: statusRaw) ?? .idle
    }

    private func setStatus(_ newStatus: LoggingStatus) {
        statusRaw = newStatus.rawValue
    }

    private func getHistory() -> [Int] {
        (try? JSONDecoder().decode([Int].self, from: historyData)) ?? []
    }

    private func setHistory(_ newHistory: [Int]) {
        if let encoded = try? JSONEncoder().encode(newHistory) {
            historyData = encoded
        }
    }

    var message: String {
        switch getStatus() {
        case .idle:
            return "Life Experiment 🌱"
        case .logging:
            return "Life Experiment 🌱"
        case .logged:
            return "Experiment Logged 🌿"
        }
    }

    func moveToNextDay() {
        // Only record day if not already in history (prevents duplicates)
        var h = getHistory()
        if !h.contains(dayCount) {
            h.append(dayCount)
            setHistory(h)
        }
        dayCount += 1
        setStatus(.idle)
    }

    var headerSection: some View {
        VStack(spacing: 8) {
            Text("Day \(dayCount)")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(message)
                .font(.title)
        }
    }

    var historySection: some View {
        let h = getHistory()
        return Group {
            if !h.isEmpty {
                VStack(spacing: 8) {
                    Text("Completed:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        ForEach(h, id: \.self) { day in
                            Button("Day \(day)") {
                                selectedDay = day
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    var idleSection: some View {
        Button("Log Today") {
            setStatus(.logging)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                setStatus(.logged)
            }
        }
    }

    var loggingSection: some View {
        Text("Saving...")
            .foregroundColor(.secondary)
            .italic()
    }

    var loggedSection: some View {
        VStack(spacing: 12) {
            Text("Logged ✓")
                .foregroundColor(.green)

            HStack(spacing: 12) {
                Button("Next Day") {
                    moveToNextDay()
                }
                .buttonStyle(.bordered)

                Button("Log out") {
                    setStatus(.idle)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                headerSection

                historySection

                if getStatus() == .idle {
                    idleSection
                }

                if getStatus() == .logging {
                    loggingSection
                }

                if getStatus() == .logged {
                    loggedSection
                }
            }
            .padding()
            .navigationDestination(item: $selectedDay) { day in
                dayDetailView(for: day)
            }
        }
    }
    
    func dayDetailView(for day: Int) -> some View {
        VStack(spacing: 20) {
            Text("Day \(day)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Details for Day \(day)")
                .foregroundColor(.secondary)
            
            Text("You completed your experiment on this day! 🎉")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("Day \(day)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
