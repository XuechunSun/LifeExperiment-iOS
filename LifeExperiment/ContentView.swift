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
        case logging
        case logged
    }

    @State private var status: LoggingStatus = .idle
    @State private var dayCount: Int = 9

    var message: String {
        switch status {
        case .idle:
            return "Life Experiment 🌱"
        case .logging:
            return "Life Experiment 🌱"
        case .logged:
            return "Experiment Logged 🌿"
        }
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
    
    var idleSection: some View {
        Button("Log Today") {
            status = .logging
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                status = .logged
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

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            if status == .idle {
                idleSection
            }
            
            if status == .logging {
                loggingSection
            }
            
            if status == .logged {
                loggedSection
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
