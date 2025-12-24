//
//  ContentView.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 12/20/25.
//

import SwiftUI

struct ContentView: View {
    enum LoggingStatus {
        case idle
        case logged
    }

    @State private var status: LoggingStatus = .idle
    @State private var dayCount: Int = 9

    var message: String {
        switch status {
        case .idle:
            return "Life Experiment 🌱"
        case .logged:
            return "Experiment Logged 🌿"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Day \(dayCount)")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(message)
                .font(.title)

            if status == .idle {
                Button("Log Today") {
                    status = .logged
                }
            }

            if status == .logged {
                VStack(spacing: 12) {
                    Text("Logged ✓")
                        .foregroundColor(.green)

                    HStack(spacing: 12) {
                        Button("Next Day") {
                            dayCount += 1
                            status = .idle
                        }
                        .buttonStyle(.bordered)

                        Button("Log out") {
                            status = .idle
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
