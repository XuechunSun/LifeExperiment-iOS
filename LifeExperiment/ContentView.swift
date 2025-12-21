//
//  ContentView.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 12/20/25.
//

import SwiftUI

struct ContentView: View {
    @State private var message = "Life Experiment 🌱"
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.title)

            Button("Log Today") {
                message = "Logged ✔︎"
            }
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
