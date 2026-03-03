//
//  ProfileView.swift
//  LifeExperiment
//
//  Created on 1/27/26.
//

import SwiftUI

struct ProfileView: View {
    // Placeholder-only until cloud sync is implemented.
    @AppStorage("pref_cloud_sync_enabled") private var cloudSyncEnabled: Bool = false
    @AppStorage("auth_is_signed_in") private var isSignedIn: Bool = false
    @AppStorage("auth_display_name") private var authDisplayName: String = "Life Experimenter"

    @State private var showSignInSheet = false
    @State private var showSignOutConfirm = false

    private var preferences = AppPreferences()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.blue)

                    if isSignedIn {
                        Text(authDisplayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text("Signed in")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Using LifeExperiment locally")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text("Sign in to back up and sync across devices.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferences")
                        .font(.headline)

                    VStack(spacing: 0) {
                        HStack {
                            Text("UI Style")
                            Spacer()
                            Picker("UI Style", selection: preferences.uiStyleBinding) {
                                ForEach(UIStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.vertical, 12)

                        Divider()

                        Toggle("Image logging", isOn: preferences.imageLoggingEnabledBinding)
                            .padding(.vertical, 12)
                    }
                    .padding(.horizontal, preferences.uiStyle.cardPadding)
                    .background(Color(.systemGray6))
                    .cornerRadius(preferences.uiStyle.cardCornerRadius)

                    Text("UI style updates will roll out gradually.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Data & System")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Cloud sync", isOn: $cloudSyncEnabled)
                            .padding(.vertical, 6)
                            .disabled(true)

                        Text("Coming soon")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, preferences.uiStyle.cardPadding)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(preferences.uiStyle.cardCornerRadius)
                }

                Button {
                    if isSignedIn {
                        showSignOutConfirm = true
                    } else {
                        showSignInSheet = true
                    }
                }
                label: {
                    Text(isSignedIn ? "Sign out" : "Sign in")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: Binding(
            get: { showSignInSheet && !isSignedIn },
            set: { showSignInSheet = $0 }
        )) {
            AuthOptionsSheet()
        }
        .alert("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Sign out", role: .destructive) {
                isSignedIn = false
            }
        } message: {
            Text("You can continue using the app locally.")
        }
    }
}
