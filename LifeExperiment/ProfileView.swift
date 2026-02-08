//
//  ProfileView.swift
//  LifeExperiment
//
//  Created on 1/27/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar section
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Life Experimenter")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Tracking your journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Divider()
                    .padding(.horizontal)
                
                // Settings button
                VStack(spacing: 12) {
                    Button(action: {
                        // Placeholder action
                    }) {
                        HStack {
                            Image(systemName: "gearshape")
                                .font(.title3)
                            Text("Settings")
                                .font(.body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }
}
